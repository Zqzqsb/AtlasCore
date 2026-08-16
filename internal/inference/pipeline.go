package inference

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/pkoukk/tiktoken-go"
	"github.com/tmc/langchaingo/llms"

	"github.com/Zqzqsb/AtlasCore/internal/adapter"
	contextpkg "github.com/Zqzqsb/AtlasCore/internal/context"
)

// Config inference pipeline configuration
type Config struct {
	UseRichContext bool
	UseReact       bool
	ReactLinking   bool // Whether Schema Linking uses ReAct mode
	UseDryRun      bool
	MaxIterations  int
	ContextFile    string

	// Clarify feature config
	ClarifyMode             string   // Clarify mode: "off" (off) | "on" (agent asks) | "force" (forced)
	LogMode                 string   // Log mode: "simple" (simple) | "full" (full)
	ResultFields            []string // Expected result field list
	ResultFieldsDescription string   // Result field descriptions

	// Proofread config
	EnableProofread bool   // Enable proofread (allow LLM to fix Rich Context)
	DBName          string // Database name
	DBType          string // Database type

	// Benchmark-specific config
	Benchmark string // "spider" | "bird" — controls prompt strategy

	// Leaderboard / black-box helpers (no gold SQL)
	EnableOutputContract bool               // Derive projection hints from question+evidence
	EnableProposeFields  bool               // Expose propose_output_fields tool
	ColumnMeaning        ColumnMeaningStore // Optional official column_meaning.json
	ScaleCandidates      int                // 0/1 = off; >=2 enables scale_light vote
	GroundingMode        string             // sparse (default) | all | meaning | profile | legacy | off

	// Linker / sampling enhancements (WiseCat + DeepEye + DataGallery distill)
	EnableLinkEnhance bool // FK expand + column refine + evidence literal hints
	EnableProbeTool   bool // Expose probe_column_values in ReAct

	// Projection Taste Aligner (remote HTTP; context over control)
	EnableProjAlignTool bool   // Master switch for the aligner
	ProjAlignMode       string // "shape" (static shape prior) | "tool" (ReAct tool) | "off"
	ProjAlignURL        string // Base URL; empty → PROJALIGN_URL env → default Mac MPS

	// Static projection few-shot (ablation; empty path = off)
	ProjFewShotPath string // JSON pool path; empty → PROJ_FEWSHOT_PATH env → off

	// Filled per Execute() — not a user-facing flag
	OutputContract *OutputContract
}

// StepCallback is called for each ReAct step update during streaming
// eventType: "thought" | "action" | "observation" | "finish"
type StepCallback func(step ReActStep, eventType string)

// Pipeline inference pipeline
type Pipeline struct {
	llm          llms.Model
	adapter      adapter.DBAdapter
	config       *Config
	context      *contextpkg.SharedContext
	schemaLinker SchemaLinker
	tokenizer    *tiktoken.Tiktoken

	// Token statistics accumulator
	promptTexts   []string
	responseTexts []string

	// Streaming callback
	stepCallback StepCallback

	// Projection shape prior for the current question ("" = no hint)
	projAlignShape string

	// Logger for structured output (stdout + file)
	Logger *InferenceLogger
}

// Result inference result
type Result struct {
	Query           string
	GeneratedSQL    string
	ExecutionResult interface{}

	// Statistics
	TotalTime     time.Duration
	LLMCalls      int
	SQLExecutions int
	TotalTokens   int
	ClarifyCount  int // Clarify count

	// Intermediate results
	SelectedTables []string
	ReActSteps     []ReActStep
}

// ReActStep represents a ReAct step
type ReActStep struct {
	Step        int         `json:"step,omitempty"` // Step number for streaming
	Thought     string      `json:"thought"`
	Action      string      `json:"action"`
	ActionInput interface{} `json:"action_input,omitempty"` // Supports string and map[string]interface{}
	Observation string      `json:"observation,omitempty"`
	Phase       string      `json:"phase,omitempty"` // "schema_linking" or "sql_generation"
}

// Reset cleans accumulated stats to prevent memory leaks
func (p *Pipeline) Reset() {
	p.promptTexts = nil
	p.responseTexts = nil
	p.stepCallback = nil
}

// SetLogger replaces the pipeline logger and propagates it to sub-components
// (e.g. SchemaLinker) so all log output is routed to the same file.
func (p *Pipeline) SetLogger(logger *InferenceLogger) {
	p.Logger = logger
	if linker, ok := p.schemaLinker.(*LLMSchemaLinker); ok {
		linker.logger = logger
	}
}

