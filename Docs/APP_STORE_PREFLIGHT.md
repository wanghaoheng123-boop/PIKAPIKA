# App Store and TestFlight preflight

Use this checklist before **Archive → Distribute** and before promoting a TestFlight build to **App Store Connect** review.

## Build and device matrix

- [ ] **Clean clone** outside cloud-sync paths; run `bash Scripts/bootstrap.sh`, open `Apps/iOS/Pika.xcodeproj`.
- [ ] **Archive** with **Release** configuration; lowest supported **iOS** version selected in General (matches `Package.swift` / deployment target).
- [ ] Test on **physical device** (not simulator only): cold launch, onboarding, chat send, Settings, background/foreground.
- [ ] **Dark Mode** and **Dynamic Type** smoke test on primary screens.

## Signing and capabilities

- [ ] **Development team** set on the iOS target (`project.yml` ships with blank team).
- [ ] **App ID** capabilities in Apple Developer portal match entitlements (Keychain, Push if used, iCloud if used, etc.).
- [ ] **Provisioning profiles** refreshed after capability changes.

## App Store Connect metadata

- [ ] Screenshots for required device sizes.
- [ ] Privacy **nutrition labels** accurate (data linked to user, tracking, etc.).
- [ ] **App Encryption** / export compliance questionnaire completed (HTTPS-only typically exempt; confirm for your stack).
- [ ] **Subscription group** and pricing for annual plan; review notes explain trial/intro if any.

## Privacy and safety

- [ ] Privacy policy URL live; matches in-app disclosure.
- [ ] AI features: disclose model providers and data sent to APIs (see [`Docs/AI_INTEGRATION.md`](AI_INTEGRATION.md) if present).
- [ ] Child safety / UGC: if user-generated content or chat is stored server-side, document moderation approach.

## CI gap (optional hardening)

- Package CI ([`.github/workflows/pika-ci.yml`](../.github/workflows/pika-ci.yml)) validates **PikaCoreBase** + **PikaAI** Swift packages. It does **not** archive the XcodeGen app by default.
- **Optional manual job:** [`.github/workflows/pika-app-build.yml`](../.github/workflows/pika-app-build.yml) (`workflow_dispatch`) runs XcodeGen + `xcodebuild` for **`Apps/iOS`** with `CODE_SIGNING_ALLOWED=NO` to catch app-level compile issues without slowing every push.

## TestFlight

- [ ] Internal testing group receives build; collect crash logs from **Xcode Organizer** or **TestFlight** feedback.
- [ ] Verify **version/build** numbers monotonic per submission.

## Post-launch

- [ ] Monitor **App Store Connect** crashes and ANRs (hang rate).
- [ ] Rollback plan: keep previous tagged release branch for hotfix.
