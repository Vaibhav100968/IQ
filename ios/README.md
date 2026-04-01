# IQ iOS App — Native SwiftUI Implementation

## Overview

Complete native iOS implementation of the IQ: Gut Intelligence app using Swift and SwiftUI. This is a pixel-parity conversion of the Next.js web app with full feature parity and native iOS optimizations.

## Setup Instructions

### Requirements
- Xcode 15.4 or later
- iOS 15.0 or later (target device)
- Swift 5.9

### Opening the Project

1. **Open Xcode:**
   ```bash
   open ios/IQ.xcodeproj
   ```

2. **Select Target Device/Simulator:**
   - In Xcode top toolbar, select target device or simulator
   - Recommended: iPhone 15 Pro (iOS 17 or later)

3. **Build & Run:**
   - Press `Cmd + R` to build and run
   - Or click the Play button in the top-left toolbar

### Project Structure

```
ios/IQ/
├── IQApp.swift                          # App entry point (@main)
├── ContentView.swift                    # Root navigation container
├── Info.plist                           # App configuration
├── DesignSystem/
│   ├── IQColors.swift                   # Design system colors + hex init
│   └── LiquidGlassKit.swift             # Liquid glass UI primitives
├── Models/
│   └── IQModels.swift                   # All Codable data models
├── Services/
│   ├── FlareEngine.swift                # Flare risk calculation engine
│   ├── LocalStorageService.swift        # UserDefaults persistence
│   └── MockResponseService.swift        # Mock AI responses
├── ViewModels/
│   └── AppViewModel.swift               # Central state (@ObservableObject)
└── Views/
    ├── Shared/
    │   ├── AppHeaderView.swift
    │   ├── BottomNavView.swift
    │   └── MainTabView.swift
    ├── Home/
    │   ├── HomeView.swift
    │   ├── CircularRiskDisk.swift
    │   ├── DailySummaryCard.swift
    │   └── QuickActionsView.swift
    ├── Onboarding/
    │   └── OnboardingView.swift
    ├── Symptoms/
    │   ├── SymptomsView.swift
    │   └── SymptomCard.swift
    ├── Food/
    │   ├── FoodView.swift
    │   └── FoodEntryForm.swift
    ├── Calendar/
    │   ├── CalendarView.swift
    │   └── GitHubHeatmap.swift
    ├── Analytics/
    │   └── AnalyticsView.swift
    └── Assistant/
        └── AssistantView.swift
```

## Architecture

### State Management
- **AppViewModel:** Central `@ObservableObject` managing all app state (user profile, entries, flare risk, chat)
- **@Published properties** for reactive updates across Views
- **@Environment** for dependency injection

### Data Persistence
- **UserDefaults** via `LocalStorageService` (mirrors web app's localStorage)
- Keys: `iq_symptom_entries`, `iq_food_entries`, `iq_user_profile`, `iq_chat_history`
- Automatic encode/decode via `Codable`

### UI Patterns
- **SwiftUI native** (no UIKit wrappers)
- **Liquid Glass cards** for food logging (frosted glass effect)
- **Circular disk** for risk visualization (rotating text ring with gauge)
- **Tab-based navigation** (bottom tab bar)
- **NavigationStack** for internal page navigation

### Design System
- **Colors:** All from web design system (IQColors struct)
- **Typography:** Custom IQFont helpers (system fonts with named weights)
- **Gradients:** Header, disk, and card gradients
- **Spacing & Sizing:** Consistent with web app

## Feature Checklist

✅ **Onboarding** — 4-step setup with condition, triggers, summary
✅ **Home** — Rotating risk disk + daily stats + quick actions
✅ **Symptom Logging** — Create, edit, view symptom history
✅ **Food Logging** — Liquid glass cards with tags, portion, notes
✅ **Calendar** — GitHub-style heatmap (53-week view) + monthly calendar
✅ **Analytics** — Line chart of logging trends (SwiftUI Charts)
✅ **AI Assistant** — Chat interface with mock responses
✅ **Flare Engine** — Full risk scoring (symptom, trigger, trend, pattern, NL signal)
✅ **Local Persistence** — UserDefaults-backed storage
✅ **Design System** — Pixel-parity with web design

## Key Implementation Notes

### Disk Text Size
- Font size increased from 8.5 to **10.5pt** for better visibility
- Tracking: **0.9** (letter-spacing)
- Rotates continuously at 30-second period

### Liquid Glass
- **LiquidGlassCard** modifier applies `.ultraThinMaterial` blur + gradient tint
- **FrostedPill** and **FrostedIconWell** provide complementary accent elements inside glass cards
- Used extensively in Food logging UI

### Flare Risk Calculation
- **5-component scoring:**
  - Symptom 35%
  - Trigger 25%
  - Trend 20%
  - Pattern 10%
  - NL Signal 10%
- Runs on every data change
- Risk levels: Low (0-35), Moderate (35-70), High (70-100)

### Chart Framework
- **SwiftUI Charts** (iOS 16+) for analytics
- Renders 30-day logging trend
- Lines and points styled to match web design

### Storage Keys (UserDefaults)
```swift
"iq_symptom_entries"   // [SymptomEntry]
"iq_food_entries"      // [FoodEntry]
"iq_user_profile"      // UserProfile
"iq_chat_history"      // [ChatMessage]
```

## Differences from Web App

| Aspect | Web | iOS |
|--------|-----|-----|
| Auth | None | Apple Sign-In (optional) |
| Navigation | Next.js routing | NavigationStack + Tab bar |
| Persistence | localStorage (browser) | UserDefaults (system) |
| Charts | Recharts (React) | SwiftUI Charts |
| Disk rendering | SVG + Framer Motion | Trigonometric positioning + SwiftUI animations |
| Glass UI | Tailwind CSS | Liquid Glass SDK (native) |
| Icons | React icons | SF Symbols |

## Troubleshooting

### Build fails with "Swift version X"
- Check Xcode version matches project settings (15.4+)
- Go to Project Settings > Build Settings > Swift Language Version

### App crashes on startup
- Check Console output (`Cmd + Shift + C` in Xcode)
- Verify Info.plist is present in IQ folder
- Ensure all Swift files are in Xcode target membership (right panel)

### Data not persisting
- Check UserDefaults keys in LocalStorageService
- Verify all models conform to `Codable`
- Try clearing app data: Settings > General > iPhone Storage > IQ > Offload App

### Simulator black screen after launch
- Try restarting simulator: Device > Erase All Content and Settings...
- Or rebuild: `Cmd + Shift + K` then `Cmd + B`

## Testing

### Manual Testing Checklist
- [ ] Onboarding completes and saves profile
- [ ] Home disk rotates continuously
- [ ] Risk score updates when adding symptoms
- [ ] Food logging with tags works
- [ ] Calendar heatmap shows correct colors
- [ ] Chat responses appear correctly
- [ ] Data persists after app close/reopen

### Data Reset
To clear all app data and start fresh:
```swift
// In AppViewModel or a debug menu:
localStorage.clearAllData()
```

## Future Enhancements

- Real API integration (replace MockResponseService)
- Push notifications for flare warnings
- Health app integration (HealthKit)
- Companion watchOS app
- CloudKit sync for multi-device support
- Siri Shortcuts integration

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Xcode build logs (`Cmd + Shift + C`)
3. Verify all source files are present in `ios/IQ/` directory
4. Ensure Info.plist exists and points to correct bundle ID

---

**Version:** 1.0
**Target iOS:** 15.0+
**Last Updated:** 2026-03-26
