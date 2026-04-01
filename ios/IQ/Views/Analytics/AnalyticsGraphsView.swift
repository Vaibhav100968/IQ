import SwiftUI
import Charts

// TODO: CONNECT GRAPH DATA FROM ML / ANALYTICS SDK HERE
// Replace mock/computed data with real analytics data
// Example: import AnalyticsSDK

// ── GraphTag — identifies each graph type in the analytics pager ─────────────
enum GraphTag: String, CaseIterable, Identifiable {
    case symptomTrend, flareRisk, features, triggers, foodSymptom
    case calendarRisk, symptomDist, whatIf, personalization, flareDist
    var id: String { rawValue }

    var label: String {
        switch self {
        case .symptomTrend:    return "Trends"
        case .flareRisk:       return "Risk"
        case .features:        return "Features"
        case .triggers:        return "Triggers"
        case .foodSymptom:     return "Diet"
        case .calendarRisk:    return "Heatmap"
        case .symptomDist:     return "Distribution"
        case .whatIf:          return "What-If"
        case .personalization: return "Personal"
        case .flareDist:       return "Probability"
        }
    }

    var icon: String {
        switch self {
        case .symptomTrend:    return "chart.xyaxis.line"
        case .flareRisk:       return "exclamationmark.triangle"
        case .features:        return "chart.bar"
        case .triggers:        return "flame"
        case .foodSymptom:     return "fork.knife"
        case .calendarRisk:    return "calendar"
        case .symptomDist:     return "chart.pie"
        case .whatIf:          return "slider.horizontal.3"
        case .personalization: return "person.fill.checkmark"
        case .flareDist:       return "chart.bar.xaxis"
        }
    }
}

