import SwiftUI

// MARK: - Gut phase (home timelines)

enum HomeGutPhase: Int, CaseIterable {
    case empty, stable, mild, elevated, flare, recovery

    @MainActor
    static func forPastDay(_ date: Date, appVM: AppViewModel) -> HomeGutPhase {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let sy = appVM.symptoms.filter { cal.isDate($0.timestamp, inSameDayAs: dayStart) }
        if sy.isEmpty, appVM.foods.filter({ cal.isDate($0.timestamp, inSameDayAs: dayStart) }).isEmpty {
            return .empty
        }
        let maxS = sy.map(\.severity).max() ?? 0
        let blood = sy.contains { $0.type == .blood_in_stool && $0.severity >= 0.5 }
        if blood || maxS >= 8 { return .flare }
        if maxS >= 5 { return .elevated }
        if maxS >= 2.5 || sy.count >= 2 { return .mild }
        return .stable
    }

    static func fromMLRisk(_ r: Double) -> HomeGutPhase {
        if r < 0.28 { return .stable }
        if r < 0.42 { return .mild }
        if r < 0.58 { return .elevated }
        return .flare
    }

    func stripColor(isFuture: Bool) -> Color {
        let base: Color
        switch self {
        case .empty: base = IQColors.lavender.opacity(0.35)
        case .stable: base = IQColors.lavenderVivid
        case .mild: base = IQColors.blushVivid
        case .elevated: base = IQColors.pinkVivid
        case .flare: base = IQColors.pinkDark
        case .recovery: base = IQColors.lavenderDark
        }
        return isFuture ? base.opacity(0.38) : base
    }

    func gradientPair(isFuture: Bool) -> [Color] {
        let c = stripColor(isFuture: isFuture)
        return [c.opacity(isFuture ? 0.55 : 1), c.opacity(isFuture ? 0.28 : 0.72)]
    }
}

// MARK: - Dashboard data

enum HomeDashboardData {
    @MainActor
    static func consecutiveStableDays(appVM: AppViewModel) -> Int {
        let cal = Calendar.current
        var n = 0
        var d = cal.startOfDay(for: Date())
        while true {
            let p = HomeGutPhase.forPastDay(d, appVM: appVM)
            if p == .flare || p == .elevated { break }
            if p == .empty { break }
            if p == .stable {
                n += 1
            } else if p == .mild {
                let sy = appVM.symptoms.filter { cal.isDate($0.timestamp, inSameDayAs: d) }
                let maxS = sy.map(\.severity).max() ?? 0
                if maxS < 4 { n += 1 } else { break }
            } else {
                break
            }
            guard let prev = cal.date(byAdding: .day, value: -1, to: d) else { break }
            d = prev
            if n > 400 { break }
        }
        return n
    }

    @MainActor
    static func dayStrip(appVM: AppViewModel, pastCount: Int, futureCount: Int) -> [(date: Date, phase: HomeGutPhase, isFuture: Bool)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let safePast = max(0, pastCount)
        let safeFuture = max(0, futureCount)
        var out: [(Date, HomeGutPhase, Bool)] = []
        if safePast > 0 {
            for i in stride(from: -(safePast - 1), through: 0, by: 1) {
                let d = cal.date(byAdding: .day, value: i, to: today)!
                out.append((d, HomeGutPhase.forPastDay(d, appVM: appVM), false))
            }
        }
        // `1...0` traps — only loop when upper bound >= 1
        if safeFuture > 0 {
            for i in 1...safeFuture {
                let d = cal.date(byAdding: .day, value: i, to: today)!
                let r = appVM.onDevicePrediction(forDay: d)?.finalRisk ?? 0.35
                out.append((d, HomeGutPhase.fromMLRisk(r), true))
            }
        }
        return out
    }

    @MainActor
    static func twoWeekStrip(appVM: AppViewModel) -> [(date: Date, phase: HomeGutPhase, isFuture: Bool)] {
        dayStrip(appVM: appVM, pastCount: 14, futureCount: 0)
    }

    struct RiskDriver: Identifiable {
        var id: String { "\(label)-\(pct)" }
        let icon: String
        let label: String
        let pct: Int
    }

