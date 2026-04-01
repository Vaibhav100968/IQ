import SwiftUI

// ── BottomNavView — custom tab bar ──────────────────────────────────────────
struct BottomNavView: View {
    @EnvironmentObject var appVM: AppViewModel

    private var primaryTabs: [AppTab] { AppTab.primaryTabs }

    var body: some View {
        VStack(spacing: 0) {
            // Top separator
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(height: 0.5)

            // Tab row
            HStack(spacing: 0) {
                ForEach(primaryTabs, id: \.self) { tab in
                    Button {
                        appVM.selectTab(tab)
                    } label: {
                        tabItem(tab)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 10)
            .padding(.horizontal, 8)
            .padding(.bottom, 6)
        }
        .background(
            Rectangle()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 8, y: -3)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func isPrimaryTabSelected(_ tab: AppTab) -> Bool {
        switch tab {
        case .home: return appVM.selectedTab == .home
        case .symptoms, .food: return appVM.selectedTab == .symptoms || appVM.selectedTab == .food
        case .calendar, .analytics: return appVM.selectedTab == .analytics || appVM.selectedTab == .calendar
        case .health, .discovery:
            return appVM.selectedTab == .discovery || appVM.selectedTab == .health
        case .profile: return appVM.selectedTab == .profile
        }
    }

    @ViewBuilder
    private func tabItem(_ tab: AppTab) -> some View {
        let isSelected = isPrimaryTabSelected(tab)
        VStack(spacing: 4) {
            Image(systemName: tab.icon)
                .font(.system(size: isSelected ? 22 : 20, weight: .semibold))
                .symbolVariant(isSelected ? .fill : .none)
                .foregroundColor(isSelected ? IQColors.pinkDark : Color.gray.opacity(0.55))

            Text(tab.title)
                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? IQColors.pinkDark : Color.gray.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .animation(.easeOut(duration: 0.18), value: isSelected)
    }
}
