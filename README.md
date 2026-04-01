# IQ: Gut Intelligence — iOS App

A native iOS app for tracking gut health, food logging, and flare prediction using SwiftUI and Swift.

## Quick Start

### Open the Project
```bash
open ios/IQ.xcodeproj
```

### Build & Run
1. Select target device or simulator in Xcode
2. Press `Cmd + R` or click the Play button
3. App will launch on device/simulator

## Project Structure

- **`ios/IQ/`** — Complete native iOS app (SwiftUI)
- **`PRD.md`** — Product requirements document
- **`AGENTS.md`** & **`CLAUDE.md`** — Development notes

## Features

✅ Symptom tracking with severity scoring
✅ Food logging with dietary tags
✅ Flare risk prediction (AI-powered scoring engine)
✅ Activity heatmap calendar (GitHub-style)
✅ Analytics dashboard with trends
✅ AI assistant chat
✅ Local data persistence (UserDefaults)
✅ Liquid glass UI design system

## Requirements

- iOS 15.0+
- Xcode 15.4+
- Swift 5.9

## Documentation

For detailed setup, architecture, and troubleshooting, see:
- **[iOS Setup Guide](ios/README.md)** — Full documentation

## Architecture Highlights

- **MVVM** with `@ObservableObject` + `@Published`
- **SwiftUI** native (no UIKit)
- **Liquid Glass** cards for food UI
- **Flare Engine** — 5-component risk scoring algorithm
- **Local persistence** via UserDefaults

---

**Version:** 1.0
**Platform:** iOS 15.0+
**Last Updated:** 2026-03-26
