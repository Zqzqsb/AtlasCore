// Package birddesc loads official BIRD database_description/*.csv
// (column_description / value_description) next to each sqlite file.
package birddesc

import (
	"encoding/csv"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"unicode"
)

// Kind classifies value_description so column semantics and value literals
// are not dumped into the same place.
type Kind string

const (
	KindNone    Kind = ""
	KindEnum    Kind = "enum"
	KindMapping Kind = "mapping"
	KindRule    Kind = "rule"
)

// Column is one official description row.
type Column struct {
	Table       string
	Name        string // original_column_name (sqlite)
	DisplayName string
	Description string
	ValueDesc   string
	Kind        Kind
	Enums       []string            // closed stored values
	Aliases     map[string][]string // stored value → extra lookup strings
	RuleText    string
}

// Database is the official description pack for one db_id.
type Database struct {
	DBID    string
	Columns []*Column
	byTable map[string][]*Column // lower table name
}

var (
	commonsenseRe = regexp.MustCompile(`(?i)commonsense\s+evidence`)
	mappingLineRe = regexp.MustCompile(`(?i)^\s*([0-9A-Za-z_]+)\s*[:=]\s*(.+?)\s*$`)
	quotedEnumRe  = regexp.MustCompile(`"([^"]+)"`)
)

// LoadForDB reads <dbDir>/<dbID>/database_description/*.csv.
// Missing directory is not an error (returns nil, nil).
func LoadForDB(dbDir, dbID string) (*Database, error) {
	if strings.TrimSpace(dbDir) == "" || strings.TrimSpace(dbID) == "" {
		return nil, nil
	}
	dir := filepath.Join(dbDir, dbID, "database_description")
	st, err := os.Stat(dir)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, err
	}
	if !st.IsDir() {
		return nil, nil
	}
	return LoadDir(dbID, dir)
}

// LoadDir parses every csv in dir. Table name = file stem.
func LoadDir(dbID, dir string) (*Database, error) {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, err
	}
	out := &Database{DBID: dbID, byTable: map[string][]*Column{}}
	for _, ent := range entries {
		if ent.IsDir() {
			continue
		}
		name := ent.Name()
		if !strings.EqualFold(filepath.Ext(name), ".csv") {
			continue
		}
		table := strings.TrimSuffix(name, filepath.Ext(name))
		f, err := os.Open(filepath.Join(dir, name))
		if err != nil {
			return nil, err
		}
		cols, err := parseCSV(table, f)
		_ = f.Close()
		if err != nil {
			return nil, fmt.Errorf("%s: %w", name, err)
		}
		for _, c := range cols {
			out.Columns = append(out.Columns, c)
			tl := strings.ToLower(c.Table)
			out.byTable[tl] = append(out.byTable[tl], c)
		}
	}
	if len(out.Columns) == 0 {
		return nil, nil
	}
	return out, nil
}

func parseCSV(table string, r io.Reader) ([]*Column, error) {
	cr := csv.NewReader(r)
	cr.LazyQuotes = true
	cr.FieldsPerRecord = -1
	cr.TrimLeadingSpace = true
	header, err := cr.Read()
	if err != nil {
		if err == io.EOF {
			return nil, nil
		}
		return nil, err
	}
	idx := headerIndex(header)
	var out []*Column
	for {
		rec, err := cr.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, err
		}
		col := strings.TrimSpace(field(rec, idx["original_column_name"]))
		if col == "" {
			continue
		}
		c := &Column{
			Table:       table,
			Name:        col,
			DisplayName: strings.TrimSpace(field(rec, idx["column_name"])),
			Description: strings.TrimSpace(field(rec, idx["column_description"])),
			ValueDesc:   strings.TrimSpace(field(rec, idx["value_description"])),
		}
		classify(c)
		out = append(out, c)
	}
	return out, nil
}

func headerIndex(header []string) map[string]int {
	out := map[string]int{}
	for i, h := range header {
		key := strings.ToLower(strings.TrimSpace(strings.ReplaceAll(h, " ", "_")))
		out[key] = i
	}
	return out
}

func field(rec []string, i int) string {
	if i < 0 || i >= len(rec) {
		return ""
	}
	return rec[i]
}

