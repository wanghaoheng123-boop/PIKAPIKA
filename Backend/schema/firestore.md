# Firestore schema — PIKAPIKA

All user-owned data is scoped under `users/{uid}` so Firestore rules remain
trivial. CloudKit remains the primary sync store for pet state; Firestore is
used only for features that CloudKit can't do (server-side AI proxy, shared
gallery, push notifications).

## Collections

### `users/{uid}`
```jsonc
{
  "createdAt":      "<timestamp>",
  "displayName":    "string",
  "fcmToken":       "string | null",
  "plan":           "free | pro",
  "lastSeenAtMs":   1234567890000
}
```

### `users/{uid}/pets/{petId}` (mirror of on-device pet; optional)
```jsonc
{
  "name":               "string",
  "species":            "string",
  "bondXP":             "number",
  "bondLevel":          "number",
  "personalityTraits":  ["string"],
  "lastInteractedAtMs": "number",
  "fcmToken":           "string | null"  // denormalized for notifications.ts query
}
```

### `gallery/{petId}` (public, read-only for non-authors)
```jsonc
{
  "name":       "string",
  "species":    "string",
  "traits":     ["string"],
  "spritePath": "string",
  "authorUid":  "string",
  "createdAt":  "<timestamp>",
  "likes":      "number"
}
```

### `rateLimits/{uid}_{YYYY-MM-DD}` (server-only writes)
```jsonc
{
  "count":      "number",
  "updatedAt":  "<timestamp>"
}
```

## Indexes

- `gallery` composite: `species` ASC, `createdAt` DESC — powers "recent fox
  pets" browse queries.

## Security rules

See `../firestore.rules`. Summary:
- `users/{uid}/**`: owner-only read/write.
- `gallery/{petId}`: public read; create requires `authorUid == auth.uid`;
  update/delete by author only.
- `rateLimits/**`: owner read; writes server-side only.

## Storage

- `users/{uid}/**`: owner-only.
- `gallery/**`: public read, authenticated write (moderation TBD).
