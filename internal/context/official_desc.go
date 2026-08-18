package context

import (
	"strings"
	"time"

	"github.com/Zqzqsb/AtlasCore/internal/birddesc"
)

// SetOfficialDesc attaches parsed BIRD database_description for this DB.
func (c *SharedContext) SetOfficialDesc(d *birddesc.Database) {
	if c == nil {
		return
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	c.officialDesc = d
}

// OfficialTablePrompt is injected into RC-gen workers (reference, then still generate).
func (c *SharedContext) OfficialTablePrompt(table string) string {
	if c == nil {
		return ""
	}
	c.mu.RLock()
	defer c.mu.RUnlock()
	if c.officialDesc == nil {
		return ""
	}
	return c.officialDesc.TablePrompt(table)
}

// BakeOfficialDesc writes column_description into OfficialMeaning and merges
// column-level rules into rich_context business_rules. Does not skip LLM notes.
func (c *SharedContext) BakeOfficialDesc() int {
	if c == nil {
		return 0
	}
	c.mu.RLock()
	d := c.officialDesc
	c.mu.RUnlock()
	if d == nil {
		return 0
	}
	n := c.ApplyOfficialMeanings(d.MeaningLookup())
	expires := time.Now().Add(7 * 24 * time.Hour).Format(time.RFC3339)
	c.mu.RLock()
	tables := make([]string, 0, len(c.Tables))
	for name := range c.Tables {
		tables = append(tables, name)
	}
	c.mu.RUnlock()
	for _, name := range tables {
		rules := d.TableRules(name)
		if strings.TrimSpace(rules) == "" {
			continue
		}
		c.mergeBusinessRule(name, rules, expires)
	}
	c.RefreshColumnGrounding()
	return n
}

func (c *SharedContext) mergeBusinessRule(table, rule, expiresAt string) {
	c.mu.Lock()
	tableMeta, ok := c.Tables[table]
	var existing string
	if ok && tableMeta != nil && tableMeta.RichContext != nil {
		if note, found := tableMeta.RichContext["business_rules"]; found {
			existing = strings.TrimSpace(note.Content)
		}
	}
	c.mu.Unlock()
	if existing == "" {
		_ = c.SetTableRichContext(table, "business_rules", rule, expiresAt)
		return
	}
	if strings.Contains(existing, rule) {
		return
	}
	_ = c.SetTableRichContext(table, "business_rules", existing+" | "+rule, expiresAt)
}

func (c *SharedContext) officialAliases() map[string][]string {
	if c == nil {
		return nil
	}
	c.mu.RLock()
	defer c.mu.RUnlock()
	if c.officialDesc == nil {
		return nil
	}
	return c.officialDesc.ValueAliases()
}