// SetStepCallback sets the callback function for streaming ReAct steps
func (p *Pipeline) SetStepCallback(callback StepCallback) {
	p.stepCallback = callback
}

// notifyStep notifies the callback of a ReAct step update
func (p *Pipeline) notifyStep(step ReActStep, eventType string) {
	if p.stepCallback != nil {
		p.stepCallback(step, eventType)
	}
}

// NewPipeline creates inference pipeline
func NewPipeline(llm llms.Model, adapter adapter.DBAdapter, config *Config) *Pipeline {
	// Initialize tokenizer (using cl100k_base for GPT-3.5/GPT-4/DeepSeek)
	tokenizer, err := tiktoken.GetEncoding("cl100k_base")
	if err != nil {
		// If failed, use nil, skip token counting later
		tokenizer = nil
	}

	// Schema Linking uses ReAct mode (controlled by ReactLinking config)
	linker := NewLLMSchemaLinker(llm, adapter, config.ReactLinking)

	p := &Pipeline{
		llm:          llm,
		adapter:      adapter,
		config:       config,
		schemaLinker: linker,
		tokenizer:    tokenizer,
		Logger:       NewInferenceLogger(),
	}

	// Set token recorder
	linker.tokenRecorder = func(prompt, response string) {
		p.promptTexts = append(p.promptTexts, prompt)
		p.responseTexts = append(p.responseTexts, response)
	}

	// Share logger with schema linker
	linker.logger = p.Logger

	// Load Context file (if provided)
	// Note: context always loaded for Schema Linking
	// UseRichContext only controls using rich_context in SQL Generation
	if config.ContextFile != "" {
		if ctx, err := p.loadContext(config.ContextFile); err == nil {
			p.context = ctx
			p.bakeOfficialMeaningsIntoRC()
		}
	}

	return p
}

// bakeOfficialMeaningsIntoRC writes column_meaning into ColumnMetadata.OfficialMeaning
// so ExportToCompactPrompt can show one fused column line (no second FormatForDB dump).
// Prefer enrich_rc --column-meaning to bake offline; this is the same API in-memory.
func (p *Pipeline) bakeOfficialMeaningsIntoRC() {
	if p == nil || p.context == nil || len(p.config.ColumnMeaning) == 0 || p.config.DBName == "" {
		return
	}
	mode := p.normalizedGroundingMode()
	if mode == "off" || mode == "profile" || mode == "legacy" {
		if p.Logger != nil {
			p.Logger.Printf("📚 Skip official_meaning bake (grounding-mode=%s)\n", mode)
		}
		return
	}
	lookup := contextpkg.ParseColumnMeaningForDB(map[string]string(p.config.ColumnMeaning), p.config.DBName)
	if len(lookup) == 0 {
		return
	}
	if n := p.context.ApplyOfficialMeanings(lookup); n > 0 {
		p.context.RefreshColumnGrounding()
		if p.Logger != nil {
			p.Logger.Printf("📚 Baked %d official_meaning into RC columns for %s\n", n, p.config.DBName)
		}
	}
}

func (p *Pipeline) normalizedGroundingMode() string {
	if p == nil || p.config == nil {
		return "sparse"
	}
	switch strings.ToLower(strings.TrimSpace(p.config.GroundingMode)) {
	case "off", "all", "meaning", "profile", "legacy", "sparse":
		return strings.ToLower(strings.TrimSpace(p.config.GroundingMode))
	default:
		return "sparse"
	}
}

func (p *Pipeline) compactExportOptions(tables []string, relevant map[string]struct{}, schemaLinking bool) *contextpkg.ExportOptions {
	opts := &contextpkg.ExportOptions{
		Tables:                 tables,
		IncludeColumns:         true,
		IncludeIndexes:         true,
		IncludeRichContext:     true,
		IncludeStats:           true,
		IncludeValueStats:      true,
		IncludeRelationships:   !schemaLinking,
		IncludeOfficialMeaning: false,
		IncludeProfileNL:       false,
	}
	if schemaLinking {
		return opts
	}
	switch p.normalizedGroundingMode() {
	case "all":
		opts.IncludeOfficialMeaning = true
		opts.IncludeProfileNL = true
	case "meaning":
		opts.IncludeOfficialMeaning = true
		opts.GroundingColumns = relevant // nil fallback = all selected table columns
	case "profile":
		opts.IncludeProfileNL = true
		if relevant == nil {
			opts.GroundingColumns = map[string]struct{}{}
		} else {
			opts.GroundingColumns = relevant
		}
	case "legacy", "off":
		// legacy appends FormatForDB later; off emits no grounding.
	default: // sparse
		opts.IncludeOfficialMeaning = true
		if relevant == nil {
			// Column refine can fail. Preserve official semantics without
			// falling back to full-column ProfileNL.
			opts.IncludeProfileNL = false
			opts.GroundingColumns = nil
		} else {
			opts.IncludeProfileNL = true
			opts.GroundingColumns = relevant
		}
	}
	return opts
}

