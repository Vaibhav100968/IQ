# iOS App — SDK Integration Guide

## Overview
This guide shows exactly where and how to integrate your custom SDKs into the IQ iOS app. All placeholder sections are clearly marked in the code.

---

## 🎯 TASK 1: Percentage Disc SDK

**Location:** `/IQ/Views/Home/HomeView.swift` (Lines ~46-71)

**Current Component:** `CircularRiskDisk`

**What to Replace:**
```swift
// CURRENT (lines 46-71)
VStack(spacing: 16) {
    CircularRiskDisk(risk: appVM.flareRisk)
        .frame(height: 280)
        .padding(.top, 8)
    riskBreakdown
}
```

**Expected SDK Props:**
- Risk score: `0-100` (from `appVM.flareRisk.overallScore`)
- Risk level: `.low` / `.medium` / `.high` (from `appVM.flareRisk.level`)
- Container size: `~280pt` height
- Circular layout, centered

**Integration Steps:**
1. Copy your Percentage Disc SDK to `/Views/Components/PercentageDisc.swift`
2. Import it in `HomeView.swift`
3. Replace the `CircularRiskDisk` call with your component
4. Keep the surrounding padding and `riskBreakdown` section unchanged

**Expected Appearance:**
- Clean, modern circular progress indicator
- Shows flare risk percentage
- Centered in the card
- Smooth animations

---

## 🎯 TASK 2: Quick Actions (Notecard Stack) SDK

**Location:** `/IQ/Views/Home/HomeView.swift` (Lines ~94-108)

**Current Component:** `QuickActionsView`

**What to Replace:**
```swift
// CURRENT (lines 94-108)
VStack(alignment: .leading, spacing: 12) {
    Text("Quick Actions")
        .font(IQFont.bold(18))
        .foregroundColor(IQColors.textPrimary)
        .padding(.horizontal, 16)

    QuickActionsView()
        .frame(maxWidth: .infinity, alignment: .leading)
}
```

**Expected SDK Behavior:**
- Cards stack vertically, first card fully visible
- Subsequent cards offset below (show ~20-30pt peek)
- **Tap to expand:** Cards spread vertically with smooth animation
- **Tap to collapse:** Cards stack back together
- **No blur** — sharp rendering in both states
- Should include 3-5 action cards (Quick log symptom, Log food, View calendar, etc.)

**Integration Steps:**
1. Copy your Testimonial Cards SDK to `/Views/Components/TestimonialCards.swift`
2. Adapt the component to show action buttons instead of testimonials
3. Replace `QuickActionsView` with your component
4. Keep the "Quick Actions" header and spacing

**Expected Card Content:**
Each card should display:
- Icon (SF Symbols)
- Action title
- Brief description
- Tap target

---

## 🎯 TASK 3: Today Stats Section SDK

**Location:** `/IQ/Views/Home/HomeView.swift` (Lines ~73-83)

**Current Component:** `DailySummaryCard`

**What to Replace:**
```swift
// CURRENT (lines 73-83)
VStack(alignment: .leading, spacing: 12) {
    todayHeader
    DailySummaryCard(
        symptomCount: appVM.todaySymptomCount,
        mealCount: appVM.todayMealCount,
        total: appVM.todayTotal
    )
}
```

