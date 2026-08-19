package context

import (
	"context"
	"fmt"
	"sort"
	"strings"

	"github.com/Zqzqsb/AtlasCore/internal/adapter"
)

const (
	maxEAVDictRows   = 400
	maxEAVEntries    = 200
	maxEAVValuesEach = 8
)

// EAVCatalog is a fact table whose values are keyed by a small dictionary
// (e.g. Business_Attributes.attribute_value × Attributes.attribute_name).
type EAVCatalog struct {
	FactTable      string     `json:"fact_table"`
	EntityColumn   string     `json:"entity_column,omitempty"`
	AttrIDColumn   string     `json:"attr_id_column"`
	ValueColumn    string     `json:"value_column"`
	DictTable      string     `json:"dict_table"`
	DictIDColumn   string     `json:"dict_id_column"`
	DictNameColumn string     `json:"dict_name_column"`
	Entries        []EAVEntry `json:"entries,omitempty"`
}

// EAVEntry is one dictionary key and the value distribution in the fact table.
type EAVEntry struct {
	ID        string           `json:"id"`
	Name      string           `json:"name"`
	TopValues []ValueFrequency `json:"top_values,omitempty"`
}

func looksLikeValueColumn(name string) bool {
	n := strings.ToLower(name)
	if strings.Contains(n, "value") || strings.HasSuffix(n, "_val") || n == "val" {
		return true
	}
	return false
}

func looksLikeNameColumn(name string) bool {
	n := strings.ToLower(name)
	return strings.Contains(n, "name") || n == "label" || n == "title" || n == "key"
}

func detectEAVCatalog(fact *TableMetadata, find func(string) *TableMetadata) *EAVCatalog {
	if fact == nil || len(fact.ForeignKeys) == 0 {
		return nil
	}
	var valueCol string
	for _, col := range fact.Columns {
		if looksLikeValueColumn(col.Name) && !col.IsPrimaryKey {
			valueCol = col.Name
			break
		}
	}
	if valueCol == "" {
		return nil
	}

	var best *EAVCatalog
	bestDictRows := int64(1 << 30)
	for _, fk := range fact.ForeignKeys {
		dict := find(fk.ReferencedTable)
		if dict == nil || dict.RowCount <= 0 || dict.RowCount > maxEAVDictRows {
			continue
		}
		dictID := strings.TrimSpace(fk.ReferencedColumn)
		if dictID == "" {
			pks := primaryKeyColumns(dict)
			if len(pks) == 1 {
				dictID = pks[0]
			}
		}
		nameCol := ""
		for _, col := range dict.Columns {
			if looksLikeNameColumn(col.Name) && !col.IsPrimaryKey {
				nameCol = col.Name
				break
			}
		}
		if dictID == "" || nameCol == "" {
			continue
		}
		entity := ""
		for _, other := range fact.ForeignKeys {
			if other.ColumnName != fk.ColumnName {
				entity = other.ColumnName
				break
			}
		}
		if dict.RowCount < bestDictRows {
			bestDictRows = dict.RowCount
			best = &EAVCatalog{
				FactTable:      fact.Name,
				EntityColumn:   entity,
				AttrIDColumn:   fk.ColumnName,
				ValueColumn:    valueCol,
				DictTable:      dict.Name,
				DictIDColumn:   dictID,
				DictNameColumn: nameCol,
			}
		}
	}
	return best
}

func loadEAVEntries(ctx context.Context, db adapter.DBAdapter, cat *EAVCatalog) ([]EAVEntry, error) {
	if db == nil || cat == nil {
		return nil, nil
	}
	sql := fmt.Sprintf(
		`SELECT d.%s AS id, d.%s AS name, f.%s AS val, COUNT(*) AS cnt
		 FROM %s f JOIN %s d ON f.%s = d.%s
		 WHERE d.%s IS NOT NULL AND CAST(d.%s AS TEXT) != ''
		 GROUP BY d.%s, d.%s, f.%s
		 ORDER BY d.%s, cnt DESC`,
		quoteIdent(cat.DictIDColumn), quoteIdent(cat.DictNameColumn), quoteIdent(cat.ValueColumn),
		quoteIdent(cat.FactTable), quoteIdent(cat.DictTable),
		quoteIdent(cat.AttrIDColumn), quoteIdent(cat.DictIDColumn),
		quoteIdent(cat.DictNameColumn), quoteIdent(cat.DictNameColumn),
		quoteIdent(cat.DictIDColumn), quoteIdent(cat.DictNameColumn), quoteIdent(cat.ValueColumn),
		quoteIdent(cat.DictIDColumn),
	)
	res, err := db.ExecuteQuery(ctx, sql)
	if err != nil || res == nil || res.Error != "" {
		if err != nil {
			return nil, err
		}
		if res != nil && res.Error != "" {
			return nil, fmt.Errorf("eav group: %s", res.Error)
		}
		return nil, nil
	}

	type acc struct {
		id, name string
		vals     []ValueFrequency
		total    int
	}
	order := []string{}
	byID := map[string]*acc{}
	for _, row := range res.Rows {
		id := strings.TrimSpace(fmt.Sprintf("%v", row["id"]))
		name := strings.TrimSpace(fmt.Sprintf("%v", row["name"]))
		val := strings.TrimSpace(fmt.Sprintf("%v", row["val"]))
		cnt := getInt(row, "cnt")
		if id == "" || name == "" || val == "" || val == "<nil>" {
			continue
		}
		a, ok := byID[id]
		if !ok {
			if len(byID) >= maxEAVEntries {
				continue
			}
			a = &acc{id: id, name: name}
			byID[id] = a
			order = append(order, id)
		}
		a.total += cnt
		if len(a.vals) < maxEAVValuesEach {
			a.vals = append(a.vals, ValueFrequency{Value: val, Count: cnt})
		}
	}
	out := make([]EAVEntry, 0, len(order))
	for _, id := range order {
		a := byID[id]
		for i := range a.vals {
			if a.total > 0 {
				a.vals[i].Percent = float64(a.vals[i].Count) / float64(a.total) * 100
			}
		}
		out = append(out, EAVEntry{ID: a.id, Name: a.name, TopValues: a.vals})
	}
	sort.Slice(out, func(i, j int) bool {
		return strings.ToLower(out[i].Name) < strings.ToLower(out[j].Name)
	})
	return out, nil
}

