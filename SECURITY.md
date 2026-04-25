# Security Policy

## Supported Scope

Commercial release readiness applies to:

- `Apps/iOS`
- `Apps/macOS`
- `Apps/Shared`
- `Packages/PikaAI`
- `Packages/SharedUI`
- `Packages/PikaCore*`

## Reporting a Vulnerability

Do not open public issues for active vulnerabilities.

Provide:

1. Affected path(s)
2. Impact summary
3. Reproduction steps
4. Suggested mitigation

## Release Blocking Rules

- Any open **critical/high** security finding blocks release.
- Any secret exposure in git history or CI scan blocks release.
- Any failing required security workflow blocks release.
