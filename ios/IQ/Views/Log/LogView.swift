import SwiftUI

struct LogView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var selectedSection: LogSection = .symptoms
    @State private var showAddSymptom = false
    @State private var showAddFood = false

    enum LogSection: String, CaseIterable {
        case symptoms = "Symptoms"
        case food = "Food"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                sectionPicker
                    .padding(.top, 8)

                addButton

                // Activity — commit grid + ML-linked flare prediction calendar
                LogActivitySection()

                switch selectedSection {
                case .symptoms: symptomsList
                case .food: foodList
                }

                Color.clear.frame(height: 16)
            }
            .padding(.horizontal, 16)
        }
        .background(Color.clear)
        .navigationTitle("Log")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAddSymptom) {
            LogAddSymptomSheet()
                .environmentObject(appVM)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showAddFood) {
            LogAddFoodSheet()
                .environmentObject(appVM)
                .presentationDetents([.medium, .large])
        }
    }

    private var sectionPicker: some View {
        Picker("Section", selection: $selectedSection) {
            ForEach(LogSection.allCases, id: \.self) { section in
                Text(section.rawValue).tag(section)
            }
        }
        .pickerStyle(.segmented)
    }

    private var addButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            switch selectedSection {
            case .symptoms: showAddSymptom = true
            case .food: showAddFood = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("Add \(selectedSection == .symptoms ? "Symptom" : "Food")")
                    .font(.subheadline.bold())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(IQColors.lavenderDark, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: IQColors.lavenderVivid.opacity(0.35), radius: 12, x: 0, y: 5)
        }
        .buttonStyle(CardPressStyle())
    }

    // MARK: - Symptoms list

    private var symptomsList: some View {
        let today = appVM.symptoms.filter { Calendar.current.isDateInToday($0.timestamp) }
        let earlier = appVM.symptoms.filter { !Calendar.current.isDateInToday($0.timestamp) }.prefix(20)

        return VStack(alignment: .leading, spacing: 16) {
            if today.isEmpty && earlier.isEmpty {
                emptyState(icon: "waveform.path.ecg", text: "No symptoms logged yet")
            }

            if !today.isEmpty {
                listHeader("Today")
                ForEach(today) { entry in
                    symptomRow(entry)
                }
            }

            if !earlier.isEmpty {
                listHeader("Recent")
                ForEach(Array(earlier)) { entry in
                    symptomRow(entry)
                }
            }
        }
    }

    private func symptomRow(_ entry: SymptomEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: entry.type.icon)
                .foregroundStyle(severityColor(entry.severity))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.type.label)
                    .font(.subheadline.bold())
                Text(severityLabel(entry.severity))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(entry.timestamp, style: .time)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Food list

    private var foodList: some View {
        let today = appVM.foods.filter { Calendar.current.isDateInToday($0.timestamp) }
        let earlier = appVM.foods.filter { !Calendar.current.isDateInToday($0.timestamp) }.prefix(20)

        return VStack(alignment: .leading, spacing: 16) {
            if today.isEmpty && earlier.isEmpty {
                emptyState(icon: "fork.knife", text: "No meals logged yet")
            }

            if !today.isEmpty {
                listHeader("Today")
                ForEach(today) { entry in
                    foodRow(entry)
                }
            }

            if !earlier.isEmpty {
                listHeader("Recent")
                ForEach(Array(earlier)) { entry in
                    foodRow(entry)
                }
            }
        }
    }

    private func foodRow(_ entry: FoodEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: entry.mealType.icon)
                .foregroundStyle(IQColors.lavenderDark)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.subheadline.bold())
                if !entry.tags.isEmpty {
                    Text(entry.tags.map(\.label).joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(entry.timestamp, style: .time)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func listHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.bold())
            .foregroundStyle(.secondary)
    }

    private func emptyState(icon: String, text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.quaternary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func severityColor(_ s: Double) -> Color {
        if s <= 3 { return IQColors.riskLow }
        if s <= 6 { return IQColors.riskModerate }
        return IQColors.riskHigh
    }
}

// MARK: - Activity Section

private struct LogActivitySection: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            activityHeader

            if isExpanded {
                VStack(spacing: 16) {
                    commitGridCard
                    calendarCard
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isExpanded)
    }

    private var activityHeader: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            isExpanded.toggle()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Activity")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    Text("Streak grid and on-device flare-risk calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
                    .padding(8)
                    .background(Color(.tertiarySystemFill), in: Circle())
            }
        }
        .buttonStyle(.plain)
    }

    private var commitGridCard: some View {
        LogCommitGrid()
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var calendarCard: some View {
        FlarePredictionCalendarView(showsEmbeddedLogShortcuts: false)
            .environmentObject(appVM)
            .padding(.horizontal, -16)
    }
}

// MARK: - Commit Grid (Log-specific, live-updating)