    @MainActor
    static func riskDrivers(from pred: OnDevicePrediction?) -> [RiskDriver] {
        guard let c = pred?.featureContributions else { return [] }
        let mapping: [String: (String, String)] = [
            "dairy": ("fork.knife", "Dairy"),
            "sleep": ("moon.zzz.fill", "Sleep"),
            "stress": ("brain.head.profile", "Stress"),
            "spicy_food": ("flame.fill", "Spicy food"),
            "pain": ("cross.case.fill", "Pain"),
            "fiber": ("leaf.fill", "Fiber"),
            "diarrhea": ("drop.fill", "Diarrhea"),
            "bloating": ("circle.dotted", "Bloating"),
            "fatigue": ("battery.25percent", "Fatigue")
        ]
        var rows: [RiskDriver] = []
        for (k, v) in c.sorted(by: { $0.value > $1.value }) {
            guard v > 0.08 else { continue }
            let key = k.lowercased()
            if let m = mapping[key] {
                rows.append(RiskDriver(icon: m.0, label: m.1, pct: min(99, Int(v * 100))))
            } else {
                let nice = key.replacingOccurrences(of: "_", with: " ").capitalized
                rows.append(RiskDriver(icon: "chart.bar.doc.horizontal", label: nice, pct: min(99, Int(v * 100))))
            }
        }
        return Array(rows.prefix(5))
    }

    @MainActor
    static func preventionAdvice(appVM: AppViewModel) -> String {
        let score = appVM.mlPrediction?.riskPercent ?? appVM.flareRisk.overallScore
        if score < 30 {
            return "Maintain your current diet and hydration. Keep logging so we can keep risk low."
        }
        if score < 60 {
            return "Avoid known triggers (especially dairy if flagged), prioritize rest, and keep meals regular."
        }
        return "Prioritize rest, hydration, and avoid high-fat or trigger foods today. Consider lighter meals."
    }

    @MainActor
    static func scenarioLine(appVM: AppViewModel) -> String {
        if let sim = appVM.runSimulate(changes: ["dairy": 0, "sleep_hours": 8, "stress": 3]) {
            let delta = sim.deltaPercent
            let dir = sim.isImprovement ? "drops" : "changes"
            return "Avoid dairy & improve sleep tonight → flare risk tomorrow \(dir) ~\(delta)%."
        }
        return "Avoid high-fat triggers today → model suggests a meaningful dip in tomorrow’s risk when you log consistently."
    }

    @MainActor
    static func personalizedInsights(appVM: AppViewModel) -> [String] {
        var out: [String] = []
        let risk = appVM.flareRisk
        if let pred = appVM.mlPrediction {
            for f in pred.riskFactors.prefix(2) { out.append(f) }
            let cont = pred.featureContributions
            if (cont["dairy"] ?? 0) >= 0.35 {
                out.append("Flares often cluster within 24–48h after dairy for people with your pattern — worth a trial skip.")
            }
            if (cont["sleep"] ?? 0) >= 0.4 {
                out.append("Low sleep shows up strongly in your model — nights under 6h correlate with most symptom spikes.")
            }
            if (cont["stress"] ?? 0) >= 0.38 {
                out.append("Stress is a top driver this week; short breathing breaks after meals may help.")
            }
        }
        if risk.trendScore > 12 {
            out.append("Your recent logs show an upward symptom trend — ease intensity for a few days.")
        }
        if out.isEmpty {
            out.append("Log meals and symptoms for a few more days to unlock sharper, personal insights.")
        }
        return Array(out.prefix(4))
    }
}

// MARK: - Connected strip (dots + bar)

