import SwiftUI

// ── OnboardingView — Auth → Crohn's Survey → Profile → Triggers → Summary ────
struct OnboardingView: View {
    @EnvironmentObject var appVM: AppViewModel

    @State private var step: Int = 0
    @State private var name: String = ""
    @State private var conditionType: UserProfile.ConditionType = .crohns
    @State private var severity: UserProfile.ConditionSeverity = .moderate
    @State private var selectedTriggers: Set<FoodTag> = []

    // Auth state
    @State private var authEmail: String = ""
    @State private var authPassword: String = ""
    @State private var showEmailForm: Bool = false
    @State private var authError: String = ""
    @State private var isAuthLoading: Bool = false

    // Crohn's survey
    @State private var isDiagnosed: Bool = true

    private let totalSteps = 4

    var body: some View {
        ZStack {
            IQColors.appCanvasGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if step > 0 {
                    progressDots.padding(.top, 60).padding(.bottom, 8)
                }

                Group {
                    switch step {
                    case 0: authStep
                    case 1: diagnosisStep
                    case 2: profileStep
                    case 3: triggersStep
                    case 4: summaryStep
                    default: EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
            }
        }
    }

    // ── Progress dots ─────────────────────────────────────────────────────────
    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(1..<totalSteps, id: \.self) { i in
                Circle()
                    .fill(step >= i ? IQColors.pinkDark : Color.white.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .scaleEffect(step == i ? 1.2 : 1)
                    .animation(.spring(response: 0.3), value: step)
            }
        }
    }

    // ── Step 0: Authentication ─────────────────────────────────────────────────
    private var authStep: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            ZStack {
                Circle()
                    .fill(IQColors.pink)
                    .frame(width: 100, height: 100)
                    .shadow(color: IQColors.pink.opacity(0.3), radius: 20)
                Text("IQ")
                    .font(.system(size: 38, weight: .black))
                    .foregroundColor(.black)
            }
            .padding(.bottom, 20)

