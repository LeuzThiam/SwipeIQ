# SwipeIQ

[![Mobile CI](https://github.com/LeuzThiam/SwipeIQ/actions/workflows/mobile-ci.yml/badge.svg?branch=dev)](https://github.com/LeuzThiam/SwipeIQ/actions/workflows/mobile-ci.yml)
[![Content CI](https://github.com/LeuzThiam/SwipeIQ/actions/workflows/content-ci.yml/badge.svg?branch=dev)](https://github.com/LeuzThiam/SwipeIQ/actions/workflows/content-ci.yml)
[![Backend CI](https://github.com/LeuzThiam/SwipeIQ/actions/workflows/backend-ci.yml/badge.svg?branch=dev)](https://github.com/LeuzThiam/SwipeIQ/actions/workflows/backend-ci.yml)

SwipeIQ is a Flutter-first learning app powered by swipeable micro-content with validated JSON pipelines.

## Demo
- TODO: add a short GIF/video.

## MVP Features
- [x] Flutter bootstrap
- [ ] Vertical feed reels
- [x] JSON content validation gate
- [ ] Stats and streaks UI
- [ ] Remote content delivery

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

## Getting Started
### Mobile
```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

### Content
```bash
python tools/validator/validate_questions.py
```

### Infra (local)
```bash
cd infra
docker compose up --build
```

## CI/CD
- `mobile-ci`: format, analyze, test, debug APK artifact.
- `content-ci`: validates JSON from `content/generated`.
- `backend-ci`: prepares backend pipeline and docker build.

## Roadmap
### V1
- Feed + content consumption
- Local stats
- Reliable content publication flow

### V2
- Full backend APIs
- Auth and profile
- Recommendations and leaderboard

## License
MIT. See [LICENSE](./LICENSE).
