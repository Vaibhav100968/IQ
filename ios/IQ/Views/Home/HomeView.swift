import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var greetingClock = Date()
    @State private var scenarioBlurb: String = "Tune sleep and triggers to see how tomorrow’s risk shifts — try the simulator in Analysis."
    @State private var pickedDay: HomePickedDay?
    @State private var showPreventionPlan = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    greetingBlock
                        .padding(.top, 8)

                    if appVM.preFlare.detected {
                        preFlareCard
                    }

                    HomeTodayGutStatusCard(
                        onViewDetails: { appVM.selectTab(.analytics) },
                        onPickDay: { pickedDay = HomePickedDay($0) }
                    )
                    .environmentObject(appVM)

                    circleSection

                    HomeRiskDriversSection(drivers: HomeDashboardData.riskDrivers(from: appVM.mlPrediction))

                    HomePreventionCard(
                        advice: HomeDashboardData.preventionAdvice(appVM: appVM),
                        onSeePlan: { showPreventionPlan = true }
                    )

                    HomeGutTimelineSection(onPickDay: { pickedDay = HomePickedDay($0) })
                        .environmentObject(appVM)

                    HomeSmartInsightsSection(lines: HomeDashboardData.personalizedInsights(appVM: appVM))

                    HomeScenarioCard(line: scenarioBlurb) {
                        appVM.selectTab(.analytics)
                    }

                    HomeLearnMoreRow { appVM.selectTab(.discovery) }

                    HomeLogQuickSection()
                        .environmentObject(appVM)

                    HomeQuoteCard()

                    Color.clear.frame(height: 88)
                }
                .padding(.horizontal, 16)
            }

            HomeFloatingLogFAB()
                .environmentObject(appVM)
                .padding(.trailing, 20)
                .padding(.bottom, 12)
        }
        .background(Color.clear)
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    appVM.assistantPresented = true
                } label: {
                    Image(systemName: "sparkles")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(IQColors.lavenderDark)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(IQColors.lavender.opacity(0.5), lineWidth: 1))
                        .shadow(color: IQColors.lavenderDark.opacity(0.18), radius: 8, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open AI assistant")
            }
        }
        .navigationDestination(isPresented: $showPreventionPlan) {
            PreventionPlanView()
                .environmentObject(appVM)
        }
        .onAppear {
            appVM.fetchMLPrediction()
            refreshScenario()
        }
        .onChange(of: appVM.mlPrediction?.riskPercent) { _ in refreshScenario() }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            greetingClock = Date()
        }
        .sheet(item: $pickedDay) { item in
            HomeDayDetailSheet(date: item.date)
                .environmentObject(appVM)
                .presentationDetents([.medium])
        }
    }

    private func refreshScenario() {
        scenarioBlurb = HomeDashboardData.scenarioLine(appVM: appVM)
    }

    // MARK: - Greeting

    private var greetingBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greetingLine)
                .font(.title2.bold())
                .foregroundStyle(.primary)
            Text("Here’s your gut status today")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greetingLine: String {
        _ = greetingClock
        let hour = Calendar.current.component(.hour, from: Date())
        let prefix: String
        if hour < 12 { prefix = "Good Morning" }
        else if hour < 17 { prefix = "Good Afternoon" }
        else { prefix = "Good Evening" }

        if AuthService.shared.isGuest {
            return "\(prefix), Guest"
        }
        let raw = (appVM.profile?.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.isEmpty {
            return prefix
        }
        let firstToken = raw.split(whereSeparator: { $0.isWhitespace }).first.map(String.init) ?? raw
        let firstName = String(firstToken).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let ch = firstName.first else { return prefix }
        let capitalized = String(ch).uppercased() + firstName.dropFirst().lowercased()
        return "\(prefix), \(capitalized)"
    }

    // MARK: - Circle (hero)

    private var circleSection: some View {
        VStack(spacing: 10) {
            CircularRiskDisk(risk: appVM.flareRisk, mlPrediction: appVM.mlPrediction)
                .frame(maxWidth: .infinity)
            RiskScoreFootnote(style: .homeDisk)
                .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Pre-flare

    private var preFlareCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(IQColors.pinkVivid)
                .symbolRenderingMode(.hierarchical)
            VStack(alignment: .leading, spacing: 2) {
                Text("Pre-Flare Pattern Detected")
                    .font(.subheadline.bold())
                Text("Confidence: \(appVM.preFlare.confidence)%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(IQColors.pinkVivid.opacity(0.22))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(IQColors.pinkVivid.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: 6)
        .shadow(color: IQColors.pinkVivid.opacity(0.14), radius: 18, x: 0, y: 0)
    }
}

// MARK: - Sheet tag

struct HomePickedDay: Identifiable {
    let id: TimeInterval
    let date: Date
    init(_ date: Date) {
        self.date = date
        self.id = date.timeIntervalSince1970
    }
}

// MARK: - Folder Card (other screens)

struct FolderCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.black.opacity(0.6))
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .iqVibrantMaterialCard()
        }
        .buttonStyle(CardPressStyle())
    }
}

struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
