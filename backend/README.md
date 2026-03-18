# Backend Django

Backend API de SwipeIQ base sur Django et Django REST Framework.

## Endpoints

- `GET /api/health/`
- `GET /api/questions/`
- `GET /api/stats/`

## Demarrage local

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

Le service lit les questions depuis `../content/generated/questions.json`.
