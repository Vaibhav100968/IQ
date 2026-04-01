import SwiftUI

// ── DailySummaryCard — Today's 3 stat cards ─────────────────────────────────
struct DailySummaryCard: View {
    let symptomCount: Int
    let mealCount: Int
    let total: Int

    var body: some View {
        HStack(spacing: 10) {
            statCard(value: symptomCount, label: "Symptoms",
                     icon: "waveform.path.ecg", gradient: IQColors.actionSymptoms)
            statCard(value: mealCount, label: "Meals",
                     icon: "fork.knife", gradient: IQColors.actionFood)
            statCard(value: total, label: "Total Logs",
                     icon: "checkmark.circle.fill", gradient: IQColors.actionAnalytics)
        }
    }

    private func statCard(value: Int, label: String,
                          icon: String, gradient: Gradient) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(LinearGradient(gradient: gradient,
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(IQColors.lavenderDark)
            }

            Text("\(value)")
                .font(IQFont.black(22))
                .foregroundColor(IQColors.textPrimary)

            Text(label)
                .font(IQFont.medium(10))
                .foregroundColor(IQColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        )
    }
}