            Text("Gut Intelligence")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(IQColors.textPrimary)
            Text("Your personal Crohn’s management companion")
                .font(IQFont.regular(15))
                .foregroundColor(IQColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 6)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                // Google Sign-In
                Button {
                    Task {
                        isAuthLoading = true
                        do {
                            try await AuthService.shared.signInWithGoogle()
                            withAnimation { step = 1 }
                        } catch {
                            authError = error.localizedDescription
                        }
                        isAuthLoading = false
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "globe")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Continue with Google")
                            .font(IQFont.semibold(15))
                    }
                    .foregroundColor(IQColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    )
                }

                // Email toggle
                Button {
                    withAnimation { showEmailForm.toggle() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                        Text(showEmailForm ? "Hide email form" : "Continue with Email")
                            .font(IQFont.medium(14))
                    }
                    .foregroundColor(IQColors.lavenderDark)
                }

                if showEmailForm {
                    emailForm
                }

                if !authError.isEmpty {
                    Text(authError)
                        .font(IQFont.regular(12))
                        .foregroundColor(IQColors.riskHigh)
                        .multilineTextAlignment(.center)
                }

                Divider().padding(.horizontal, 8)

                Button("Continue as Guest") {
                    AuthService.shared.continueAsGuest()
                    withAnimation { step = 1 }
                }
                .font(IQFont.medium(13))
                .foregroundColor(IQColors.textMuted)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    private var emailForm: some View {
        VStack(spacing: 10) {
            TextField("Email", text: $authEmail)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(IQColors.border))

            SecureField("Password", text: $authPassword)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(IQColors.border))

            HStack(spacing: 10) {
                authEmailButton(label: "Sign In") {
                    try await AuthService.shared.signIn(email: authEmail, password: authPassword)
                }
                authEmailButton(label: "Sign Up") {
                    try await AuthService.shared.signUp(email: authEmail, password: authPassword)
                }
            }
        }
    }

    private func authEmailButton(label: String, action: @escaping () async throws -> Void) -> some View {
        Button {
            guard !authEmail.trimmingCharacters(in: .whitespaces).isEmpty,
                  !authPassword.isEmpty else {
                authError = "Please enter your email and password."
                return
            }
            guard authPassword.count >= 6 else {
                authError = "Password must be at least 6 characters."
                return
            }
            Task {
                isAuthLoading = true
                authError = ""
                do {
                    try await action()
                    withAnimation { step = 1 }
                } catch {
                    authError = error.localizedDescription
                }
                isAuthLoading = false
            }
        } label: {
            Group {
                if isAuthLoading {
                    ProgressView().tint(.black)
                } else {
                    Text(label).font(IQFont.semibold(14)).foregroundColor(.black)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(IQColors.pink)
            )
        }
    }

    // ── Step 1: Crohn's diagnosis survey ──────────────────────────────────────
    private var diagnosisStep: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 28) {
                stepHeader(title: "Your Diagnosis",
                           subtitle: "This helps us personalize your AI predictions")

                VStack(spacing: 12) {
                    Text("Have you been diagnosed with Crohn’s disease?")
                        .font(IQFont.medium(15))
                        .foregroundColor(IQColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    HStack(spacing: 12) {
                        diagnosisOption(label: "Yes, I have Crohn’s", icon: "checkmark.circle.fill",
                                        selected: isDiagnosed) { isDiagnosed = true }
                        diagnosisOption(label: "No / Just Exploring", icon: "questionmark.circle.fill",
                                        selected: !isDiagnosed) { isDiagnosed = false }
                    }
                }

                if !isDiagnosed {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(IQColors.lavenderDark)
                        Text("Personalized AI predictions require a diagnosis. You can still explore general insights.")
                            .font(IQFont.regular(12))
                            .foregroundColor(IQColors.textSecondary)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(IQColors.lavender.opacity(0.3)))
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            nextButton("Continue") { withAnimation { step = 2 } }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
        }
    }

    private func diagnosisOption(label: String, icon: String, selected: Bool,
                                  action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(selected ? IQColors.pinkDark : IQColors.textMuted)
                Text(label)
                    .font(IQFont.medium(13))
                    .foregroundColor(selected ? IQColors.textPrimary : IQColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(selected ? IQColors.pink.opacity(0.2) : Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(selected ? IQColors.pinkDark.opacity(0.4) : IQColors.border, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2), value: selected)
    }

    // ── Step 2: Name + Condition + Severity ────────────────────────────────────
    private var profileStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                stepHeader(title: "Your Profile",
                           subtitle: "Tell us about your condition for personalized tracking")

                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Name").font(IQFont.semibold(13)).foregroundColor(IQColors.textSecondary)
                    TextField("Enter your name", text: $name)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(IQColors.border))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Condition Type").font(IQFont.semibold(13)).foregroundColor(IQColors.textSecondary)
                    VStack(spacing: 8) {
                        ForEach(UserProfile.ConditionType.allCases, id: \.self) { ct in
                            toggleRow(label: ct.label, selected: conditionType == ct) {
                                conditionType = ct
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Condition Severity").font(IQFont.semibold(13)).foregroundColor(IQColors.textSecondary)
                    HStack(spacing: 8) {
                        ForEach(UserProfile.ConditionSeverity.allCases, id: \.self) { sev in
                            Button { severity = sev } label: {
                                Text(sev.label)
                                    .font(IQFont.semibold(13))
                                    .foregroundColor(severity == sev ? .black : IQColors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(severity == sev ? IQColors.pink : Color.white)
                                    )
                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(IQColors.border, lineWidth: severity == sev ? 0 : 1))
                            }
                        }
                    }
                }

                nextButton("Continue") { withAnimation { step = 3 } }
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }

    // ── Step 3: Known triggers ─────────────────────────────────────────────────
    private var triggersStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                stepHeader(title: "Known Triggers",
                           subtitle: "Select foods and factors that trigger your symptoms")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(triggerTags, id: \.self) { tag in triggerChip(tag: tag) }
                }

                nextButton("Continue") { withAnimation { step = 4 } }
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }

    private func triggerChip(tag: FoodTag) -> some View {
        let selected = selectedTriggers.contains(tag)
        return Button {
            if selected { selectedTriggers.remove(tag) } else { selectedTriggers.insert(tag) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selected ? IQColors.pinkDark : IQColors.textMuted)
                Text(tag.label)
                    .font(IQFont.medium(13))
                    .foregroundColor(selected ? IQColors.textPrimary : IQColors.textSecondary)
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selected ? IQColors.pink.opacity(0.2) : Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(selected ? IQColors.pinkDark.opacity(0.4) : IQColors.border, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2), value: selected)
    }

    // ── Step 4: Summary ────────────────────────────────────────────────────────
    private var summaryStep: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.black)

                Text("You're all set\(name.isEmpty ? "" : ", \(name)")!")
                    .font(IQFont.black(24))
                    .foregroundColor(IQColors.textPrimary)

                Text(isDiagnosed
                     ? "Start logging to get AI-powered personalized flare predictions."
                     : "Explore general gut health insights in guest mode.")
                    .font(IQFont.regular(14))
                    .foregroundColor(IQColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                VStack(spacing: 8) {
                    summaryChip(icon: "heart.text.square.fill", text: conditionType.label)
                    summaryChip(icon: "gauge.medium", text: "\(severity.label) severity")
                    if !selectedTriggers.isEmpty {
                        summaryChip(icon: "exclamationmark.triangle.fill",
                                    text: "\(selectedTriggers.count) known triggers identified")
                    }
                    if !isDiagnosed {
                        summaryChip(icon: "person.fill.questionmark", text: "Guest exploration mode")
                    }
                }
                .padding(.horizontal, 24)
            }
            Spacer()

            nextButton("Start Tracking") {
                let p = UserProfile(
                    name: name,
                    conditionType: conditionType,
                    severity: severity,
                    knownTriggers: Array(selectedTriggers),
                    onboardingCompleted: true
                )
                appVM.saveProfile(p)
                if !AuthService.shared.isAuthenticated {
                    AuthService.shared.continueAsGuest()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    private func summaryChip(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(IQColors.pinkDark)
            Text(text).font(IQFont.medium(13)).foregroundColor(IQColors.textPrimary)
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2))
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(spacing: 6) {
            Text(title).font(IQFont.black(26)).foregroundColor(IQColors.textPrimary)
            Text(subtitle).font(IQFont.regular(14)).foregroundColor(IQColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private func toggleRow(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label).font(IQFont.medium(14))
                    .foregroundColor(selected ? IQColors.pinkDark : IQColors.textPrimary)
                Spacer()
                if selected { Image(systemName: "checkmark.circle.fill").foregroundColor(IQColors.pinkDark) }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selected ? IQColors.pink.opacity(0.2) : Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(selected ? IQColors.pinkDark.opacity(0.4) : IQColors.border, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2), value: selected)
    }

    private func nextButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(IQFont.bold(16)).foregroundColor(.black)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(IQColors.pink)
                        .shadow(color: IQColors.pink.opacity(0.3), radius: 8, y: 4)
                )
        }
    }
}