private struct LogCommitGrid: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var appeared = false
    @State private var tappedDate: Date? = nil

    private let weekCount = 16
    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 2.5
    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            gridHeader
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

    private var gridHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(IQColors.lavenderDark)
            Text("Last 16 Weeks")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Spacer()
            Text(streakText)
                .font(.caption2.bold())
                .foregroundStyle(IQColors.lavenderDark)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(IQColors.lavender.opacity(0.3), in: Capsule())
        }
    }

    // MARK: - Grid data

    private var grid: [[Date?]] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today) - 1
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

    private func countsForDate(_ date: Date) -> (symptoms: Int, food: Int) {
        let cal = Calendar.current
        let s = appVM.symptoms.filter { cal.isDate($0.timestamp, inSameDayAs: date) }.count
        let f = appVM.foods.filter { cal.isDate($0.timestamp, inSameDayAs: date) }.count
        return (s, f)
    }

    private var streakText: String {
        let cal = Calendar.current
        var streak = 0
        var day = Date()
        while appVM.logCountForDate(day) > 0 {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak > 0 ? "\(streak)-day streak" : "Start your streak"
    }

    // MARK: - Cell color (same ramp as legend + CommitsGridView)

    private func cellColor(date: Date?) -> Color {
        guard let date = date else { return .clear }
        let (symptoms, food) = countsForDate(date)
        let total = symptoms + food
        guard total > 0 else { return IQColors.commitHeatmapColors[0] }
        let idx = min(total, 4)
        return IQColors.commitHeatmapColors[idx]
    }

    // MARK: - Month labels

    private var monthLabels: some View {
        let cal = Calendar.current
        let labelWidth = cellSize + cellSpacing
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
                    .foregroundStyle(.tertiary)
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Grid body

    private var gridBody: some View {
        HStack(alignment: .top, spacing: cellSpacing) {
            VStack(spacing: cellSpacing) {
                ForEach(0..<7, id: \.self) { i in
                    Text(dayLabels[i])
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .frame(width: cellSize, height: cellSize)
                }
            }

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
        let isTapped = date != nil && tappedDate.map { cal.isDate($0, inSameDayAs: date!) } ?? false
        let count = date.map { appVM.logCountForDate($0) } ?? 0
        let color = cellColor(date: date)
        return RoundedRectangle(cornerRadius: 3)
            .fill(color)
            .frame(width: cellSize, height: cellSize)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(
                        isToday ? IQColors.lavenderDark :
                        isTapped ? IQColors.lavenderDark.opacity(0.6) :
                        Color.clear,
                        lineWidth: isToday ? 1.5 : 1
                    )
            )
            .scaleEffect(isTapped ? 1.35 : 1)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.12), value: appeared)
            .animation(.easeOut(duration: 0.12), value: isTapped)
            .animation(.easeOut(duration: 0.12), value: count)
            .onTapGesture {
                guard let date = date, count > 0 else { return }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation { tappedDate = tappedDate == date ? nil : date }
            }
            .overlay(alignment: .bottom) {
                if isTapped, let date = date {
                    cellPopover(date: date)
                        .offset(y: 36)
                        .zIndex(100)
                        .transition(.scale(scale: 0.8, anchor: .top).combined(with: .opacity))
                }
            }
    }

    private func cellPopover(date: Date) -> some View {
        let (symptoms, food) = countsForDate(date)
        let cal = Calendar.current
        let dayLabel = cal.isDateInToday(date) ? "Today" : date.formatted(.dateTime.month(.abbreviated).day())

        return VStack(spacing: 4) {
            Text(dayLabel)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.primary)
            HStack(spacing: 6) {
                if symptoms > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 7))
                            .foregroundStyle(IQColors.pinkDark)
                        Text("\(symptoms)")
                            .font(.system(size: 8, weight: .bold))
                    }
                }
                if food > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 7))
                            .foregroundStyle(IQColors.lavenderDark)
                        Text("\(food)")
                            .font(.system(size: 8, weight: .bold))
                    }
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 5) {
            Text("Less")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(IQColors.textMuted.opacity(0.9))

            ForEach(0..<IQColors.commitHeatmapColors.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(IQColors.commitHeatmapColors[i])
                    .frame(width: 9, height: 9)
            }

            Text("More")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(IQColors.textMuted.opacity(0.9))

            Spacer()
        }
    }
}

// MARK: - Add Symptom Sheet

struct LogAddSymptomSheet: View {
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: SymptomType = .abdominal_pain
    @State private var severity: Double = 5

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Symptom Type")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(SymptomType.allCases) { type in
                            Button {
                                selectedType = type
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: type.icon)
                                        .font(.system(size: 12))
                                    Text(type.label)
                                        .font(.caption.bold())
                                }
                                .foregroundStyle(selectedType == type ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    selectedType == type ? AnyShapeStyle(IQColors.lavenderDark) : AnyShapeStyle(.ultraThinMaterial),
                                    in: RoundedRectangle(cornerRadius: 10)
                                )
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Severity")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(severity))/10")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                    }
                    Slider(value: $severity, in: 1...10, step: 1)
                        .tint(IQColors.lavenderDark)
                }

                Spacer()
            }
            .padding(16)
            .navigationTitle("Add Symptom")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        appVM.addSymptom(SymptomEntry(type: selectedType, severity: severity))
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

// MARK: - Add Food Sheet

struct LogAddFoodSheet: View {
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var mealType: MealType = .lunch
    @State private var selectedTags: Set<FoodTag> = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                TextField("Food name", text: $name)
                    .padding(12)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))

                Picker("Meal", selection: $mealType) {
                    ForEach(MealType.allCases) { type in
                        Text(type.label).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(FoodTag.allCases) { tag in
                            let selected = selectedTags.contains(tag)
                            Button {
                                if selected { selectedTags.remove(tag) } else { selectedTags.insert(tag) }
                            } label: {
                                Text(tag.label)
                                    .font(.caption.bold())
                                    .foregroundStyle(selected ? .white : .primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        selected ? AnyShapeStyle(IQColors.pinkDark) : AnyShapeStyle(.ultraThinMaterial),
                                        in: RoundedRectangle(cornerRadius: 8)
                                    )
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(16)
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !name.isEmpty else { return }
                        appVM.addFood(FoodEntry(name: name, tags: Array(selectedTags), mealType: mealType))
                        dismiss()
                    }
                    .bold()
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
