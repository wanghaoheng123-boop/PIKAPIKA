# Roadmap

## P0 — Scaffold ✅ (2026-04-18)
- PikaCore domain + utilities (shipped before this milestone)
- PikaAI, PetEngine, PikaSync, PikaSubscription, SharedUI — first-pass
- XcodeGen specs, iOS + macOS app shells
- Firebase project (functions, rules, schema docs)
- Docs

## P1 — AI chat MVP ✅ (2026-04-18)
- [x] Persist `ConversationMessage` through SwiftData instead of in-memory `@State` ([Apps/Shared/Sources/PetChatScreen.swift](Apps/Shared/Sources/PetChatScreen.swift))
- [x] Prune to last 50 messages per pet (after each save; optional `BackgroundTasks` polish later)
- [x] Wire `AIProviderRouter` fallback on 5xx / rate-limit / network-ish `URLError`
- [x] Settings: preferred provider + test connection ([Apps/Shared/Sources/PikaSettingsContent.swift](Apps/Shared/Sources/PikaSettingsContent.swift))
- [x] Error surface + Retry in shared chat when the assistant stream fails after the user line was saved

## P2 — Bond loop
- [ ] Daily check-in streak logic
- [ ] Level-up celebration animation + haptic
- [ ] BondEvent write-through and analytics view
- [ ] Respect `BondProgression.dailyCap`

## P3 — Activity monitor (macOS)
- [ ] Accessibility permission onboarding flow
- [ ] Menu-bar live state (currently static)
- [ ] Sprite + Lottie render (replace emoji placeholder in `PetAvatarView`)

## P4 — CloudKit sync
- [ ] SwiftData CloudKit container entitlement
- [ ] Conflict resolution tests against real CK backend
- [ ] Handoff: start chat on iPhone, continue on Mac

## P5 — Monetization
- [ ] App Store Connect products (`com.pikapika.pro.monthly` etc.)
- [ ] Paywall sheet
- [ ] Entitlement gating in AI proxy (Pro → higher quota)

## P6 — Ship
- [ ] App Store assets, screenshots, reviews
- [ ] TestFlight cohort
- [ ] Launch
