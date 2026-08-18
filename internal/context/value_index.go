package context

import (
	"context"
	"fmt"
	"path/filepath"
	"strings"

	"github.com/Zqzqsb/AtlasCore/internal/valueindex"
)

// ValueIndexSidecarPath is <contextDir>/value_index/<dbID>.sqlite
func ValueIndexSidecarPath(contextDir, dbID string) string {
	return valueindex.DefaultSidecarPath(contextDir, dbID)
}

// DefaultValueIndexOptions returns iter14 per-DB caps.
func DefaultValueIndexOptions() valueindex.Options {
	return valueindex.DefaultOptions()
}

// BuildValueIndex builds a per-DB business-value inverted index sidecar and
// writes policy metadata onto this SharedContext. Values are NOT embedded in RC JSON.
//
// outPath should be the absolute sidecar path; relativePath is stored on ValueIndex.Path
// (typically "value_index/<db>.sqlite").
func (c *SharedContext) BuildValueIndex(
	ctx context.Context,
	sourceDBPath, outPath, relativePath string,
	opt valueindex.Options,
) (*valueindex.Report, error) {
	if c == nil {
		return nil, fmt.Errorf("BuildValueIndex: nil context")
	}
	cols := c.columnSpecsForValueIndex()
	if aliases := c.officialAliases(); len(aliases) > 0 {
		opt.Aliases = aliases
	}
	dbID := c.DatabaseName
	if dbID == "" {
		dbID = strings.TrimSuffix(filepath.Base(outPath), ".sqlite")
	}
	report, err := valueindex.Build(ctx, sourceDBPath, outPath, dbID, cols, opt)
	if err != nil {
		return report, err
	}

	// Re-run policy on the same specs to stamp per-column status (cheap).
	decisions := valueindex.SelectColumns(cols, opt)
	statusByKey := make(map[string]valueindex.Decision, len(decisions))
	actual := make(map[string]struct{}, len(report.IndexedColumnKeys))
	for _, key := range report.IndexedColumnKeys {
		actual[key] = struct{}{}
	}
	truncated := make(map[string]struct{}, len(report.TruncatedColumnKeys))
	for _, key := range report.TruncatedColumnKeys {
		truncated[key] = struct{}{}
	}
	for _, d := range decisions {
		key := d.Spec.Table + "\x00" + d.Spec.Column
		if d.Status == "indexed" {
			if _, ok := actual[key]; !ok {
				d.Status = "build_cap"
				d.Reason = "document_or_posting_cap"
			} else if _, ok := truncated[key]; ok {
				d.Status = "indexed_truncated"
				d.Reason = "per_column_posting_cap"
			}
		}
		statusByKey[key] = d
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	for tName, table := range c.Tables {
		if table == nil {
			continue
		}
		for i := range table.Columns {
			col := &table.Columns[i]
			d, ok := statusByKey[tName+"\x00"+col.Name]
			if !ok {
				continue
			}
			col.ValueIndexStatus = d.Status
			if d.Lane != "" {
				col.ValueIndexKind = string(d.Lane)
			}
		}
	}
	rel := relativePath
	if rel == "" {
		rel = filepath.ToSlash(filepath.Join("value_index", filepath.Base(outPath)))
	}
	labelSrc := ""
	if c.ValueIndex != nil {
		labelSrc = c.ValueIndex.LabelSource
	}
	c.ValueIndex = &ValueIndexInfo{
		Path:           rel,
		Documents:      report.Documents,
		Postings:       report.Postings,
		ColumnsIndexed: report.ColumnsIndexed,
		BuiltAt:        report.BuiltAt,
		LabelSource:    labelSrc,
	}
	return report, nil
}

func (c *SharedContext) columnSpecsForValueIndex() []valueindex.ColumnSpec {
	c.mu.RLock()
	defer c.mu.RUnlock()
	var maps map[string]struct{}
	if c.officialDesc != nil {
		maps = c.officialDesc.IndexedValueColumns()
	}
	var out []valueindex.ColumnSpec
	for tName, table := range c.Tables {
		if table == nil {
			continue
		}
		for _, col := range table.Columns {
			spec := valueindex.ColumnSpec{
				Table:              tName,
				Column:             col.Name,
				DeclType:           col.Type,
				IsPK:               col.IsPrimaryKey,
				NRows:              table.RowCount,
				Policy:             col.ValueIndexPolicy,
				EstimatedDocuments: col.ValueIndexEstimatedDocs,
				Kind:               col.ValueIndexKind,
			}
			if col.ValueStats != nil {
				spec.NDV = col.ValueStats.DistinctCount
			}
			key := strings.ToLower(tName) + "|" + strings.ToLower(col.Name)
			if _, ok := maps[key]; ok {
				spec.ForceIndex = true
				spec.Policy = valueindex.PolicyInclude
			}
			out = append(out, spec)
		}
	}
	return out
}
