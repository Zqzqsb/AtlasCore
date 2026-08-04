package inference

import (
	"strings"
)

// Lookup returns official meaning for db|table|column (case-insensitive), or "".
func (s ColumnMeaningStore) Lookup(dbID, table, column string) string {
	if len(s) == 0 {
		return ""
	}
	key := strings.ToLower(strings.TrimSpace(dbID)) + "|" +
		strings.ToLower(strings.TrimSpace(table)) + "|" +
		strings.ToLower(strings.TrimSpace(column))
	return s[key]
}

// MeaningsForTables builds ExportOptions-ready map keys "table|column" (lower)
// for the given db + tables. Empty if nothing matches.
func (s ColumnMeaningStore) MeaningsForTables(dbID string, tables []string) map[string]string {
	if len(s) == 0 || dbID == "" {
		return nil
	}
	allow := map[string]struct{}{}
	for _, t := range tables {
		allow[strings.ToLower(t)] = struct{}{}
	}
	dbLower := strings.ToLower(dbID)
	prefix := dbLower + "|"
	out := map[string]string{}
	for k, v := range s {
		if !strings.HasPrefix(k, prefix) {
			continue
		}
		parts := strings.SplitN(k, "|", 3)
		if len(parts) != 3 {
			continue
		}
		table, col := parts[1], parts[2]
		if len(allow) > 0 {
			if _, ok := allow[table]; !ok {
				continue
			}
		}
		desc := sanitizeMeaning(v, 160)
		if desc == "" {
			continue
		}
		out[table+"|"+col] = desc
	}
	if len(out) == 0 {
		return nil
	}
	return out
}

func sanitizeMeaning(v string, max int) string {
	desc := strings.TrimSpace(v)
	desc = strings.ReplaceAll(desc, "#", "")
	desc = strings.ReplaceAll(desc, "\n", " ")
	desc = strings.Join(strings.Fields(desc), " ")
	if max > 0 && len(desc) > max {
		desc = desc[:max-3] + "..."
	}
	return desc
}

// FormatColumnCardNote is a one-line legend when fused meanings are inlined.
func FormatColumnCardNote() string {
	return "Column cards: type / FK / value stats; `//` = official column_meaning (when available).\n"
}
