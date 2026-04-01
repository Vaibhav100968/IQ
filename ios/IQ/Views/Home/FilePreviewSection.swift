import SwiftUI

// ── FilePreviewSection — sub-tab/content preview inside a file card ──────────
struct FilePreviewSection: View {
    let items: [String]
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accentColor.opacity(0.35))
                        .frame(width: 4, height: 16)

                    Text(item)
                        .font(IQFont.medium(12))
                        .foregroundColor(IQColors.textSecondary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(IQColors.textMuted.opacity(0.5))
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor.opacity(0.04))
                )

                if index < items.count - 1 {
                    Divider().opacity(0.3)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(IQColors.background.opacity(0.6))
        )
    }
}