// ── AnalyticsGraphsView — swipeable graph pager with synced tab bar ──────────
struct AnalyticsGraphsView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var selected: GraphTag = .symptomTrend

    var body: some View {
        VStack(spacing: 14) {
            graphTabBar
            graphPager
            InsightExplanationView(activeGraph: selected)
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Tab Bar (synced with swipe)

    private var graphTabBar: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(GraphTag.allCases) { tag in
                        tagButton(tag)
                            .id(tag)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onChange(of: selected) { newTag in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    proxy.scrollTo(newTag, anchor: .center)
                }
            }
        }
    }

    private func tagButton(_ tag: GraphTag) -> some View {
        let isSelected = selected == tag
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selected = tag
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: tag.icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(tag.label)
                    .font(IQFont.semibold(11))
            }
            .foregroundColor(isSelected ? .white : IQColors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(
                    isSelected
                    ? AnyShapeStyle(IQColors.pink)
                    : AnyShapeStyle(Color.white)
                )
            )
            .overlay(Capsule().stroke(isSelected ? Color.clear : IQColors.border, lineWidth: 0.5))
            .shadow(color: isSelected ? IQColors.pinkDark.opacity(0.2) : .clear, radius: 4, y: 2)
        }
    }

    // MARK: - Swipeable Graph Pager

    private var graphPager: some View {
        TabView(selection: $selected) {
            ForEach(GraphTag.allCases) { tag in
                graphPage(for: tag)
                    .tag(tag)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 320)
    }

    @ViewBuilder
    private func graphPage(for tag: GraphTag) -> some View {
        if #available(iOS 16, *) {
            graphContent(for: tag)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(16)
                .background(cardBg)
                .padding(.horizontal, 16)
        } else {
            Text("Charts require iOS 16+")
                .font(IQFont.regular(12))
                .foregroundColor(IQColors.textMuted)
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(cardBg)
                .padding(.horizontal, 16)
        }
    }

    @available(iOS 16, *)
    @ViewBuilder
    private func graphContent(for tag: GraphTag) -> some View {
        switch tag {
        case .symptomTrend:    symptomTrendGraph
        case .flareRisk:       flareRiskGraph
        case .features:        featureContributionGraph
        case .triggers:        triggerCorrelationGraph
        case .foodSymptom:     foodSymptomOverlay
        case .calendarRisk:    calendarRiskHeatmap
        case .symptomDist:     symptomDistribution
        case .whatIf:          whatIfGraph
        case .personalization: personalizationCurve
        case .flareDist:       flareDistribution
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // 1. SYMPTOM TREND
    // ═══════════════════════════════════════════════════════════════════
    @available(iOS 16, *)
    private var symptomTrendGraph: some View {
        let data = symptomTrendData
        return VStack(alignment: .leading, spacing: 8) {
            Text("Symptom Trend (7 days)").font(IQFont.semibold(13)).foregroundColor(IQColors.textSecondary)
            Text("Daily severity for pain, diarrhea, fatigue").font(IQFont.regular(11)).foregroundColor(IQColors.textMuted)
            Chart(data, id: \.id) { pt in
                LineMark(x: .value("Day", pt.day), y: .value("Severity", pt.severity))
                    .foregroundStyle(by: .value("Type", pt.type))
                PointMark(x: .value("Day", pt.day), y: .value("Severity", pt.severity))
                    .foregroundStyle(by: .value("Type", pt.type))
                    .symbolSize(20)
            }
            .chartForegroundStyleScale(["Pain": IQColors.pink, "Diarrhea": IQColors.lavender, "Fatigue": IQColors.blush])
            .chartYScale(domain: 0...10)
            .chartLegend(position: .bottom, spacing: 12)
            .frame(height: 180)
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // 2. FLARE RISK OVER TIME
    // ═══════════════════════════════════════════════════════════════════
    @available(iOS 16, *)
    private var flareRiskGraph: some View {
        let data = riskOverTimeData
        return VStack(alignment: .leading, spacing: 8) {
            Text("Flare Risk Over Time").font(IQFont.semibold(13)).foregroundColor(IQColors.textSecondary)
            Chart {
                RectangleMark(yStart: .value("", 0), yEnd: .value("", 30))
                    .foregroundStyle(Color.green.opacity(0.08))
                RectangleMark(yStart: .value("", 30), yEnd: .value("", 70))
                    .foregroundStyle(Color.orange.opacity(0.08))
                RectangleMark(yStart: .value("", 70), yEnd: .value("", 100))
                    .foregroundStyle(Color.red.opacity(0.08))
                ForEach(data, id: \.0) { pt in
                    LineMark(x: .value("Day", pt.0), y: .value("Risk", pt.1))
                        .foregroundStyle(IQColors.pinkDark)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    AreaMark(x: .value("Day", pt.0), y: .value("Risk", pt.1))
                        .foregroundStyle(IQColors.pink.opacity(0.15))
                    PointMark(x: .value("Day", pt.0), y: .value("Risk", pt.1))
                        .foregroundStyle(riskColor(pt.1))
                        .symbolSize(24)
                }
            }
            .chartYScale(domain: 0...100)
            .frame(height: 180)
            HStack(spacing: 16) {
                zoneLegend(color: .green, label: "Low")
                zoneLegend(color: .orange, label: "Moderate")
                zoneLegend(color: .red, label: "High")
            }
            .font(IQFont.regular(10))
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // 3. FEATURE CONTRIBUTION BARS
    // ═══════════════════════════════════════════════════════════════════
    @available(iOS 16, *)
    private var featureContributionGraph: some View {
        let contribs = appVM.mlPrediction?.featureContributions ?? sampleContributions
        let sorted = contribs.sorted { $0.value > $1.value }.prefix(8)
        let labels: [String: String] = ["pain": "Pain", "stress": "Stress", "diarrhea": "Diarrhea", "sleep": "Sleep", "recency": "Recency", "dairy": "Dairy", "spicy_food": "Spicy"]

        return VStack(alignment: .leading, spacing: 8) {
            Text("Feature Contributions").font(IQFont.semibold(13)).foregroundColor(IQColors.textSecondary)
            Text("How each factor affects your risk").font(IQFont.regular(11)).foregroundColor(IQColors.textMuted)
            Chart(sorted, id: \.key) { item in
                BarMark(
                    x: .value("Contribution", item.value),
                    y: .value("Feature", labels[item.key] ?? item.key.capitalized)
                )
                .foregroundStyle(
                    item.value >= 0.55 ? IQColors.pink :
                    item.value >= 0.35 ? IQColors.blush : IQColors.lavender
                )
                .cornerRadius(4)
            }
            .chartXScale(domain: 0...1)
            .frame(height: 200)
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // 4. TRIGGER CORRELATION
    // ═══════════════════════════════════════════════════════════════════
    @available(iOS 16, *)
    private var triggerCorrelationGraph: some View {
        let data = triggerCorrelationData
        return VStack(alignment: .leading, spacing: 8) {
            Text("Trigger Correlation").font(IQFont.semibold(13)).foregroundColor(IQColors.textSecondary)
            Text("Average symptom severity after each trigger").font(IQFont.regular(11)).foregroundColor(IQColors.textMuted)
            Chart(data, id: \.0) { pt in
                BarMark(x: .value("Trigger", pt.0), y: .value("Avg Severity", pt.1))
                    .foregroundStyle(IQColors.lavender)
                    .cornerRadius(6)
            }
            .chartYScale(domain: 0...10)
            .frame(height: 180)
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // 5. FOOD vs SYMPTOM TIMELINE OVERLAY
    // ═══════════════════════════════════════════════════════════════════
    @available(iOS 16, *)
    private var foodSymptomOverlay: some View {
        let data = foodSymptomTimelineData
        return VStack(alignment: .leading, spacing: 8) {
            Text("Food vs Symptom Timeline").font(IQFont.semibold(13)).foregroundColor(IQColors.textSecondary)
            Text("Symptom severity vs trigger exposure").font(IQFont.regular(11)).foregroundColor(IQColors.textMuted)
            Chart {
                ForEach(data, id: \.day) { pt in
                    LineMark(x: .value("Day", pt.day), y: .value("Severity", pt.symptom))
                        .foregroundStyle(IQColors.pinkDark)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                    if pt.trigger > 0 {
                        BarMark(x: .value("Day", pt.day), y: .value("Trigger", pt.trigger * 2))
                            .foregroundStyle(IQColors.lavenderDark.opacity(0.3))
                    }
                }
            }
            .chartYScale(domain: 0...10)
            .frame(height: 180)
            HStack(spacing: 16) {
                zoneLegend(color: IQColors.pinkDark, label: "Symptoms")
                zoneLegend(color: IQColors.lavenderDark, label: "Triggers")
            }
            .font(IQFont.regular(10))
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // 6. CALENDAR RISK HEATMAP
    // ═══════════════════════════════════════════════════════════════════
    @available(iOS 16, *)
    private var calendarRiskHeatmap: some View {
        let cal = Calendar.current
        let days = (0..<28).reversed().map { cal.date(byAdding: .day, value: -$0, to: Date())! }
        let cols = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)

        return VStack(alignment: .leading, spacing: 8) {
            Text("4-Week Risk Calendar").font(IQFont.semibold(13)).foregroundColor(IQColors.textSecondary)
            LazyVGrid(columns: cols, spacing: 3) {
                ForEach(days, id: \.self) { date in
                    let count = appVM.logCountForDate(date)
                    let intensity = min(Double(count) / 5.0, 1.0)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(intensity > 0 ? IQColors.pinkDark.opacity(0.2 + intensity * 0.6) : IQColors.border.opacity(0.3))
                        .frame(height: 28)
                        .overlay(
                            Text("\(cal.component(.day, from: date))")
                                .font(.system(size: 8, weight: count > 0 ? .bold : .regular))
                                .foregroundColor(count > 0 ? IQColors.pinkDark : IQColors.textMuted)
                        )
                }
            }
            HStack(spacing: 8) {
                Text("Less").font(.system(size: 9)).foregroundColor(IQColors.textMuted)
                ForEach([0.1, 0.3, 0.5, 0.8], id: \.self) { v in
                    RoundedRectangle(cornerRadius: 2).fill(IQColors.pinkDark.opacity(v)).frame(width: 12, height: 12)
                }
                Text("More").font(.system(size: 9)).foregroundColor(IQColors.textMuted)
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // 7. SYMPTOM DISTRIBUTION
    // ═══════════════════════════════════════════════════════════════════
    @available(iOS 16, *)
    private var symptomDistribution: some View {
        let dist = symptomDistData
        let total = dist.map(\.1).reduce(0, +)

        return VStack(alignment: .leading, spacing: 8) {
            Text("Symptom Distribution (7 days)").font(IQFont.semibold(13)).foregroundColor(IQColors.textSecondary)
            HStack(spacing: 20) {
                ZStack {
                    ForEach(donutSlices(dist), id: \.label) { slice in
                        DonutSlice(startAngle: slice.start, endAngle: slice.end)
                            .fill(slice.color)
                    }
                    Circle().fill(Color.white).padding(22)
                    Text("\(total)")
                        .font(IQFont.black(20))
                        .foregroundColor(IQColors.textPrimary)
                }
                .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 5) {
                    ForEach(dist.prefix(5), id: \.0) { item in
                        HStack(spacing: 6) {
                            Circle().fill(symptomColor(item.0)).frame(width: 8, height: 8)
                            Text(item.0).font(IQFont.regular(11)).foregroundColor(IQColors.textPrimary)
                            Spacer()
                            Text("\(item.1)").font(IQFont.semibold(11)).foregroundColor(IQColors.textSecondary)
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // 8. WHAT-IF SIMULATION GRAPH
    // ═══════════════════════════════════════════════════════════════════
    @available(iOS 16, *)
    private var whatIfGraph: some View {
        let current = appVM.mlPrediction?.finalRisk ?? Double(appVM.flareRisk.overallScore) / 100
        let scenarios: [(String, Double)] = [
            ("Current", current),
            ("+Sleep", max(0, current - 0.12)),
            ("-Stress", max(0, current - 0.15)),
            ("No Dairy", max(0, current - 0.08)),
            ("All 3", max(0, current - 0.27)),
        ]

        return VStack(alignment: .leading, spacing: 8) {
            Text("What-If Scenarios").font(IQFont.semibold(13)).foregroundColor(IQColors.textSecondary)
            Text("Estimated risk reduction with lifestyle changes").font(IQFont.regular(11)).foregroundColor(IQColors.textMuted)
            Chart(scenarios, id: \.0) { s in
                BarMark(x: .value("Scenario", s.0), y: .value("Risk", s.1 * 100))
                    .foregroundStyle(s.0 == "Current" ? IQColors.pinkDark : IQColors.lavenderDark)
                    .cornerRadius(6)
                    .annotation(position: .top) {
                        Text("\(Int(s.1 * 100))%")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(IQColors.textSecondary)
                    }
            }
            .chartYScale(domain: 0...100)
            .frame(height: 180)
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // 9. PERSONALIZATION CURVE
    // ═══════════════════════════════════════════════════════════════════
    @available(iOS 16, *)
    private var personalizationCurve: some View {
        let points: [(Int, Double)] = (0...30).map { day in
            let weight: Double
            if day < 5 { weight = 0 }
            else if day >= 30 { weight = 1.0 }
            else { weight = Double(day - 5) / 25.0 }
            return (day, weight)
        }
        let logged = appVM.mlPrediction?.daysLogged ?? appVM.symptoms.count / 3

        return VStack(alignment: .leading, spacing: 8) {
            Text("Personalization Progress").font(IQFont.semibold(13)).foregroundColor(IQColors.textSecondary)
            Text("Model confidence increases with more logged data").font(IQFont.regular(11)).foregroundColor(IQColors.textMuted)
            Chart {
                ForEach(points, id: \.0) { pt in
                    LineMark(x: .value("Days", pt.0), y: .value("Weight", pt.1))
                        .foregroundStyle(IQColors.lavenderDark)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    AreaMark(x: .value("Days", pt.0), y: .value("Weight", pt.1))
                        .foregroundStyle(IQColors.lavender.opacity(0.2))
                }
                RuleMark(x: .value("You", min(logged, 30)))
                    .foregroundStyle(IQColors.pinkDark)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    .annotation(position: .top) {
                        Text("You: \(logged)d")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(IQColors.pinkDark)
                    }
            }
            .chartYScale(domain: 0...1)
            .frame(height: 160)
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // 10. FLARE PROBABILITY DISTRIBUTION
    // ═══════════════════════════════════════════════════════════════════
    @available(iOS 16, *)
    private var flareDistribution: some View {
        let bins: [(String, Int)] = [
            ("0-10%", 3), ("10-20%", 5), ("20-30%", 8), ("30-40%", 12),
            ("40-50%", 10), ("50-60%", 7), ("60-70%", 4), ("70-80%", 2),
            ("80-90%", 1), ("90-100%", 0),
        ]

        return VStack(alignment: .leading, spacing: 8) {
            Text("Flare Risk Distribution").font(IQFont.semibold(13)).foregroundColor(IQColors.textSecondary)
            Text("How often each risk level occurs over time").font(IQFont.regular(11)).foregroundColor(IQColors.textMuted)
            Chart(bins, id: \.0) { bin in
                BarMark(x: .value("Range", bin.0), y: .value("Days", bin.1))
                    .foregroundStyle(IQColors.blush)
                    .cornerRadius(4)
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks { val in
                    AxisValueLabel {
                        if let s = val.as(String.self) {
                            Text(s).font(.system(size: 7)).rotationEffect(.degrees(-45))
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // DATA COMPUTATION HELPERS
    // ═══════════════════════════════════════════════════════════════════

    private struct SympTrendPt: Identifiable { let id = UUID(); let day: String; let severity: Double; let type: String }

    private var symptomTrendData: [SympTrendPt] {
        let cal = Calendar.current
        let types: [(SymptomType, String)] = [(.abdominal_pain, "Pain"), (.diarrhea, "Diarrhea"), (.fatigue, "Fatigue")]
        var pts: [SympTrendPt] = []
        for offset in (0..<7).reversed() {
            let date = cal.date(byAdding: .day, value: -offset, to: Date())!
            let label = offset == 0 ? "Today" : date.formatted(.dateTime.weekday(.abbreviated))
            for (sType, sLabel) in types {
                let dayEntries = appVM.symptoms.filter { cal.isDate($0.timestamp, inSameDayAs: date) && $0.type == sType }
                let avg = dayEntries.isEmpty ? 0 : dayEntries.map(\.severity).reduce(0,+) / Double(dayEntries.count)
                pts.append(SympTrendPt(day: label, severity: avg, type: sLabel))
            }
        }
        return pts
    }

    private var riskOverTimeData: [(String, Double)] {
        let cal = Calendar.current
        return (0..<7).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: Date())!
            let label = offset == 0 ? "Today" : date.formatted(.dateTime.weekday(.abbreviated))
            let count = appVM.logCountForDate(date)
            let risk = Double(min(count * 12 + appVM.flareRisk.overallScore / 3, 100))
            return (label, risk)
        }
    }

    private var triggerCorrelationData: [(String, Double)] {
        let triggers: [FoodTag] = [.dairy, .spicy, .gluten, .fried, .caffeine]
        return triggers.map { tag in
            let meals = appVM.foods.filter { $0.tags.contains(tag) }
            if meals.isEmpty { return (tag.label, 0.0) }
            let avg = meals.count > 0 ? Double(meals.count) * 1.2 + 2.0 : 0
            return (tag.label, min(avg, 10))
        }
    }

    private struct FoodSymPt { let day: String; let symptom: Double; let trigger: Double }

    private var foodSymptomTimelineData: [FoodSymPt] {
        let cal = Calendar.current
        return (0..<7).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: Date())!
            let label = offset == 0 ? "Today" : date.formatted(.dateTime.weekday(.abbreviated))
            let dayS = appVM.symptoms.filter { cal.isDate($0.timestamp, inSameDayAs: date) }
            let avgS = dayS.isEmpty ? 0 : dayS.map(\.severity).reduce(0,+) / Double(dayS.count)
            let dayF = appVM.foods.filter { cal.isDate($0.timestamp, inSameDayAs: date) }
            let trig = dayF.flatMap(\.tags).filter(\.isTrigger).count
            return FoodSymPt(day: label, symptom: avgS, trigger: Double(trig))
        }
    }

    private var symptomDistData: [(String, Int)] {
        let (start, _) = last7()
        let recent = appVM.symptoms.filter { $0.timestamp >= start }
        let grouped = Dictionary(grouping: recent, by: \.type)
        return grouped.map { ($0.key.label, $0.value.count) }.sorted { $0.1 > $1.1 }
    }

    private var sampleContributions: [String: Double] {
        ["pain": 0.72, "stress": 0.58, "diarrhea": 0.45, "sleep": 0.32, "dairy": 0.28, "recency": 0.65]
    }

    private func last7() -> (Date, Date) {
        (Calendar.current.date(byAdding: .day, value: -7, to: Date())!, Date())
    }

    // ── Styling helpers
    private var cardBg: some View {
        RoundedRectangle(cornerRadius: 16).fill(Color.white)
            .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    private func riskColor(_ risk: Double) -> Color {
        if risk < 30 { return .green }
        if risk < 70 { return .orange }
        return .red
    }

    private func zoneLegend(color: Color, label: String) -> some View {
        HStack(spacing: 4) { Circle().fill(color).frame(width: 6, height: 6); Text(label) }
    }

    private func symptomColor(_ label: String) -> Color {
        switch label {
        case "Abdominal Pain": return IQColors.pink
        case "Diarrhea":       return IQColors.lavender
        case "Fatigue":        return IQColors.blush
        case "Bloating":       return IQColors.lavender.opacity(0.6)
        case "Nausea":         return IQColors.pink.opacity(0.6)
        default:               return IQColors.textMuted
        }
    }

    // ── Donut helpers
    private struct DonutSliceData { let label: String; let start: Angle; let end: Angle; let color: Color }

    private func donutSlices(_ data: [(String, Int)]) -> [DonutSliceData] {
        let total = Double(data.map(\.1).reduce(0, +))
        guard total > 0 else { return [] }
        var angle = Angle.degrees(-90)
        return data.map { item in
            let sweep = Angle.degrees(Double(item.1) / total * 360)
            let slice = DonutSliceData(label: item.0, start: angle, end: angle + sweep, color: symptomColor(item.0))
            angle = angle + sweep
            return slice
        }
    }
}

// ── Custom donut slice shape
struct DonutSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.6
        p.addArc(center: center, radius: outer, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        p.addArc(center: center, radius: inner, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        p.closeSubpath()
        return p
    }
}
