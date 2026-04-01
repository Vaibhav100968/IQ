import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                avatarSection
                    .padding(.top, 8)

                statsSection

                conditionSection

                if let triggers = appVM.profile?.knownTriggers, !triggers.isEmpty {
                    triggersSection(triggers)
                }

                signOutButton
                    .padding(.top, 8)

                Color.clear.frame(height: 24)
            }
            .padding(.horizontal, 16)
        }
        .background(Color.clear)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(IQColors.lavenderVivid.opacity(0.38))
                    .frame(width: 80, height: 80)
                    .overlay(Circle().strokeBorder(IQColors.pinkVivid.opacity(0.45), lineWidth: 1.5))
                Text(initials)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(IQColors.lavenderDark)
            }
            Text(appVM.profile?.name ?? "Guest User")
                .font(.title2.bold())
            if AuthService.shared.isGuest {
                Text("Guest Mode")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(.secondarySystemBackground), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 12) {
            statCard(value: "\(appVM.symptoms.count)", label: "Symptoms", icon: "waveform.path.ecg")
            statCard(value: "\(appVM.foods.count)", label: "Meals", icon: "fork.knife")
            statCard(value: "\(PersonalizationService.shared.daysLogged)", label: "Days", icon: "calendar")
        }
    }

    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(IQColors.lavenderDark)
                .symbolRenderingMode(.hierarchical)
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .iqVibrantMaterialCard(cornerRadius: 12)
    }

    // MARK: - Condition

    private var conditionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Condition")
                .font(.title3.bold())

            if let p = appVM.profile {
                profileRow(icon: "heart.text.square.fill", label: "Type", value: p.conditionType.label)
                profileRow(icon: "gauge.medium", label: "Severity", value: p.severity.label)
            }
        }
    }

    private func profileRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(IQColors.lavenderDark)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
        .padding(12)
        .iqVibrantMaterialCard(cornerRadius: 12)
    }

    // MARK: - Triggers

    private func triggersSection(_ triggers: [FoodTag]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Known Triggers")
                .font(.title3.bold())
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(triggers, id: \.self) { tag in
                    Text(tag.label)
                        .font(.caption.bold())
                        .foregroundStyle(IQColors.riskHigh)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(IQColors.riskHighBg.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    // MARK: - Sign Out

    private var signOutButton: some View {
        Button {
            AuthService.shared.signOut()
            appVM.onboardingCompleted = false
        } label: {
            Text("Sign Out")
                .font(.subheadline.bold())
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var initials: String {
        let name = appVM.profile?.name ?? "?"
        return String(name.prefix(2).uppercased())
    }
}
