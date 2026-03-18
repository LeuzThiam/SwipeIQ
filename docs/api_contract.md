# Contrat API

## GET /api/health/

Reponse 200:

```json
{ "status": "ok" }
```

## GET /api/questions/

Parametres query:

- `theme` optionnel
- `level` optionnel
- `limit` optionnel, `20` par defaut, maximum `50`

Reponse 200:

```json
{
  "items": [
    {
      "id": "seed-001",
      "theme": "general",
      "level": "easy",
      "question": "Qu'est-ce que SwipeIQ ?",
      "choices": [
        "Une application mobile d'apprentissage",
        "Une base de donnees",
        "Une console de jeu",
        "Un navigateur"
      ],
      "answer": 0,
      "explanation": "SwipeIQ est l'application mobile de ce monorepo."
    }
  ],
  "meta": {
    "count": 1,
    "limit": 20,
    "theme": null,
    "level": null
  }
}
```

## GET /api/stats/

Reponse 200:

```json
{
  "totalQuestions": 1,
  "themes": ["general"],
  "levels": ["easy"]
}
```
