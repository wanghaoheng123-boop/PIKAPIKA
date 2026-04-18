# Backend

Firebase project for PIKAPIKA.

## Layout

- `firebase.json` — project config + emulator ports
- `firestore.rules`, `storage.rules` — security rules
- `firestore.indexes.json` — composite indexes
- `functions/` — Cloud Functions (TypeScript, Node 20)
- `schema/firestore.md` — Firestore collection layout & conventions

## Local dev

```bash
cd functions && npm install
npm run build
firebase emulators:start
```

## Secrets

Set the AI provider keys before deploy:

```bash
firebase functions:secrets:set ANTHROPIC_API_KEY
firebase functions:secrets:set OPENAI_API_KEY
```
