import SwiftUI

// ── CalendarView — Activity section: commits grid + interactive calendar ─────
// Layout: VStack with compact heatmap at top, full interactive calendar below.
// Both components are fully visible without horizontal scrolling.
struct CalendarView: View {
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                // ── Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Activity")
                            .font(IQFont.black(22))
                            .foregroundColor(IQColors.textPrimary)
                        Text("Your tracking overview")
                            .font(IQFont.regular(13))
                            .foregroundColor(IQColors.textSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)

                // ══════════════════════════════════════════════════════════
                // SECTION 1: COMMITS GRID — compact activity heatmap
                // ══════════════════════════════════════════════════════════
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(IQColors.lavenderDark)
                        Text("Activity — Last 16 Weeks")
                            .font(IQFont.semibold(13))
                            .foregroundColor(IQColors.textSecondary)
                    }

                    CommitsGridView(countForDate: appVM.logCountForDate)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
                )
                .padding(.horizontal, 16)

                // ══════════════════════════════════════════════════════════
                // SECTION 2: INTERACTIVE CALENDAR
                // ══════════════════════════════════════════════════════════
                ActivityCalendarView()
                    .padding(.horizontal, 16)

                // ── Text-art commits grid (branding element)
                CommitsGrid(text: "IQ")
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)

                Spacer(minLength: 32)
            }
            .padding(.top, 16)
        }
        .background(IQColors.background.ignoresSafeArea())
    }
}
