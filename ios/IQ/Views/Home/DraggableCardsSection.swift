import SwiftUI

// ── Task 1: Today Section — 3 Draggable Cards ────────────────────────────────
struct DraggableCardsSection: View {
    @EnvironmentObject var appVM: AppViewModel

    @State private var cards: [DragCard] = [
        DragCard(icon: "waveform.path.ecg", title: "Log Symptom", subtitle: "Track how you feel", color: Color(hex: "c4458a")),
        DragCard(icon: "fork.knife",        title: "Log Meal",    subtitle: "Record what you ate", color: Color(hex: "5057d5")),
        DragCard(icon: "chart.line.uptrend.xyaxis", title: "View Insights", subtitle: "Check your analytics", color: Color(hex: "16a34a")),
    ]
    @State private var draggingID: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today")
                    .font(IQFont.bold(18))
                    .foregroundColor(IQColors.textPrimary)
                Spacer()
                Text(Date(), style: .date)
                    .font(IQFont.regular(12))
                    .foregroundColor(IQColors.textSecondary)
            }

            VStack(spacing: 10) {
                ForEach(cards) { card in
                    draggableCard(card)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
            )
        }
        .padding(.horizontal, 16)
    }

    private func draggableCard(_ card: DragCard) -> some View {
        let isDragging = draggingID == card.id

        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(card.color.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: card.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(card.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(card.title)
                    .font(IQFont.semibold(14))
                    .foregroundColor(IQColors.textPrimary)
                Text(card.subtitle)
                    .font(IQFont.regular(11))
                    .foregroundColor(IQColors.textMuted)
            }

            Spacer()

            Image(systemName: "line.3.horizontal")
                .font(.system(size: 14))
                .foregroundColor(IQColors.textMuted)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDragging ? IQColors.pink.opacity(0.08) : IQColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isDragging ? IQColors.pinkDark.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .scaleEffect(isDragging ? 1.03 : 1.0)
        .shadow(color: isDragging ? .black.opacity(0.08) : .clear, radius: 8, y: 4)
        .gesture(
            DragGesture()
                .onChanged { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        draggingID = card.id
                    }
                }
                .onEnded { value in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        draggingID = nil
                        // Reorder based on drag direction
                        if let idx = cards.firstIndex(where: { $0.id == card.id }) {
                            let newIdx: Int
                            if value.translation.height > 40 && idx < cards.count - 1 {
                                newIdx = idx + 1
                            } else if value.translation.height < -40 && idx > 0 {
                                newIdx = idx - 1
                            } else {
                                return
                            }
                            cards.move(fromOffsets: IndexSet(integer: idx),
                                       toOffset: newIdx > idx ? newIdx + 1 : newIdx)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }
                }
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                switch card.title {
                case "Log Symptom":  appVM.selectedTab = .symptoms
                case "Log Meal":     appVM.selectedTab = .food
                case "View Insights": appVM.selectedTab = .analytics
                default: break
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.72), value: cards.map(\.id))
    }
}

struct DragCard: Identifiable, Equatable {
    let id = UUID().uuidString
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    static func == (lhs: DragCard, rhs: DragCard) -> Bool { lhs.id == rhs.id }
}
