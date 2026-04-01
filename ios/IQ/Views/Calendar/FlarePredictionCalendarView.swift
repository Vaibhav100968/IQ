import SwiftUI

// MARK: - Models

enum GutDayPhase: Int, CaseIterable, Equatable {
    case noData, stable, mild, moderate, flare, recovery

    var label: String {
        switch self {
        case .noData: return "No data"
        case .stable: return "Stable"
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .flare: return "Flare"
        case .recovery: return "Recovery"
        }
    }

    static func fromMLRisk(_ r: Double) -> GutDayPhase {
        if r < 0.24 { return .stable }
        if r < 0.40 { return .mild }
        if r < 0.62 { return .moderate }
        return .flare
    }
}

struct FlareDayCellData {
    let date: Date
    var phase: GutDayPhase
    let isPredicted: Bool
    /// Display risk; for forecast days may reflect smoothed timeline after `applyForecastTimelinePhases`.
    var riskPercent: Int
    let contributions: [(icon: String, label: String, pct: Int)]
}

// MARK: - Colors & styling

private func phaseSolid(_ p: GutDayPhase) -> Color {
    switch p {
    case .noData: return IQColors.calFrost
    case .stable: return IQColors.calStable
    case .mild: return IQColors.calMild
    case .moderate: return IQColors.calModerate
    case .flare: return IQColors.calFlare
    case .recovery: return IQColors.calRecovery
    }
}

private func cellFill(phase: GutDayPhase, predicted: Bool) -> Color {
    let c = phaseSolid(phase)
    return predicted ? c.opacity(0.52) : c
}

private func cellGradient(phase: GutDayPhase, predicted: Bool) -> LinearGradient {
    let c = phaseSolid(phase)
    let top = predicted ? c.opacity(0.65) : c
    let bottom = predicted ? c.opacity(0.35) : c.opacity(0.78)
    return LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
}

// MARK: - Data builder

@MainActor
enum FlareCalendarBuilder {

    static func logSnapshot(for date: Date, appVM: AppViewModel) -> (symptomCount: Int, maxSev: Double, avgSev: Double, triggerFoods: Int, blood: Double) {
        let cal = Calendar.current
        let day = cal.startOfDay(for: date)
        let sy = appVM.symptoms.filter { cal.isDate($0.timestamp, inSameDayAs: day) }
        let fd = appVM.foods.filter { cal.isDate($0.timestamp, inSameDayAs: day) }
        let maxSev = sy.map(\.severity).max() ?? 0
        let avgSev = sy.isEmpty ? 0 : sy.map(\.severity).reduce(0, +) / Double(sy.count)
        let triggers = fd.filter { $0.tags.contains(where: { $0.isTrigger }) }.count
        let blood = sy.filter { $0.type == .blood_in_stool }.map(\.severity).max() ?? 0
        return (sy.count, maxSev, avgSev, triggers, blood)
    }

    static func resolvePhase(
        date: Date,
        appVM: AppViewModel,
        yesterdayPhase: GutDayPhase?,
        isFuture: Bool
    ) -> (phase: GutDayPhase, predicted: Bool, risk: Int, contributions: [(icon: String, label: String, pct: Int)]) {
        let pred = appVM.onDevicePrediction(forDay: date)
        let risk = pred?.riskPercent ?? appVM.flareRisk.overallScore
        let r = pred.map { $0.finalRisk } ?? Double(risk) / 100

        let snap = logSnapshot(for: date, appVM: appVM)

        var phase: GutDayPhase
        var predicted = isFuture

        if isFuture {
            phase = GutDayPhase.fromMLRisk(r)
        } else {
            if snap.symptomCount == 0 && snap.triggerFoods == 0 {
                if let p = pred, p.finalRisk > 0.12 {
                    phase = GutDayPhase.fromMLRisk(p.finalRisk)
                    predicted = false
                } else {
                    phase = .noData
                }
            } else {
                if snap.maxSev >= 8 || snap.blood >= 1 {
                    phase = .flare
                } else if snap.avgSev >= 5 || snap.triggerFoods >= 2 {
                    phase = .moderate
                } else if snap.avgSev >= 2.5 || snap.symptomCount >= 2 {
                    phase = .mild
                } else {
                    phase = .stable
                }
                if let y = yesterdayPhase, (y == .flare || y == .moderate), snap.avgSev < 3.5, snap.maxSev < 7 {
                    phase = .recovery
                }
                if let p = pred {
                    let mlPhase = GutDayPhase.fromMLRisk(p.finalRisk)
                    if mlPhase == .flare && phase == .stable { phase = .moderate }
                    if mlPhase == .moderate && phase == .stable && snap.symptomCount > 0 { phase = .mild }
                }
            }
        }

        let contributions = buildContributions(pred: pred, snap: snap, appVM: appVM)
        return (phase, predicted, risk, contributions)
    }

