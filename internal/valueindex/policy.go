package valueindex

import (
	"regexp"
	"sort"
	"strings"
	"time"
)

// Default budget caps (iter14 / WiseCat MR90-aligned, per DB).
const (
	DefaultMaxColumns       = 64
	DefaultEntityColumns    = 40
	DefaultCategoryColumns  = 24
	DefaultEntityNDVCap     = 50_000
	DefaultCategoryNDVCap   = 5_000
	DefaultMaxDocuments     = 100_000
	DefaultMaxValueRunes    = 256
	DefaultExactDistinctMax = int64(2_000_000)
	DefaultSampleDistinct   = 50_000
)

var (
	skipNameRe = regexp.MustCompile(`(?i)(^id$|_id$|uuid|guid|hash|password|passwd|token|secret|email|phone|mobile|ssn|url|path|blob|payload|json|xml|content|description|comment|remark|note|body|text$)`)
	hardDropRe = regexp.MustCompile(`(?i)(created|updated|timestamp|_at$|date|time$|latitude|longitude|address|message|summary|keyword|apicalls|item_number|case_number|acctid|projectid|methodid|photo|image|binary|postalcode|zipcode)`)
	entityRe   = regexp.MustCompile(`(?i)(name|title|brand|company|customer|product|city|country|region|state|genre|category|type|status|label|tag|author|artist|album|movie|school|team|player|vendor|supplier|client)`)
	textTypeRe = regexp.MustCompile(`(?i)(char|clob|text|varchar|nvarchar|string|nchar)`)
	nonTextRe  = regexp.MustCompile(`(?i)(int|real|floa|doub|num|dec|bool|blob)`)
)

// Options controls offline index build budgets.
type Options struct {
	MaxColumns           int
	EntityColumns        int
	CategoryColumns      int
	EntityNDVCap         int
	CategoryNDVCap       int
	MaxDocuments         int
	MaxValueRunes        int
	ExactDistinctMaxRows int64
	SampleDistinctCap    int
	ColumnQueryTimeout   time.Duration
}

// DefaultOptions returns iter14 recommended caps.
func DefaultOptions() Options {
	return Options{
		MaxColumns:           DefaultMaxColumns,
		EntityColumns:        DefaultEntityColumns,
		CategoryColumns:      DefaultCategoryColumns,
		EntityNDVCap:         DefaultEntityNDVCap,
		CategoryNDVCap:       DefaultCategoryNDVCap,
		MaxDocuments:         DefaultMaxDocuments,
		MaxValueRunes:        DefaultMaxValueRunes,
		ExactDistinctMaxRows: DefaultExactDistinctMax,
		SampleDistinctCap:    DefaultSampleDistinct,
		ColumnQueryTimeout:   20 * time.Second,
	}
}

func (o Options) withDefaults() Options {
	d := DefaultOptions()
	if o.MaxColumns <= 0 {
		o.MaxColumns = d.MaxColumns
	}
	if o.EntityColumns <= 0 {
		o.EntityColumns = d.EntityColumns
	}
	if o.CategoryColumns <= 0 {
		o.CategoryColumns = d.CategoryColumns
	}
	if o.EntityNDVCap <= 0 {
		o.EntityNDVCap = d.EntityNDVCap
	}
	if o.CategoryNDVCap <= 0 {
		o.CategoryNDVCap = d.CategoryNDVCap
	}
	if o.MaxDocuments <= 0 {
		o.MaxDocuments = d.MaxDocuments
	}
	if o.MaxValueRunes <= 0 {
		o.MaxValueRunes = d.MaxValueRunes
	}
	if o.ExactDistinctMaxRows <= 0 {
		o.ExactDistinctMaxRows = d.ExactDistinctMaxRows
	}
	if o.SampleDistinctCap <= 0 {
		o.SampleDistinctCap = d.SampleDistinctCap
	}
	if o.ColumnQueryTimeout <= 0 {
		o.ColumnQueryTimeout = d.ColumnQueryTimeout
	}
	return o
}

// Policy values for Agent/heuristic labeling (WiseCat three-state).
const (
	PolicyInclude = "include"
	PolicyExclude = "exclude"
	PolicyUnknown = "unknown"
)

// ColumnSpec describes one physical column considered for indexing.
type ColumnSpec struct {
	Table    string
	Column   string
	DeclType string
	IsPK     bool
	NRows    int64
	NDV      int    // 0 unknown; prefer ValueStats.DistinctCount when available
	Policy   string // include|exclude|unknown (empty = unknown)
}

// Lane is entity vs category selection pool.
type Lane string

const (
	LaneEntity   Lane = "entity"
	LaneCategory Lane = "category"
)

// Decision is the policy outcome for one column.
type Decision struct {
	Spec   ColumnSpec
	Lane   Lane
	Status string // indexed|hard_gate|ndv_cap|budget|non_text
	Reason string
}

// IsTextDecl reports whether a SQL type looks indexable as text.
func IsTextDecl(decl string) bool {
	d := strings.TrimSpace(decl)
	if d == "" {
		return true
	}
	if textTypeRe.MatchString(d) {
		return true
	}
	if nonTextRe.MatchString(d) {
		return false
	}
	up := strings.ToUpper(d)
	if strings.Contains(up, "DATE") || strings.Contains(up, "TIME") {
		return true
	}
	return false
}

