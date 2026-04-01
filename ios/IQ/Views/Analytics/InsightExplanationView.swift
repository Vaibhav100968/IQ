import SwiftUI

// TODO: CONNECT PERSONALIZED INSIGHT TEXT FROM ML OUTPUT
// Replace placeholder logic with real ML-generated insights
// Example: let insight = sdk.getInsight(for: activeGraph)

// ── InsightExplanationView — dynamic personalized insight card ───────────────
// Shows a contextual explanation below each graph that updates in sync
// with the active graph. Derives insights from user symptoms, food logs,
// flare risk, and ML prediction data.
struct InsightExplanationView: View {
    let activeGraph: GraphTag
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: insightIcon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(insightAccent)
                Text("Insight")
                    .font(IQFont.semibold(12))
                    .foregroundColor(IQColors.textSecondary)
                Spacer()
                Text(activeGraph.label)
                    .font(IQFont.medium(10))
                    .foregroundColor(insightAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(insightAccent.opacity(0.1)))
            }

            Text(insightText)
                .font(IQFont.regular(13))
                .foregroundColor(IQColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
                .id(activeGraph)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(insightAccent.opacity(0.15), lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: activeGraph)
    }

    // MARK: - Personalized Insight Logic

    // TODO: Replace with ML-generated personalized insights
    private var insightText: String {
        switch activeGraph {
        case .symptomTrend:
            return symptomTrendInsight
        case .flareRisk:
            return "Your flare risk is currently \(appVM.flareRisk.level.label.lowercased()). \(appVM.flareRisk.explanation)"
        case .features:
            return featureInsight
        case .triggers:
            return triggerInsight
        case .foodSymptom:
            return foodSymptomInsight
        case .calendarRisk:
            return calendarInsight
        case .symptomDist:
            return distributionInsight
        case .whatIf:
            return "Improving sleep and reducing stress could lower your risk by up to 27%. Small lifestyle changes compound over time."
        case .personalization:
            return personalizationInsight
        case .flareDist:
            return "Based on your history, your risk stays below 50% for most observed days. Consistent tracking helps improve prediction accuracy."
        }
    }

    private var insightIcon: String {
        switch activeGraph {
        case .symptomTrend:    return "lightbulb.fill"
        case .flareRisk:       return "shield.fill"
        case .features:        return "list.bullet.clipboard.fill"
        case .triggers:        return "exclamationmark.circle.fill"
        case .foodSymptom:     return "fork.knife.circle.fill"
        case .calendarRisk:    return "calendar.badge.clock"
        case .symptomDist:     return "chart.pie.fill"
        case .whatIf:          return "sparkles"
        case .personalization: return "brain.head.profile"
        case .flareDist:       return "function"
        }
    }

    private var insightAccent: Color {
        switch activeGraph {
        case .symptomTrend, .flareRisk, .flareDist:
            return IQColors.pinkDark
        case .features, .personalization:
            return IQColors.lavender
        case .triggers, .whatIf:
            return IQColors.blush
        case .foodSymptom, .calendarRisk:
            return IQColors.lavender
        case .symptomDist:
            return IQColors.pink
        }
    }

    // MARK: - Derived Insights

    private var symptomTrendInsight: String {
        let cal = Calendar.current
        let recentDays = (0..<3).compactMap { cal.date(byAdding: .day, value: -$0, to: Date()) }
        let olderDays = (3..<7).compactMap { cal.date(byAdding: .day, value: -$0, to: Date()) }

        let recentAvg = avgSeverity(for: recentDays)
        let olderAvg = avgSeverity(for: olderDays)

        if recentAvg > olderAvg + 1.5 {
            return "Your symptoms have been increasing over the last 3 days compared to earlier this week. Consider reviewing recent triggers and rest patterns."
        } else if recentAvg < olderAvg - 1.5 {
            return "Good news — your symptom severity has been declining. Whatever you've been doing this week is working. Keep it up."
        } else {
            return "Your symptom levels have been relatively stable this week. Consistent tracking helps identify subtle patterns over time."
        }
    }

    private var featureInsight: String {
        let contribs = appVM.mlPrediction?.featureContributions ?? ["pain": 0.72, "stress": 0.58, "diarrhea": 0.45]
        let labels: [String: String] = [
            "pain": "pain levels", "stress": "stress", "diarrhea": "diarrhea frequency",
            "sleep": "sleep quality", "dairy": "dairy intake", "recency": "time since last flare",
            "spicy_food": "spicy food consumption",
        ]
        if let top = contribs.max(by: { $0.value < $1.value }) {
            let name = labels[top.key] ?? top.key
            return "Your top contributing factor is \(name) at \(Int(top.value * 100))% influence. Focusing on this area could have the biggest impact on reducing your risk."
        }
        return "Log more data so the AI can identify your key risk factors."
    }

    private var triggerInsight: String {
        let triggerFoods = appVM.foods.flatMap(\.tags).filter(\.isTrigger)
        let counts = Dictionary(triggerFoods.map { ($0.label, 1) }, uniquingKeysWith: +)
        if let top = counts.max(by: { $0.value < $1.value }) {
            return "\(top.key) is your most frequent trigger food (\(top.value) occurrences). Track how your symptoms respond after consuming it to confirm the correlation."
        }
        return "No trigger foods logged recently. Keep logging your meals to uncover potential food-symptom correlations."
    }

    private var foodSymptomInsight: String {
        let cal = Calendar.current
        var trigDays = 0, trigTotal = 0.0, cleanDays = 0, cleanTotal = 0.0
        for offset in 0..<7 {
            let date = cal.date(byAdding: .day, value: -offset, to: Date())!
            let dayFoods = appVM.foods.filter { cal.isDate($0.timestamp, inSameDayAs: date) }
            let hasTrigger = dayFoods.flatMap(\.tags).contains(where: \.isTrigger)
            let daySymptoms = appVM.symptoms.filter { cal.isDate($0.timestamp, inSameDayAs: date) }
            let avg = daySymptoms.isEmpty ? 0 : daySymptoms.map(\.severity).reduce(0,+) / Double(daySymptoms.count)
            if hasTrigger { trigDays += 1; trigTotal += avg }
            else { cleanDays += 1; cleanTotal += avg }
        }
        let trigAvg = trigDays > 0 ? trigTotal / Double(trigDays) : 0
        let cleanAvg = cleanDays > 0 ? cleanTotal / Double(cleanDays) : 0
        if trigDays > 0 && trigAvg > cleanAvg + 1 {
            return "On days with trigger foods, your average severity is \(String(format: "%.1f", trigAvg)) vs \(String(format: "%.1f", cleanAvg)) on clean days. Avoiding triggers could meaningfully reduce symptoms."
        }
        return "Your food and symptom data shows no strong correlation yet. Keep tracking both consistently for better insights."
    }

    private var calendarInsight: String {
        let cal = Calendar.current
        let activeDays = (0..<28).filter { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: Date())!
            return appVM.logCountForDate(date) > 0
        }.count
        let pct = Int(Double(activeDays) / 28.0 * 100)
        if pct >= 80 {
            return "Excellent consistency — you logged on \(activeDays) of the last 28 days (\(pct)%). This data density gives the AI strong predictive power."
        } else if pct >= 50 {
            return "You logged on \(activeDays) of the last 28 days (\(pct)%). Try to log daily for more accurate risk predictions."
        }
        return "You've logged on \(activeDays) of the last 28 days. More frequent tracking will significantly improve your personalized insights."
    }

    private var distributionInsight: String {
        let (start, _) = (Calendar.current.date(byAdding: .day, value: -7, to: Date())!, Date())
        let recent = appVM.symptoms.filter { $0.timestamp >= start }
        let grouped = Dictionary(grouping: recent, by: \.type)
        if let top = grouped.max(by: { $0.value.count < $1.value.count }) {
            let pct = recent.isEmpty ? 0 : Int(Double(top.value.count) / Double(recent.count) * 100)
            return "\(top.key.label) is your most logged symptom this week, making up \(pct)% of all entries. Monitor if specific foods or activities precede it."
        }
        return "No symptoms logged in the last 7 days. Log regularly to see your symptom distribution."
    }

    private var personalizationInsight: String {
        let logged = appVM.mlPrediction?.daysLogged ?? appVM.symptoms.count / 3
        let remaining = max(0, 30 - logged)
        if remaining == 0 {
            return "Your model is fully personalized with \(logged)+ days of data. Predictions now reflect your unique patterns and history."
        }
        return "You've logged \(logged) days so far. \(remaining) more days of tracking will unlock full AI personalization tailored to your body."
    }

    // MARK: - Helpers

    private func avgSeverity(for dates: [Date]) -> Double {
        let cal = Calendar.current
        let entries = dates.flatMap { date in
            appVM.symptoms.filter { cal.isDate($0.timestamp, inSameDayAs: date) }
        }
        guard !entries.isEmpty else { return 0 }
        return entries.map(\.severity).reduce(0, +) / Double(entries.count)
    }
}
