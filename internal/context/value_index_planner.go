package context

import (
	"context"
	"fmt"
	"regexp"
	"strings"
	"time"

	"github.com/tmc/langchaingo/llms"

	"github.com/Zqzqsb/AtlasCore/internal/valueindex"
)

const SampledValueIndexPlannerVersion = "sampled-v1"

var (
	plannerEntityNameRe = regexp.MustCompile(`(?i)(name|title|brand|company|customer|product|city|country|region|state|genre|category|type|status|label|tag|author|artist|album|movie|school|team|player|vendor|supplier|client|description|keyword)`)
	plannerSecretRe     = regexp.MustCompile(`(?i)(password|passwd|token|secret|ssn|email|phone|mobile|blob|payload|json|xml|content|body|comment|summary|message|essay|statement|url|path|address|image|photo|binary)`)
	plannerIDNameRe     = regexp.MustCompile(`(?i)(id$|uuid|guid|hash|acctid|projectid|methodid|item_number|case_number)`)
	plannerTimeNameRe   = regexp.MustCompile(`(?i)(created|updated|timestamp|_at$|date|time$|^start$|^stop$|birthdate|period$)`)
	plannerTechnicalRe  = regexp.MustCompile(`(?i)(method|parameter|repository|repo|solution|api|commit|source_?code|file_?name)`)
)

type sampledPlan struct {
	policy     string
	kind       string
	confidence float64
	reasons    []string
	estimated  int
}

// LabelValueIndexSampled derives an index plan from value statistics already
// stored in RC. It performs no database or LLM calls and is safe to rerun when
// planner rules change.
func (c *SharedContext) LabelValueIndexSampled() (include, exclude, review int) {
	if c == nil {
		return
	}
	c.mu.Lock()
	defer c.mu.Unlock()

	mappings := map[string]struct{}{}
	if c.officialDesc != nil {
		mappings = c.officialDesc.IndexedValueColumns()
	}
	for tName, table := range c.Tables {
		if table == nil {
			continue
		}
		if table.Name == "" {
			table.Name = tName
		}
		for i := range table.Columns {
			col := &table.Columns[i]
			_, forced := mappings[strings.ToLower(tName)+"|"+strings.ToLower(col.Name)]
			plan := planSampledColumn(table, col, forced)
			col.ValueIndexPolicy = plan.policy
			col.ValueIndexPolicySource = SampledValueIndexPlannerVersion
			col.ValueIndexPolicyReason = strings.Join(plan.reasons, ",")
			col.ValueIndexConfidence = plan.confidence
			col.ValueIndexEvidence = append([]string(nil), plan.reasons...)
			col.ValueIndexEstimatedDocs = plan.estimated
			col.ValueIndexKind = plan.kind
			col.ValueIndexStatus = ""
			switch plan.policy {
			case valueindex.PolicyInclude:
				include++
			case valueindex.PolicyExclude:
				exclude++
			default:
				review++
			}
		}
	}
	if c.ValueIndex == nil {
		c.ValueIndex = &ValueIndexInfo{}
	}
	c.ValueIndex.LabelSource = SampledValueIndexPlannerVersion
	c.ValueIndex.PlannerVersion = SampledValueIndexPlannerVersion
	c.ValueIndex.PlannedAt = time.Now().UTC()
	return
}

