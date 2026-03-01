# SwipeIQ

[![Mobile CI](https://github.com/LeuzThiam/SwipeIQ/actions/workflows/mobile-ci.yml/badge.svg?branch=dev)](https://github.com/LeuzThiam/SwipeIQ/actions/workflows/mobile-ci.yml)
[![Content CI](https://github.com/LeuzThiam/SwipeIQ/actions/workflows/content-ci.yml/badge.svg?branch=dev)](https://github.com/LeuzThiam/SwipeIQ/actions/workflows/content-ci.yml)
[![Backend CI](https://github.com/LeuzThiam/SwipeIQ/actions/workflows/backend-ci.yml/badge.svg?branch=dev)](https://github.com/LeuzThiam/SwipeIQ/actions/workflows/backend-ci.yml)

SwipeIQ est une application d'apprentissage Flutter basee sur du micro-contenu "swipe" avec des pipelines JSON valides.

## Demo
- TODO: ajouter un GIF ou une courte video.

## Fonctionnalites MVP
- [x] Initialisation Flutter
- [ ] Feed vertical type reels
- [x] Validation JSON en gate CI
- [ ] Ecran stats et streaks
- [ ] Livraison de contenu distant

## Architecture
```text
SwipeIQ/
|- mobile/
|- backend/
|- content/
|- tools/
|- infra/
|- docs/
```

## Demarrage rapide
### Mobile
```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

### Contenu
```bash
python tools/validator/validate_questions.py
```

### Infra (local)
```bash
cd infra
docker compose up --build
```

## CI/CD
- `mobile-ci`: format, analyse, tests, artefact APK debug.
- `content-ci`: valide les JSON de `content/generated`.
- `backend-ci`: prepare le pipeline backend et le build Docker.

## Feuille de route
### V1
- Feed + consommation de contenu
- Statistiques locales
- Flux de publication contenu fiable

### V2
- API backend completes
- Authentification et profil
- Recommandations et classement

## Licence
MIT. Voir [LICENSE](./LICENSE).