func classify(c *Column) {
	v := strings.TrimSpace(c.ValueDesc)
	if v == "" {
		c.Kind = KindNone
		return
	}
	if commonsenseRe.MatchString(v) || looksLikeColumnRule(v) {
		c.Kind = KindRule
		c.RuleText = collapseWS(v)
		return
	}
	if m := parseMapping(v); len(m) > 0 {
		c.Kind = KindMapping
		c.Aliases = m
		return
	}
	if enums := parseEnums(v); len(enums) >= 2 {
		c.Kind = KindEnum
		c.Enums = enums
		c.Aliases = map[string][]string{}
		for _, e := range enums {
			c.Aliases[e] = []string{e}
		}
		return
	}
	c.Kind = KindRule
	c.RuleText = collapseWS(v)
}

func looksLikeColumnRule(v string) bool {
	lower := strings.ToLower(v)
	if strings.Contains(lower, "null") && (strings.Contains(lower, "empty") || strings.Contains(lower, "means") || strings.Contains(lower, "refers")) {
		return true
	}
	if strings.Contains(lower, "higher") && strings.Contains(lower, "means") {
		return true
	}
	return false
}

func parseMapping(v string) map[string][]string {
	chunks := splitMappingChunks(v)
	out := map[string][]string{}
	for _, chunk := range chunks {
		m := mappingLineRe.FindStringSubmatch(chunk)
		if m == nil {
			continue
		}
		key := strings.TrimSpace(m[1])
		rhs := strings.Trim(strings.TrimSpace(m[2]), `"'`)
		rhs = strings.TrimSuffix(rhs, ";")
		rhs = strings.TrimSpace(rhs)
		if key == "" || rhs == "" {
			continue
		}
		aliases := []string{rhs}
		for _, part := range strings.FieldsFunc(rhs, func(r rune) bool {
			return r == ',' || r == '/' || r == ';'
		}) {
			part = strings.TrimSpace(part)
			if part != "" && !strings.EqualFold(part, key) {
				aliases = append(aliases, part)
			}
		}
		out[key] = uniqueFold(aliases)
	}
	if len(out) < 2 {
		return nil
	}
	return out
}

func splitMappingChunks(v string) []string {
	v = strings.ReplaceAll(v, "\r\n", "\n")
	var chunks []string
	for _, line := range strings.Split(v, "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		for _, part := range strings.Split(line, ";") {
			part = strings.TrimSpace(part)
			if part != "" {
				chunks = append(chunks, part)
			}
		}
	}
	return chunks
}

func parseEnums(v string) []string {
	quoted := quotedEnumRe.FindAllStringSubmatch(v, -1)
	if len(quoted) >= 2 {
		var out []string
		for _, m := range quoted {
			s := strings.TrimSpace(m[1])
			if s != "" {
				out = append(out, s)
			}
		}
		return uniqueFold(out)
	}
	// comma-separated identifiers without colons
	if strings.Contains(v, ":") || strings.Contains(v, "=") {
		return nil
	}
	parts := strings.Split(v, ",")
	if len(parts) < 2 {
		return nil
	}
	var out []string
	for _, p := range parts {
		p = strings.Trim(strings.TrimSpace(p), `"'`)
		if p == "" || strings.ContainsAny(p, " \t") && utf8Len(p) > 40 {
			return nil
		}
		if looksIdent(p) || utf8Len(p) <= 40 {
			out = append(out, p)
		}
	}
	if len(out) < 2 {
		return nil
	}
	return uniqueFold(out)
}

func looksIdent(s string) bool {
	if s == "" {
		return false
	}
	for i, r := range s {
		if unicode.IsLetter(r) || r == '_' {
			continue
		}
		if unicode.IsDigit(r) && i > 0 {
			continue
		}
		return false
	}
	return true
}

func utf8Len(s string) int { return len([]rune(s)) }

func uniqueFold(in []string) []string {
	seen := map[string]struct{}{}
	var out []string
	for _, s := range in {
		s = strings.TrimSpace(s)
		if s == "" {
			continue
		}
		k := strings.ToLower(s)
		if _, ok := seen[k]; ok {
			continue
		}
		seen[k] = struct{}{}
		out = append(out, s)
	}
	return out
}

func collapseWS(s string) string {
	s = strings.ReplaceAll(s, "\r\n", "\n")
	s = strings.ReplaceAll(s, "\n", " ")
	return strings.Join(strings.Fields(s), " ")
}

// ColumnsForTable returns official columns for a sqlite table (case-insensitive).
func (d *Database) ColumnsForTable(table string) []*Column {
	if d == nil {
		return nil
	}
	return d.byTable[strings.ToLower(strings.TrimSpace(table))]
}