// RefreshEAVFromDB detects dictionary-valued fact tables and fills per-key value dists.
func (c *SharedContext) RefreshEAVFromDB(ctx context.Context, db adapter.DBAdapter) {
	if c == nil || db == nil {
		return
	}
	c.mu.Lock()
	if c.eavRefreshed {
		c.mu.Unlock()
		return
	}
	c.eavRefreshed = true
	facts := make([]*TableMetadata, 0, len(c.Tables))
	for _, t := range c.Tables {
		if t != nil {
			facts = append(facts, t)
		}
	}
	c.mu.Unlock()

	find := func(name string) *TableMetadata {
		c.mu.RLock()
		defer c.mu.RUnlock()
		return c.findTableLocked(name)
	}

	for _, fact := range facts {
		cat := detectEAVCatalog(fact, find)
		if cat == nil {
			continue
		}
		entries, err := loadEAVEntries(ctx, db, cat)
		if err != nil || len(entries) == 0 {
			continue
		}
		cat.Entries = entries
		c.mu.Lock()
		if t := c.Tables[fact.Name]; t != nil {
			t.EAVCatalog = cat
		}
		c.mu.Unlock()
	}
}

// FormatMatchedEAV renders only dictionary keys that match query literals / index hits.
func (c *SharedContext) FormatMatchedEAV(tables []string, queries []string) string {
	if c == nil || len(queries) == 0 {
		return ""
	}
	want := map[string]struct{}{}
	for _, q := range queries {
		q = strings.ToLower(strings.TrimSpace(q))
		if q == "" {
			continue
		}
		want[q] = struct{}{}
	}
	if len(want) == 0 {
		return ""
	}
	allow := map[string]struct{}{}
	for _, t := range tables {
		allow[strings.ToLower(t)] = struct{}{}
	}

	c.mu.RLock()
	defer c.mu.RUnlock()
	var b strings.Builder
	for _, table := range c.Tables {
		if table == nil || table.EAVCatalog == nil {
			continue
		}
		cat := table.EAVCatalog
		if len(allow) > 0 {
			_, factOK := allow[strings.ToLower(cat.FactTable)]
			_, dictOK := allow[strings.ToLower(cat.DictTable)]
			if !factOK && !dictOK {
				continue
			}
		}
		var hits []EAVEntry
		for _, e := range cat.Entries {
			if _, ok := want[strings.ToLower(e.Name)]; ok {
				hits = append(hits, e)
			}
		}
		if len(hits) == 0 {
			continue
		}
		if b.Len() == 0 {
			b.WriteString("EAV value keys (matched; not a column-wide enum):\n")
		}
		fmt.Fprintf(&b, "- %s.%s via %s.%s:\n", cat.FactTable, cat.ValueColumn, cat.DictTable, cat.DictNameColumn)
		for _, e := range hits {
			vals := make([]string, 0, len(e.TopValues))
			for _, tv := range e.TopValues {
				if tv.Percent > 0 {
					vals = append(vals, fmt.Sprintf("%s(%.0f%%)", tv.Value, tv.Percent))
				} else {
					vals = append(vals, fmt.Sprintf("%s(%d)", tv.Value, tv.Count))
				}
			}
			fmt.Fprintf(&b, "  - %q (%s=%s): %s\n", e.Name, cat.AttrIDColumn, e.ID, strings.Join(vals, ", "))
		}
	}
	return b.String()
}