struct HomeGutConnectedStrip: View {
    let days: [(date: Date, phase: HomeGutPhase, isFuture: Bool)]
    var dotSize: CGFloat = 12
    var barHeight: CGFloat = 5
    var onSelect: ((Date) -> Void)?

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let count = days.count
            let n = max(count, 1)
            let step = w / CGFloat(n)
            let segmentCount = max(0, count - 1)
            ZStack(alignment: .center) {
                ForEach(0..<segmentCount, id: \.self) { i in
                    let a = days[i]
                    let b = days[i + 1]
                    let left = step * (CGFloat(i) + 0.5)
                    let c1 = a.phase.stripColor(isFuture: a.isFuture)
                    let c2 = b.phase.stripColor(isFuture: b.isFuture)
                    Path { p in
                        p.move(to: CGPoint(x: left, y: geo.size.height / 2))
                        p.addLine(to: CGPoint(x: left + step, y: geo.size.height / 2))
                    }
                    .stroke(
                        LinearGradient(colors: [c1, c2], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: barHeight, lineCap: .round)
                    )
                    .opacity(0.92)
                }
                HStack(spacing: 0) {
                    ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                        Button {
                            onSelect?(day.date)
                        } label: {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: day.phase.gradientPair(isFuture: day.isFuture),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: dotSize, height: dotSize)
                                .overlay(Circle().stroke(Color.white.opacity(0.45), lineWidth: 1))
                                .shadow(color: day.phase.stripColor(isFuture: day.isFuture).opacity(0.5), radius: day.isFuture ? 2 : 5, y: 1)
                        }
                        .buttonStyle(.plain)
                        .frame(width: step, height: geo.size.height)
                    }
                }
            }
        }
        .frame(height: 36)
    }
}

// MARK: - Section views

struct HomeTodayGutStatusCard: View {
    @EnvironmentObject var appVM: AppViewModel
    var onViewDetails: () -> Void
    var onPickDay: (Date) -> Void

    private var strip: [(date: Date, phase: HomeGutPhase, isFuture: Bool)] {
        HomeDashboardData.dayStrip(appVM: appVM, pastCount: 7, futureCount: 3)
    }

    private var statusTitle: String {
        if let p = appVM.mlPrediction {
            return "\(p.riskLabel) Flare Risk"
        }
        return "\(appVM.flareRisk.level.label) Flare Risk"
    }

    private var stableLine: String {
        let n = HomeDashboardData.consecutiveStableDays(appVM: appVM)
        if n <= 0 { return "Log today to sharpen your gut timeline." }
        return "Your gut has been relatively calm for \(n) day\(n == 1 ? "" : "s")."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Today’s Gut Status")
                .font(.subheadline.bold())
                .foregroundColor(IQColors.textSecondary)

            Text(statusTitle)
                .font(.title2.bold())
                .foregroundColor(IQColors.textPrimary)

            Text(stableLine)
                .font(.caption)
                .foregroundColor(IQColors.textSecondary)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Past")
                        .font(.caption2.bold())
                        .foregroundColor(IQColors.textMuted.opacity(0.9))
                    Spacer()
                    Text("Forecast")
                        .font(.caption2.bold())
                        .foregroundColor(IQColors.textMuted.opacity(0.9))
                }
                HomeGutConnectedStrip(days: strip, dotSize: 11, barHeight: 4, onSelect: onPickDay)
            }

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onViewDetails()
            } label: {
                HStack {
                    Text("View Details")
                        .font(.subheadline.bold())
                    Image(systemName: "arrow.right")
                        .font(.caption.bold())
                }
                .foregroundColor(IQColors.lavenderDark)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .iqVibrantMaterialCard()
    }
}

struct HomeRiskDriversSection: View {
    let drivers: [HomeDashboardData.RiskDriver]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What’s Driving Your Risk")
                .font(.title3.bold())

            if drivers.isEmpty {
                Text("Log food and symptoms — we’ll rank sleep, stress, and triggers here.")
                    .font(.caption)
                    .foregroundColor(IQColors.textSecondary)
            } else {
                ForEach(drivers) { d in
                    HStack(spacing: 12) {
                        Image(systemName: d.icon)
                            .font(.body)
                            .foregroundColor(IQColors.lavenderDark)
                            .frame(width: 28, alignment: .center)
                        Text(d.label)
                            .font(.subheadline.bold())
                        Spacer()
                        Text("+\(d.pct)%")
                            .font(.subheadline.bold())
                            .foregroundColor(IQColors.pinkDark)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(16)
        .iqVibrantMaterialCard()
    }
}

struct HomePreventionCard: View {
    let advice: String
    var onSeePlan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today’s Recommendation")
                .font(.title3.bold())
            Text(advice)
                .font(.subheadline)
                .foregroundColor(IQColors.textSecondary)
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onSeePlan()
            } label: {
                Text("See Prevention Plan")
                    .font(.subheadline.bold())
                    .foregroundColor(IQColors.pinkDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(IQColors.pink.opacity(0.42))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(IQColors.pinkVivid.opacity(0.38), lineWidth: 1)
                    )
                    .shadow(color: IQColors.pinkVivid.opacity(0.2), radius: 12, x: 0, y: 4)
            }
            .buttonStyle(PreventionPlanTapStyle())
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(IQColors.pink.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: IQColors.pinkVivid.opacity(0.12), radius: 16, x: 0, y: 5)
    }
}

