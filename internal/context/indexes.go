package context

import (
	"context"
	"fmt"
	"strings"

	"github.com/Zqzqsb/AtlasCore/internal/adapter"
)

func skipPrimaryIndex(name, origin string) bool {
	n := strings.ToLower(strings.TrimSpace(name))
	o := strings.ToLower(strings.TrimSpace(origin))
	if n == "" {
		return true
	}
	if n == "primary" || o == "pk" {
		return true
	}
	return strings.HasPrefix(n, "sqlite_autoindex_")
}

func indexesFromTempData(data interface{}) []IndexMetadata {
	indexMap := make(map[string]*IndexMetadata)
	var order []string
	addRow := func(row map[string]interface{}) {
		name := getString(row, "name")
		if name == "" {
			name = getString(row, "Key_name")
		}
		if skipPrimaryIndex(name, getString(row, "origin")) {
			return
		}
		idx, ok := indexMap[name]
		if !ok {
			idx = &IndexMetadata{Name: name, Columns: []string{}, IsUnique: rowIsUniqueIndex(row)}
			indexMap[name] = idx
			order = append(order, name)
		}
		for _, col := range indexColumnsFromRow(row) {
			idx.Columns = append(idx.Columns, col)
		}
	}
	switch rows := data.(type) {
	case []interface{}:
		for _, raw := range rows {
			if row, ok := raw.(map[string]interface{}); ok {
				addRow(row)
			}
		}
	case []map[string]interface{}:
		for _, row := range rows {
			addRow(row)
		}
	}
	out := make([]IndexMetadata, 0, len(order))
	for _, name := range order {
		out = append(out, *indexMap[name])
	}
	return out
}

func indexColumnsFromRow(row map[string]interface{}) []string {
	if raw, ok := row["columns"]; ok {
		switch cols := raw.(type) {
		case []string:
			return append([]string{}, cols...)
		case []interface{}:
			var out []string
			for _, c := range cols {
				s := strings.TrimSpace(fmt.Sprintf("%v", c))
				if s != "" && s != "<nil>" {
					out = append(out, s)
				}
			}
			return out
		}
	}
	if col := getString(row, "Column_name"); col != "" {
		return []string{col}
	}
	if col := getString(row, "column_name"); col != "" {
		return []string{col}
	}
	return nil
}

func rowIsUniqueIndex(row map[string]interface{}) bool {
	if row == nil {
		return false
	}
	if _, ok := row["unique"]; ok {
		return getInt(row, "unique") != 0
	}
	if _, ok := row["Non_unique"]; ok {
		return getInt(row, "Non_unique") == 0
	}
	return false
}

// LoadTableIndexes reads secondary indexes from the live DB (not PK autoindexes).
func LoadTableIndexes(ctx context.Context, db adapter.DBAdapter, table string) ([]IndexMetadata, error) {
	if db == nil || strings.TrimSpace(table) == "" {
		return nil, nil
	}
	switch strings.ToLower(db.GetDatabaseType()) {
	case "sqlite":
		return loadSQLiteIndexes(ctx, db, table)
	case "mysql":
		return loadMySQLIndexes(ctx, db, table)
	default:
		return nil, nil
	}
}

func loadSQLiteIndexes(ctx context.Context, db adapter.DBAdapter, table string) ([]IndexMetadata, error) {
	list, err := db.ExecuteQuery(ctx, fmt.Sprintf("PRAGMA index_list(%s)", quoteIdent(table)))
	if err != nil || list == nil || list.Error != "" {
		if err != nil {
			return nil, err
		}
		if list != nil && list.Error != "" {
			return nil, fmt.Errorf("index_list: %s", list.Error)
		}
		return nil, nil
	}
	var out []IndexMetadata
	for _, row := range list.Rows {
		name := getString(row, "name")
		if skipPrimaryIndex(name, getString(row, "origin")) {
			continue
		}
		info, err := db.ExecuteQuery(ctx, fmt.Sprintf("PRAGMA index_info(%s)", quoteIdent(name)))
		if err != nil || info == nil {
			continue
		}
		var cols []string
		for _, ir := range info.Rows {
			if col := getString(ir, "name"); col != "" {
				cols = append(cols, col)
			}
		}
		if len(cols) == 0 {
			continue
		}
		out = append(out, IndexMetadata{
			Name:     name,
			Columns:  cols,
			IsUnique: rowIsUniqueIndex(row),
		})
	}
	return out, nil
}

func loadMySQLIndexes(ctx context.Context, db adapter.DBAdapter, table string) ([]IndexMetadata, error) {
	res, err := db.ExecuteQuery(ctx, fmt.Sprintf("SHOW INDEX FROM `%s`", strings.ReplaceAll(table, "`", "``")))
	if err != nil || res == nil {
		return nil, err
	}
	return indexesFromTempData(res.Rows), nil
}

// RefreshIndexesFromDB overwrites RC indexes from sqlite/mysql. Once per context.
func (c *SharedContext) RefreshIndexesFromDB(ctx context.Context, db adapter.DBAdapter) {
	if c == nil || db == nil {
		return
	}
	c.mu.Lock()
	if c.indexesRefreshed {
		c.mu.Unlock()
		return
	}
	c.indexesRefreshed = true
	names := make([]string, 0, len(c.Tables))
	for name := range c.Tables {
		names = append(names, name)
	}
	c.mu.Unlock()

	for _, name := range names {
		idxs, err := LoadTableIndexes(ctx, db, name)
		if err != nil {
			continue
		}
		c.ReplaceTableIndexes(name, idxs)
	}
}

func (c *SharedContext) LoadAndSetTableIndexes(ctx context.Context, db adapter.DBAdapter, table string) {
	idxs, err := LoadTableIndexes(ctx, db, table)
	if err != nil {
		return
	}
	c.ReplaceTableIndexes(table, idxs)
}

func (c *SharedContext) ReplaceTableIndexes(table string, idxs []IndexMetadata) {
	if c == nil {
		return
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	t, ok := c.Tables[table]
	if !ok || t == nil {
		return
	}
	if idxs == nil {
		idxs = []IndexMetadata{}
	}
	t.Indexes = idxs
}
