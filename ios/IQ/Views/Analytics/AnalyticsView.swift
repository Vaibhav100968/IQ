import SwiftUI
import Charts

// ── AnalyticsView — Task 8: Gut Intelligence with tag-navigated graphs ─────────
struct AnalyticsView: View {
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                // ── Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gut Intelligence")
                            .font(IQFont.black(22))
                            .foregroundColor(IQColors.textPrimary)
                        Text("AI-powered health analytics")
                            .font(IQFont.regular(13))
                            .foregroundColor(IQColors.textSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)

                // ── ML Intelligence section (AI risk score + personalization)
                MLInsightsSection()

                // ── Interactive Graphs — tag-navigated (Task 8)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(IQColors.lavenderDark)
                        Text("Interactive Analytics")
                            .font(IQFont.bold(16))
                            .foregroundColor(IQColors.textPrimary)
                    }
                    .padding(.horizontal, 16)

                    Text("Tap a tag to explore different views of your health data")
                        .font(IQFont.regular(11))
                        .foregroundColor(IQColors.textMuted)
                        .padding(.horizontal, 16)

                    AnalyticsGraphsView()
                }

                // ── Divider
                HStack {
                    Text("Summary")
                        .font(IQFont.semibold(11))
                        .foregroundColor(IQColors.textMuted)
                    Rectangle().fill(IQColors.border).frame(height: 1)
                }
                .padding(.horizontal, 16)

                // ── Risk score card
                riskCard

                // ── Score breakdown
                scoreBreakdown

                // ── 7-day symptom trend chart
                symptomTrendChart

                // ── Top symptoms
                topSymptoms

                // ── Top trigger foods
                triggerFoods

                Spacer(minLength: 32)
            }
            .padding(.top, 16)
        }
        .background(Color.clear)
    }

    // ── Overall risk card
    private var riskCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Current Flare Risk")
                    .font(IQFont.semibold(14))
                    .foregroundColor(IQColors.textSecondary)
                Spacer()
                riskBadge
            }

            HStack(alignment: .bottom, spacing: 4) {
                Text("\(appVM.flareRisk.overallScore)")
                    .font(IQFont.black(48))
                    .foregroundColor(IQColors.textPrimary)
                Text("%")
                    .font(IQFont.bold(20))
                    .foregroundColor(IQColors.textSecondary)
                    .padding(.bottom, 8)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(IQColors.border).frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(IQColors.pinkVivid)
                        .frame(width: geo.size.width * CGFloat(appVM.flareRisk.overallScore) / 100, height: 10)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: appVM.flareRisk.overallScore)
                }
            }
            .frame(height: 10)

            Text(appVM.flareRisk.explanation)
                .font(IQFont.regular(12))
                .foregroundColor(IQColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            RiskScoreFootnote(style: .analyticsRuleBased)
        }
        .padding(16)
        .iqVibrantMaterialCard()
        .padding(.horizontal, 16)
    }

    private var riskBadge: some View {
        Text(appVM.flareRisk.level.label)
            .font(IQFont.semibold(11))
            .foregroundColor(.white)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Capsule().fill(riskCapsuleFill))
    }

    private var riskCapsuleFill: Color {
        switch appVM.flareRisk.level {
        case .low: return IQColors.lavenderDark
        case .moderate: return IQColors.pinkVivid
        case .high: return IQColors.pinkDark
        }
    }

    // ── Score breakdown bars
    private var scoreBreakdown: some View {
        let r = appVM.flareRisk
        return VStack(alignment: .leading, spacing: 12) {
            Text("Score Breakdown").font(IQFont.semibold(13)).foregroundColor(IQColors.textSecondary)
            breakdownRow(label: "Symptom Severity",  value: r.symptomScore, max: 35)
            breakdownRow(label: "Trigger Foods",     value: r.triggerScore,  max: 25)
            breakdownRow(label: "7-Day Trend",       value: r.trendScore,    max: 20)
            breakdownRow(label: "Historical Pattern", value: r.patternScore, max: 10)
        }
        .padding(16)
        .iqVibrantMaterialCard()
        .padding(.horizontal, 16)
    }

    private func breakdownRow(label: String, value: Int, max: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(IQFont.medium(13)).foregroundColor(IQColors.textPrimary)
                Spacer()
                Text("\(value)/\(max)").font(IQFont.semibold(12)).foregroundColor(IQColors.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(IQColors.border).frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(IQColors.lavenderVivid)
                        .frame(width: geo.size.width * CGFloat(value) / CGFloat(max), height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: value)
                }
            }
            .frame(height: 8)
        }
    }

    // ── 7-day symptom trend
    private var symptomTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("7-Day Symptom Trend").font(IQFont.semibold(13)).foregroundColor(IQColors.textSecondary)
            if #available(iOS 16, *) {
                Chart {
                    ForEach(sevenDayData, id: \.0) { point in
                        LineMark(x: .value("Day", point.0), y: .value("Avg", point.1))
                            .foregroundStyle(IQColors.pinkVivid)
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        AreaMark(x: .value("Day", point.0), y: .value("Avg", point.1))
                            .foregroundStyle(IQColors.pinkVivid.opacity(0.22))
                        PointMark(x: .value("Day", point.0), y: .value("Avg", point.1))
                            .foregroundStyle(IQColors.pinkVivid).symbolSize(30)
                    }
                }
                .chartYScale(domain: 0...10)
                .frame(height: 160)
            }
        }
        .padding(16)
        .iqVibrantMaterialCard()
        .padding(.horizontal, 16)
    }

    // ── Top symptoms
    private var topSymptoms: some View {
        let (start, end) = last7Days()
        let recent = appVM.symptoms.filter { $0.timestamp >= start && $0.timestamp <= end }
        let grouped = Dictionary(grouping: recent, by: \.type)
        let sorted = grouped.map { (type: $0.key, count: $0.value.count, avg: $0.value.map(\.severity).reduce(0,+) / Double($0.value.count)) }
            .sorted { $0.count > $1.count }.prefix(5)

        return VStack(alignment: .leading, spacing: 10) {
            Text("Top Symptoms (7 days)").font(IQFont.semibold(13)).foregroundColor(IQColors.textSecondary)
            if sorted.isEmpty {
                Text("No symptoms logged in the last 7 days").font(IQFont.regular(12)).foregroundColor(IQColors.textMuted)
            } else {
                ForEach(sorted, id: \.type) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.type.icon).font(.system(size: 14)).foregroundColor(IQColors.pinkVivid).frame(width: 24)
                        Text(item.type.label).font(IQFont.medium(13)).foregroundColor(IQColors.textPrimary)
                        Spacer()
                        Text("\(item.count)×").font(IQFont.semibold(12)).foregroundColor(IQColors.textSecondary)
                        Text("avg \(String(format: "%.1f", item.avg))")
                            .font(IQFont.regular(11)).foregroundColor(IQColors.textMuted)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(IQColors.border))
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(IQColors.background))
                }
            }
        }
        .padding(16)
        .iqVibrantMaterialCard()
        .padding(.horizontal, 16)
    }

    // ── Trigger foods
    private var triggerFoods: some View {
        let (start, end) = last7Days()
        let recent = appVM.foods.filter { $0.timestamp >= start && $0.timestamp <= end }
        let allTags = recent.flatMap(\.tags).filter { $0.isTrigger }
        let tagCounts = Dictionary(allTags.map { ($0, 1) }, uniquingKeysWith: +)
        let sorted = tagCounts.sorted { $0.value > $1.value }.prefix(5)

        return VStack(alignment: .leading, spacing: 10) {
            Text("Trigger Exposure (7 days)").font(IQFont.semibold(13)).foregroundColor(IQColors.textSecondary)
            if sorted.isEmpty {
                Text("No trigger foods logged").font(IQFont.regular(12)).foregroundColor(IQColors.textMuted)
            } else {
                ForEach(sorted, id: \.key) { tag, count in
                    HStack {
                        Text(tag.label).font(IQFont.medium(13)).foregroundColor(IQColors.riskHigh)
                        Spacer()
                        Text("\(count) time\(count == 1 ? "" : "s")")
                            .font(IQFont.semibold(12)).foregroundColor(IQColors.textSecondary)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(IQColors.riskHighBg.opacity(0.4)))
                }
            }
        }
        .padding(16)
        .iqVibrantMaterialCard()
        .padding(.horizontal, 16)
    }

    // ── Helpers
    private var sevenDayData: [(String, Double)] {
        let cal = Calendar.current
        return (0..<7).reversed().map { offset -> (String, Double) in
            let date = cal.date(byAdding: .day, value: -offset, to: Date())!
            let dayS = appVM.symptoms.filter { cal.isDate($0.timestamp, inSameDayAs: date) }
            let avg = dayS.isEmpty ? 0 : dayS.map(\.severity).reduce(0,+) / Double(dayS.count)
            return (offset == 0 ? "Today" : date.formatted(.dateTime.weekday(.abbreviated)), avg)
        }
    }

    private func last7Days() -> (Date, Date) {
        (Calendar.current.date(byAdding: .day, value: -7, to: Date())!, Date())
    }

}
