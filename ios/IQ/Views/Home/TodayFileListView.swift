import SwiftUI

// TODO: IMPORT SDK HERE
// Replace with actual SDK import when available
// Example: import YourSDKName

// ── TodayFileListView — Folder expands to reveal file tabs as navigation ─────
struct TodayFileListView: View {
    @EnvironmentObject var appVM: AppViewModel

    @State private var folderIsOpen = false
    @State private var showAssistantSheet = false
    @State private var showProfileSheet = false

    // TODO: USE SDK DATA HERE
    // Replace this mock data with SDK-provided file list
    // Example:
    //   let files = sdk.getFiles()
    //   let files = SDKManager.shared.fetchSections()
    //   let files = sdkFolder.files
    private let files: [AppFileItem] = [
        AppFileItem(
            name: "Home",
            icon: "house.fill",
            color: Color(hex: "5057d5"),
            description: "Dashboard & health overview",
            subSections: ["Flare Risk Score", "Daily Summary", "Health Trends"],
            tab: .home
        ),
        AppFileItem(
            name: "Symptoms",
            icon: "waveform.path.ecg",
            color: Color(hex: "c4458a"),
            description: "Track and monitor symptoms",
            subSections: ["Log Symptom", "Symptom History", "Severity Trends"],
            tab: .symptoms
        ),
        AppFileItem(
            name: "Food",
            icon: "fork.knife",
            color: Color(hex: "e67e22"),
            description: "Food diary & trigger tracking",
            subSections: ["Log Meal", "Food Diary", "Trigger Foods"],
            tab: .food
        ),
        AppFileItem(
            name: "Activity",
            icon: "calendar",
            color: Color(hex: "16a34a"),
            description: "Daily activity & exercise log",
            subSections: ["Daily Activity", "Exercise Log", "Sleep Tracking"],
            tab: .calendar
        ),
        AppFileItem(
            name: "Analytics",
            icon: "chart.line.uptrend.xyaxis",
            color: Color(hex: "8b5cf6"),
            description: "Insights & risk analysis",
            subSections: ["Risk Trends", "Correlations", "ML Predictions"],
            tab: .analytics
        ),
        AppFileItem(
            name: "Discover",
            icon: "sparkles",
            color: Color(hex: "0ea5e9"),
            description: "Learn about your condition",
            subSections: ["Articles", "Insights", "Quick Learn"],
            tab: .discovery
        ),
        AppFileItem(
            name: "Assistant",
            icon: "bubble.left.and.bubble.right.fill",
            color: Color(hex: "0ea5e9"),
            description: "AI-powered health assistant",
            subSections: ["Chat", "Health Tips", "Recommendations"],
            tab: nil
        ),
        AppFileItem(
            name: "Profile",
            icon: "person.crop.circle.fill",
            color: Color(hex: "64748b"),
            description: "Personal info & settings",
            subSections: ["Personal Info", "Medications", "App Settings"],
            tab: nil
        ),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader
            folderWithTabs
        }
        .sheet(isPresented: $showAssistantSheet) {
            AssistantView()
                .environmentObject(appVM)
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileSheet()
                .environmentObject(appVM)
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Navigate")
                    .font(IQFont.bold(20))
                    .foregroundColor(IQColors.textPrimary)
                Text(folderIsOpen ? "\(files.count) files" : "Tap folder to explore")
                    .font(IQFont.regular(12))
                    .foregroundColor(IQColors.textMuted)
            }

            Spacer()

            Text(Date(), style: .date)
                .font(IQFont.medium(12))
                .foregroundColor(IQColors.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(IQColors.border.opacity(0.5)))
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Folder + File Tabs

    private var folderWithTabs: some View {
        VStack(spacing: 18) {
            ZStack(alignment: .bottom) {
                FolderInteraction()
                    .simultaneousGesture(TapGesture().onEnded {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            folderIsOpen.toggle()
                        }
                    })

                if !folderIsOpen {
                    Text("Tap to open")
                        .font(IQFont.medium(11))
                        .foregroundColor(IQColors.textMuted.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.white.opacity(0.85)))
                        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                        .offset(y: 24)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, folderIsOpen ? 0 : 16)

            if folderIsOpen {
                fileTabsGrid
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
    }

    // MARK: - File Tabs Grid

    private var fileTabsGrid: some View {
        VStack(spacing: 8) {
            // TODO: USE SDK DATA HERE
            // Replace `files` with SDK-provided file list
            // Example: let files = sdkFolder.files
            ForEach(Array(files.enumerated()), id: \.element.id) { index, file in
                FileTabCard(
                    file: file,
                    isActive: isFileActive(file),
                    index: index
                ) {
                    navigateToFile(file)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Navigation

    private func isFileActive(_ file: AppFileItem) -> Bool {
        if let tab = file.tab {
            return appVM.selectedTab == tab
        }
        return false
    }

    private func navigateToFile(_ file: AppFileItem) {
        // TODO: USE SDK NAVIGATION HERE
        // Replace with SDK-provided navigation when available
        // Example: sdkFolder.navigate(to: file)
        if let tab = file.tab {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                appVM.selectedTab = tab
            }
        } else {
            switch file.name {
            case "Assistant": showAssistantSheet = true
            case "Profile":   showProfileSheet = true
            default: break
            }
        }
    }
}
