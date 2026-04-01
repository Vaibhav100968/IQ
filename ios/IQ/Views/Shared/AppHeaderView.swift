import SwiftUI

// ── AppHeaderView — with Assistant + Profile buttons ──────────────────────────
struct AppHeaderView: View {
    @EnvironmentObject var appVM: AppViewModel
    @Binding var showAssistant: Bool
    @State private var showProfile = false

    var body: some View {
        ZStack {
            IQColors.blush
                .ignoresSafeArea(edges: .top)

            HStack(spacing: 8) {
                // Logo
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(IQColors.pink)
                        .frame(width: 28, height: 28)
                    Text("IQ")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white)
                }

                HStack(spacing: 0) {
                    Text("IQ").font(.system(size: 17, weight: .bold)).foregroundColor(IQColors.textPrimary)
                    Text(": ").font(.system(size: 17, weight: .bold)).foregroundColor(IQColors.textPrimary)
                    Text("Gut Intelligence")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(IQColors.lavenderDark)
                        .kerning(0.5).textCase(.uppercase)
                }

                Spacer()

                // Assistant button (Task 5)
                Button { showAssistant = true } label: {
                    ZStack {
                        Circle()
                            .fill(IQColors.lavender.opacity(0.3))
                            .frame(width: 32, height: 32)
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(IQColors.lavenderDark)
                    }
                }

                // Profile button (Task 6)
                Button { showProfile = true } label: {
                    Circle()
                        .fill(IQColors.pink)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 14))
                                .foregroundColor(IQColors.pinkDark)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(height: 56)
        .sheet(isPresented: $showProfile) {
            ProfileSheet()
                .environmentObject(appVM)
        }
    }
}
