# iOS Project Repair/Regeneration Status (2026-04-27)

## Result

- Legacy `Apps/PIKAPIKA/PIKAPIKA.xcodeproj` remains unreadable (`XCLocalSwiftPackageReference _setOwner:`).
- Regenerated/canonical replacement path is confirmed:
  - `Apps/iOS/Pika.xcodeproj` (XcodeGen-managed app target).

## Verification Commands

1. Legacy project check (fails as damaged):
   - `xcodebuild -list -project "Apps/PIKAPIKA/PIKAPIKA.xcodeproj"`
2. Canonical project check (passes):
   - `xcodebuild -list -project "Apps/iOS/Pika.xcodeproj"`
3. iOS scheme build verification (passes when unsigned CI-style build is used):
   - `xcodebuild -project "Apps/iOS/Pika.xcodeproj" -scheme "Pika" -destination "generic/platform=iOS" CODE_SIGNING_ALLOWED=NO build`

## Notes

- Signed local device builds still require a configured development team.
- For autonomous CI and deterministic local verification, use unsigned build invocation above.
- Effective resolution for this plan item is **explicit project replacement** with the canonical iOS project under `Apps/iOS`.

