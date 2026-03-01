# SwipeIQ

[![Mobile CI](https://github.com/LeuzThiam/SwipeIQ/actions/workflows/mobile-ci.yml/badge.svg?branch=dev)](https://github.com/LeuzThiam/SwipeIQ/actions/workflows/mobile-ci.yml)
[![Content CI](https://github.com/LeuzThiam/SwipeIQ/actions/workflows/content-ci.yml/badge.svg?branch=dev)](https://github.com/LeuzThiam/SwipeIQ/actions/workflows/content-ci.yml)

SwipeIQ is a short-video inspired mobile app to learn from swipeable micro-content.

## Demo
- TODO: add GIF or short demo video.

## MVP Features
- [x] Flutter app bootstrap in `mobile/`
- [ ] Vertical swipe feed
- [ ] JSON-driven content rendering
- [ ] Favorites and progress tracking
- [ ] Local analytics dashboard

## Architecture
```text
SwipeIQ (monorepo)
|- mobile/   # Flutter app
|- content/  # JSON content packs
|- tools/    # validators and scripts
|- infra/    # deployment and automation assets
|- docs/     # product and technical docs
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

### Content Validation
```bash
python tools/validate_content.py
```

## CI/CD
- `mobile-ci`: format check, analyze, test, Android APK artifact.
- `content-ci`: validates JSON files in `content/` on push/PR.

## Roadmap
### V1
- Core feed and content playback
- JSON schema stabilization
- First production-ready content pack

### V2
- User profiles and sync
- Recommendations
- Experimentation and A/B support

## License
MIT. See [LICENSE](./LICENSE).
