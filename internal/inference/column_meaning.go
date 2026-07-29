package inference

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"
)

// ColumnMeaningStore maps "db|table|column" (case-insensitive keys) -> description.
// Compatible with BIRD / TA-SQL column_meaning.json.
type ColumnMeaningStore map[string]string

// LoadColumnMeaningJSON loads official-style column meaning file.
func LoadColumnMeaningJSON(path string) (ColumnMeaningStore, error) {
	if path == "" {
		return nil, nil
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	raw := map[string]string{}
	if err := json.Unmarshal(data, &raw); err != nil {
		return nil, fmt.Errorf("parse column_meaning: %w", err)
	}
	store := make(ColumnMeaningStore, len(raw))
	for k, v := range raw {
		store[strings.ToLower(strings.TrimSpace(k))] = strings.TrimSpace(v)
	}
	return store, nil
}

// FormatForDB returns a compact markdown block for one database, optionally filtered by tables.
func (s ColumnMeaningStore) FormatForDB(dbID string, tables []string) string {
	if len(s) == 0 || dbID == "" {
		return ""
	}
	dbLower := strings.ToLower(dbID)
	tableAllow := map[string]struct{}{}
	for _, t := range tables {
		tableAllow[strings.ToLower(t)] = struct{}{}
	}

	type colRow struct {
		table, col, desc string
	}
	var rows []colRow
	prefix := dbLower + "|"
	for k, v := range s {
		if !strings.HasPrefix(k, prefix) {
			continue
		}
		parts := strings.SplitN(k, "|", 3)
		if len(parts) != 3 {
			continue
		}
		table, col := parts[1], parts[2]
		if len(tableAllow) > 0 {
			if _, ok := tableAllow[table]; !ok {
				continue
			}
		}
		desc := v
		desc = strings.ReplaceAll(desc, "#", "")
		desc = strings.ReplaceAll(desc, "\n", " ")
		if len(desc) > 220 {
			desc = desc[:217] + "..."
		}
		rows = append(rows, colRow{table: table, col: col, desc: desc})
	}
	if len(rows) == 0 {
		return ""
	}

	// Stable-ish grouping by table
	byTable := map[string][]colRow{}
	var order []string
	for _, r := range rows {
		if _, ok := byTable[r.table]; !ok {
			order = append(order, r.table)
		}
		byTable[r.table] = append(byTable[r.table], r)
	}

	var sb strings.Builder
	sb.WriteString("### Official column meanings (column_meaning.json)\n")
	for _, table := range order {
		sb.WriteString(fmt.Sprintf("#### Table `%s`\n", table))
		for _, r := range byTable[table] {
			sb.WriteString(fmt.Sprintf("- `%s`: %s\n", r.col, r.desc))
		}
	}
	sb.WriteString("\n")
	return sb.String()
}
