import SwiftUI

// ── GitHubHeatmap — 53-week grid, mirrors git-hub-calendar.tsx ──────────────
struct GitHubHeatmap: View {

    /// logCountForDate closure — provided by the parent
    let countForDate: (Date) -> Int

    private let weeks = 53
    private let daysPerWeek = 7
    private let cellSize: CGFloat = 11
    private let cellSpacing: CGFloat = 3

    // Build a 53×7 grid of dates ending today
    private var grid: [[Date?]] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // Align so column 0 starts on Sunday
        let weekday = cal.component(.weekday, from: today) - 1 // 0=Sun
        let totalDays = weeks * daysPerWeek
        // Last cell is today or later in the week
        let lastDayOffset = daysPerWeek - 1 - weekday
        guard let gridEnd = cal.date(byAdding: .day, value: lastDayOffset, to: today),
              let gridStart = cal.date(byAdding: .day, value: -(totalDays - 1), to: gridEnd)
        else { return [] }

        var result: [[Date?]] = []
        for w in 0..<weeks {
            var week: [Date?] = []
            for d in 0..<daysPerWeek {
                let offset = w * daysPerWeek + d
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

    @State private var hoveredDate: Date? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Month labels
            monthLabels

            // Main grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: cellSpacing) {
                    // Day-of-week labels
                    VStack(spacing: cellSpacing) {
                        ForEach(["S","M","T","W","T","F","S"], id: \.self) { label in
                            Text(label)
                                .font(.system(size: 8))
                                .foregroundColor(IQColors.textMuted)
                                .frame(width: cellSize, height: cellSize)
                        }
                    }

                    // Week columns
                    ForEach(0..<grid.count, id: \.self) { w in
                        VStack(spacing: cellSpacing) {
                            ForEach(0..<7, id: \.self) { d in
                                cell(date: grid[w][d])
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // Legend
            legend
        }
    }

    // ── Cell
    private func cell(date: Date?) -> some View {
        let cal = Calendar.current
        let isToday = date.map { cal.isDateInToday($0) } ?? false
        let count = date.map { countForDate($0) } ?? 0
        let color = date == nil ? Color.clear : IQColors.commitHeatmapColors[min(count, 4)]

        return RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: cellSize, height: cellSize)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(isToday ? IQColors.lavenderDark : Color.clear, lineWidth: 1.5)
            )
    }

    // ── Month labels row
    private var monthLabels: some View {
        let cal = Calendar.current
        var labels: [(String, Int)] = [] // (label, week index)
        var lastMonth = -1
        for (w, week) in grid.enumerated() {
            if let date = week.first(where: { $0 != nil }) ?? nil {
                let month = cal.component(.month, from: date)
                if month != lastMonth {
                    labels.append((date.formatted(.dateTime.month(.abbreviated)), w))
                    lastMonth = month
                }
            }
        }

        return HStack(spacing: 0) {
            ForEach(labels, id: \.1) { label, weekIdx in
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(IQColors.textMuted)
                    .frame(width: CGFloat(weekIdx) * (cellSize + cellSpacing), alignment: .leading)
                    .fixedSize()
                Spacer()
            }
        }
        .padding(.leading, cellSize + cellSpacing + 4) // offset for day labels
    }

    // ── Legend
    private var legend: some View {
        HStack(spacing: 4) {
            Text("Less")
                .font(.system(size: 9))
                .foregroundColor(IQColors.textMuted)
            ForEach(0..<IQColors.commitHeatmapColors.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(IQColors.commitHeatmapColors[i])
                    .frame(width: 10, height: 10)
            }
            Text("More")
                .font(.system(size: 9))
                .foregroundColor(IQColors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