func planSampledColumn(table *TableMetadata, col *ColumnMetadata, forced bool) sampledPlan {
	stats := col.ValueStats
	mode, observed, sampleRows, uniqueness := normalizedStats(table, stats)
	estimated := estimateDocuments(table.RowCount, mode, observed, uniqueness)
	name := col.Name
	decl := strings.ToUpper(strings.TrimSpace(col.Type))
	avgLen, shape := 0.0, ""
	if stats != nil {
		avgLen, shape = stats.AvgLen, strings.ToLower(stats.DominantShape)
	}
	reasonStats := fmt.Sprintf("ndv_%s=%d", mode, observed)

	if forced {
		return sampledPlan{valueindex.PolicyInclude, string(valueindex.LaneCategory), 1, []string{"official_value_description", reasonStats}, maxInt(observed, 1)}
	}
	if col.IsPrimaryKey {
		return sampledPlan{valueindex.PolicyExclude, "", 1, []string{"primary_key", reasonStats}, estimated}
	}
	if plannerSecretRe.MatchString(name) || strings.Contains(decl, "BLOB") {
		return sampledPlan{valueindex.PolicyExclude, "", .99, []string{"secret_or_free_text_name", reasonStats}, estimated}
	}
	if !valueindex.IsTextDecl(col.Type) || plannerTimeNameRe.MatchString(name) || strings.Contains(decl, "DATE") || strings.Contains(decl, "TIME") {
		return sampledPlan{valueindex.PolicyExclude, "", .98, []string{"non_business_text_type", reasonStats}, estimated}
	}
	if observed <= 1 {
		return sampledPlan{valueindex.PolicyExclude, "", .95, []string{"constant_or_empty", reasonStats}, estimated}
	}

	shortText := avgLen == 0 || avgLen <= 80
	highUnique := uniqueness >= .75
	opaque := (shape == "digits" || shape == "alnum") && avgLen >= 8 && highUnique
	if plannerIDNameRe.MatchString(name) && (highUnique || observed > 200) {
		return sampledPlan{valueindex.PolicyExclude, "", .97, []string{"opaque_identifier", reasonStats}, estimated}
	}
	if avgLen > 120 {
		return sampledPlan{valueindex.PolicyExclude, "", .95, []string{"long_free_text", reasonStats}, estimated}
	}

	if mode == "exact" {
		switch {
		case observed <= 200 && shortText && !opaque:
			return sampledPlan{valueindex.PolicyInclude, string(valueindex.LaneCategory), .96, []string{"low_cardinality", "short_semantic_values", reasonStats}, observed}
		case plannerEntityNameRe.MatchString(name) && observed <= valueindex.DefaultEntityNDVCap && shortText:
			return sampledPlan{valueindex.PolicyInclude, string(valueindex.LaneEntity), .9, []string{"entity_semantic_name", reasonStats}, observed}
		case observed <= valueindex.DefaultCategoryNDVCap && shortText && !opaque:
			return sampledPlan{valueindex.PolicyInclude, string(valueindex.LaneCategory), .78, []string{"bounded_cardinality", reasonStats}, observed}
		default:
			return sampledPlan{valueindex.PolicyReview, "", .55, []string{"high_cost_or_ambiguous", reasonStats}, estimated}
		}
	}

	// Sampled NDV is only a lower bound. Repetition is positive evidence for a
	// category; a mostly-unique sample from a large table must not be mistaken
	// for a small exact domain.
	switch {
	case sampleRows >= 100 && observed <= 200 && uniqueness <= .25 && shortText && !opaque:
		// Repeated values in a reasonably large sample are a bounded category.
		// Do not extrapolate observed/sampleRows to the full fact table: that
		// would turn a 2-value boolean into thousands of estimated documents.
		bounded := observed * 2
		if bounded > valueindex.DefaultCategoryNDVCap {
			bounded = valueindex.DefaultCategoryNDVCap
		}
		return sampledPlan{valueindex.PolicyInclude, string(valueindex.LaneCategory), .78, []string{"sample_repeats", "likely_low_cardinality", reasonStats}, bounded}
	case plannerTechnicalRe.MatchString(table.Name+"."+name) && observed > 200:
		return sampledPlan{valueindex.PolicyReview, "", .75, []string{"technical_identifier_like", reasonStats}, estimated}
	case plannerEntityNameRe.MatchString(name) && shortText:
		confidence := .7
		reasons := []string{"entity_semantic_name", "sample_not_unique", reasonStats}
		if highUnique {
			confidence = .64
			reasons = []string{"entity_semantic_name", "sample_high_uniqueness", "builder_budget_required", reasonStats}
		}
		return sampledPlan{valueindex.PolicyInclude, string(valueindex.LaneEntity), confidence, reasons, estimated}
	case highUnique:
		return sampledPlan{valueindex.PolicyReview, "", .7, []string{"sample_high_uniqueness", "cost_uncertain", reasonStats}, estimated}
	default:
		return sampledPlan{valueindex.PolicyReview, "", .5, []string{"sample_ambiguous", reasonStats}, estimated}
	}
}

