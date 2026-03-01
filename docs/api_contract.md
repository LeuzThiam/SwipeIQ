# API Contract (Draft)

## GET /health
Response 200:
```json
{ "status": "ok" }
```

## GET /questions
Query params:
- `theme` (optional)
- `level` (optional)
- `limit` (optional, default 20)

Response 200:
```json
{
  "items": [
    {
      "id": "seed-001",
      "theme": "general",
      "level": "easy",
      "question": "What is SwipeIQ?",
      "choices": ["A", "B", "C", "D"],
      "answer": 0,
      "explanation": "..."
    }
  ]
}
```