// countTokens counts text token count
func (p *Pipeline) countTokens(text string) int {
	if p.tokenizer == nil {
		return 0
	}
	tokens := p.tokenizer.Encode(text, nil, nil)
	return len(tokens)
}

// Execute runs inference
func (p *Pipeline) Execute(ctx context.Context, query string) (*Result, error) {
	startTime := time.Now()

	// Reset token stat accumulator
	p.promptTexts = []string{}
	p.responseTexts = []string{}

	result := &Result{
		Query:      query,
		ReActSteps: []ReActStep{},
	}

	// 1. Schema Linking (always runs, identifies relevant tables)
	var allTableInfo map[string]*TableInfo
	var err error
	if p.context != nil {
		// Extract table info from Rich Context
		allTableInfo = ExtractTableInfo(p.context)
	} else {
		// Query table info from DB
		allTableInfo, err = p.extractTableInfoFromDB(ctx)
		if err != nil {
			return nil, fmt.Errorf("failed to extract table info: %w", err)
		}
	}

	// Build full RC prompt for Schema Linker (so it can read everything and output focused context)
	var fullRCPrompt string
	if p.config.UseRichContext && p.context != nil {
		fullRCOpts := p.compactExportOptions(nil, nil, true)
		fullRCPrompt = p.context.ExportToCompactPrompt(fullRCOpts)
	}

	linkResult, err := p.schemaLinker.Link(ctx, query, allTableInfo, fullRCPrompt)
	if err != nil {
		return nil, fmt.Errorf("schema linking failed: %w", err)
	}
	tables := linkResult.Tables
	result.SelectedTables = tables
	result.LLMCalls++

	// Add Schema Linking ReAct steps to result
	for _, step := range linkResult.Steps {
		result.ReActSteps = append(result.ReActSteps, ReActStep{
			Thought:     step.Thought,
			Action:      step.Action,
			ActionInput: step.ActionInput,
			Observation: step.Observation,
			Phase:       "schema_linking",
		})
	}

	p.Logger.Printf("📋 Selected Tables: %v\n\n", tables)

	// 1b. Link enhance: FK expand + relevant columns + evidence literal hints
	var linkInject string
	var relevantColumns map[string]struct{}
	if p.config.EnableLinkEnhance {
		expanded, inject, relevant, enhErr := p.ApplyLinkEnhance(ctx, query, tables, allTableInfo)
		if enhErr != nil {
			p.Logger.Printf("⚠️  link enhance failed: %v\n", enhErr)
		} else {
			if len(expanded) > 0 {
				tables = expanded
				result.SelectedTables = tables
			}
			linkInject = inject
			relevantColumns = relevant
			result.LLMCalls++ // column refine (best-effort; may no-op on error)
		}
	}

	// 2. Build Schema Context for SQL generation
	var contextPrompt string
	var crossTableSummary string

	if p.config.UseRichContext && p.context != nil {
		useFocused := linkResult.ContextPrompt != "" && !p.config.EnableLinkEnhance
		if useFocused {
			contextPrompt = linkResult.ContextPrompt
			p.Logger.Printf("📚 Using Schema Linker's focused context (%d chars)\n", len(contextPrompt))
		} else {
			opts := p.compactExportOptions(tables, relevantColumns, false)
			contextPrompt = p.context.ExportToCompactPrompt(opts)
			p.Logger.Printf("📚 Using Rich Context for %d tables\n", len(tables))
			p.Logger.Printf("🧭 Grounding mode=%s relevant_columns=%d context_chars=%d\n",
				p.normalizedGroundingMode(), len(relevantColumns), len(contextPrompt))
		}

		crossTableSummary = p.context.BuildCrossTableQualitySummary(tables)

		p.Logger.FileOnly("\n┌─ Rich Context Content ───────────────────────────────────\n")
		p.Logger.FileOnly("%s", contextPrompt)
		if crossTableSummary != "" {
			p.Logger.FileOnly("\n--- Cross-Table Quality Summary ---\n%s", crossTableSummary)
		}
		p.Logger.FileOnly("└──────────────────────────────────────────────────────────\n\n")
	} else {
		contextPrompt = p.buildBasicSchema(ctx, tables)
		p.Logger.Printf("📋 Using Basic Schema for %d tables\n", len(tables))
	}

	if linkInject != "" {
		contextPrompt = contextPrompt + "\n" + linkInject
		p.Logger.Printf("📎 Link inject appended (%d chars)\n", len(linkInject))
		p.Logger.FileOnly("\n┌─ Link Enhance Inject ────────────────────────────────────\n%s\n└──────────────────────────────────────────────────────────\n\n", linkInject)
	}

	// 2b. Gold-free output contract (leaderboard)
	if p.config.EnableOutputContract {
		// query may already include "Evidence (...)" suffix from eval
		qOnly, evOnly := splitQuestionEvidence(query)
		p.config.OutputContract = BuildOutputContract(qOnly, evOnly)
		p.Logger.Printf("📝 Output contract keywords: %v\n", p.config.OutputContract.Keywords)
	}

	// No-RC and explicit legacy mode retain the separate meaning block.
	if len(p.config.ColumnMeaning) > 0 && (p.context == nil || p.normalizedGroundingMode() == "legacy") {
		cmBlock := p.config.ColumnMeaning.FormatForDB(p.config.DBName, tables)
		if cmBlock != "" {
			contextPrompt = contextPrompt + "\n" + cmBlock
		}
	}

	// 3. Generate SQL
	var sql string
	if p.config.UseReact {
		sql, err = p.reactLoop(ctx, query, contextPrompt, crossTableSummary, result)
	} else {
		sql, err = p.oneShotGeneration(ctx, query, contextPrompt, crossTableSummary)
		result.LLMCalls++
	}

	if err != nil {
		return nil, fmt.Errorf("SQL generation failed: %w", err)
	}

	// 3b. Optional scale_light: extra one-shot variants + execution vote
	if p.config.ScaleCandidates >= 2 {
		chosen, cands, scaleErr := p.RunScaleLight(ctx, query, contextPrompt, crossTableSummary, sql, result)
		if scaleErr != nil {
			p.Logger.Printf("⚠️  scale_light failed: %v (keeping primary SQL)\n", scaleErr)
		} else if chosen != "" {
			p.Logger.Printf("🗳️  scale_light selected from %d candidates\n", len(cands))
			sql = chosen
		}
	}

	// 3c. Deterministic rewrites: dialect + projection (name split, drop ranking metric)
	qOnly, evOnly := splitQuestionEvidence(query)
	if cleaned := SanitizeGeneratedSQLWithQuery(sql, qOnly, evOnly); cleaned != sql {
		p.Logger.Printf("🧹 Sanitized generated SQL (dialect + projection)\n")
		sql = cleaned
	}

	result.GeneratedSQL = sql
	result.TotalTime = time.Since(startTime)

	// 4. Count tokens (from all accumulated prompts and responses)
	// Token counting temporarily disabled to avoid potential issues
	p.Logger.Printf("[DEBUG] Token counting disabled (would count %d prompts, %d responses)\n", len(p.promptTexts), len(p.responseTexts))
	result.TotalTokens = 0 // temporarily set to 0

	// if p.tokenizer != nil {
	// 	for i, prompt := range p.promptTexts {
	// 		fmt.Printf("[DEBUG] Counting prompt %d/%d (length: %d)\n", i+1, len(p.promptTexts), len(prompt))
	// 		result.TotalTokens += p.countTokens(prompt)
	// 	}
	// 	for i, response := range p.responseTexts {
	// 		fmt.Printf("[DEBUG] Counting response %d/%d (length: %d)\n", i+1, len(p.responseTexts), len(response))
	// 		result.TotalTokens += p.countTokens(response)
	// 	}
	// }

	// 5. Execute SQL (optional)
	if sql != "" {
		execResult, err := p.adapter.ExecuteQuery(ctx, sql)
		if err == nil {
			result.ExecutionResult = execResult
			result.SQLExecutions++
		}
	}

	return result, nil
}