func normalizedStats(table *TableMetadata, stats *ValueStats) (mode string, observed, sampleRows int, uniqueness float64) {
	if stats == nil {
		return "sampled", 0, 0, 0
	}
	mode = strings.ToLower(strings.TrimSpace(stats.DistinctMode))
	if mode == "" {
		if table != nil && table.RowCount <= heavyTableRowLimit {
			mode = "exact"
		} else {
			mode = "sampled"
		}
	}
	observed = stats.ObservedNDV
	if observed == 0 {
		observed = stats.DistinctCount
	}
	sampleRows = stats.SampleRows
	if sampleRows == 0 && table != nil {
		if mode == "exact" {
			sampleRows = int(table.RowCount) - stats.NullCount
		} else {
			sampleRows = minInt(int(table.RowCount), 800)
		}
	}
	uniqueness = stats.Uniqueness
	if uniqueness == 0 && sampleRows > 0 {
		uniqueness = float64(observed) / float64(sampleRows)
	}
	return
}

func estimateDocuments(rows int64, mode string, observed int, uniqueness float64) int {
	if mode == "exact" {
		return observed
	}
	if rows <= 0 {
		return observed
	}
	estimate := int(float64(rows) * uniqueness)
	if estimate < observed {
		estimate = observed
	}
	if estimate > valueindex.DefaultEntityNDVCap {
		estimate = valueindex.DefaultEntityNDVCap
	}
	return estimate
}

// LabelValueIndexSampledWithLLM asks the model only about planner review
// columns. Deterministic include/exclude decisions and official mappings stay
// untouched.
func (c *SharedContext) LabelValueIndexSampledWithLLM(ctx context.Context, model llms.Model) (include, exclude, review int, err error) {
	if model == nil {
		return 0, 0, 0, fmt.Errorf("nil llm")
	}
	c.LabelValueIndexSampled()
	type candidate struct{ key, line string }
	var candidates []candidate
	c.mu.RLock()
	for tName, table := range c.Tables {
		for _, col := range table.Columns {
			if col.ValueIndexPolicy != valueindex.PolicyReview {
				continue
			}
			vs := col.ValueStats
			samples := []string{}
			if vs != nil {
				for _, v := range vs.TopValues {
					samples = append(samples, v.Value)
					if len(samples) >= 5 {
						break
					}
				}
				if len(samples) == 0 {
					samples = append(samples, vs.SampleValues...)
					if len(samples) > 5 {
						samples = samples[:5]
					}
				}
			}
			line := fmt.Sprintf("%s.%s | type=%s rows=%d estimated_docs=%d avg_len=%.1f shape=%s meaning=%s samples=%s",
				tName, col.Name, col.Type, table.RowCount, col.ValueIndexEstimatedDocs,
				func() float64 {
					if vs != nil {
						return vs.AvgLen
					}
					return 0
				}(),
				func() string {
					if vs != nil {
						return vs.DominantShape
					}
					return ""
				}(),
				trimRunes(col.OfficialMeaning, 80), trimRunes(strings.Join(samples, ", "), 120))
			candidates = append(candidates, candidate{strings.ToLower(tName + "." + col.Name), line})
		}
	}
	c.mu.RUnlock()
	if len(candidates) == 0 {
		return c.countPolicies()
	}

	var b strings.Builder
	b.WriteString("Resolve REVIEW columns for a Text-to-SQL business-value index.\n")
	b.WriteString("Output: table.column | include|exclude|review | short reason\n")
	b.WriteString("Include meaningful filter literals. Exclude opaque IDs, free text, PII, and costly near-unique values.\nNo markdown.\n\n")
	for _, cand := range candidates {
		b.WriteString(cand.line)
		b.WriteByte('\n')
	}
	resp, err := model.Call(ctx, b.String())
	if err != nil {
		return 0, 0, 0, err
	}
	labels := parseValueIndexLabels(resp)
	c.mu.Lock()
	for tName, table := range c.Tables {
		for i := range table.Columns {
			col := &table.Columns[i]
			if col.ValueIndexPolicy != valueindex.PolicyReview {
				continue
			}
			if lab, ok := labels[strings.ToLower(tName+"."+col.Name)]; ok {
				col.ValueIndexPolicy = lab.policy
				col.ValueIndexPolicySource = SampledValueIndexPlannerVersion + "+llm"
				col.ValueIndexPolicyReason = lab.reason
				col.ValueIndexConfidence = .8
			}
		}
	}
	c.ValueIndex.LabelSource = SampledValueIndexPlannerVersion + "+llm"
	c.ValueIndex.PlannerVersion = SampledValueIndexPlannerVersion + "+llm"
	include, exclude, review = c.countPoliciesUnlocked()
	c.mu.Unlock()
	return include, exclude, review, nil
}

func minInt(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func maxInt(a, b int) int {
	if a > b {
		return a
	}
	return b
}
