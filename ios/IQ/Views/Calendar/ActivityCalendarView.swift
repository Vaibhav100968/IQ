import SwiftUI

// TODO: IMPORT CALENDAR SDK HERE
// Example: import GlassCalendarSDK

// ── ActivityCalendarView — interactive glass-style month calendar ─────────────
// Adapted from the GlassCalendar SDK with IQ design system integration.
// Supports month navigation, day selection, activity indicators, and a
// selected-day detail panel.
struct ActivityCalendarView: View {
    @EnvironmentObject var appVM: AppViewModel

    @State private var displayedMonth: Date = {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
    }()
    @State private var selectedDate: Date = Date()
    @State private var monthTransitionID = UUID()

    private let cal = Calendar.current

    // TODO: USE SDK CALENDAR DATA HERE
    // Replace activity lookups with SDK-provided calendar data
    // Example:
    //   let events = sdk.getEventsForMonth(displayedMonth)

    var body: some View {
        VStack(spacing: 0) {
            monthNavigation
            weekdayRow
            calendarGrid
            Divider().padding(.horizontal, 14).opacity(0.4)
            selectedDayDetail
            Divider().padding(.horizontal, 14).opacity(0.4)
            calendarFooter
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
        )
    }

    // MARK: - Month Navigation

    private var monthNavigation: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    displayedMonth = cal.date(byAdding: .month, value: -1, to: displayedMonth)!
                    monthTransitionID = UUID()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(IQColors.lavenderDark)
                    .padding(10)
                    .background(Circle().fill(IQColors.lavender.opacity(0.3)))
            }

            Spacer()

            VStack(spacing: 2) {
                Text(displayedMonth.formatted(.dateTime.month(.wide)))
                    .font(IQFont.bold(20))
                    .foregroundColor(IQColors.textPrimary)
                    .id(monthTransitionID)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                Text(displayedMonth.formatted(.dateTime.year()))
                    .font(IQFont.regular(12))
                    .foregroundColor(IQColors.textMuted)
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    displayedMonth = cal.date(byAdding: .month, value: 1, to: displayedMonth)!
                    monthTransitionID = UUID()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(IQColors.lavenderDark)
                    .padding(10)
                    .background(Circle().fill(IQColors.lavender.opacity(0.3)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }

    // MARK: - Weekday Row

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                Text(day)
                    .font(IQFont.medium(10))
                    .foregroundColor(IQColors.textMuted)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = daysInMonth()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                dayCell(date: date)
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 12)
        .id(monthTransitionID)
        .transition(.opacity)
    }

    private func dayCell(date: Date?) -> some View {
        let isSelected = date.map { cal.isDate($0, inSameDayAs: selectedDate) } ?? false
        let isToday = date.map { cal.isDateInToday($0) } ?? false
        let count = date.map { appVM.logCountForDate($0) } ?? 0
        let hasLogs = count > 0
        let dayNum = date.map { cal.component(.day, from: $0) } ?? 0

        return Button {
            guard let date = date else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDate = date
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(IQColors.pink)
                            .frame(width: 34, height: 34)
                            .transition(.scale.combined(with: .opacity))
                    } else if isToday {
                        Circle()
                            .stroke(IQColors.lavenderDark, lineWidth: 1.5)
                            .frame(width: 34, height: 34)
                    }

                    if date != nil {
                        Text("\(dayNum)")
                            .font(isSelected || isToday ? IQFont.bold(14) : IQFont.regular(13))
                            .foregroundColor(isSelected ? .white : IQColors.textPrimary)
                    }
                }
                .frame(width: 38, height: 38)

                // Activity dot
                Circle()
                    .fill(hasLogs && !isSelected ? IQColors.pinkDark : Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .buttonStyle(.plain)
        .disabled(date == nil)
    }

    // MARK: - Selected Day Detail

    private var selectedDayDetail: some View {
        let count = appVM.logCountForDate(selectedDate)
        let symptomCount = appVM.symptoms.filter { cal.isDate($0.timestamp, inSameDayAs: selectedDate) }.count
        let foodCount = appVM.foods.filter { cal.isDate($0.timestamp, inSameDayAs: selectedDate) }.count
        let isToday = cal.isDateInToday(selectedDate)

        return VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isToday ? "Today" : selectedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                        .font(IQFont.semibold(14))
                        .foregroundColor(IQColors.textPrimary)
                    Text(count > 0 ? "\(count) entries logged" : "No entries yet")
                        .font(IQFont.regular(11))
                        .foregroundColor(IQColors.textMuted)
                }

                Spacer()

                if count > 0 {
                    HStack(spacing: 12) {
                        statBadge(icon: "waveform.path.ecg", value: symptomCount, color: IQColors.pinkDark)
                        statBadge(icon: "fork.knife", value: foodCount, color: IQColors.lavenderDark)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .animation(.spring(response: 0.3), value: selectedDate)
    }

    private func statBadge(icon: String, value: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
            Text("\(value)")
                .font(IQFont.semibold(12))
                .foregroundColor(IQColors.textPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(color.opacity(0.1))
        )
    }

    // MARK: - Footer (adapted from GlassCalendar SDK)

    private var calendarFooter: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "pencil")
                    .font(.system(size: 12))
                Text("Add a note...")
                    .font(IQFont.regular(12))
            }
            .foregroundColor(IQColors.textMuted)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3)) {
                    appVM.selectedTab = .symptoms
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("Log Entry")
                        .font(IQFont.semibold(12))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(IQColors.pink)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    // MARK: - Date Helpers

    private func daysInMonth() -> [Date?] {
        guard let range = cal.range(of: .day, in: .month, for: displayedMonth),
              let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let firstWeekday = cal.component(.weekday, from: firstOfMonth) - 1

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            if let d = cal.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(d)
            }
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }
}