    /// The Core ML pipeline scores **one day at a time** (features → risk), not a dedicated sequence model (e.g. LSTM).
    /// This pass turns the per-day forecast into a **coherent phase track**: smoothed risk + ramp / peak / recovery labels on future days.
    private static func applyForecastTimelinePhases(cells: inout [FlareDayCellData], rawMLRisks: [Double]) {
        let n = cells.count
        guard n == rawMLRisks.count, n > 0 else { return }
        let futureIndices = cells.indices.filter { cells[$0].isPredicted }
        guard !futureIndices.isEmpty else { return }

        var smoothed = rawMLRisks
        for i in futureIndices {
            let a = max(0, i - 1)
            let b = min(n - 1, i + 1)
            smoothed[i] = (rawMLRisks[a] + rawMLRisks[i] + rawMLRisks[b]) / 3.0
        }

        for i in futureIndices {
            let r0 = smoothed[i]
            let rL = i > 0 ? smoothed[i - 1] : r0
            let rR = i < n - 1 ? smoothed[i + 1] : r0

            let phase: GutDayPhase
            // Down-slope after elevated risk → recovery phase of the “cycle”
            if i > 0, smoothed[i - 1] >= 0.36, r0 < smoothed[i - 1] - 0.02 {
                phase = .recovery
            }
            // Local peak on the smoothed forecast curve
            else if r0 >= rL - 0.01, r0 >= rR - 0.01, r0 >= max(rL, rR) - 0.015, r0 >= 0.38 {
                if r0 >= 0.55 { phase = .flare }
                else if r0 >= 0.42 { phase = .moderate }
                else { phase = .mild }
            }
            // Building toward higher risk ahead (approach phase)
            else if i < n - 1, rR > r0 + 0.025, rR >= 0.36 {
                let blended = r0 * 0.45 + rR * 0.55
                var ramp = GutDayPhase.fromMLRisk(blended)
                if ramp == .stable, rR >= 0.34 { ramp = .mild }
                phase = ramp
            } else {
                phase = GutDayPhase.fromMLRisk(r0)
            }

            cells[i].phase = phase
            cells[i].riskPercent = min(99, max(0, Int(round(r0 * 100))))
        }
    }