**Expected SDK Props:**
- `symptomCount`: Int (logged symptoms today)
- `mealCount`: Int (logged meals today)
- `total`: Int (symptoms + meals)
- Date: `Date()` (today's date)

**Integration Steps:**
1. Copy your Draggable Card or custom Today section SDK to `/Views/Components/TodayStatsCard.swift`
2. Replace `DailySummaryCard` with your component
3. Keep the `todayHeader` section above it

**Expected Layout:**
- 3 stat cards in horizontal row (or responsive grid)
- Show counts for: Symptoms, Meals, Total
- Clean, modern design
- Matches overall design system (pink/lavender gradients)

---

## 🎯 TASK 4: Bottom Tab Bar Spacing Fixes ✅ COMPLETED

**Location:** `/IQ/Views/Shared/BottomNavView.swift`

**What Was Fixed:**
- ✅ Moved tab bar upward (added 10pt top divider padding)
- ✅ Improved spacing between items (12pt bottom padding, 8pt horizontal)
- ✅ Fixed icon/text spacing (4pt gap instead of 3pt)
- ✅ Fixed height to 72pt for consistent safe area alignment
- ✅ Larger tap targets (8pt vertical padding per tab)

**No action needed** — this section is already complete!

---

## 📐 Layout Grid & Spacing System

### Vertical Spacing (Section Gaps)
```
16pt  — Pre-flare banner to Disk section
24pt  — Major section gaps (Disk → Today → Quick Actions)
12pt  — Sub-section gaps (Header → Content)
8pt   — Minor content gaps
```

### Horizontal Padding
```
16pt  — Main content padding (left/right)
8pt   — Internal component spacing
4pt   — Fine details (dividers, etc.)
```

### Font Hierarchy
```
18pt Bold    — Section titles ("Today", "Quick Actions")
16pt Bold    — Card titles
14pt Regular — Body text
12pt Regular — Secondary text
10pt Regular — Tab labels
```

---

## 🎨 Design System (IQColors)

Use these colors for your SDK components:

```swift
IQColors.pink          // #FFCAE9 (primary pink)
IQColors.pinkDark      // #c4458a (darker pink)
IQColors.lavender      // #CDD0F8 (primary lavender)
IQColors.lavenderDark  // #5057d5 (darker lavender)
IQColors.background    // #F5F4FF (light bg)
IQColors.textPrimary   // #1a1a2e (dark text)
IQColors.textSecondary // Muted gray
IQColors.textMuted     // Light gray
IQColors.border        // Border color
```

---

## 📋 SDK Integration Checklist

### Before Copying SDK Code:
- [ ] Remove any external dependencies
- [ ] Convert to pure SwiftUI (no UIKit unless necessary)
- [ ] Ensure iOS 16+ compatibility
- [ ] Test on iPhone 12, 13, 14 sizes

### After Integration:
- [ ] Check spacing matches surrounding content
- [ ] Verify animations are smooth (60fps)
- [ ] Test on light/dark mode
- [ ] Ensure safe area is respected
- [ ] Check accessibility (VoiceOver labels)

### Testing:
- [ ] Build on simulator (`Cmd+R` in Xcode)
- [ ] Test all interactions (tap, drag, scroll)
- [ ] Verify no console warnings/errors
- [ ] Check memory usage (no leaks)

---

## 🔧 Quick Reference: File Locations

```
ios/IQ/
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift          ← Main page
│   │   ├── CircularRiskDisk.swift
│   │   ├── DailySummaryCard.swift
│   │   └── QuickActionsView.swift
│   ├── Components/                 ← PUT SDKs HERE
│   │   ├── PercentageDisc.swift
│   │   ├── TestimonialCards.swift
│   │   ├── TodayStatsCard.swift
│   │   └── ...
│   └── Shared/
│       ├── BottomNavView.swift      ← Fixed ✅
│       └── AppHeaderView.swift
├── DesignSystem/
│   ├── IQColors.swift
│   └── IQFont.swift
└── ...
```

---

## 💡 Common Integration Patterns

### Using SDK Data
```swift
// In your SDK component
struct YourSDKComponent: View {
    let symptomCount: Int
    let mealCount: Int
    let total: Int

    var body: some View {
        // Your layout here
    }
}

// Usage in HomeView
YourSDKComponent(
    symptomCount: appVM.todaySymptomCount,
    mealCount: appVM.todayMealCount,
    total: appVM.todayTotal
)
```

### Animations
```swift
// All animations use spring physics
withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
    // State changes here
}
```

### Safe Area
```swift
// Always respect safe area
.ignoresSafeArea(edges: .bottom)  // Only if needed
// Otherwise let SwiftUI handle it automatically
```

---

## ❓ FAQ

**Q: Can I use external packages in my SDK?**
A: Avoid third-party dependencies. Use native SwiftUI APIs only.

**Q: What if my SDK uses AsyncImage?**
A: That's fine — `AsyncImage` is built into SwiftUI (iOS 15+).

**Q: How do I handle dark mode?**
A: Use colors from `IQColors` — they automatically adapt to system appearance.

**Q: My SDK looks different on iPhone 12 vs 14 Pro Max?**
A: Use `.frame(maxWidth: .infinity)` for responsive layouts, and test with different `@ScaledMetric` values.

---

## 🚀 Next Steps

1. **Prepare your SDK code**
   - Remove any external dependencies
   - Ensure it's pure SwiftUI

2. **Copy to Components folder**
   - Create new files in `/Views/Components/`
   - Import in `HomeView.swift`

3. **Replace placeholders**
   - Remove old components
   - Add your SDK components

4. **Test thoroughly**
   - Run on simulator
   - Check all interactions
   - Verify layout on different devices

5. **Deploy**
   - Build for device
   - Archive and submit to App Store

---

## 📞 Support

For layout questions, refer to:
- `/IQ/DesignSystem/IQColors.swift` — all colors
- `/IQ/DesignSystem/IQFont.swift` — all fonts
- This guide's spacing system section

Good luck! 🎉
