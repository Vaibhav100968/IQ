import SwiftUI

/// Preloads all root tabs in a `ZStack` (no `TabView` page transition) for instant switching.
struct MainTabView: View {
    @EnvironmentObject var appVM: AppViewModel

    /// Which primary tab is visible (merges legacy aliases).
    private var visibleTab: AppTab {
        switch appVM.selectedTab {
        case .home: return .home
        case .symptoms, .food: return .symptoms
        case .calendar, .analytics: return .analytics
        case .health, .discovery: return .discovery
        case .profile: return .profile
        }
    }

    private var assistantBinding: Binding<Bool> {
        Binding(
            get: { appVM.assistantPresented },
            set: { appVM.assistantPresented = $0 }
        )
    }

    var body: some View {
        ZStack {
            IQColors.appCanvasGradient
                .ignoresSafeArea()

            ZStack {
                tabContainer(.home) {
                    HomeView()
                }
                tabContainer(.symptoms) {
                    LogView()
                }
                tabContainer(.analytics) {
                    AnalyticsView()
                }
                tabContainer(.discovery) {
                    ContentDiscoveryView()
                }
                tabContainer(.profile) {
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            IQCustomTabBar(visibleTab: visibleTab) { tab in
                appVM.selectTab(tab)
            }
            .background(.bar)
        }
        .onAppear {
            if appVM.selectedTab == .health {
                appVM.selectTab(.discovery)
            }
        }
        .sheet(isPresented: assistantBinding) {
            AssistantView()
                .environmentObject(appVM)
        }
    }

    @ViewBuilder
    private func tabContainer(_ tab: AppTab, @ViewBuilder content: () -> some View) -> some View {
        NavigationStack {
            content()
        }
        .environmentObject(appVM)
        .opacity(visibleTab == tab ? 1 : 0)
        .allowsHitTesting(visibleTab == tab)
        .accessibilityHidden(visibleTab != tab)
        .zIndex(visibleTab == tab ? 1 : 0)
    }
}

// MARK: - Custom tab bar (pastel pink selected / lavender inactive)

private struct IQCustomTabBar: View {
    let visibleTab: AppTab
    let onSelect: (AppTab) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 0.5)

            HStack(spacing: 0) {
                ForEach(AppTab.primaryTabs, id: \.self) { tab in
                    Button {
                        onSelect(tab)
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: tab.icon)
                                .font(.system(size: visibleTab == tab ? 22 : 19, weight: .semibold))
                                .symbolVariant(visibleTab == tab ? .fill : .none)
                                .foregroundColor(visibleTab == tab ? IQColors.pinkDark : Color.gray.opacity(0.55))

                            Text(tab.title)
                                .font(.system(size: 10, weight: visibleTab == tab ? .bold : .medium))
                                .foregroundColor(visibleTab == tab ? IQColors.pinkDark : Color.gray.opacity(0.55))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                        .padding(.bottom, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
        .background(
            Color.white
                .shadow(color: .black.opacity(0.08), radius: 8, y: -3)
        )
    }
}