// FindColumn matches sqlite column name against original_column_name.
func (d *Database) FindColumn(table, column string) *Column {
	for _, c := range d.ColumnsForTable(table) {
		if strings.EqualFold(c.Name, column) {
			return c
		}
	}
	return nil
}

// MeaningLookup is table|column → column_description for ApplyOfficialMeanings.
func (d *Database) MeaningLookup() map[string]string {
	if d == nil {
		return nil
	}
	out := map[string]string{}
	for _, c := range d.Columns {
		if strings.TrimSpace(c.Description) == "" {
			continue
		}
		key := strings.ToLower(c.Table) + "|" + strings.ToLower(c.Name)
		out[key] = c.Description
	}
	return out
}

// ValueAliases maps lower(table)|lower(col)|display → extra lookup strings.
func (d *Database) ValueAliases() map[string][]string {
	if d == nil {
		return nil
	}
	out := map[string][]string{}
	for _, c := range d.Columns {
		if c.Kind != KindMapping && c.Kind != KindEnum {
			continue
		}
		tl := strings.ToLower(c.Table)
		cl := strings.ToLower(c.Name)
		for stored, aliases := range c.Aliases {
			key := tl + "|" + cl + "|" + stored
			out[key] = uniqueFold(aliases)
		}
	}
	if len(out) == 0 {
		return nil
	}
	return out
}

// MappingColumns lists table.column that have 0/1-style encodings (force-index).
func (d *Database) MappingColumns() map[string]struct{} {
	out := map[string]struct{}{}
	if d == nil {
		return out
	}
	for _, c := range d.Columns {
		if c.Kind != KindMapping {
			continue
		}
		out[strings.ToLower(c.Table)+"|"+strings.ToLower(c.Name)] = struct{}{}
	}
	return out
}

// IndexedValueColumns lists columns whose official description provides
// closed-set values or stored-value aliases. They must be eligible for value
// indexing even when their physical type or column name would be gated out.
func (d *Database) IndexedValueColumns() map[string]struct{} {
	out := map[string]struct{}{}
	if d == nil {
		return out
	}
	for _, c := range d.Columns {
		if c.Kind != KindMapping && c.Kind != KindEnum {
			continue
		}
		out[strings.ToLower(c.Table)+"|"+strings.ToLower(c.Name)] = struct{}{}
	}
	return out
}

// TablePrompt is injected into RC-gen workers: reference, then still generate.
func (d *Database) TablePrompt(table string) string {
	cols := d.ColumnsForTable(table)
	if len(cols) == 0 {
		return ""
	}
	var b strings.Builder
	b.WriteString("Official dataset descriptions for this table (REFERENCE only — still sample the sqlite and write {col}_meaning / {col}_values / business_rules yourself; do not skip generation):\n")
	for _, c := range cols {
		desc := strings.TrimSpace(c.Description)
		if desc == "" && c.Kind == KindNone {
			continue
		}
		fmt.Fprintf(&b, "- %s", c.Name)
		if c.DisplayName != "" && !strings.EqualFold(c.DisplayName, c.Name) {
			fmt.Fprintf(&b, " (%s)", c.DisplayName)
		}
		if desc != "" {
			fmt.Fprintf(&b, ": %s", collapseWS(desc))
		}
		b.WriteByte('\n')
		switch c.Kind {
		case KindEnum:
			fmt.Fprintf(&b, "  stored values: %s\n", strings.Join(c.Enums, ", "))
		case KindMapping:
			keys := make([]string, 0, len(c.Aliases))
			for k := range c.Aliases {
				keys = append(keys, k)
			}
			sort.Strings(keys)
			var parts []string
			for _, k := range keys {
				vs := c.Aliases[k]
				if len(vs) > 0 {
					parts = append(parts, k+"="+vs[0])
				}
			}
			if len(parts) > 0 {
				fmt.Fprintf(&b, "  value encoding: %s\n", strings.Join(parts, "; "))
			}
		case KindRule:
			if c.RuleText != "" {
				fmt.Fprintf(&b, "  rule: %s\n", c.RuleText)
			}
		}
	}
	return strings.TrimSpace(b.String())
}

// TableRules concatenates column-level rules (NULL semantics, etc.).
func (d *Database) TableRules(table string) string {
	var parts []string
	for _, c := range d.ColumnsForTable(table) {
		if c.Kind != KindRule || c.RuleText == "" {
			continue
		}
		parts = append(parts, c.Name+": "+c.RuleText)
	}
	return strings.Join(parts, " | ")
}
