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
	for _, d := range decisions {
		key := d.Spec.Table + "\x00" + d.Spec.Column
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
	var out []valueindex.ColumnSpec
	for tName, table := range c.Tables {
		if table == nil {
			continue
		}
		for _, col := range table.Columns {
			spec := valueindex.ColumnSpec{
				Table:    tName,
				Column:   col.Name,
				DeclType: col.Type,
				IsPK:     col.IsPrimaryKey,
				NRows:    table.RowCount,
				Policy:   col.ValueIndexPolicy,
			}
			if col.ValueStats != nil {
				spec.NDV = col.ValueStats.DistinctCount
			}
			out = append(out, spec)
		}
	}
	return out
}
