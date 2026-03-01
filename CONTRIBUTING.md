# Contributing

Thanks for contributing to SwipeIQ.

## Workflow
1. Create a branch from `dev`: `feature/<name>`.
2. Keep commits small and conventional (`feat:`, `fix:`, `chore:`, `docs:`).
3. Open a pull request to `dev`.
4. Ensure CI passes before merge.

## Local checks
- Mobile: `flutter analyze && flutter test`
- Content: `python tools/validate_content.py`

## Pull request checklist
- Scope is clear and focused.
- Tests were added/updated when needed.
- Docs were updated when behavior changed.
