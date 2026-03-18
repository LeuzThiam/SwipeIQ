# Architecture

Le projet SwipeIQ est organise autour de deux applications principales:

- `mobile/`: application React Native basee sur Expo et TypeScript
- `backend/`: API Django REST lisant les questions depuis `content/generated/questions.json`

Les autres zones du monorepo restent specialisées:

- `content/`: source de verite des questions
- `tools/`: scripts Python de validation et workflows d'automatisation
- `infra/`: orchestration locale Docker
- `docs/`: documentation technique

## Flux principal

1. Les questions sont generees et validees dans `content/` et `tools/`.
2. Django expose ces questions via `GET /api/questions/`.
3. React Native consomme l'API pour afficher le feed mobile.
