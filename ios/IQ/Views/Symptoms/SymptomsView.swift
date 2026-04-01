import SwiftUI

// ── SymptomsView — mirrors symptoms/page.tsx ────────────────────────────────
struct SymptomsView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var showAddSheet = false
    @State private var selectedType: SymptomType? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {

                // ── Page header
                pageHeader

                // ── Symptom type grid (log new)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Log a Symptom")
                        .font(IQFont.semibold(13))
                        .foregroundColor(IQColors.textSecondary)
                        .padding(.horizontal, 16)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()),
                                        GridItem(.flexible())], spacing: 10) {
                        ForEach(SymptomType.allCases) { type in
                            typeChip(type)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Divider().padding(.horizontal, 16)

                // ── Recent entries
                if appVM.symptoms.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recent Entries")
                            .font(IQFont.semibold(13))
                            .foregroundColor(IQColors.textSecondary)
                            .padding(.horizontal, 16)

                        ForEach(appVM.symptoms.prefix(30)) { entry in
                            SymptomCard(entry: entry) {
                                appVM.deleteSymptom(id: entry.id)
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }

                Spacer(minLength: 32)
            }
            .padding(.top, 16)
        }
        .background(IQColors.background.ignoresSafeArea())
        .sheet(item: $selectedType) { type in
            AddSymptomSheet(type: type) { entry in
                appVM.addSymptom(entry)
            }
        }
    }

    // ── Page header
    private var pageHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Symptoms")
                    .font(IQFont.black(22))
                    .foregroundColor(IQColors.textPrimary)
                Text("\(appVM.todaySymptomCount) logged today")
                    .font(IQFont.regular(13))
                    .foregroundColor(IQColors.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // ── Type chip
    private func typeChip(_ type: SymptomType) -> some View {
        Button { selectedType = type } label: {
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 18))
                    .foregroundColor(.black.opacity(0.6))
                Text(type.label)
                    .font(IQFont.medium(10))
                    .foregroundColor(IQColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // ── Empty state
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 40))
                .foregroundColor(IQColors.textMuted)
            Text("No symptoms logged yet")
                .font(IQFont.semibold(16))
                .foregroundColor(IQColors.textSecondary)
            Text("Tap a symptom above to start tracking")
                .font(IQFont.regular(13))
                .foregroundColor(IQColors.textMuted)
        }
        .padding(.vertical, 32)
    }
}

// ── SymptomCard ──────────────────────────────────────────────────────────────
struct SymptomCard: View {
    let entry: SymptomEntry
    let onDelete: () -> Void

    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Row
            Button { withAnimation(.spring(response: 0.3)) { expanded.toggle() } } label: {
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(severityBg)
                            .frame(width: 38, height: 38)
                        Image(systemName: entry.type.icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(severityColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.type.label)
                            .font(IQFont.semibold(14))
                            .foregroundColor(IQColors.textPrimary)
                        Text(entry.timestamp, style: .relative)
                            .font(IQFont.regular(11))
                            .foregroundColor(IQColors.textMuted)
                    }

                    Spacer()

                    // Severity badge
                    Text("\(Int(entry.severity))/10")
                        .font(IQFont.bold(13))
                        .foregroundColor(severityColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(severityBg))

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(IQColors.textMuted)
                }
                .padding(12)
            }
            .buttonStyle(.plain)

            // Expanded notes + delete
            if expanded {
                Divider().padding(.horizontal, 12)

                VStack(alignment: .leading, spacing: 8) {
                    if let notes = entry.notes, !notes.isEmpty {
                        Text(notes)
                            .font(IQFont.regular(13))
                            .foregroundColor(IQColors.textSecondary)
                    }

                    Text(entry.timestamp.formatted(date: .long, time: .shortened))
                        .font(IQFont.regular(11))
                        .foregroundColor(IQColors.textMuted)

                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                            .font(IQFont.medium(12))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
        )
    }

    private var severityColor: Color {
        if entry.severity <= 3 { return IQColors.riskLow }
        if entry.severity <= 6 { return IQColors.riskModerate }
        return IQColors.riskHigh
    }

    private var severityBg: Color {
        if entry.severity <= 3 { return IQColors.riskLowBg }
        if entry.severity <= 6 { return IQColors.riskModerateBg }
        return IQColors.riskHighBg
    }
}

// ── AddSymptomSheet ──────────────────────────────────────────────────────────
struct AddSymptomSheet: View {
    let type: SymptomType
    let onSave: (SymptomEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var severity: Double = 5
    @State private var notes: String = ""

    private func severityLabel(_ v: Double) -> String {
        if v <= 3 { return "Mild" }
        if v <= 6 { return "Moderate" }
        return "Severe"
    }

    private func severityColor(_ v: Double) -> Color {
        if v <= 3 { return IQColors.riskLow }
        if v <= 6 { return IQColors.riskModerate }
        return IQColors.riskHigh
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Symptom") {
                    HStack {
                        Image(systemName: type.icon)
                            .foregroundColor(IQColors.pinkDark)
                        Text(type.label)
                            .font(IQFont.semibold(15))
                    }
                }

                Section("Severity: \(Int(severity))/10") {
                    VStack(spacing: 4) {
                        HStack {
                            Text("Mild").font(IQFont.regular(11)).foregroundColor(IQColors.riskLow)
                            Spacer()
                            Text(severityLabel(severity))
                                .font(IQFont.bold(16))
                                .foregroundColor(severityColor(severity))
                            Spacer()
                            Text("Severe").font(IQFont.regular(11)).foregroundColor(IQColors.riskHigh)
                        }

                        // iOS Clock-style wheel picker (Task 7)
                        Picker("Severity", selection: Binding(
                            get: { Int(severity) },
                            set: { severity = Double($0) }
                        )) {
                            ForEach(1...10, id: \.self) { value in
                                Text("\(value)")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                }

                Section("Notes (optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Log \(type.label)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(SymptomEntry(type: type, severity: severity,
                                            notes: notes.isEmpty ? nil : notes))
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}
