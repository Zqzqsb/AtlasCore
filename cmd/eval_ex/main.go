// Command eval_ex scores predict.sql against private gold without feeding gold to inference.
package main

import (
	"database/sql"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"

	_ "modernc.org/sqlite"
)

type goldItem struct {
	QuestionID int    `json:"question_id"`
	DbID       string `json:"db_id"`
	SQL        string `json:"SQL"`
}

func main() {
	predictPath := flag.String("predict", "", "predict.sql (SQL\\tdb_id per line) or results.json")
	goldPath := flag.String("gold", "", "private gold.json")
	dbDir := flag.String("db-dir", "", "sqlite root: {db}/{db}.sqlite")
	timeout := flag.Duration("timeout", 30*time.Second, "per-query timeout budget (best-effort)")
	flag.Parse()
	_ = timeout

	if *predictPath == "" || *goldPath == "" || *dbDir == "" {
		log.Fatalf("usage: go run ./cmd/eval_ex --predict P --gold G --db-dir D")
	}

	gold, err := loadGold(*goldPath)
	if err != nil {
		log.Fatalf("gold: %v", err)
	}
	preds, err := loadPredicts(*predictPath)
	if err != nil {
		log.Fatalf("predict: %v", err)
	}
	if len(preds) != len(gold) {
		fmt.Printf("⚠️  predict n=%d gold n=%d (scoring min length)\n", len(preds), len(gold))
	}
	n := len(gold)
	if len(preds) < n {
		n = len(preds)
	}

	correct := 0
	empty := 0
	execErr := 0
	for i := 0; i < n; i++ {
		g := gold[i]
		pSQL, pDB := preds[i].sql, preds[i].db
		if pDB == "" {
			pDB = g.DbID
		}
		if strings.TrimSpace(pSQL) == "" || strings.EqualFold(strings.TrimSpace(pSQL), "SELECT 1") && g.SQL != "SELECT 1" {
			// count truly empty separately — SELECT 1 placeholder still scored
			if strings.TrimSpace(pSQL) == "" {
				empty++
			}
		}
		dbPath := filepath.Join(*dbDir, pDB, pDB+".sqlite")
		ok, err := execEqual(dbPath, pSQL, g.SQL)
		if err != nil {
			execErr++
			continue
		}
		if ok {
			correct++
		}
	}

	fmt.Printf("EX: %d/%d = %.2f%%\n", correct, n, 100*float64(correct)/float64(n))
	fmt.Printf("empty_pred: %d (%.2f%%)\n", empty, 100*float64(empty)/float64(n))
	fmt.Printf("exec_error_or_timeout: %d\n", execErr)
}

type predLine struct {
	sql string
	db  string
}

func loadGold(path string) ([]goldItem, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var items []goldItem
	if err := json.Unmarshal(data, &items); err != nil {
		return nil, err
	}
	return items, nil
}

func loadPredicts(path string) ([]predLine, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	if strings.HasSuffix(path, ".json") {
		var results []struct {
			GeneratedSQL string `json:"generated_sql"`
			DbID         string `json:"db_id"`
		}
		if err := json.Unmarshal(data, &results); err != nil {
			return nil, err
		}
		out := make([]predLine, len(results))
		for i, r := range results {
			out[i] = predLine{sql: r.GeneratedSQL, db: r.DbID}
		}
		return out, nil
	}
	lines := strings.Split(strings.ReplaceAll(string(data), "\r\n", "\n"), "\n")
	var out []predLine
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		parts := strings.Split(line, "\t")
		pl := predLine{sql: parts[0]}
		if len(parts) > 1 {
			pl.db = parts[1]
		}
		out = append(out, pl)
	}
	return out, nil
}

func execEqual(dbPath, pred, gold string) (bool, error) {
	if _, err := os.Stat(dbPath); err != nil {
		return false, err
	}
	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return false, err
	}
	defer db.Close()

	predRows, err1 := fetchAll(db, pred)
	goldRows, err2 := fetchAll(db, gold)
	if err1 != nil || err2 != nil {
		if err1 != nil {
			return false, err1
		}
		return false, err2
	}
	return sameBag(predRows, goldRows), nil
}

func fetchAll(db *sql.DB, q string) ([][]string, error) {
	rows, err := db.Query(q)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	cols, err := rows.Columns()
	if err != nil {
		return nil, err
	}
	var out [][]string
	for rows.Next() {
		raw := make([]interface{}, len(cols))
		ptrs := make([]interface{}, len(cols))
		for i := range raw {
			ptrs[i] = &raw[i]
		}
		if err := rows.Scan(ptrs...); err != nil {
			return nil, err
		}
		rec := make([]string, len(cols))
		for i, v := range raw {
			if v == nil {
				rec[i] = "NULL"
			} else {
				rec[i] = fmt.Sprintf("%v", v)
			}
		}
		out = append(out, rec)
	}
	return out, rows.Err()
}

func sameBag(a, b [][]string) bool {
	if len(a) != len(b) {
		return false
	}
	// Order-insensitive multiset compare of row tuples
	ca := map[string]int{}
	cb := map[string]int{}
	for _, r := range a {
		ca[strings.Join(r, "\x1f")]++
	}
	for _, r := range b {
		cb[strings.Join(r, "\x1f")]++
	}
	if len(ca) != len(cb) {
		return false
	}
	for k, v := range ca {
		if cb[k] != v {
			return false
		}
	}
	return true
}
