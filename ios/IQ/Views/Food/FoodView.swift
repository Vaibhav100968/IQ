import SwiftUI

// ── FoodView — liquid glass redesign ────────────────────────────────────────
struct FoodView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var showAddSheet = false

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {

                    // ── Header
                    header

                    // ── Meal type chips
                    mealTypeRow

                    // ── Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.4))
                        .frame(height: 0.5)
                        .padding(.horizontal, 16)

                    // ── Entry list
                    if appVM.foods.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 12) {
                            ForEach(appVM.foods.prefix(40)) { entry in
                                FoodEntryRow(entry: entry) {
                                    appVM.deleteFood(id: entry.id)
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }

                    Spacer(minLength: 36)
                }
                .padding(.top, 16)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            FoodEntryForm { entry in appVM.addFood(entry) }
        }
    }

    // ── Header
    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Food Log")
                    .font(IQFont.black(22))
                    .foregroundColor(IQColors.textPrimary)
                Text("\(appVM.todayMealCount) meal\(appVM.todayMealCount == 1 ? "" : "s") logged today")
                    .font(IQFont.regular(13))
                    .foregroundColor(IQColors.textSecondary)
            }
            Spacer()
            // Add button — glass variant
            Button { showAddSheet = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text("Add")
                        .font(IQFont.semibold(14))
                }
                .foregroundColor(IQColors.pinkDark)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(
                    ZStack {
                        Capsule().fill(.ultraThinMaterial)
                        Capsule().fill(IQColors.pink.opacity(0.20))
                        Capsule().stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                    }
                )
            }
        }
        .padding(.horizontal, 16)
    }

    // ── Meal type chips
    private var mealTypeRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MealType.allCases) { meal in
                    mealChip(meal)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
    }

    private func mealChip(_ meal: MealType) -> some View {
        let count = appVM.foods.filter {
            Calendar.current.isDateInToday($0.timestamp) && $0.mealType == meal
        }.count

        return HStack(spacing: 5) {
            Image(systemName: meal.icon)
                .font(.system(size: 11, weight: .medium))
            Text(meal.label)
                .font(IQFont.medium(12))
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 16, height: 16)
                    .background(Circle().fill(IQColors.pinkDark))
            }
        }
        .foregroundColor(IQColors.lavenderDark)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            ZStack {
                Capsule().fill(.ultraThinMaterial)
                Capsule().fill(IQColors.lavender.opacity(0.22))
                Capsule().stroke(Color.white.opacity(0.4), lineWidth: 0.8)
            }
        )
        .shadow(color: IQColors.lavender.opacity(0.2), radius: 4, y: 2)
    }

    // ── Empty state
    private var emptyState: some View {
        VStack(spacing: 14) {
            FrostedIconWell(systemName: "fork.knife", color: IQColors.lavenderDark, size: 56)
            Text("No meals logged yet")
                .font(IQFont.semibold(16))
                .foregroundColor(IQColors.textSecondary)
            Text("Tap Add to log your first meal")
                .font(IQFont.regular(13))
                .foregroundColor(IQColors.textMuted)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - FoodEntryRow (Liquid Glass) ─────────────────────────────────────────

struct FoodEntryRow: View {
    let entry: FoodEntry
    let onDelete: () -> Void

    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {

            // ── Collapsed row
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    expanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {

                    // Frosted icon well
                    FrostedIconWell(
                        systemName: entry.mealType.icon,
                        color: IQColors.lavenderDark
                    )

                    // Name + meta
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.name)
                            .font(IQFont.semibold(14))
                            .foregroundColor(IQColors.textPrimary)
                        HStack(spacing: 5) {
                            Text(entry.mealType.label)
                                .font(IQFont.regular(11))
                                .foregroundColor(IQColors.textMuted)
                            Text("·")
                                .foregroundColor(IQColors.textMuted)
                                .font(.system(size: 9))
                            Text(entry.timestamp, style: .relative)
                                .font(IQFont.regular(11))
                                .foregroundColor(IQColors.textMuted)
                        }
                    }

                    Spacer(minLength: 6)

                    // Up to 2 tag pills
                    HStack(spacing: 4) {
                        ForEach(entry.tags.prefix(2), id: \.self) { tag in
                            FrostedPill(
                                text: tag.label,
                                color: tag.isTrigger ? IQColors.riskHigh : IQColors.riskLow
                            )
                        }
                    }

                    // Chevron
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            // ── Expanded detail
            if expanded {
                // Frosted separator
                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(height: 0.5)
                    .padding(.horizontal, 14)

                VStack(alignment: .leading, spacing: 10) {

                    // All tags
                    if !entry.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(entry.tags, id: \.self) { tag in
                                    FrostedPill(
                                        text: tag.label,
                                        color: tag.isTrigger ? IQColors.riskHigh : IQColors.riskLow
                                    )
                                }
                            }
                        }
                    }

                    // Spice Level
                    if entry.spiceLevel > 0 {
                        metaRow(icon: "flame.fill", label: "Spice", value: String(repeating: "🌶️", count: entry.spiceLevel))
                    }

                    // Notes
                    if let notes = entry.notes, !notes.isEmpty {
                        metaRow(icon: "note.text", label: "Notes", value: notes)
                    }

                    // Timestamp
                    metaRow(
                        icon: "clock",
                        label: "Logged",
                        value: entry.timestamp.formatted(date: .abbreviated, time: .shortened)
                    )

                    // Delete
                    Button(role: .destructive, action: onDelete) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("Delete entry")
                        }
                        .font(IQFont.medium(12))
                        .foregroundColor(.red.opacity(0.75))
                        .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        // ── Liquid glass card
        .liquidGlassCard(cornerRadius: 18, tint: IQColors.lavender)
    }

    private func metaRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(Color.white.opacity(0.55))
                .frame(width: 16)
            Text(label)
                .font(IQFont.medium(11))
                .foregroundColor(Color.white.opacity(0.55))
            Text(value)
                .font(IQFont.regular(12))
                .foregroundColor(IQColors.textPrimary.opacity(0.85))
        }
    }
}

