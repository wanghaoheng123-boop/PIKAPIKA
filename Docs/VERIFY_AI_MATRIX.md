# Manual verification — AI and settings (both apps)

Run these on **iOS Simulator** or device after `bash Scripts/generate-xcode.sh` (Pika) or opening **PIKAPIKA.xcodeproj** (legacy).

| Scenario | Steps | Expected |
|----------|--------|----------|
| Anthropic-only | Save Anthropic key only; preference “Anthropic first”; remote chat on | Chat and connection test succeed; image generation still requires OpenAI (banner / Settings copy). |
| OpenAI-only | Save OpenAI only; preference “OpenAI first” | Chat + DALL·E-style portrait tools work when toggles allow. |
| Both keys | Save both; flip provider order | Chat follows preference; fallback on rate limit / network errors when the other key exists. |
| No keys | Remove both keys | Mock / offline behavior; UI explains missing keys (Pika chat banner; PIKAPIKA Settings status). |
| Remote toggles off | Keys present; disable “Use remote AI for chat” | Local companion replies only (legacy `PetChatActions`). |
| Post-create edit | Pika: **Edit** on home; PIKAPIKA: customize sheet | Name, species, traits, preset persist. |
| 3D preset | Set preset cat/dog/spark; no USDZ | Procedural SceneKit figure appears in PIKAPIKA avatar stage. |

CI: `.github/workflows/pika-ci.yml` (packages) and `functions-ci.yml` (Backend) should stay green after changes.
