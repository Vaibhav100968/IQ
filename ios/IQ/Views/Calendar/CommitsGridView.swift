import SwiftUI

// TODO: IMPORT COMMITS GRID SDK HERE
// Example: import CommitsGridSDK

// ── CommitsGridView — compact GitHub-style activity heatmap ──────────────────
// Displays the last 16 weeks of daily activity as a grid of colored squares.
// Fits entirely on screen without horizontal scrolling.
struct CommitsGridView: View {
    /// Closure returning the number of logs for a given date
    let countForDate: (Date) -> Int

    // TODO: USE SDK DATA FOR GRID VALUES
    // Replace countForDate with SDK-provided activity data
    // Example:
    //   let activityData = sdk.getActivityGrid()
    //   let count = activityData[date] ?? 0

    // 16 weeks ≈ 4 months — compact enough to fit any iPhone width
    private let weekCount = 16
    private let cellSize: CGFloat = 11
    private let cellSpacing: CGFloat = 2.5

    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    @State private var appeared = false

    // MARK: - Grid Data

    private var grid: [[Date?]] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today) - 1 // 0 = Sun
        let totalDays = weekCount * 7
        let lastDayOffset = 6 - weekday
        guard let gridEnd = cal.date(byAdding: .day, value: lastDayOffset, to: today),
              let gridStart = cal.date(byAdding: .day, value: -(totalDays - 1), to: gridEnd)
        else { return [] }

        var result: [[Date?]] = []
        for w in 0..<weekCount {
            var week: [Date?] = []
            for d in 0..<7 {
                let offset = w * 7 + d
                if let date = cal.date(byAdding: .day, value: offset, to: gridStart) {
                    week.append(date <= today ? date : nil)
                } else {
                    week.append(nil)
                }
            }
            result.append(week)
        }
        return result
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            monthLabels
            gridBody
            legend
        }
        .onAppear {
            var t = Transaction()
            t.animation = nil
            withTransaction(t) { appeared = true }
        }
    }

    // MARK: - Month Labels

    private var monthLabels: some View {
        let cal = Calendar.current
        let labelWidth = cellSize + cellSpacing // day-label column offset
        var labels: [(String, Int)] = []
        var lastMonth = -1

        for (w, week) in grid.enumerated() {
            if let date = week.compactMap({ $0 }).first {
                let month = cal.component(.month, from: date)
                if month != lastMonth {
                    labels.append((date.formatted(.dateTime.month(.abbreviated)), w))
                    lastMonth = month
                }
            }
        }

        return HStack(spacing: 0) {
            Color.clear.frame(width: labelWidth)
            ForEach(labels, id: \.1) { label, _ in
                Text(label)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(IQColors.textMuted)
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Grid

    private var gridBody: some View {
        HStack(alignment: .top, spacing: cellSpacing) {
            // Day-of-week labels
            VStack(spacing: cellSpacing) {
                ForEach(0..<7, id: \.self) { i in
                    Text(dayLabels[i])
                        .font(.system(size: 7, weight: .medium))
                        .foregroundColor(IQColors.textMuted)
                        .frame(width: cellSize, height: cellSize)
                }
            }

            // Week columns
            ForEach(0..<grid.count, id: \.self) { w in
                VStack(spacing: cellSpacing) {
                    ForEach(0..<7, id: \.self) { d in
                        gridCell(date: grid[w][d])
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func gridCell(date: Date?) -> some View {
        let cal = Calendar.current
        let isToday = date.map { cal.isDateInToday($0) } ?? false
        let count = date.map { countForDate($0) } ?? 0
        let color = date == nil ? Color.clear : IQColors.commitHeatmapColors[min(count, 4)]
        return RoundedRectangle(cornerRadius: 2.5)
            .fill(color)
            .frame(width: cellSize, height: cellSize)
            .overlay(
                RoundedRectangle(cornerRadius: 2.5)
                    .stroke(isToday ? IQColors.lavenderDark : Color.clear, lineWidth: 1.5)
            )
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.12), value: appeared)
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 4) {
            Text("Less")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(IQColors.textMuted)
            ForEach(0..<IQColors.commitHeatmapColors.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(IQColors.commitHeatmapColors[i])
                    .frame(width: 9, height: 9)
            }
            Text("More")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(IQColors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
