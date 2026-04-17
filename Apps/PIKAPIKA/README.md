# PIKAPIKA — run this app in Xcode

You **do not** need **File → New → Project**. The Xcode project is already here: **`PIKAPIKA.xcodeproj`**.

## 1. Keep these folders together (required)

The app depends on a **local Swift package**. If you move only `Apps/PIKAPIKA`, the build will fail.

**Minimum layout** (paths must stay valid):

```
PIKAPIKA/                          ← repo / project root (any name is OK)
├── Apps/PIKAPIKA/
│   ├── PIKAPIKA.xcodeproj/        ← open this in Xcode
│   └── PIKAPIKA/
│       ├── PIKAPIKAApp.swift
│       ├── ContentView.swift
│       └── Assets.xcassets/
├── Packages/PikaCore/             ← required (SwiftData + umbrella module)
└── Packages/PikaCoreBase/         ← required (PikaCore’s path dependency)
```

When you **zip**, **upload to iCloud/Drive**, or **push to GitHub**, include at least **`Apps/`** and **`Packages/`** (or the whole repo).

## 2. One-time: point tools at Xcode (recommended)

In **Terminal**:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## 3. Open the project

- **Finder:** double-click **`PIKAPIKA.xcodeproj`** inside **`Apps/PIKAPIKA/`**,  
  **or**
- **Xcode:** **File → Open…** → select **`PIKAPIKA.xcodeproj`**.

Wait until **Package Dependencies** finish resolving (status bar). The local package is **`../../Packages/PikaCore`**.

## 4. Choose a simulator and run

1. At the top of Xcode, open the **scheme** menu → choose **PIKAPIKA** (if not already).
2. Open the **destination** menu → pick an **iPhone** simulator (iOS **17** or newer).
3. Press **⌘R** (Run).

If Xcode asks to install a simulator runtime, click **Get** and wait for it to finish, then run again.

## 5. Signing (optional)

- **Simulator only:** no Apple Developer account needed.
- **Physical iPhone:** select the **PIKAPIKA** target → **Signing & Capabilities** → choose your **Team** (Apple ID).

## 6. Command-line build (optional)

```bash
cd Apps/PIKAPIKA
xcodebuild -project PIKAPIKA.xcodeproj -scheme PIKAPIKA \
  -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build
```

You should see **`BUILD SUCCEEDED`**.

## What the app does

- In-memory **SwiftData** store for `Pet`, `BondEvent`, `ConversationMessage`, `SeasonalEvent`.
- **ContentView** shows an empty state until you add pets; bond tier uses **`BondLevel.from(xp:)`** from `PikaCore`.

## Package tests (library only, no app UI)

```bash
cd Packages/PikaCoreBase
swift test
```