// ClassifyLane returns entity/category or empty if hard-gated.
func ClassifyLane(col ColumnSpec) (Lane, string, string) {
	if col.IsPK {
		return "", "hard_gate", "primary_key"
	}
	if !IsTextDecl(col.DeclType) {
		return "", "non_text", "non_text_type"
	}
	name := col.Column
	if skipNameRe.MatchString(name) || hardDropRe.MatchString(name) {
		return "", "hard_gate", "name_gate"
	}
	if entityRe.MatchString(name) {
		return LaneEntity, "", ""
	}
	return LaneCategory, "", ""
}

func estimatedDocs(c ColumnSpec, ndvCap int) int {
	if c.NDV > 0 {
		return c.NDV
	}
	if c.NRows > 0 && c.NRows < int64(ndvCap) {
		return int(c.NRows)
	}
	return ndvCap
}

func sortCandidates(ds []Decision) {
	sort.Slice(ds, func(i, j int) bool {
		ai := ds[i].Spec.NDV
		aj := ds[j].Spec.NDV
		if ai == 0 {
			ai = int(ds[i].Spec.NRows)
		}
		if aj == 0 {
			aj = int(ds[j].Spec.NRows)
		}
		if ai != aj {
			return ai < aj
		}
		ki := ds[i].Spec.Table + "." + ds[i].Spec.Column
		kj := ds[j].Spec.Table + "." + ds[j].Spec.Column
		return ki < kj
	})
}

// HeuristicPolicy derives include/exclude/unknown from hard gates + name roles.
func HeuristicPolicy(col ColumnSpec) (policy, kind, reason string) {
	lane, status, reason := ClassifyLane(col)
	if lane == "" {
		return PolicyExclude, "", reason
	}
	if status != "" {
		return PolicyExclude, string(lane), reason
	}
	// Prefer indexing entity-ish names; category stays unknown so budget can trim.
	if lane == LaneEntity {
		return PolicyInclude, string(lane), "entity_name"
	}
	return PolicyUnknown, string(lane), "other_text"
}

// SelectColumns applies per-DB budgets. Prefer low-NDV columns within each lane.
// Policy exclude is always skipped; include is preferred into the entity lane.
func SelectColumns(cols []ColumnSpec, opt Options) []Decision {
	opt = opt.withDefaults()
	var rejected, entity, category []Decision

	for _, c := range cols {
		policy := strings.ToLower(strings.TrimSpace(c.Policy))
		if policy == "" {
			policy = PolicyUnknown
		}
		if policy == PolicyExclude {
			rejected = append(rejected, Decision{Spec: c, Status: "excluded", Reason: "policy_exclude"})
			continue
		}

		lane, status, reason := ClassifyLane(c)
		if policy == PolicyInclude {
			// Agent/heuristic include overrides name miss — still respect PK/non-text hard gates.
			if status == "hard_gate" || status == "non_text" {
				rejected = append(rejected, Decision{Spec: c, Status: status, Reason: reason})
				continue
			}
			if lane == "" {
				lane = LaneEntity
			}
		} else if lane == "" {
			rejected = append(rejected, Decision{Spec: c, Status: status, Reason: reason})
			continue
		}

		ndvCap := opt.EntityNDVCap
		if lane == LaneCategory {
			ndvCap = opt.CategoryNDVCap
		}
		if c.NDV > ndvCap {
			rejected = append(rejected, Decision{Spec: c, Lane: lane, Status: "ndv_cap", Reason: "ndv_over_cap"})
			continue
		}
		d := Decision{Spec: c, Lane: lane, Status: "candidate"}
		if lane == LaneEntity || policy == PolicyInclude {
			d.Lane = LaneEntity
			entity = append(entity, d)
		} else {
			category = append(category, d)
		}
	}
	sortCandidates(entity)
	sortCandidates(category)

	out := append([]Decision{}, rejected...)
	indexed := 0
	docs := 0

	pick := func(pool []Decision, colCap, ndvCap int) {
		n := 0
		for _, d := range pool {
			take := estimatedDocs(d.Spec, ndvCap)
			switch {
			case indexed >= opt.MaxColumns || n >= colCap:
				d.Status = "budget"
				d.Reason = "column_cap"
			case docs+take > opt.MaxDocuments:
				d.Status = "budget"
				d.Reason = "document_cap"
			default:
				d.Status = "indexed"
				d.Reason = "selected"
				docs += take
				indexed++
				n++
			}
			out = append(out, d)
		}
	}
	pick(entity, opt.EntityColumns, opt.EntityNDVCap)
	pick(category, opt.CategoryColumns, opt.CategoryNDVCap)
	return out
}

// IndexedColumns returns decisions marked for indexing.
func IndexedColumns(decisions []Decision) []Decision {
	var out []Decision
	for _, d := range decisions {
		if d.Status == "indexed" {
			out = append(out, d)
		}
	}
	return out
}
