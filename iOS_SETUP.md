# iOS App — Ready to Build

✅ **Status:** Complete, ready to open in Xcode

## What's Included

- **23 Swift files** fully implemented
- **Xcode project** (.xcodeproj) configured
- **All features complete:** Home, Symptoms, Food, Calendar, Analytics, Assistant
- **Design system:** Liquid glass UI, custom colors, fonts
- **State management:** AppViewModel with full data binding
- **Persistence:** UserDefaults-backed storage
- **Flare engine:** Complete risk scoring algorithm

## Open & Run

### Option 1: Xcode UI
1. Open Finder
2. Navigate to `intestease/ios/`
3. Double-click `IQ.xcodeproj`
4. Select target device in toolbar
5. Press `Cmd + R` or click Play button

### Option 2: Terminal
```bash
cd /Users/vaibhav08/Documents/intestease
open ios/IQ.xcodeproj
```

### Option 3: Xcode Command Line
```bash
xcodebuild -scheme IQ -configuration Debug -derivedDataPath .build
```

## Recent Changes

✅ Disk words size: **8.5pt → 10.5pt** (bigger, more readable)
✅ Liquid glass: **Fully integrated** in FoodView (frosted glass cards + complementary UI)
✅ Next.js app: **Deleted** (src/, package.json, node_modules/, .next/)
✅ Project structure: **Cleaned** (iOS-only repo)

## File Organization

```
intestease/
├── ios/
│   ├── IQ.xcodeproj/              # Xcode project
│   ├── IQ/
│   │   ├── IQApp.swift            # Entry point
│   │   ├── ContentView.swift      # Root nav
│   │   ├── Info.plist             # App config
│   │   ├── DesignSystem/          # Colors, glass UI
│   │   ├── Models/                # Data types
│   │   ├── Services/              # Engines, storage
│   │   ├── ViewModels/            # State
│   │   └── Views/                 # All screens
│   └── README.md                  # Full docs
├── README.md                       # Quick start
├── PRD.md                          # Product spec
├── AGENTS.md                       # Dev notes
└── .git/                           # Version control
```

## Before You Build

✅ Check Xcode version: 15.4 or later
✅ Check iOS deployment target: 15.0 or later
✅ No external dependencies (pure SwiftUI)
✅ All source files in place

## Testing Checklist

Once the app launches:
- [ ] Onboarding flow appears
- [ ] Can complete 4-step setup
- [ ] Home screen shows rotating disk
- [ ] Risk score appears in disk center
- [ ] Symptom logging works
- [ ] Food logging has liquid glass cards
- [ ] Calendar shows heatmap
- [ ] Chat responses work
- [ ] Data persists after app restart

## Features Map

| Screen | File | Status |
|--------|------|--------|
| **Onboarding** | OnboardingView.swift | ✅ Complete |
| **Home** | HomeView.swift | ✅ Complete + disk 10.5pt |
| **Disk Ring** | CircularRiskDisk.swift | ✅ Complete + bigger text |
| **Symptoms** | SymptomsView.swift | ✅ Complete |
| **Food** | FoodView.swift | ✅ Complete + liquid glass |
| **Calendar** | CalendarView.swift | ✅ Complete |
| **Analytics** | AnalyticsView.swift | ✅ Complete |
| **Assistant** | AssistantView.swift | ✅ Complete |
| **Navigation** | MainTabView.swift | ✅ Complete |

## Known Limitations

- No real API (uses MockResponseService)
- No cloud sync (local only)
- No Apple Sign-In (added as optional in onboarding structure)
- No Health app integration
- No push notifications

## Next Steps After Build

1. **Test on simulator** — Build and run on iPhone 15 Pro simulator
2. **Test on device** — Deploy to real iPhone (requires developer account)
3. **Customize** — Update bundle ID, app icon, display name in Info.plist
4. **Submit** — When ready, submit to App Store via Xcode Organizer

## Troubleshooting

### Build fails
```bash
# Clean build folder
Cmd + Shift + K

# Then rebuild
Cmd + B
```

### Simulator issues
```bash
# Restart simulator
Device > Erase All Content and Settings...
```

### Console errors
Check Xcode console output (`Cmd + Shift + C`) for Swift compilation errors.

## Support

Full documentation: See `ios/README.md` for detailed setup, architecture, and troubleshooting.

---

**Ready to build!** 🚀

Next.js web app has been replaced with iOS-only project. All source code is self-contained in `ios/IQ/` and ready to build with Xcode.

**Command to open:**
```bash
open /Users/vaibhav08/Documents/intestease/ios/IQ.xcodeproj
```
