#!/usr/bin/env python3
"""Unit checks for proj_fields v2 labeling."""
from wash_proj_fields import parse_projection, tables_from_sql


def test_count_star():
    p = parse_projection("SELECT COUNT(*) FROM t", "v2")
    assert p["shape"] == "scalar"
    assert p["fields"] == [{"name": "*", "kind": "count", "expr": "COUNT(*)"}] or (
        p["fields"][0]["name"] == "*" and p["fields"][0]["kind"] == "count"
    )


def test_count_col_strips_table():
    p = parse_projection("SELECT COUNT(T2.user_id) FROM users AS T2", "v2")
    assert p["shape"] == "scalar"
    assert p["fields"][0]["kind"] == "count"
    assert p["fields"][0]["name"] == "user_id"
    assert "(" not in p["fields"][0]["name"]


def test_avg_alias():
    p = parse_projection("SELECT AVG(rating_score) AS avg_score FROM ratings", "v2")
    assert p["fields"][0]["kind"] == "avg"
    assert p["fields"][0]["name"] == "avg_score"


def test_bare_col_list():
    p = parse_projection("SELECT T1.movie_title FROM movies AS T1", "v2")
    assert p["shape"] == "list"
    assert p["fields"][0]["name"] == "movie_title"
    assert p["fields"][0]["kind"] == "col"


def test_entity_limit1():
    p = parse_projection("SELECT name FROM t ORDER BY x DESC LIMIT 1", "v2")
    assert p["shape"] == "entity"


def test_tables_from_sql():
    ts = tables_from_sql("SELECT a FROM movies AS T1 JOIN ratings AS T2 ON T1.id=T2.mid")
    assert "movies" in ts and "ratings" in ts


def test_percent_formula_not_count_star():
    sql = (
        "SELECT CAST(SUM(CASE WHEN user_subscriber = 1 THEN 1 ELSE 0 END) AS REAL) "
        "* 100 / COUNT(*) FROM ratings"
    )
    p = parse_projection(sql, "v2")
    assert p["shape"] == "scalar"
    assert p["fields"][0]["kind"] == "col"
    assert p["fields"][0]["name"] == "value"


if __name__ == "__main__":
    for fn in [
        test_count_star,
        test_count_col_strips_table,
        test_avg_alias,
        test_bare_col_list,
        test_entity_limit1,
        test_tables_from_sql,
        test_percent_formula_not_count_star,
    ]:
        fn()
        print("ok", fn.__name__)
    print("ALL_OK")
