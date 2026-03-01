#!/usr/bin/env python3
"""Validate SwipeIQ question JSON files in content/generated."""

from __future__ import annotations

import json
from pathlib import Path

REQUIRED_KEYS = {"id", "theme", "level", "question", "choices", "answer", "explanation"}


def validate_question(item: object, file_label: str, index: int) -> list[str]:
    errors: list[str] = []
    if not isinstance(item, dict):
        return [f"{file_label}: question[{index}] must be an object"]

    missing = REQUIRED_KEYS - set(item.keys())
    if missing:
        errors.append(f"{file_label}: question[{index}] missing keys: {sorted(missing)}")

    choices = item.get("choices")
    if not isinstance(choices, list) or len(choices) != 4 or not all(isinstance(c, str) for c in choices):
        errors.append(f"{file_label}: question[{index}] choices must be an array of 4 strings")

    answer = item.get("answer")
    if not isinstance(answer, int) or answer < 0 or answer > 3:
        errors.append(f"{file_label}: question[{index}] answer must be an int in [0..3]")

    return errors


def validate_file(path: Path, root: Path) -> list[str]:
    label = str(path.relative_to(root))
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # noqa: BLE001
        return [f"{label}: invalid JSON ({exc})"]

    if not isinstance(data, dict):
        return [f"{label}: root must be an object"]

    questions = data.get("questions")
    if not isinstance(questions, list):
        return [f"{label}: `questions` must be an array"]

    errors: list[str] = []
    for idx, question in enumerate(questions):
        errors.extend(validate_question(question, label, idx))
    return errors


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    generated = root / "content" / "generated"

    if not generated.exists():
        print("[OK] content/generated does not exist yet; nothing to validate.")
        return 0

    files = sorted(generated.rglob("*.json"))
    if not files:
        print("[OK] No JSON files found in content/generated.")
        return 0

    all_errors: list[str] = []
    for file_path in files:
        all_errors.extend(validate_file(file_path, root))

    if all_errors:
        print("[ERROR] Content validation failed:")
        for err in all_errors:
            print(f"- {err}")
        return 1

    print(f"[OK] Validated {len(files)} JSON file(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
