# IQ: Gut Intelligence — iOS App

A complete native iOS port of the Next.js IQ web app, built with Swift + SwiftUI.

---

## Project Structure

```
ios/IQ/
├── IQApp.swift                          # @main entry point
├── ContentView.swift                    # Onboarding vs main routing
│
├── DesignSystem/
│   └── IQColors.swift                   # Color system + IQFont helpers
│
├── Models/
│   └── IQModels.swift                   # All data models (Codable)
│
├── Services/
│   ├── FlareEngine.swift                # Risk calculation engine (1:1 JS port)
│   ├── LocalStorageService.swift        # UserDefaults persistence
│   └── MockResponseService.swift        # Mock AI responses
│
├── ViewModels/
│   └── AppViewModel.swift              # Central @ObservableObject state
│
└── Views/
    ├── Shared/
    │   ├── AppHeaderView.swift          # Gradient header bar
    │   ├── BottomNavView.swift          # Custom tab bar
    │   └── MainTabView.swift            # Tab shell (header + content + nav)
    ├── Onboarding/
    │   └── OnboardingView.swift         # 4-step onboarding + Apple Sign In
    ├── Home/
    │   ├── HomeView.swift               # Main home screen
    │   ├── CircularRiskDisk.swift       # Rotating word ring + score gauge
    │   ├── DailySummaryCard.swift       # Today's 3 stat cards
    │   └── QuickActionsView.swift       # Stacked deck → fan out on tap
    ├── Symptoms/
    │   └── SymptomsView.swift           # Symptom logging + history cards
    ├── Food/
    │   └── FoodView.swift               # Food logging + history
    ├── Calendar/
    │   ├── CalendarView.swift           # Monthly calendar + heatmap
    │   └── GitHubHeatmap.swift          # 53-week activity heatmap
    ├── Analytics/
    │   └── AnalyticsView.swift          # Charts + score breakdown
    └── Assistant/
        └── AssistantView.swift          # AI chat interface
```

---

## Xcode Setup

### Requirements
- Xcode 15+
- iOS 16+ deployment target (required for `Charts` framework)
- Swift 5.9+

### Steps

1. **Create a new Xcode project**
   - Template: App
   - Interface: SwiftUI
   - Language: Swift
   - Bundle ID: `com.yourname.IQ`
   - Minimum Deployment: iOS 16.0

2. **Copy all Swift files** from `ios/IQ/` into the Xcode project, preserving the folder structure.

3. **Add Capabilities**
   - In your target → Signing & Capabilities → **+ Capability** → add **Sign in with Apple**

4. **Frameworks** (all built-in — no external dependencies required)
   - `SwiftUI` — UI framework
   - `Charts` — analytics charts (iOS 16+)
   - `AuthenticationServices` — Apple Sign In
   - `Foundation` — data models + UserDefaults

5. **Build & Run** on Simulator (iOS 16+) or a physical device.

---

## Feature Parity

| Web Feature | iOS Equivalent |
|---|---|
| Next.js App Router | `AppTab` enum + `MainTabView` |
| React Context | `AppViewModel` (`@EnvironmentObject`) |
| localStorage | `UserDefaults` via `LocalStorageService` |
| Framer Motion animations | SwiftUI `withAnimation`, `.spring()`, `.linear().repeatForever()` |
| Recharts line chart | SwiftUI `Charts` framework (`LineMark`, `AreaMark`) |
| GitHub calendar SDK | `GitHubHeatmap` custom component |
| Circular text ring (SVG) | `CircularRiskDisk` using trigonometric positioning |
| Quick Actions stacked deck | `QuickActionsView` (2-phase: stacked → spread) |
| Gradient header | `AppHeaderView` with `LinearGradient` |
| Onboarding flow | `OnboardingView` (4 steps) |
| Authentication (N/A in web) | Apple Sign In via `AuthenticationServices` |
| shadcn/ui Slider | Native SwiftUI `Slider` |

---

## Architecture

- **MVVM**: Views are purely declarative, all business logic lives in `AppViewModel`
- **Single source of truth**: `AppViewModel` owns all `@Published` state
- **Persistence**: `LocalStorageService` wraps UserDefaults with type-safe JSON encode/decode
- **Risk engine**: `FlareEngine.swift` is a direct Swift translation of `flare-engine.ts` — weights, scoring functions, and public API are identical

---

## Approximations

- **Font variant "small-caps"**: SwiftUI does not support `font-variant: small-caps` directly — replaced with `.textCase(.uppercase)` + slightly smaller font size on "Gut Intelligence" subtitle.
- **Disk text ring**: Web uses SVG `<textPath>` on a circle arc. iOS uses trigonometric `cos`/`sin` positioning with per-label rotation — visually equivalent.
- **Framer Motion spring physics**: Matched as closely as possible using SwiftUI `spring(response:dampingFraction:)` with tuned parameters.
- **AI responses**: The app uses `MockResponseService` (pattern matching), the same as the web app's chatbot. No real LLM is integrated in either version.
