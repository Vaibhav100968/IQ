import SwiftUI

/// Health tab — quick hub (distinct from Profile account settings).
struct HealthDashboardView: View {
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Track how you feel and what you eat — your health view stays in sync with Today and Analysis.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                hubCard(
                    title: "Flare risk (rule-based)",
                    subtitle: "\(appVM.flareRisk.overallScore)% · \(appVM.flareRisk.level.label)",
                    icon: "gauge.medium",
                    tab: .analytics
                )

                hubCard(
                    title: "Log & calendar",
                    subtitle: "Symptoms, food, flare calendar",
                    icon: "calendar",
                    tab: .symptoms
                )

                NavigationLink {
                    PreventionPlanView()
                        .environmentObject(appVM)
                } label: {
                    hubRow(title: "Prevention plan", subtitle: "Personalized steps from your data", icon: "shield.lefthalf.filled")
                }
                .buttonStyle(.plain)

                hubCard(
                    title: "Content",
                    subtitle: "Articles and courses",
                    icon: "book.fill",
                    tab: .discovery
                )

                Color.clear.frame(height: 24)
            }
            .padding(20)
        }
        .background(Color.clear)
        .navigationTitle("Health")
        .navigationBarTitleDisplayMode(.large)
    }

    private func hubCard(title: String, subtitle: String, icon: String, tab: AppTab) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            appVM.selectedTab = tab
        } label: {
            hubRow(title: title, subtitle: subtitle, icon: icon)
        }
        .buttonStyle(.plain)
    }

    private func hubRow(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(IQColors.lavenderDark)
                .frame(width: 44, height: 44)
                .background(IQColors.lavender.opacity(0.35), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .iqVibrantMaterialCard()
    }
}