// loadContext loads Rich Context
func (p *Pipeline) loadContext(path string) (*contextpkg.SharedContext, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	var ctx contextpkg.SharedContext
	if err := json.Unmarshal(data, &ctx); err != nil {
		return nil, err
	}

	return &ctx, nil
}

// extractTableInfoFromDB extracts table info from DB
func (p *Pipeline) extractTableInfoFromDB(ctx context.Context) (map[string]*TableInfo, error) {
	// Get all table names
	var query string
	switch p.adapter.GetDatabaseType() {
	case "MySQL":
		query = "SHOW TABLES"
	case "PostgreSQL":
		query = "SELECT tablename FROM pg_tables WHERE schemaname='public'"
	case "SQLite":
		query = "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
	default:
		return nil, fmt.Errorf("unsupported database type")
	}

	result, err := p.adapter.ExecuteQuery(ctx, query)
	if err != nil {
		return nil, err
	}

	tableInfo := make(map[string]*TableInfo)

	// Query column info for each table
	for _, row := range result.Rows {
		var tableName string
		for _, val := range row {
			if name, ok := val.(string); ok {
				tableName = name
				break
			}
		}

		if tableName == "" {
			continue
		}

		// Query column info
		var colQuery string
		switch p.adapter.GetDatabaseType() {
		case "MySQL":
			colQuery = fmt.Sprintf("DESCRIBE %s", tableName)
		case "SQLite":
			colQuery = fmt.Sprintf("PRAGMA table_info(%s)", tableName)
		case "PostgreSQL":
			colQuery = fmt.Sprintf("SELECT column_name FROM information_schema.columns WHERE table_name='%s'", tableName)
		}

		colResult, err := p.adapter.ExecuteQuery(ctx, colQuery)
		if err != nil {
			continue
		}

		columns := make([]string, 0, len(colResult.Rows))
		for _, colRow := range colResult.Rows {
			var colName string
			switch p.adapter.GetDatabaseType() {
			case "MySQL":
				if field, ok := colRow["Field"].(string); ok {
					colName = field
				}
			case "SQLite":
				if name, ok := colRow["name"].(string); ok {
					colName = name
				}
			case "PostgreSQL":
				if name, ok := colRow["column_name"].(string); ok {
					colName = name
				}
			}

			if colName != "" {
				columns = append(columns, colName)
			}
		}

		tableInfo[tableName] = &TableInfo{
			Name:    tableName,
			Columns: columns,
		}
	}

	return tableInfo, nil
}