// MARK: - FoodEntryForm (Liquid Glass) ────────────────────────────────────────

struct FoodEntryForm: View {
    let onSave: (FoodEntry) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name        = ""
    @State private var selectedTags: Set<FoodTag> = []
    @State private var mealType    : MealType = .lunch
    @State private var portion     = ""
    @State private var spiceLevel  = 0
    @State private var notes       = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {

                        // ── Food name
                        glassSection(title: "Food Name") {
                            glassTextField("e.g. Grilled Chicken", text: $name)
                        }

                        // ── Meal type
                        glassSection(title: "Meal Type") {
                            HStack(spacing: 8) {
                                ForEach(MealType.allCases) { meal in
                                    mealTypeButton(meal)
                                }
                            }
                        }

                        // ── Food tags
                        glassSection(title: "Food Tags") {
                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible()),
                                          GridItem(.flexible())],
                                spacing: 8
                            ) {
                                ForEach(FoodTag.allCases) { tag in
                                    tagToggle(tag)
                                }
                            }
                        }

                        // ── Spice Level
                        glassSection(title: "Spice Level") {
                            HStack(spacing: 12) {
                                ForEach(0...5, id: \.self) { level in
                                    Button { spiceLevel = level } label: {
                                        VStack(spacing: 4) {
                                            if level == 0 {
                                                Image(systemName: "slash.circle")
                                                    .font(.system(size: 16))
                                                Text("None")
                                                    .font(.system(size: 9))
                                            } else {
                                                Image(systemName: "flame.fill")
                                                    .font(.system(size: 16))
                                                Text("\(level)")
                                                    .font(.system(size: 9))
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(spiceLevel == level ? IQColors.pink.opacity(0.3) : Color.white.opacity(0.05))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(spiceLevel == level ? IQColors.pinkDark : Color.white.opacity(0.1), lineWidth: 1)
                                                )
                                        )
                                        .foregroundColor(spiceLevel == level ? IQColors.pinkDark : IQColors.textMuted)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // ── Optional fields
                        glassSection(title: "Optional Details") {
                            VStack(spacing: 10) {
                                glassTextField("Portion size (e.g. 1 cup)", text: $portion)
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 0.5)
                                glassTextField("Notes", text: $notes)
                            }
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(16)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Log Food")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(IQColors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !name.isEmpty else { return }
                        onSave(FoodEntry(
                            name: name,
                            tags: Array(selectedTags),
                            mealType: mealType,
                            portionSize: portion.isEmpty ? nil : portion,
                            spiceLevel: spiceLevel,
                            notes: notes.isEmpty ? nil : notes
                        ))
                        dismiss()
                    }
                    .bold()
                    .foregroundColor(name.isEmpty ? IQColors.textMuted : IQColors.pinkDark)
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    // ── Glass section container
    private func glassSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(IQColors.textMuted)
                .kerning(0.8)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content()
            }
            .padding(14)
            .liquidGlassCard(cornerRadius: 16, tint: IQColors.lavender)
        }
    }

    // ── Glass text field
    private func glassTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(IQFont.regular(15))
            .foregroundColor(IQColors.textPrimary)
            .tint(IQColors.pinkDark)
    }

    // ── Meal type selector button
    private func mealTypeButton(_ meal: MealType) -> some View {
        let selected = mealType == meal
        return Button { mealType = meal } label: {
            VStack(spacing: 5) {
                Image(systemName: meal.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(selected ? IQColors.pinkDark : IQColors.textMuted)
                Text(meal.label)
                    .font(.system(size: 10, weight: selected ? .semibold : .regular))
                    .foregroundColor(selected ? IQColors.pinkDark : IQColors.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selected ? IQColors.pink.opacity(0.25) : Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            selected ? IQColors.pinkDark.opacity(0.45) : Color.white.opacity(0.2),
                            lineWidth: selected ? 1 : 0.6
                        )
                }
            )
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: selected)
        }
        .buttonStyle(.plain)
    }

    // ── Tag toggle
    private func tagToggle(_ tag: FoodTag) -> some View {
        let sel = selectedTags.contains(tag)
        let accent: Color = tag == .safe_food ? IQColors.riskLow : IQColors.riskHigh
        return Button {
            if sel { selectedTags.remove(tag) } else { selectedTags.insert(tag) }
        } label: {
            HStack(spacing: 5) {
                if sel {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(accent)
                }
                Text(tag.label)
                    .font(.system(size: 11, weight: sel ? .semibold : .regular))
                    .foregroundColor(sel ? accent : IQColors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(sel ? accent.opacity(0.12) : Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(sel ? accent.opacity(0.45) : Color.white.opacity(0.2), lineWidth: sel ? 0.9 : 0.6)
                }
            )
            .animation(.spring(response: 0.18, dampingFraction: 0.8), value: sel)
        }
        .buttonStyle(.plain)
    }
}