    static func buildContributions(pred: OnDevicePrediction?, snap: (symptomCount: Int, maxSev: Double, avgSev: Double, triggerFoods: Int, blood: Double), appVM: AppViewModel) -> [(icon: String, label: String, pct: Int)] {
        var rows: [(icon: String, label: String, pct: Int)] = []
        let labels: [String: String] = [
            "dairy": "Dairy", "stress": "Stress", "sleep": "Sleep",
            "pain": "Pain", "diarrhea": "Diarrhea", "spicy_food": "Spicy food",
        ]
        let icons: [String: String] = [
            "dairy": "fork.knife", "stress": "brain.head.profile", "sleep": "moon.zzz.fill",
            "pain": "waveform.path.ecg", "diarrhea": "drop.fill", "spicy_food": "flame.fill",
        ]
        if let p = pred {
            for (k, v) in p.featureContributions.sorted(by: { $0.value > $1.value }).prefix(4) {
                let pct = min(99, Int(v * 100))
                if pct < 5 { continue }
                rows.append((icon: icons[k] ?? "chart.bar.fill", label: labels[k] ?? k.replacingOccurrences(of: "_", with: " "), pct: pct))
            }
        }
        if snap.triggerFoods > 0 && !rows.contains(where: { $0.label == "Dairy" }) {
            rows.append((icon: "fork.knife", label: "Food triggers", pct: min(40, 18 + snap.triggerFoods * 6)))
        }
        if (pred?.featureContributions["stress"] ?? 0) > 0.4 || snap.avgSev > 4 {
            if !rows.contains(where: { $0.label == "Stress" }) {
                rows.append((icon: "brain.head.profile", label: "Stress spike", pct: 22))
            }
        }
        if (pred?.featureContributions["sleep"] ?? 0) > 0.35 {
            if !rows.contains(where: { $0.label == "Sleep" }) {
                rows.append((icon: "moon.zzz.fill", label: "Poor sleep", pct: 18))
            }
        }
        if rows.isEmpty {
            rows.append((icon: "cross.case.fill", label: "Log more for causes", pct: 0))
        }
        return Array(rows.prefix(5))
    }

    static func monthCells(for month: Date, appVM: AppViewModel) -> [FlareDayCellData] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: month),
              let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: month)) else { return [] }

        let today = cal.startOfDay(for: Date())
        var result: [FlareDayCellData] = []
        var rawMLRisks: [Double] = []

        for d in range {
            guard let day = cal.date(byAdding: .day, value: d - 1, to: firstOfMonth) else { continue }
            let dayStart = cal.startOfDay(for: day)
            let yesterday = cal.date(byAdding: .day, value: -1, to: dayStart)!
            let yPhase = result.last(where: { cal.isDate($0.date, inSameDayAs: yesterday) })?.phase
            let isFuture = dayStart > today
            let (phase, predicted, risk, contribs) = resolvePhase(
                date: dayStart,
                appVM: appVM,
                yesterdayPhase: yPhase,
                isFuture: isFuture
            )
            let pred = appVM.onDevicePrediction(forDay: dayStart)
            let rRaw = pred?.finalRisk ?? Double(risk) / 100.0
            rawMLRisks.append(rRaw)
            result.append(FlareDayCellData(date: dayStart, phase: phase, isPredicted: predicted, riskPercent: risk, contributions: contribs))
        }
        applyForecastTimelinePhases(cells: &result, rawMLRisks: rawMLRisks)
        return result
    }

    static func monthGridDates(_ month: Date) -> [[Date?]] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: month),
              let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: month)) else { return [] }

        let offset = (cal.component(.weekday, from: firstOfMonth) - cal.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: offset)
        for d in range {
            cells.append(cal.date(byAdding: .day, value: d - 1, to: firstOfMonth).map { cal.startOfDay(for: $0) })
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<min($0 + 7, cells.count)]) }
    }
}

// MARK: - Main view

struct FlarePredictionCalendarView: View {
    @EnvironmentObject var appVM: AppViewModel
    /// Set to `false` when embedded on the Log tab so the primary Add button isn’t duplicated.
    var showsEmbeddedLogShortcuts: Bool = true
    @State private var month = Date()
    @State private var selected: FlareDayCellData?
    @State private var pulseToday = false