// buildBasicSchema builds basic schema from DB table structure
func (p *Pipeline) buildBasicSchema(ctx context.Context, tables []string) string {
	var sb strings.Builder

	sb.WriteString(fmt.Sprintf("Database: %s\n\n", p.adapter.GetDatabaseType()))

	for _, tableName := range tables {
		// Query table structure
		var query string
		switch p.adapter.GetDatabaseType() {
		case "MySQL":
			query = fmt.Sprintf("DESCRIBE %s", tableName)
		case "SQLite":
			query = fmt.Sprintf("PRAGMA table_info(%s)", tableName)
		case "PostgreSQL":
			query = fmt.Sprintf("SELECT column_name, data_type FROM information_schema.columns WHERE table_name='%s'", tableName)
		default:
			continue
		}

		result, err := p.adapter.ExecuteQuery(ctx, query)
		if err != nil {
			continue
		}

		// Format table structure
		sb.WriteString(fmt.Sprintf("Table %s:\n", tableName))

		for _, row := range result.Rows {
			var colName, colType string

			// Extract column name and type based on DB type
			switch p.adapter.GetDatabaseType() {
			case "MySQL":
				if field, ok := row["Field"].(string); ok {
					colName = field
				}
				if typ, ok := row["Type"].(string); ok {
					colType = typ
				}
			case "SQLite":
				if name, ok := row["name"].(string); ok {
					colName = name
				}
				if typ, ok := row["type"].(string); ok {
					colType = typ
				}
			case "PostgreSQL":
				if name, ok := row["column_name"].(string); ok {
					colName = name
				}
				if typ, ok := row["data_type"].(string); ok {
					colType = typ
				}
			}

			if colName != "" {
				sb.WriteString(fmt.Sprintf("  - %s: %s\n", colName, colType))
			}
		}

		sb.WriteString("\n")
	}

	return sb.String()
}
