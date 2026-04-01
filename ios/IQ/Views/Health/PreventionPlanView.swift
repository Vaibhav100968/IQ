import SwiftUI

/// Full prevention plan — opened from Home “See Prevention Plan”.
struct PreventionPlanView: View {
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your plan is based on today’s logs and the on-device model.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                planSection(title: "Today’s focus", icon: "target") {
                    Text(HomeDashboardData.preventionAdvice(appVM: appVM))
                        .font(.body)
                }

                if let p = appVM.mlPrediction, !p.riskFactors.isEmpty {
                    planSection(title: "Address these drivers", icon: "exclamationmark.triangle.fill") {
                        ForEach(p.riskFactors, id: \.self) { f in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 5))
                                    .foregroundStyle(IQColors.pinkVivid)
                                    .padding(.top, 6)
                                Text(f)
                                    .font(.subheadline)
                            }
                        }
                    }
                }

                if let p = appVM.mlPrediction, !p.protectiveFactors.isEmpty {
                    planSection(title: "Keep doing", icon: "checkmark.seal.fill") {
                        ForEach(p.protectiveFactors, id: \.self) { f in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "leaf.fill")
                                    .font(.caption)
                                    .foregroundStyle(IQColors.lavenderVivid)
                                Text(f)
                                    .font(.subheadline)
                            }
                        }
                    }
                }

                planSection(title: "Habits", icon: "repeat") {
                    VStack(alignment: .leading, spacing: 10) {
                        habitRow("Log meals and symptoms the same day they happen.")
                        habitRow("Note sleep and stress when you can — they sharpen predictions.")
                        habitRow("Review Analysis for the full AI simulator and charts.")
                    }
                }

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    appVM.selectedTab = .symptoms
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Open Calendar to log")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(IQColors.lavenderDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(IQColors.lavender.opacity(0.35), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(IQColors.lavender.opacity(0.55), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Color.clear.frame(height: 24)
            }
            .padding(20)
        }
        .background(Color.clear)
        .navigationTitle("Prevention Plan")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { appVM.fetchMLPrediction() }
    }

    private func planSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(IQColors.lavenderDark)
                Text(title)
                    .font(.headline)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .iqVibrantMaterialCard()
    }

    private func habitRow(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.primary)
    }
}