    private var dataByDay: [Date: FlareDayCellData] {
        Dictionary(uniqueKeysWithValues: FlareCalendarBuilder.monthCells(for: month, appVM: appVM).map { ($0.date, $0) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            calendarGrid
            legend
            insightsCard
            if showsEmbeddedLogShortcuts {
                logCTA
            }
        }
        .padding(16)
        .iqVibrantMaterialCard()
        .overlay(alignment: .bottomTrailing) {
            if showsEmbeddedLogShortcuts {
                fab
                    .padding(20)
            }
        }
        .sheet(item: $selected) { cell in
            FlareDayDetailSheet(cell: cell)
                .environmentObject(appVM)
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            appVM.fetchMLPrediction()
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulseToday = true
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Flare Prediction Calendar")
                    .font(.title3.bold())
                Text("When symptoms hit, what’s ahead, and why")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Future days use the same daily model, then a short smoothing pass so phases can read as ramp, peak, or recovery — not a separate time-series network.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            HStack(spacing: 12) {
                Button {
                    shiftMonth(-1)
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(IQColors.calStable)
                }
                Text(monthTitle)
                    .font(.subheadline.bold())
                    .frame(minWidth: 120)
                Button {
                    shiftMonth(1)
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(IQColors.calStable)
                }
            }
        }
    }

    private var monthTitle: String {
        month.formatted(.dateTime.month(.wide).year())
    }

    private func shiftMonth(_ v: Int) {
        if let d = Calendar.current.date(byAdding: .month, value: v, to: month) {
            month = d
        }
    }

    private var weekdayLabels: some View {
        let syms = Calendar.current.shortWeekdaySymbols
        let first = Calendar.current.firstWeekday - 1
        let ordered = (0..<7).map { syms[($0 + first) % 7] }
        return HStack(spacing: 0) {
            ForEach(Array(ordered.enumerated()), id: \.offset) { _, w in
                Text(String(w.prefix(1)))
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        let weeks = FlareCalendarBuilder.monthGridDates(month)
        return VStack(spacing: 6) {
            weekdayLabels
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                weekRow(week)
            }
        }
    }

    private func weekRow(_ week: [Date?]) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let cellW = w / 7
            ZStack(alignment: .topLeading) {
                phaseBars(week: week, cellWidth: cellW, totalWidth: w)
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { i in
                        dayCell(date: week[i], cellWidth: cellW)
                    }
                }
            }
        }
        .frame(height: 52)
    }

    private func phaseBars(week: [Date?], cellWidth: CGFloat, totalWidth: CGFloat) -> some View {
        let cal = Calendar.current
        var runs: [(Int, Int, GutDayPhase, Bool)] = []
        var i = 0
        while i < 7 {
            guard let d = week[i], let cell = dataByDay[cal.startOfDay(for: d)] else {
                i += 1
                continue
            }
            let p = cell.phase
            let pred = cell.isPredicted
            var j = i + 1
            while j < 7, let d2 = week[j], let c2 = dataByDay[cal.startOfDay(for: d2)], c2.phase == p, c2.isPredicted == pred, p != .noData {
                j += 1
            }
            if p != .noData {
                runs.append((i, j - 1, p, pred))
            }
            i = j
        }

        return ForEach(0..<runs.count, id: \.self) { idx in
            let run = runs[idx]
            let (a, b, phase, pred) = run
            let x = CGFloat(a) * cellWidth + 2
            let barW = CGFloat(b - a + 1) * cellWidth - 4
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(cellGradient(phase: phase, predicted: pred))
                .frame(width: barW, height: 8)
                .opacity(0.85)
                .offset(x: x, y: -2)
        }
    }

    @ViewBuilder
    private func dayCell(date: Date?, cellWidth: CGFloat) -> some View {
        if let date {
            let cal = Calendar.current
            let key = cal.startOfDay(for: date)
            let cell = dataByDay[key]
            let isToday = cal.isDateInToday(date)
            Button {
                if let c = cell { selected = c }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(cell != nil ? cellGradient(phase: cell!.phase, predicted: cell!.isPredicted) : LinearGradient(colors: [IQColors.calFrost], startPoint: .top, endPoint: .bottom))
                        .overlay(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(isToday ? IQColors.calMild : Color.white.opacity(0.35), lineWidth: isToday ? 2.5 : 0.5)
                        )
                        .shadow(color: isToday ? IQColors.calMild.opacity(pulseToday ? 0.55 : 0.35) : .clear, radius: isToday ? 8 : 0)

                    VStack(spacing: 2) {
                        Text("\(cal.component(.day, from: date))")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        if let c = cell, c.phase != .noData {
                            HStack(spacing: 2) {
                                ForEach(Array(iconTags(for: c).prefix(2).enumerated()), id: \.offset) { _, ic in
                                    Image(systemName: ic)
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.95))
                                }
                            }
                        }
                    }
                }
                .frame(width: cellWidth - 4, height: 46)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        } else {
            Color.clear
                .frame(width: cellWidth, height: 46)
                .frame(maxWidth: .infinity)
        }
    }

    private func iconTags(for cell: FlareDayCellData) -> [String] {
        var s = cell.contributions.map { $0.icon }
        if s.isEmpty {
            if cell.phase == .flare || cell.phase == .moderate {
                return ["waveform.path.ecg", "fork.knife"]
            }
        }
        return s
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legend")
                .font(.caption.bold())
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                legendDot(color: IQColors.calStable, text: "Stable")
                legendDot(color: IQColors.calMild, text: "Mild")
                legendDot(color: IQColors.calModerate, text: "Moderate")
                legendDot(color: IQColors.calFlare, text: "Flare")
                legendDot(color: IQColors.calRecovery, text: "Recovery")
                legendDot(color: IQColors.calFrost, text: "No data")
            }
            Text("Predicted days use a softer, glassy tint")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func legendDot(color: Color, text: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 0.5))
            Text(text)
                .font(.caption2)
        }
    }

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Flare Insights", systemImage: "lightbulb.fill")
                .font(.subheadline.bold())
                .foregroundStyle(IQColors.calStable)
            if let p = appVM.mlPrediction {
                Text(insightText(p))
                    .font(.caption)
                    .foregroundStyle(.primary)
            } else {
                Text("Log symptoms and meals — on-device ML will personalize this calendar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(IQColors.calRecovery.opacity(0.35), lineWidth: 1)
                )
        )
    }

    private func insightText(_ p: OnDevicePrediction) -> String {
        if p.riskPercent < 25 {
            return "Outlook: calmer patch — keep sleep and meals consistent to stay in the stable zone."
        }
        if p.riskPercent < 55 {
            return "Elevated signals — watch trigger foods and stress; the calendar highlights higher-risk days ahead."
        }
        return "Higher flare probability — prioritize rest, hydration, and avoid known triggers; check red days on the grid."
    }

    private var logCTA: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            appVM.selectedTab = .symptoms
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Log Today — symptoms, food, or flare")
                    .font(.subheadline.bold())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [IQColors.calModerate, IQColors.calFlare.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .shadow(color: IQColors.calFlare.opacity(0.25), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var fab: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            appVM.selectedTab = .symptoms
        } label: {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(IQColors.calStable)
                        .shadow(color: IQColors.calStable.opacity(0.45), radius: pulseToday ? 14 : 8, y: 3)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Detail sheet

private struct FlareDayDetailSheet: View {
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.dismiss) private var dismiss
    let cell: FlareDayCellData

    private var weightedContribs: [(icon: String, label: String, pct: Int)] {
        cell.contributions.filter { $0.pct > 0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(cell.date.formatted(date: .complete, time: .omitted))
                                .font(.title3.bold())
                            Text(cell.phase.label + (cell.isPredicted ? " · Forecast" : " · Recorded"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(cellGradient(phase: cell.phase, predicted: cell.isPredicted))
                                .frame(width: 72, height: 72)
                            Text("\(cell.riskPercent)%")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        }
                    }

                    Text("Likely causes")
                        .font(.headline)

                    if weightedContribs.isEmpty {
                        Text("Keep logging — ML will surface weighted causes here.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(weightedContribs.enumerated()), id: \.offset) { _, row in
                            HStack {
                                Image(systemName: row.icon)
                                    .foregroundStyle(IQColors.calRecovery)
                                    .frame(width: 28)
                                Text(row.label)
                                Spacer()
                                Text("+\(row.pct)%")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(IQColors.calModerate)
                            }
                            .padding(10)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Day detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

extension FlareDayCellData: Identifiable {
    var id: Date { date }
}
