# Contribution

Merci de contribuer a SwipeIQ.

## Workflow
1. Creer une branche depuis `dev`: `feature/<nom>`.
2. Garder des commits petits et conventionnels (`feat:`, `fix:`, `chore:`, `docs:`).
3. Ouvrir une pull request vers `dev`.
4. Verifier que la CI est verte avant fusion.

## Verifications locales
- Mobile: `flutter analyze && flutter test`
- Contenu: `python tools/validate_content.py`

## Checklist pull request
- Le scope est clair et focalise.
- Les tests ont ete ajoutes/maj si necessaire.
- La documentation a ete mise a jour si le comportement change.