private struct PreventionPlanTapStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .shadow(
                color: IQColors.pinkVivid.opacity(configuration.isPressed ? 0.28 : 0.18),
                radius: configuration.isPressed ? 16 : 12,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct HomeGutTimelineSection: View {
    @EnvironmentObject var appVM: AppViewModel
    var onPickDay: (Date) -> Void

    private var days: [(date: Date, phase: HomeGutPhase, isFuture: Bool)] {
        HomeDashboardData.twoWeekStrip(appVM: appVM)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Gut Activity")
                .font(.title3.bold())
            Text("Last 14 days · tap a day")
                .font(.caption)
                .foregroundColor(IQColors.textMuted.opacity(0.9))
            HomeGutConnectedStrip(days: days, dotSize: 13, barHeight: 5, onSelect: onPickDay)
                .frame(height: 40)
        }
        .padding(16)
        .iqVibrantMaterialCard()
    }
}

struct HomeSmartInsightsSection: View {
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights From Your Data")
                .font(.title3.bold())
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(IQColors.lavenderDark)
                    Text(line)
                        .font(.subheadline)
                        .foregroundColor(IQColors.textPrimary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .iqVibrantMaterialCard(cornerRadius: 12)
            }
        }
    }
}

struct HomeScenarioCard: View {
    let line: String
    var onTry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What If…")
                .font(.title3.bold())
            Text(line)
                .font(.subheadline)
                .foregroundColor(IQColors.textSecondary)
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onTry()
            } label: {
                Text("Try Scenario")
                    .font(.subheadline.bold())
                    .foregroundColor(IQColors.lavenderDark)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .iqVibrantMaterialCard()
    }
}

struct HomeLearnMoreRow: View {
    var onOpenContent: () -> Void

    private let cards: [(String, String)] = [
        ("Best foods for gut recovery", "leaf.fill"),
        ("How stress affects Crohn’s", "brain.head.profile")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Learn More")
                .font(.title3.bold())
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(cards.enumerated()), id: \.offset) { _, c in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onOpenContent()
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: c.1)
                                    .foregroundColor(IQColors.lavenderDark)
                                Text(c.0)
                                    .font(.subheadline.bold())
                                    .foregroundColor(IQColors.textPrimary)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(14)
                            .frame(width: 200, alignment: .leading)
                            .iqVibrantMaterialCard(cornerRadius: 14)
                        }
                        .buttonStyle(CardPressStyle())
                    }
                }
            }
        }
    }
}

struct HomeLogQuickSection: View {
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Log Today")
                .font(.title3.bold())

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                logChip(title: "Add Food", icon: "fork.knife", emphasized: true) { appVM.selectTab(.symptoms) }
                logChip(title: "Add Symptom", icon: "waveform.path.ecg", emphasized: true) { appVM.selectTab(.symptoms) }
                logChip(title: "Add BM", icon: "drop.circle.fill", emphasized: false) { appVM.selectTab(.symptoms) }
                logChip(title: "Add Stress", icon: "wind", emphasized: false) { appVM.selectTab(.symptoms) }
            }

            Text("Opens Log — pick Symptoms or Food to record.")
                .font(.caption2)
                .foregroundColor(IQColors.textMuted.opacity(0.9))
        }
        .padding(16)
        .iqVibrantMaterialCard()
    }

    private func logChip(title: String, icon: String, emphasized: Bool, action: @escaping () -> Void) -> some View {
        Group {
            if emphasized {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    action()
                } label: {
                    logChipLabel(title: title, icon: icon, emphasized: true)
                }
                .buttonStyle(LogChipInteractiveStyle())
            } else {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    action()
                } label: {
                    logChipLabel(title: title, icon: icon, emphasized: false)
                }
                .buttonStyle(CardPressStyle())
            }
        }
    }

    private func logChipLabel(title: String, icon: String, emphasized: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
            Text(title)
                .font(.caption.bold())
        }
        .foregroundColor(IQColors.pinkDark)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(emphasized ? IQColors.pinkVivid.opacity(0.22) : IQColors.pink.opacity(0.32))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(emphasized ? IQColors.pinkVivid.opacity(0.5) : IQColors.pink.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: emphasized ? IQColors.pinkVivid.opacity(0.26) : IQColors.pink.opacity(0.12), radius: emphasized ? 14 : 6, x: 0, y: 3)
    }
}

