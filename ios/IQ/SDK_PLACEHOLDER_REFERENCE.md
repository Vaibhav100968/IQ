# SDK Placeholder Reference — Copy & Paste Locations

## 🎯 Quick Reference: Where to Paste Your SDKs

Open `HomeView.swift` and find these three sections. The comments show exactly where to paste each SDK.

---

## SDK #1: Percentage Disc (Circular Progress)

**File:** `HomeView.swift`
**Search for:** `// SECTION 1: PERCENTAGE DISC + RISK BREAKDOWN`
**Lines:** ~20-45

### Current Code Block:
```swift
// ═══════════════════════════════════════════════════════════════
// SECTION 1: PERCENTAGE DISC + RISK BREAKDOWN
// ═══════════════════════════════════════════════════════════════
VStack(spacing: 16) {
    // ───────────────────────────────────────────────────────────
    // SDK PLACEHOLDER: PERCENTAGE DISC
    // ───────────────────────────────────────────────────────────
    // Replace the CircularRiskDisk below with your Percentage Disc SDK
    // Expected props: risk score (0-100), risk level (low/medium/high)
    // Size: ~280pt container
    //
    // Paste your SDK component here:
    // ───────────────────────────────────────────────────────────

    CircularRiskDisk(risk: appVM.flareRisk)
        .frame(height: 280)
        .padding(.top, 8)

    // Risk detail breakdown chips
    riskBreakdown
}
```

### What to Replace:
**Remove this line:**
```swift
CircularRiskDisk(risk: appVM.flareRisk)
    .frame(height: 280)
    .padding(.top, 8)
```

**Replace with your SDK:**
```swift
YourPercentageDiscSDK(
    riskScore: appVM.flareRisk.overallScore,
    riskLevel: appVM.flareRisk.level
)
.frame(height: 280)
.padding(.top, 8)
```

### Expected Component Props:
```swift
struct YourPercentageDiscSDK: View {
    let riskScore: Int          // 0-100
    let riskLevel: RiskLevel    // .low, .medium, .high
    // ... your implementation
}
```

### Keep This Unchanged:
- The surrounding `VStack(spacing: 16)`
- The `riskBreakdown` section below
- All padding and styling

---

## SDK #2: Today Stats Card

**File:** `HomeView.swift`
**Search for:** `// SECTION 2: TODAY STATS`
**Lines:** ~59-82

### Current Code Block:
```swift
// ═══════════════════════════════════════════════════════════════
// SECTION 2: TODAY STATS
// ═══════════════════════════════════════════════════════════════
VStack(alignment: .leading, spacing: 12) {
    // Header with date
    todayHeader

    // ───────────────────────────────────────────────────────────
    // SDK PLACEHOLDER: TODAY STATS CARD
    // ───────────────────────────────────────────────────────────
    // Replace DailySummaryCard with your "Today" section SDK
    // Expected props: symptomCount, mealCount, total
    // Layout: 3 stat cards in a horizontal row
    //
    // Paste your SDK component here:
    // ───────────────────────────────────────────────────────────

    DailySummaryCard(
        symptomCount: appVM.todaySymptomCount,
        mealCount: appVM.todayMealCount,
        total: appVM.todayTotal
    )
}
.padding(.horizontal, 16)
```

### What to Replace:
**Remove this component:**
```swift
DailySummaryCard(
    symptomCount: appVM.todaySymptomCount,
    mealCount: appVM.todayMealCount,
    total: appVM.todayTotal
)
```

**Replace with your SDK:**
```swift
YourTodayStatsSDK(
    symptomCount: appVM.todaySymptomCount,
    mealCount: appVM.todayMealCount,
    total: appVM.todayTotal
)
```

### Expected Component Props:
```swift
struct YourTodayStatsSDK: View {
    let symptomCount: Int
    let mealCount: Int
    let total: Int
    // ... your implementation
}
```

### Keep This Unchanged:
- The `VStack(alignment: .leading, spacing: 12)`
- The `todayHeader` above
- The `.padding(.horizontal, 16)` wrapper

---

## SDK #3: Quick Actions Notecard Stack

**File:** `HomeView.swift`
**Search for:** `// SECTION 3: QUICK ACTIONS (NOTECARDS STACK)`
**Lines:** ~84-110

### Current Code Block:
```swift
// ═══════════════════════════════════════════════════════════════
// SECTION 3: QUICK ACTIONS (NOTECARDS STACK)
// ═══════════════════════════════════════════════════════════════
VStack(alignment: .leading, spacing: 12) {
    // Section header
    Text("Quick Actions")
        .font(IQFont.bold(18))
        .foregroundColor(IQColors.textPrimary)
        .padding(.horizontal, 16)

    // ───────────────────────────────────────────────────────────
    // SDK PLACEHOLDER: NOTECARD STACK
    // ───────────────────────────────────────────────────────────
    // Replace QuickActionsView with your Testimonial Cards SDK
    // Expected behavior:
    //   - Cards stack vertically, first card fully visible
    //   - Subsequent cards slightly offset below (peek)
    //   - Tap to expand: cards spread apart smoothly
    //   - Tap to collapse: cards stack back together
    //   - No blur, sharp rendering in both states
    //
    // Paste your SDK component here:
    // ───────────────────────────────────────────────────────────

    QuickActionsView()
        .frame(maxWidth: .infinity, alignment: .leading)
}
```

