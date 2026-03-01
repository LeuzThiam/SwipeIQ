#!/usr/bin/env python3
"""Validate every JSON file under content/."""

from __future__ import annotations

import json
import sys
from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    content_dir = root / "content"

    if not content_dir.exists():
        print("[OK] content/ does not exist yet; nothing to validate.")
        return 0

    json_files = sorted(content_dir.rglob("*.json"))
    if not json_files:
        print("[OK] No JSON files found in content/.")
        return 0

    failures: list[str] = []
    for file_path in json_files:
        try:
            file_path.read_text(encoding="utf-8")
            with file_path.open("r", encoding="utf-8") as handle:
                json.load(handle)
        except Exception as exc:  # noqa: BLE001
            failures.append(f"{file_path.relative_to(root)} -> {exc}")

    if failures:
        print("[ERROR] Invalid JSON content detected:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print(f"[OK] Validated {len(json_files)} JSON file(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
