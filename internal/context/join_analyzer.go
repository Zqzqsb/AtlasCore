package context

import (
	"fmt"
	"sort"
	"strings"
)

// AnalyzeJoinPaths builds direct FK join edges (1-hop) with cardinality labels.
// Full pairwise BFS is avoided — only catalog FK edges, so prompts stay compact
// while still teaching 1:N / N:1 for DISTINCT decisions.
func (c *SharedContext) AnalyzeJoinPaths() {
	c.mu.Lock()
	defer c.mu.Unlock()

	c.resolveImpliedFKColumnsLocked()

	c.JoinPaths = make(map[string]*JoinPath)
	c.FieldSemantics = make(map[string]*FieldSemantic)

	for tableName, table := range c.Tables {
		for _, fk := range table.ForeignKeys {
			card := fk.Cardinality
			if card == "" {
				card = "N:1"
			}
			parentCard := fk.ParentToChild
			if parentCard == "" {
				parentCard = "1:N"
			}

			// Child → Parent (N:1 typical)
			forwardKey := joinEdgeKey(tableName, fk.ColumnName, fk.ReferencedTable, fk.ReferencedColumn)
			clause := fmt.Sprintf("%s.%s = %s.%s",
				tableName, fk.ColumnName, fk.ReferencedTable, fk.ReferencedColumn)
			desc := fmt.Sprintf("%s.%s → %s.%s [%s]",
				tableName, fk.ColumnName, fk.ReferencedTable, fk.ReferencedColumn, card)
			if fk.AvgChildren > 1.05 {
				desc += fmt.Sprintf("; avg %.1f child rows/parent — JOIN may multiply rows; use DISTINCT when listing unique parents", fk.AvgChildren)
			}
			c.JoinPaths[forwardKey] = &JoinPath{
				FromTable:   tableName,
				ToTable:     fk.ReferencedTable,
				Path:        []string{tableName, fk.ReferencedTable},
				JoinClauses: []string{clause},
				Description: desc,
				Cardinality: card,
			}

			// Parent → Child reverse view (1:N)
			reverseKey := joinEdgeKey(fk.ReferencedTable, fk.ReferencedColumn, tableName, fk.ColumnName)
			revDesc := fmt.Sprintf("%s → %s via %s.%s [%s]",
				fk.ReferencedTable, tableName, tableName, fk.ColumnName, parentCard)
			if fk.AvgChildren > 1.05 {
				revDesc += "; selecting child after JOIN can duplicate parent rows"
			}
			c.JoinPaths[reverseKey] = &JoinPath{
				FromTable:   fk.ReferencedTable,
				ToTable:     tableName,
				Path:        []string{fk.ReferencedTable, tableName},
				JoinClauses: []string{clause},
				Description: revDesc,
				Cardinality: parentCard,
			}
		}
	}

	c.analyzeFieldSemanticsLocked()
}

func joinEdgeKey(fromTable, fromColumn, toTable, toColumn string) string {
	return fmt.Sprintf("%s.%s→%s.%s", fromTable, fromColumn, toTable, toColumn)
}

