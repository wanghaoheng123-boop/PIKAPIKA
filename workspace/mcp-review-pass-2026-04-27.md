# DeepSeek MCP Review Pass (2026-04-27)

Model: `deepseek-v4-pro`  
Tool: `chat_completion` (schema-first)  
Scope:
- `Backend/functions/src/aiProxy.ts`
- `Backend/storage.rules`
- `Packages/PikaAI/Sources/PikaAI/{OpenAIClient,AnthropicClient,DeepSeekClient}.swift`

## Summary

DeepSeek review was run against backend + streaming client surfaces.  
Main practical items to keep/act on:

1. Add stronger message/content constraints in `aiProxy.ts` (already capped by schema, but still worth refining for abuse resistance).
2. Add stricter Storage content controls (`contentType`, size caps) for uploads.
3. Keep error-body sanitization and non-secret client errors (already implemented in `SecureNetworkPolicy.sanitizeServerBody` path).

## Findings Cross-check Against Real Code

### Confirmed
- `storage.rules` currently has no content-type / file-size checks.
- `aiProxy.ts` accepts up to 50 messages * 4000 chars each; this can be computationally expensive.
- Streaming clients now use `URLSession.bytes(for:)` + SSE parsing and a hardened ephemeral session policy.

### Already fixed (do not duplicate)
- Prompt injection via client `systemPrompt` is mitigated: `systemPrompt` is server-fixed in `aiProxy.ts`.
- Role injection from client `system` messages is mitigated: schema limits role to `user|assistant`.
- Quota race condition is mitigated: `enforceQuota` already uses Firestore `runTransaction`.
- DeepSeek reasoning tokens are suppressed and visible content is streamed correctly.

## Recommended next hardening (queued, not auto-applied in this note)

1. `aiProxy.ts`: add request-level size budget guard (aggregate chars / tokens estimate).
2. `storage.rules`: add `request.resource.size` and `request.resource.contentType.matches(...)` checks.
3. `aiProxy.ts`: enforce provider-model pair mapping explicitly (Anthropic models only for Anthropic, OpenAI models only for OpenAI) at runtime.
4. Keep sanitized provider errors to client; emit full diagnostics server-side only.

