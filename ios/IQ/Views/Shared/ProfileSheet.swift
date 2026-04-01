import SwiftUI

// ── Task 6: Profile Sheet — shows user tags and info ──────────────────────────
struct ProfileSheet: View {
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(
                                IQColors.pink
                            )
                            .frame(width: 80, height: 80)
                        Text(initials)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(IQColors.pinkDark)
                    }
                    .padding(.top, 12)

                    Text(appVM.profile?.name ?? "Guest User")
                        .font(IQFont.bold(20))
                        .foregroundColor(IQColors.textPrimary)

                    if AuthService.shared.isGuest {
                        Text("Guest Mode")
                            .font(IQFont.regular(12))
                            .foregroundColor(IQColors.textMuted)
                    }

                    Divider()

                    // Profile tags
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Profile")
                            .font(IQFont.semibold(14))
                            .foregroundColor(IQColors.textSecondary)

                        if let p = appVM.profile {
                            profileRow(icon: "heart.text.square.fill", label: "Condition", value: p.conditionType.label)
                            profileRow(icon: "gauge.medium", label: "Severity", value: p.severity.label)
                            profileRow(icon: "calendar", label: "Symptoms Logged", value: "\(appVM.symptoms.count)")
                            profileRow(icon: "fork.knife", label: "Meals Logged", value: "\(appVM.foods.count)")
                        }
                    }
                    .padding(.horizontal, 16)

                    // Known triggers
                    if let triggers = appVM.profile?.knownTriggers, !triggers.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Known Triggers")
                                .font(IQFont.semibold(14))
                                .foregroundColor(IQColors.textSecondary)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(triggers, id: \.self) { tag in
                                    Text(tag.label)
                                        .font(IQFont.medium(11))
                                        .foregroundColor(IQColors.riskHigh)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(IQColors.riskHighBg.opacity(0.5))
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // All app tabs
                    VStack(alignment: .leading, spacing: 10) {
                        Text("App Sections")
                            .font(IQFont.semibold(14))
                            .foregroundColor(IQColors.textSecondary)

                        ForEach(AppTab.primaryTabs, id: \.self) { tab in
                            HStack(spacing: 12) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(IQColors.lavenderDark)
                                    .frame(width: 24)
                                Text(tab.title)
                                    .font(IQFont.medium(14))
                                    .foregroundColor(IQColors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(IQColors.textMuted)
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(IQColors.background))
                            .onTapGesture {
                                appVM.selectTab(tab)
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Sign out
                    Button {
                        AuthService.shared.signOut()
                        appVM.onboardingCompleted = false
                        dismiss()
                    } label: {
                        Text("Sign Out")
                            .font(IQFont.medium(14))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.08))
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    Spacer(minLength: 32)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(IQColors.lavenderDark)
                }
            }
        }
    }

    private var initials: String {
        let name = appVM.profile?.name ?? "?"
        return String(name.prefix(2).uppercased())
    }

    private func profileRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(IQColors.pinkDark)
                .frame(width: 20)
            Text(label)
                .font(IQFont.medium(13))
                .foregroundColor(IQColors.textSecondary)
            Spacer()
            Text(value)
                .font(IQFont.semibold(13))
                .foregroundColor(IQColors.textPrimary)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(IQColors.background))
    }
}
