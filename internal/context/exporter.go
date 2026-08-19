package context

import (
	"fmt"
	"sort"
	"strings"
	"time"
)

// ExportOptions export options
type ExportOptions struct {
	// Tables to export (empty = all)
	Tables []string
	// Include detailed column info
	IncludeColumns bool
	// Include index info
	IncludeIndexes bool
	// Include Rich Context
	IncludeRichContext bool
	// Include statistics
	IncludeStats bool
	// Include inline value samples/enums/ranges.
	IncludeValueStats bool
	// Include baked official column meanings.
	IncludeOfficialMeaning bool
	// Include deterministic sparse profile notes.
	IncludeProfileNL bool
	// Include per-table FK relationship summaries.
	IncludeRelationships bool
	// Restrict meaning/profile to these lower-case "table.column" keys.
	// Nil means all columns; a non-nil empty map means no columns.
	GroundingColumns map[string]struct{}
}

// DefaultExportOptions default export options
func DefaultExportOptions() *ExportOptions {
	return &ExportOptions{
		Tables:                 nil, // Export all tables
		IncludeColumns:         true,
		IncludeIndexes:         true,
		IncludeRichContext:     true,
		IncludeStats:           true,
		IncludeValueStats:      true,
		IncludeOfficialMeaning: true,
		IncludeProfileNL:       true,
		IncludeRelationships:   true,
	}
}

func groundingColumnSelected(opts *ExportOptions, tableName, columnName string) bool {
	if opts == nil || opts.GroundingColumns == nil {
		return true
	}
	_, ok := opts.GroundingColumns[strings.ToLower(tableName+"."+columnName)]
	return ok
}

// formatColumnGrounding appends baked meaning and sparse, actionable profile notes.
func formatColumnGrounding(tableName string, col ColumnMetadata, opts *ExportOptions) string {
	if opts == nil || !groundingColumnSelected(opts, tableName, col.Name) {
		return ""
	}
	var parts []string
	if opts.IncludeOfficialMeaning {
		m := strings.TrimSpace(col.OfficialMeaning)
		if m != "" {
			parts = append(parts, m)
		}
	}
	if opts.IncludeProfileNL {
		p := BuildSparseProfileNL(col)
		if p != "" {
			parts = append(parts, p)
		}
	}
	if len(parts) == 0 {
		return ""
	}
	s := strings.Join(parts, " | ")
	if len(s) > 220 {
		s = s[:217] + "..."
	}
	return " // " + s
}