/// Tap feedback for primary log actions (scale + pink glow).
private struct LogChipInteractiveStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .shadow(
                color: IQColors.pinkVivid.opacity(configuration.isPressed ? 0.35 : 0.2),
                radius: configuration.isPressed ? 16 : 10,
                x: 0,
                y: configuration.isPressed ? 2 : 3
            )
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct HomeQuoteCard: View {
    @State private var appeared = false
    @State private var floatY: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            (Text("Don’t watch the clock; do what it does. ")
                .font(.body)
                .italic()
                .foregroundColor(IQColors.textPrimary)
            + Text("Keep going.")
                .font(.body)
                .italic()
                .fontWeight(.semibold)
                .foregroundColor(IQColors.pinkDark))
                .opacity(appeared ? 1 : 0)

            Text("— Sam Levenson")
                .font(.caption)
                .foregroundColor(IQColors.textMuted.opacity(0.9))
                .opacity(appeared ? 1 : 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(IQColors.blush.opacity(0.35))
        )
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(IQColors.pink.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        .shadow(color: IQColors.pinkVivid.opacity(0.12), radius: 20, x: 0, y: 0)
        .offset(y: floatY)
        .onAppear {
            withAnimation(.easeOut(duration: 0.9)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                floatY = -3
            }
        }
    }
}

struct HomeFloatingLogFAB: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var open = false
    @State private var pulse: CGFloat = 1

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            if open {
                fabAction("Log Food", "fork.knife") {
                    appVM.selectTab(.symptoms)
                    open = false
                }
                fabAction("Log Symptom", "waveform.path.ecg") {
                    appVM.selectTab(.symptoms)
                    open = false
                }
                fabAction("Log Flare", "flame.fill") {
                    appVM.selectTab(.symptoms)
                    open = false
                }
                fabAction("Log Medication", "pills.fill") {
                    appVM.selectTab(.symptoms)
                    open = false
                }
            }
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    open.toggle()
                }
            } label: {
                Image(systemName: open ? "xmark" : "plus")
                    .font(.title2.bold())
                    .foregroundColor(IQColors.pinkDark)
                    .frame(width: 58, height: 58)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(IQColors.pink.opacity(0.85), lineWidth: 1.5))
                    .background(
                        Circle()
                            .fill(IQColors.pink.opacity(0.55))
                            .blur(radius: 14)
                            .scaleEffect(pulse)
                    )
                    .shadow(color: IQColors.pinkVivid.opacity(0.35), radius: open ? 6 : 14, y: 4)
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulse = 1.12
            }
        }
    }

    private func fabAction(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .font(.caption.bold())
            }
            .foregroundColor(IQColors.pinkDark)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(IQColors.pink.opacity(0.6), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }
}

// MARK: - Day detail sheet

struct HomeDayDetailSheet: View {
    @EnvironmentObject var appVM: AppViewModel
    let date: Date
    @Environment(\.dismiss) private var dismiss

    private var riskPct: Int {
        appVM.onDevicePrediction(forDay: date)?.riskPercent ?? appVM.flareRisk.overallScore
    }

    private var causes: [String] {
        if let p = appVM.onDevicePrediction(forDay: date) {
            return Array(p.riskFactors.prefix(4))
        }
        let cal = Calendar.current
        let sy = appVM.symptoms.filter { cal.isDate($0.timestamp, inSameDayAs: date) }
        if sy.isEmpty { return ["No symptoms logged this day"] }
        return sy.map { "\($0.type.label) (\(Int($0.severity))/10)" }.prefix(4).map { String($0) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Flare risk") {
                    Text("\(riskPct)%")
                        .font(.title2.bold())
                }
                Section("Likely causes") {
                    ForEach(causes, id: \.self) { c in
                        Text(c)
                    }
                }
            }
            .navigationTitle(date.formatted(date: .abbreviated, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
