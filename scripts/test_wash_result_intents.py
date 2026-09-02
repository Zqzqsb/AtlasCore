#!/usr/bin/env python3.12
"""Unit checks for the result-intent washer."""

import json
import tempfile
from pathlib import Path

from wash_result_intents import (
    attach_gold,
    build_predicted_user_prompt,
    extract_json_object,
    gold_projection_summary,
    validate_result,
)


def test_extract_fenced_json():
    obj = extract_json_object(
        '```json\n{"result_intent":"Return exactly one value: school count."}\n```'
    )
    assert obj["result_intent"].startswith("Return exactly")


def test_validate_semantic_intent():
    got = validate_result(
        {
            "result_intent": (
                "Return exactly one value: the highest eligible free meal rate "
                "for K-12 students."
            )
        }
    )
    assert "Free Meal Count (K-12)" not in got


def test_allow_semicolon_between_semantic_outputs():
    got = validate_result(
        {
            "result_intent": (
                "Return two outputs per row, in order: school name; funding type."
            )
        }
    )
    assert "school name; funding type" in got


def test_allow_natural_ordering_language():
    got = validate_result(
        {
            "result_intent": (
                "Return three university IDs, ordered by female student "
                "percentage from highest to lowest."
            )
        }
    )
    assert "ordered by" in got


def test_reject_row_count_as_output_arity():
    try:
        validate_result(
            {
                "result_intent": (
                    "Return four output values, one per team: build-up speed."
                )
            },
            expected_arity=1,
        )
    except ValueError as exc:
        assert "do not confuse rows with columns" in str(exc)
    else:
        raise AssertionError("expected output-arity rejection")


def test_reject_sql_leak():
    try:
        validate_result({"result_intent": "Return SELECT MAX(score) FROM exams."})
    except ValueError as exc:
        assert "physical SQL" in str(exc)
    else:
        raise AssertionError("expected SQL leak rejection")


def test_attach_gold_by_question_id():
    questions = [
        {"question_id": 7, "db_id": "db", "question": "q", "SQL": ""},
    ]
    gold = [
        {"question_id": 7, "db_id": "db", "SQL": "SELECT x FROM t"},
    ]
    got = attach_gold(questions, gold)
    assert got[0]["_gold_sql"] == "SELECT x FROM t"


def test_projection_summary_omits_filters():
    summary = gold_projection_summary(
        "SELECT MAX(CAST(`Free Meal Count (K-12)` AS REAL) / "
        "`Enrollment (K-12)`) FROM frpm WHERE County = 'Alameda' "
        "ORDER BY 1 DESC LIMIT 1"
    )
    assert "Free Meal Count" in summary
    assert "frpm" not in summary
    assert "Alameda" not in summary
    assert "order_by=1 DESC" in summary
    assert "limit=1" in summary


def test_projection_summary_handles_subquery():
    summary = gold_projection_summary(
        "SELECT name, (SELECT COUNT(*) FROM child WHERE child.pid=parent.id) AS n "
        "FROM parent WHERE active=1"
    )
    assert "name, (SELECT COUNT(*) FROM child" in summary
    assert "parent WHERE" not in summary


def test_projection_summary_uses_outer_order_by():
    summary = gold_projection_summary(
        "SELECT name, (SELECT x FROM child ORDER BY x DESC LIMIT 1) AS x "
        "FROM parent ORDER BY score ASC, name DESC LIMIT 3"
    )
    assert "order_by=score ASC, name DESC" in summary
    assert "order_by=x DESC" not in summary


def test_predicted_prompt_uses_context_but_not_gold_sql():
    with tempfile.TemporaryDirectory() as tmp:
        Path(tmp, "school.json").write_text(
            json.dumps(
                {
                    "schema_diagram": {"content": "erDiagram\nSCHOOL { text name }"},
                    "tables": {"school": {"description": "Educational institutions."}},
                }
            )
        )
        prompt = build_predicted_user_prompt(
            {
                "db_id": "school",
                "question": "Which school has the most students?",
                "evidence": "",
                "SQL": "SELECT secret_gold_column FROM secret_gold_table",
            },
            Path(tmp),
        )
    assert "Which school has the most students?" in prompt
    assert "Educational institutions." in prompt
    assert "secret_gold_column" not in prompt
    assert "secret_gold_table" not in prompt


if __name__ == "__main__":
    for fn in [
        test_extract_fenced_json,
        test_validate_semantic_intent,
        test_allow_semicolon_between_semantic_outputs,
        test_allow_natural_ordering_language,
        test_reject_row_count_as_output_arity,
        test_reject_sql_leak,
        test_attach_gold_by_question_id,
        test_projection_summary_omits_filters,
        test_projection_summary_handles_subquery,
        test_projection_summary_uses_outer_order_by,
        test_predicted_prompt_uses_context_but_not_gold_sql,
    ]:
        fn()
        print("ok", fn.__name__)
    print("ALL_OK")