// ResolveImpliedFKColumns fills SQLite unnamed REFERENCES (PRAGMA to IS NULL)
// with the parent table's primary key. Safe to call on already-saved RC JSON
// that stored the literal "<nil>".
func (c *SharedContext) ResolveImpliedFKColumns() int {
	if c == nil {
		return 0
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.resolveImpliedFKColumnsLocked()
}

func (c *SharedContext) resolveImpliedFKColumnsLocked() int {
	n := 0
	for _, table := range c.Tables {
		if table == nil {
			continue
		}
		for i := range table.ForeignKeys {
			fk := &table.ForeignKeys[i]
			if !missingReferencedColumn(fk.ReferencedColumn) {
				continue
			}
			pks := primaryKeyColumns(c.findTableLocked(fk.ReferencedTable))
			target := impliedFKTargetColumn(fk.ColumnName, pks)
			if target == "" {
				continue
			}
			fk.ReferencedColumn = target
			n++
		}
	}
	return n
}

func (c *SharedContext) findTableLocked(name string) *TableMetadata {
	if t := c.Tables[name]; t != nil {
		return t
	}
	for n, t := range c.Tables {
		if strings.EqualFold(n, name) {
			return t
		}
	}
	return nil
}

func primaryKeyColumns(t *TableMetadata) []string {
	if t == nil {
		return nil
	}
	if len(t.PrimaryKey) > 0 {
		return append([]string{}, t.PrimaryKey...)
	}
	var out []string
	for _, col := range t.Columns {
		if col.IsPrimaryKey {
			out = append(out, col.Name)
		}
	}
	return out
}

func impliedFKTargetColumn(childCol string, pks []string) string {
	switch len(pks) {
	case 0:
		return ""
	case 1:
		return pks[0]
	default:
		for _, pk := range pks {
			if strings.EqualFold(pk, childCol) {
				return pk
			}
		}
		return ""
	}
}

// analyzeFieldSemanticsLocked assumes c.mu is held.
func (c *SharedContext) analyzeFieldSemanticsLocked() {
	for tableName, table := range c.Tables {
		for _, fk := range table.ForeignKeys {
			key := fmt.Sprintf("%s.%s", tableName, fk.ColumnName)
			cardNote := fk.Cardinality
			if cardNote == "" {
				cardNote = "N:1"
			}
			note := fmt.Sprintf("FK → %s.%s [%s]. Stores ID, not display name — JOIN parent to get names.",
				fk.ReferencedTable, fk.ReferencedColumn, cardNote)
			if fk.ParentToChild == "1:N" || (fk.AvgChildren > 1.05) {
				note += " Parent→child is 1:N: JOIN from parent multiplies rows; DISTINCT if listing unique parents."
			}
			c.FieldSemantics[key] = &FieldSemantic{
				TableName:   tableName,
				ColumnName:  fk.ColumnName,
				StorageType: "foreign_key",
				References:  fmt.Sprintf("%s.%s", fk.ReferencedTable, fk.ReferencedColumn),
				Note:        note,
			}
		}

		for _, col := range table.Columns {
			colLower := strings.ToLower(col.Name)
			if !(strings.HasSuffix(colLower, "_id") || strings.HasSuffix(colLower, "id")) {
				continue
			}
			key := fmt.Sprintf("%s.%s", tableName, col.Name)
			if _, exists := c.FieldSemantics[key]; exists {
				continue
			}
			if col.IsPrimaryKey {
				c.FieldSemantics[key] = &FieldSemantic{
					TableName:   tableName,
					ColumnName:  col.Name,
					StorageType: "primary_key",
					Note:        fmt.Sprintf("Primary key of %s", tableName),
				}
			}
		}
	}
}

// buildForeignKeyGraph builds FK relationship graph
func (c *SharedContext) buildForeignKeyGraph() map[string][]string {
	graph := make(map[string][]string)

	for tableName, table := range c.Tables {
		if _, exists := graph[tableName]; !exists {
			graph[tableName] = []string{}
		}

		for _, fk := range table.ForeignKeys {
			graph[tableName] = append(graph[tableName], fk.ReferencedTable)
			if _, exists := graph[fk.ReferencedTable]; !exists {
				graph[fk.ReferencedTable] = []string{}
			}
			graph[fk.ReferencedTable] = append(graph[fk.ReferencedTable], tableName)
		}
	}

	return graph
}

// findShortestPath uses BFS to find shortest path
func (c *SharedContext) findShortestPath(graph map[string][]string, from, to string) []string {
	if from == to {
		return []string{from}
	}

	visited := make(map[string]bool)
	queue := [][]string{{from}}
	visited[from] = true

	for len(queue) > 0 {
		path := queue[0]
		queue = queue[1:]

		current := path[len(path)-1]

		for _, neighbor := range graph[current] {
			if neighbor == to {
				return append(path, neighbor)
			}

			if !visited[neighbor] {
				visited[neighbor] = true
				newPath := make([]string, len(path))
				copy(newPath, path)
				newPath = append(newPath, neighbor)
				queue = append(queue, newPath)
			}
		}
	}

	return nil
}

// buildJoinPath builds JoinPath from path
func (c *SharedContext) buildJoinPath(path []string) *JoinPath {
	if len(path) < 2 {
		return nil
	}

	joinClauses := []string{}
	for i := 0; i < len(path)-1; i++ {
		joinClause := c.findJoinClause(path[i], path[i+1])
		if joinClause != "" {
			joinClauses = append(joinClauses, joinClause)
		}
	}

	description := ""
	if len(path) == 2 {
		description = fmt.Sprintf("Direct join between %s and %s", path[0], path[1])
	} else {
		intermediates := path[1 : len(path)-1]
		description = fmt.Sprintf("Join through intermediate table(s): %s", strings.Join(intermediates, ", "))
	}

	return &JoinPath{
		FromTable:   path[0],
		ToTable:     path[len(path)-1],
		Path:        path,
		JoinClauses: joinClauses,
		Description: description,
	}
}

// findJoinClause finds JOIN condition between two tables
func (c *SharedContext) findJoinClause(table1, table2 string) string {
	if t1, exists := c.Tables[table1]; exists {
		for _, fk := range t1.ForeignKeys {
			if fk.ReferencedTable == table2 {
				return fmt.Sprintf("%s.%s = %s.%s",
					table1, fk.ColumnName,
					table2, fk.ReferencedColumn)
			}
		}
	}

	if t2, exists := c.Tables[table2]; exists {
		for _, fk := range t2.ForeignKeys {
			if fk.ReferencedTable == table1 {
				return fmt.Sprintf("%s.%s = %s.%s",
					table2, fk.ColumnName,
					table1, fk.ReferencedColumn)
			}
		}
	}

	return ""
}

// FormatJoinPathsForPrompt formats JOIN path info for Prompt
func (c *SharedContext) FormatJoinPathsForPrompt() string {
	if len(c.JoinPaths) == 0 {
		return ""
	}

	var sb strings.Builder
	sb.WriteString("\n## Join Relationships (with cardinality)\n")
	sb.WriteString("Use these FK edges. N:1 / 1:N means JOIN can multiply rows — add DISTINCT when listing unique entities on the '1' side.\n\n")

	keys := make([]string, 0, len(c.JoinPaths))
	for key := range c.JoinPaths {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	for _, key := range keys {
		joinPath := c.JoinPaths[key]
		card := joinPath.Cardinality
		if card == "" {
			card = "?"
		}
		sb.WriteString(fmt.Sprintf("- **%s** [%s]: %s\n", key, card, joinPath.Description))
		if len(joinPath.JoinClauses) > 0 {
			sb.WriteString(fmt.Sprintf("  ON %s\n", strings.Join(joinPath.JoinClauses, " AND ")))
		}
	}
	sb.WriteString("\n")

	return sb.String()
}

// FormatFieldSemanticsForPrompt formats field semantic info for Prompt
func (c *SharedContext) FormatFieldSemanticsForPrompt() string {
	if len(c.FieldSemantics) == 0 {
		return ""
	}

	var sb strings.Builder
	sb.WriteString("\n## Field Semantics\n")
	sb.WriteString("Important field storage information:\n\n")

	tableFields := make(map[string][]*FieldSemantic)
	for _, fs := range c.FieldSemantics {
		tableFields[fs.TableName] = append(tableFields[fs.TableName], fs)
	}

	for tableName, fields := range tableFields {
		sb.WriteString(fmt.Sprintf("**%s**:\n", tableName))
		for _, fs := range fields {
			sb.WriteString(fmt.Sprintf("  - %s (%s): %s\n", fs.ColumnName, fs.StorageType, fs.Note))
			if fs.References != "" {
				sb.WriteString(fmt.Sprintf("    References: %s\n", fs.References))
			}
		}
		sb.WriteString("\n")
	}

	return sb.String()
}
