# Contrat API (Brouillon)

## GET /health
Reponse 200:
```json
{ "status": "ok" }
```

## GET /questions
Parametres query:
- `theme` (optionnel)
- `level` (optionnel)
- `limit` (optionnel, 20 par defaut)

Reponse 200:
```json
{
  "items": [
    {
      "id": "seed-001",
      "theme": "general",
      "level": "easy",
      "question": "Qu'est-ce que SwipeIQ ?",
      "choices": ["A", "B", "C", "D"],
      "answer": 0,
      "explanation": "..."
    }
  ]
}
```
