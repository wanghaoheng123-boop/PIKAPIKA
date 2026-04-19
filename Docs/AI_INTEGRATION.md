# AI integration

## Providers

| Provider  | Chat                   | Image gen             | Vision (describe)  |
|-----------|------------------------|-----------------------|--------------------|
| Anthropic | ✅ streaming, cached    | ❌ (fallback OpenAI)  | ✅                 |
| OpenAI    | ✅ streaming            | ✅ `dall-e-3`         | ✅ `gpt-4o` vision |

Routing is handled by `PikaAI.AIProviderRouter`. Default preference is
Anthropic for chat; OpenAI is the mandatory fallback for image generation.

The legacy **PIKAPIKA** target uses `PikaAI.RoutedAIClient` (same routing) once any vendor key exists, so **Anthropic-only** setups still get real chat instead of the old OpenAI-only gate.

## Models (as of 2026-04)

- Chat default: `claude-sonnet-4-6`
- Chat "fast" tier (future): `claude-haiku-4-5-20251001`
- Chat "smart" tier (future): `claude-opus-4-7`
- Image: `dall-e-3`
- Vision: `gpt-4o` (OpenAI) or `claude-sonnet-4-6` (Anthropic)

To change the default, update `AnthropicClient(model:)` or `OpenAIClient(model:)`
at the call site, or expose a Setting. Don't fork the client.

## Prompt caching

The system prompt built by `PromptLibrary.systemPrompt` is long-lived per
(pet, bondLevel, context) — exactly the shape prompt caching is designed for.
`AnthropicClient` marks the system block with
`cache_control: { type: "ephemeral" }`. Chat turns within the 5-minute cache
window get a cache hit, cutting input-token cost for chat-heavy pets.

If you edit `PromptLibrary`, be aware that every byte change busts the cache
for existing conversations. Prefer append-only edits during a session.

## Server-side proxy

`Backend/functions/src/aiProxy.ts` exposes the same shape as a callable
function, using server-owned keys. Use it for:
- Free-tier users without a BYO key (gated by subscription in P5)
- Enforcing a daily quota per UID (`rateLimits/{uid}_{YYYY-MM-DD}`)

The client's `AIClient` abstraction makes it trivial to swap in a
`FirebaseProxyClient` that calls `aiChat` instead of the vendor API. Not
shipped yet — see P1.

## Keys

Keys live in the device Keychain via `PikaCore.KeychainHelper`. They never
leave the device except as outgoing Authorization headers to the vendor.
`BiometricAuthManager` gates reveal in Settings.