### What to Replace:
**Remove this component:**
```swift
QuickActionsView()
    .frame(maxWidth: .infinity, alignment: .leading)
```

**Replace with your SDK:**
```swift
YourNotecardStackSDK()
    .frame(maxWidth: .infinity, alignment: .leading)
```

### Expected Component Behavior:
```swift
struct YourNotecardStackSDK: View {
    // Behavior expectations:
    // 1. Cards stack vertically (no horizontal scroll)
    // 2. First card fully visible
    // 3. Other cards show ~20-30pt peek below
    // 4. Tap card → expand: cards spread apart
    // 5. Tap again → collapse: cards stack
    // 6. Sharp rendering (no blur effects)
    // 7. Smooth spring animations

    var body: some View {
        // ... your implementation
    }
}
```

### Keep This Unchanged:
- The "Quick Actions" header `Text(...)`
- The surrounding `VStack(alignment: .leading, spacing: 12)`
- The `.frame(maxWidth: .infinity, alignment: .leading)` on your SDK

---

## 🔧 Step-by-Step Integration

### Step 1: Create SDK File
```bash
# In Xcode or terminal:
touch ios/IQ/Views/Components/YourSDKName.swift
```

### Step 2: Add Import to HomeView
```swift
import SwiftUI
// ← YourSDKName is automatically available if in same module
```

### Step 3: Find & Replace
1. Open `HomeView.swift`
2. Find the SDK PLACEHOLDER comment sections
3. Replace the old component with your new one
4. Keep all surrounding code unchanged

### Step 4: Build & Test
```bash
# In Xcode:
Cmd+R  # Build and run on simulator
```

### Step 5: Verify Spacing
Check that:
- [ ] 24pt gaps between sections (major sections)
- [ ] 12pt gaps between header and content
- [ ] 16pt horizontal padding
- [ ] Responsive on different iPhone sizes

---

## ✅ Integration Checklist

Before pasting each SDK:
- [ ] SDK file created in `/Views/Components/`
- [ ] No external dependencies (pure SwiftUI only)
- [ ] Uses `IQColors` for all colors
- [ ] Uses `IQFont` for all typography
- [ ] iOS 16+ compatible
- [ ] Has a `#Preview` block for testing

After pasting each SDK:
- [ ] No compilation errors
- [ ] Builds successfully (`Cmd+B`)
- [ ] Layout looks correct on simulator
- [ ] Spacing matches surrounding sections
- [ ] Animations are smooth (60fps)
- [ ] Works in light & dark mode

---

## 📝 Example: Custom Percentage Disc SDK

Here's a template for how your SDK should look:

```swift
import SwiftUI

struct YourPercentageDiscSDK: View {
    let riskScore: Int           // 0-100
    let riskLevel: RiskLevel     // from your app

    var body: some View {
        ZStack {
            // Circular background
            Circle()
                .fill(IQColors.background)
                .shadow(...)

            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(riskScore) / 100)
                .stroke(
                    LinearGradient(
                        colors: [IQColors.pink, IQColors.lavender],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotation3DEffect(
                    .degrees(180),
                    axis: (x: 0, y: 1, z: 0)
                )

            // Center text
            VStack(spacing: 4) {
                Text("\(riskScore)%")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(IQColors.textPrimary)

                Text(riskLevel.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(IQColors.textSecondary)
            }
        }
        .frame(height: 280)
    }
}

#Preview {
    YourPercentageDiscSDK(riskScore: 62, riskLevel: .medium)
        .padding()
        .background(IQColors.background)
}
```

---

## 📞 Quick Reference

| SDK | File Location | Replace Component | Props |
|-----|---------------|--------------------|-------|
| **Disc** | HomeView:~20 | `CircularRiskDisk` | `riskScore: Int, riskLevel: RiskLevel` |
| **Today** | HomeView:~59 | `DailySummaryCard` | `symptomCount: Int, mealCount: Int, total: Int` |
| **Quick Actions** | HomeView:~84 | `QuickActionsView` | None (standalone) |

---

## 🎨 Design System Reference

Use these while building your SDKs:

```swift
// Colors
IQColors.pink              // #FFCAE9
IQColors.pinkDark          // #c4458a
IQColors.lavender          // #CDD0F8
IQColors.lavenderDark      // #5057d5
IQColors.background        // #F5F4FF
IQColors.textPrimary       // #1a1a2e
IQColors.textSecondary     // Muted gray
IQColors.textMuted         // Light gray

// Fonts
IQFont.bold(18)            // Section headers
IQFont.semibold(16)        // Card titles
IQFont.regular(14)         // Body text
IQFont.regular(12)         // Secondary text
```

---

## 💡 Pro Tips

1. **Test in isolation first**
   - Create your SDK with a #Preview block
   - Test it works before integrating

2. **Keep original spacing**
   - Don't change the `VStack` spacing
   - Your SDK should just fill the container

3. **Responsive design**
   - Use `.frame(maxWidth: .infinity)`
   - Test on iPhone 12, 13, 14 sizes

4. **Dark mode**
   - Use colors from `IQColors`
   - They automatically adapt to system appearance

5. **Performance**
   - Avoid heavy state updates
   - Use `@ViewBuilder` for complex layouts
   - Cache computed properties if needed

---

**Ready to integrate?** Open `HomeView.swift` and find the SDK PLACEHOLDER sections. Paste your SDKs and build! 🚀