func sortedRichContextKeys(notes map[string]RichContextValue) []string {
	keys := make([]string, 0, len(notes))
	for key := range notes {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
}

// appendRichContextNotes keeps prompt order deterministic across runs.
func appendRichContextNotes(sb *strings.Builder, notes map[string]RichContextValue, indent string) {
	for _, key := range sortedRichContextKeys(notes) {
		note := notes[key]
		expiredTag := ""
		if note.ExpiresAt != "" {
			expiresAt, err := time.Parse(time.RFC3339, note.ExpiresAt)
			if err == nil && time.Now().After(expiresAt) {
				expiredTag = " [EXPIRED]"
			}
		}
		sb.WriteString(fmt.Sprintf("%s* %s: %s%s\n", indent, formatKey(key), note.Content, expiredTag))
	}
}

// ExportToPrompt exports to LLM-friendly Prompt format
func (c *SharedContext) ExportToPrompt(opts *ExportOptions) string {
	if opts == nil {
		opts = DefaultExportOptions()
	}

	var sb strings.Builder

	// 1. Database overview
	sb.WriteString("# Database Schema Context\n\n")
	sb.WriteString(fmt.Sprintf("**Database**: %s (%s)\n", c.DatabaseName, c.DatabaseType))

	// Filter tables to export
	tables := c.filterTables(opts.Tables)
	sb.WriteString(fmt.Sprintf("**Tables**: %d\n\n", len(tables)))

	// 2. Table details
	for _, tableName := range tables {
		table, exists := c.Tables[tableName]
		if !exists {
			continue
		}

		sb.WriteString("---\n\n")
		sb.WriteString(fmt.Sprintf("## Table: `%s`\n\n", table.Name))

		// Statistics
		if opts.IncludeStats {
			sb.WriteString(fmt.Sprintf("- **Row Count**: %d\n", table.RowCount))
			sb.WriteString(fmt.Sprintf("- **Columns**: %d\n", len(table.Columns)))
			sb.WriteString(fmt.Sprintf("- **Indexes**: %d\n\n", len(table.Indexes)))
		}

		// Table comment / LLM description
		if table.Description != "" {
			sb.WriteString(fmt.Sprintf("**Description**: %s\n\n", table.Description))
		} else if table.Comment != "" {
			sb.WriteString(fmt.Sprintf("**Description**: %s\n\n", table.Comment))
		}

		// Rich Context (business info and quality issues)
		if opts.IncludeRichContext {
			// Show structured quality issues first
			if len(table.QualityIssues) > 0 {
				sb.WriteString("### ⚠️ Data Quality Issues\n\n")
				sb.WriteString("> **CRITICAL**: These issues directly affect SQL query correctness.\n\n")
				for _, issue := range table.QualityIssues {
					sb.WriteString(fmt.Sprintf("- **[%s] %s**: %s → Fix: `%s`\n",
						issue.Severity, issue.Column, issue.Description, issue.SQLFix))
				}
				sb.WriteString("\n")
			}

			// Then show LLM-generated business context (skip old quality_issue keys)
			if len(table.RichContext) > 0 {
				businessContext := make(map[string]RichContextValue)
				for key, note := range table.RichContext {
					if strings.Contains(key, "quality_issue") || strings.Contains(key, "orphan_issue") {
						continue
					}
					if strings.HasSuffix(key, "_columns") || strings.HasSuffix(key, "_indexes") ||
						strings.HasSuffix(key, "_rowcount") || strings.HasSuffix(key, "_foreignkeys") {
						continue
					}
					businessContext[key] = note
				}

				if len(businessContext) > 0 {
					sb.WriteString("### Business Context\n\n")
					for _, key := range sortedRichContextKeys(businessContext) {
						sb.WriteString(fmt.Sprintf("- **%s**: %s\n", formatKey(key), businessContext[key].Content))
					}
					sb.WriteString("\n")
				}
			}
		}

		// Column info
		if opts.IncludeColumns && len(table.Columns) > 0 {
			sb.WriteString("### Columns\n\n")
			sb.WriteString("| Column | Type | Nullable | Default | Key | Comment |\n")
			sb.WriteString("|--------|------|----------|---------|-----|----------|\n")

			for _, col := range table.Columns {
				nullable := "NO"
				if col.Nullable {
					nullable = "YES"
				}

				key := ""
				if col.IsPrimaryKey {
					key = "PRI"
				}

				defaultVal := col.DefaultValue
				if defaultVal == "" {
					defaultVal = "-"
				}

				comment := col.Comment
				if comment == "" {
					comment = "-"
				}

				sb.WriteString(fmt.Sprintf("| `%s` | %s | %s | %s | %s | %s |\n",
					col.Name, col.Type, nullable, defaultVal, key, comment))
			}
			sb.WriteString("\n")
		}

		// Index info
		if opts.IncludeIndexes && len(table.Indexes) > 0 {
			sb.WriteString("### Indexes\n\n")
			for _, idx := range table.Indexes {
				indexType := "INDEX"
				if idx.IsPrimary {
					indexType = "PRIMARY KEY"
				} else if idx.IsUnique {
					indexType = "UNIQUE INDEX"
				}

				sb.WriteString(fmt.Sprintf("- **%s** `%s` on (%s)\n",
					indexType, idx.Name, strings.Join(idx.Columns, ", ")))
			}
			sb.WriteString("\n")
		}

		// Foreign key relationships (simple format)
		if len(table.ForeignKeys) > 0 {
			sb.WriteString("### Foreign Keys\n\n")
			for _, fk := range table.ForeignKeys {
				card := fk.Cardinality
				if card == "" {
					card = "?"
				}
				extra := ""
				if fk.AvgChildren > 1.05 {
					extra = fmt.Sprintf(" (avg %.1f children/parent)", fk.AvgChildren)
				}
				sb.WriteString(fmt.Sprintf("- `%s` → `%s.%s` [%s]%s\n",
					fk.ColumnName, fk.ReferencedTable, fk.ReferencedColumn, card, extra))
			}
			sb.WriteString("\n")
		}
	}

	return sb.String()
}

// ExportTableToPrompt exports single table as Prompt format
func (c *SharedContext) ExportTableToPrompt(tableName string) string {
	opts := DefaultExportOptions()
	opts.Tables = []string{tableName}
	return c.ExportToPrompt(opts)
}

// ExportToCompactPrompt exports as compact Prompt format (for Schema Linking)
func (c *SharedContext) ExportToCompactPrompt(opts *ExportOptions) string {
	if opts == nil {
		opts = DefaultExportOptions()
	}

	var sb strings.Builder

	// Database info
	sb.WriteString(fmt.Sprintf("Database: %s\n\n", c.DatabaseName))

	// Filter tables to export
	tables := c.filterTables(opts.Tables)

	for _, tableName := range tables {
		table, exists := c.Tables[tableName]
		if !exists {
			continue
		}

		// Table name, row count, description
		if table.Description != "" {
			sb.WriteString(fmt.Sprintf("Table %s (%d rows): %s\n", table.Name, table.RowCount, table.Description))
		} else if table.Comment != "" {
			sb.WriteString(fmt.Sprintf("Table %s (%d rows): %s\n", table.Name, table.RowCount, table.Comment))
		} else {
			sb.WriteString(fmt.Sprintf("Table %s (%d rows):\n", table.Name, table.RowCount))
		}

		// Column info (compact format with inline value stats)
		if opts.IncludeColumns {
			for _, col := range table.Columns {
				pk := ""
				if col.IsPrimaryKey {
					pk = " [PK]"
				}
				// Check if foreign key (+ cardinality)
				fkInfo := ""
				for _, fk := range table.ForeignKeys {
					if fk.ColumnName == col.Name {
						card := fk.Cardinality
						if card == "" {
							card = "N:1"
						}
						fkInfo = fmt.Sprintf(" → %s.%s [%s]", fk.ReferencedTable, fk.ReferencedColumn, card)
						if fk.AvgChildren > 1.05 {
							fkInfo += fmt.Sprintf(" ~%.1fx", fk.AvgChildren)
						}
						break
					}
				}

				// Inline value stats annotation
				statsInfo := ""
				if opts.IncludeValueStats && col.ValueStats != nil {
					vs := col.ValueStats
					if vs.DistinctCount > 0 && vs.DistinctCount <= 30 && len(vs.TopValues) > 0 {
						// Enum display (aligned with storage threshold)
						vals := make([]string, 0, len(vs.TopValues))
						for _, tv := range vs.TopValues {
							if len(vals) >= 8 {
								vals = append(vals, "...")
								break
							}
							vals = append(vals, fmt.Sprintf("%s(%d)", tv.Value, tv.Count))
						}
						statsInfo = fmt.Sprintf(" values=[%s]", strings.Join(vals, ", "))
					} else if len(vs.SampleValues) > 0 {
						vals := make([]string, 0, len(vs.SampleValues))
						for _, s := range vs.SampleValues {
							if len(vals) >= 6 {
								vals = append(vals, "...")
								break
							}
							vals = append(vals, s)
						}
						statsInfo = fmt.Sprintf(" samples=[%s]", strings.Join(vals, ", "))
					} else if vs.Range != nil {
						statsInfo = fmt.Sprintf(" range=[%.0f..%.0f]", vs.Range.Min, vs.Range.Max)
					}
				}

				// Grounding note: prefer baked official meaning; append profile_nl when useful
				groundInfo := formatColumnGrounding(table.Name, col, opts)

				sb.WriteString(fmt.Sprintf("  - %s: %s%s%s%s%s\n", col.Name, col.Type, pk, fkInfo, statsInfo, groundInfo))
			}
		}

		// FK already appears on the column line; only keep 1:N fan-out warnings.
		if opts.IncludeRelationships {
			if warn := formatFanoutJoins(table); warn != "" {
				sb.WriteString(warn)
			}
		}

		// Structured quality issues (from deterministic checker)
		if opts.IncludeRichContext && len(table.QualityIssues) > 0 {
			sb.WriteString("  ⚠️ Data Quality Issues:\n")
			for _, issue := range table.QualityIssues {
				sb.WriteString(fmt.Sprintf("    * [%s] %s.%s: %s → Fix: %s\n",
					issue.Severity, issue.Table, issue.Column, issue.Description, issue.SQLFix))
			}
		}

		// Rich Context (LLM notes that are not already on the column line)
		if opts.IncludeRichContext && len(table.RichContext) > 0 {
			businessNotes := make(map[string]RichContextValue)
			for key, note := range table.RichContext {
				if skipDuplicateRichContextNote(key, table, opts) {
					continue
				}
				businessNotes[key] = note
			}

			if len(businessNotes) > 0 {
				sb.WriteString("  Business Notes:\n")
				appendRichContextNotes(&sb, businessNotes, "    ")
			}
		}

		sb.WriteString("\n")
	}

	return sb.String()
}

// ExportToSchemaLinking exports as Schema Linking format (most compact)
func (c *SharedContext) ExportToSchemaLinking(tableNames []string) string {
	var sb strings.Builder

	tables := c.filterTables(tableNames)

	for i, tableName := range tables {
		table, exists := c.Tables[tableName]
		if !exists {
			continue
		}

		if i > 0 {
			sb.WriteString(" | ")
		}

		// Table name
		sb.WriteString(table.Name)
		sb.WriteString(" (")

		// Column name list
		colNames := make([]string, len(table.Columns))
		for j, col := range table.Columns {
			if col.IsPrimaryKey {
				colNames[j] = col.Name + "*"
			} else {
				colNames[j] = col.Name
			}
		}
		sb.WriteString(strings.Join(colNames, ", "))
		sb.WriteString(")")
	}

	return sb.String()
}

// BuildCrossTableQualitySummary builds a compact quality summary from ALL tables,
// focusing on issues that affect cross-table JOINs and commonly-misused columns.
// selectedTables controls which tables get per-table detail; issues from other tables
// that reference a selected table (e.g., orphan FK) are also included.
func (c *SharedContext) BuildCrossTableQualitySummary(selectedTables []string) string {
	c.mu.RLock()
	defer c.mu.RUnlock()

	selected := make(map[string]bool, len(selectedTables))
	for _, t := range selectedTables {
		selected[t] = true
	}

	// Collect cross-table-relevant issues from ALL tables
	type issueEntry struct {
		table string
		issue QualityIssue
	}
	var crossIssues []issueEntry

	for tableName, table := range c.Tables {
		if selected[tableName] {
			continue // per-table Quality Issues already listed in compact prompt
		}
		for _, qi := range table.QualityIssues {
			if qi.Type == "orphan" {
				crossIssues = append(crossIssues, issueEntry{tableName, qi})
				continue
			}
			if qi.Type == "whitespace" || qi.Type == "type_mismatch" {
				for _, op := range qi.AffectedOps {
					if op == "JOIN" {
						crossIssues = append(crossIssues, issueEntry{tableName, qi})
						break
					}
				}
			}
		}
	}

	if len(crossIssues) == 0 {
		return ""
	}

	var sb strings.Builder
	sb.WriteString("Cross-Table Data Quality Warnings:\n")
	for _, entry := range crossIssues {
		sb.WriteString(fmt.Sprintf("- %s.%s: %s → %s\n",
			entry.table, entry.issue.Column, entry.issue.Description, entry.issue.SQLFix))
	}
	return sb.String()
}

// filterTables filters tables to export
func (c *SharedContext) filterTables(tableNames []string) []string {
	c.mu.RLock()
	defer c.mu.RUnlock()

	// If no tables specified, return all
	if len(tableNames) == 0 {
		result := make([]string, 0, len(c.Tables))
		for name := range c.Tables {
			result = append(result, name)
		}
		return result
	}

	// Filter existing tables
	result := make([]string, 0, len(tableNames))
	for _, name := range tableNames {
		if _, exists := c.Tables[name]; exists {
			result = append(result, name)
		}
	}
	return result
}

func formatFanoutJoins(table *TableMetadata) string {
	if table == nil {
		return ""
	}
	var b strings.Builder
	n := 0
	for _, fk := range table.ForeignKeys {
		if fk.ParentToChild != "1:N" && !(fk.Cardinality == "N:1" && fk.AvgChildren > 1.05) {
			continue
		}
		if n == 0 {
			b.WriteString("  1:N JOINs (rows may multiply):\n")
		}
		n++
		line := fmt.Sprintf("    * %s.%s → %s.%s", table.Name, fk.ColumnName, fk.ReferencedTable, fk.ReferencedColumn)
		if fk.AvgChildren > 1.05 {
			line += fmt.Sprintf(" ~%.1fx", fk.AvgChildren)
		}
		b.WriteString(line + "\n")
	}
	return b.String()
}

func skipDuplicateRichContextNote(key string, table *TableMetadata, opts *ExportOptions) bool {
	k := strings.ToLower(strings.TrimSpace(key))
	if strings.Contains(k, "quality_issue") || strings.Contains(k, "orphan_issue") {
		return true
	}
	if strings.HasSuffix(k, "_columns") || strings.HasSuffix(k, "_indexes") ||
		strings.HasSuffix(k, "_rowcount") || strings.HasSuffix(k, "_foreignkeys") {
		return true
	}
	if table == nil {
		return false
	}
	cols := make(map[string]ColumnMetadata, len(table.Columns))
	for _, col := range table.Columns {
		cols[strings.ToLower(col.Name)] = col
	}
	if opts != nil && opts.IncludeValueStats {
		if col, ok := noteColumnSuffix(k, "_values", cols); ok && columnHasInlineValues(col) {
			return true
		}
	}
	if opts != nil && opts.IncludeOfficialMeaning {
		if col, ok := noteColumnSuffix(k, "_meaning", cols); ok && strings.TrimSpace(col.OfficialMeaning) != "" {
			return true
		}
	}
	return false
}

func noteColumnSuffix(key, suffix string, cols map[string]ColumnMetadata) (ColumnMetadata, bool) {
	if !strings.HasSuffix(key, suffix) {
		return ColumnMetadata{}, false
	}
	name := strings.TrimSuffix(key, suffix)
	col, ok := cols[name]
	return col, ok
}

func columnHasInlineValues(col ColumnMetadata) bool {
	if col.ValueStats == nil {
		return false
	}
	vs := col.ValueStats
	if vs.DistinctCount > 0 && vs.DistinctCount <= 30 && len(vs.TopValues) > 0 {
		return true
	}
	if len(vs.SampleValues) > 0 || vs.Range != nil {
		return true
	}
	return false
}
