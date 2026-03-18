# SwipeIQ

SwipeIQ est maintenant structure comme un monorepo `React Native + Django`.

## Structure

```text
SwipeIQ/
|- mobile/   # React Native (Expo + TypeScript)
|- backend/  # Django REST API
|- content/  # questions JSON
|- tools/    # validation et automatisation
|- infra/    # docker-compose local
|- docs/     # architecture et contrat API
```

## Demarrage rapide

### Backend

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

### Mobile

```bash
cd mobile
npm install
npm run start
```

### Infra

```bash
cd infra
docker compose --profile backend up --build
```

## Endpoints MVP

- `GET /api/health/`
- `GET /api/questions/` avec `meta.count`, `meta.limit`, `theme`, `level`
- `GET /api/stats/`

## Etat actuel

- backend Django REST lisant `content/generated/questions.json`
- mobile React Native Expo nettoye, sans reliquats Flutter
- feed vertical pagine plein ecran avec quiz interactif et score local
- statistiques de catalogue chargees depuis `/api/stats/`
