import SwiftUI

// ── QuickActionsView — stacked deck that fans out on tap ────────────────────
// Two-phase (stacked → spread), Y-only offset. No blur.

private struct ActionItem: Identifiable {
    let id: AppTab
    let title: String
    let subtitle: String
    let icon: String
    let gradient: Gradient
}

private let actions: [ActionItem] = [
    ActionItem(id: .analytics, title: "Analytics",
               subtitle: "View symptom trends", icon: "chart.line.uptrend.xyaxis",
               gradient: IQColors.actionAnalytics),
    ActionItem(id: .calendar,  title: "Calendar",
               subtitle: "View your log history", icon: "calendar",
               gradient: IQColors.actionCalendar),
    ActionItem(id: .food,      title: "Food Log",
               subtitle: "Track what you eat", icon: "fork.knife",
               gradient: IQColors.actionFood),
    ActionItem(id: .symptoms,  title: "Log Symptoms",
               subtitle: "Record how you feel", icon: "waveform.path.ecg",
               gradient: IQColors.actionSymptoms),
]

// Dim opacity per card in stacked mode (0 = back, 3 = front / fully visible)
private let stackDim: [Int: Double] = [0: 0.50, 1: 0.30, 2: 0.12, 3: 0]

struct QuickActionsView: View {
    @EnvironmentObject var appVM: AppViewModel

    @State private var expanded = false

    // Container height adapts to phase
    private var containerHeight: CGFloat {
        expanded ? CGFloat(actions.count) * 74 : 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // ── Section header
            HStack {
                Text("Quick Actions")
                    .font(IQFont.bold(18))
                    .foregroundColor(IQColors.textPrimary)

                Spacer()

                if expanded {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                            expanded = false
                        }
                    } label: {
                        Text("Collapse")
                            .font(IQFont.medium(12))
                            .foregroundColor(IQColors.lavenderDark)
                    }
                } else {
                    Text("Tap to expand")
                        .font(IQFont.regular(11))
                        .foregroundColor(IQColors.textMuted)
                }
            }
            .padding(.horizontal, 16)

            // ── Card stack
            ZStack(alignment: .top) {
                ForEach(Array(actions.enumerated()), id: \.element.id) { idx, action in
                    actionCard(action, index: idx)
                        .offset(y: expanded ? CGFloat(idx) * 74 : CGFloat(idx) * 12)
                        .zIndex(Double(actions.count - idx))
                }
            }
            .frame(height: containerHeight)
            .clipped()
            .contentShape(Rectangle())
            .onTapGesture {
                guard !expanded else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                    expanded = true
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.72), value: expanded)
        }
    }

    // ── Single action card
    private func actionCard(_ action: ActionItem, index: Int) -> some View {
        Button {
            guard expanded else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                appVM.selectedTab = action.id
            }
        } label: {
            HStack(spacing: 14) {
                // Icon badge
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(gradient: action.gradient,
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: action.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(IQColors.lavenderDark)
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(action.title)
                        .font(IQFont.semibold(14))
                        .foregroundColor(IQColors.textPrimary)
                    Text(action.subtitle)
                        .font(IQFont.regular(11))
                        .foregroundColor(IQColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(IQColors.textMuted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
            )
            // Stacked dim overlay — sharp, no blur
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        Color.white.opacity(expanded ? 0 : (stackDim[index] ?? 0))
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!expanded)
        .padding(.horizontal, 16)
    }
}
