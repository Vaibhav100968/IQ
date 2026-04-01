import SwiftUI

// ── Task 2: Quick Actions — File/Folder Style ─────────────────────────────────
struct QuickActionsFolders: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var isExpanded = false

    private let folders: [(icon: String, label: String, tab: AppTab, color: Color)] = [
        ("chart.line.uptrend.xyaxis", "Analytics",            .analytics, Color(hex: "5057d5")),
        ("fork.knife",                "Food Log",             .symptoms,  Color(hex: "c4458a")),
        ("waveform.path.ecg",         "Symptoms & Activity",  .symptoms,  Color(hex: "16a34a")),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(IQFont.bold(18))
                .foregroundColor(IQColors.textPrimary)
                .padding(.horizontal, 16)

            // Folder container
            VStack(spacing: 0) {
                // Folder header (tap to expand)
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(colors: [Color(hex: "fbbf24"), Color(hex: "f59e0b")],
                                                   startPoint: .top, endPoint: .bottom)
                                )
                                .frame(width: 38, height: 30)
                            Image(systemName: isExpanded ? "folder.fill" : "folder")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        Text("Quick Navigate")
                            .font(IQFont.semibold(15))
                            .foregroundColor(IQColors.textPrimary)

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(IQColors.textMuted)
                    }
                    .padding(14)
                }
                .buttonStyle(.plain)

                // Expanded tags
                if isExpanded {
                    Divider().padding(.horizontal, 14)

                    VStack(spacing: 6) {
                        ForEach(folders, id: \.label) { folder in
                            Button {
                                appVM.selectTab(folder.tab)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(folder.color.opacity(0.7))
                                        .frame(width: 20)

                                    Image(systemName: folder.icon)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(folder.color)
                                        .frame(width: 22)

                                    Text(folder.label)
                                        .font(IQFont.medium(13))
                                        .foregroundColor(IQColors.textPrimary)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10))
                                        .foregroundColor(IQColors.textMuted)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(folder.color.opacity(0.06))
                                )
                            }
                            .buttonStyle(.plain)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
            )
            .padding(.horizontal, 16)
        }
    }
}
