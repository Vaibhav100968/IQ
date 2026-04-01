import SwiftUI

// ── AppFileItem — model for each navigable file/section (SDK — DO NOT MODIFY) ─
struct AppFileItem: Identifiable {
    let id = UUID().uuidString
    let name: String
    let icon: String
    let color: Color
    let description: String
    let subSections: [String]
    let tab: AppTab?
}

// ── FileTabCard — compact tab-style card for folder file navigation ──────────

struct FileTabCard: View {
    let file: AppFileItem
    let isActive: Bool
    let index: Int
    let onTap: () -> Void

    @State private var appeared = false

    var body: some View {
        Button {
            onTap()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isActive ? file.color : file.color.opacity(0.1))
                        .frame(width: 36, height: 36)
                    Image(systemName: file.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isActive ? .white : file.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .font(IQFont.semibold(13))
                        .foregroundColor(isActive ? file.color : IQColors.textPrimary)
                    Text(file.description)
                        .font(IQFont.regular(10))
                        .foregroundColor(IQColors.textMuted)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                if isActive {
                    Circle()
                        .fill(file.color)
                        .frame(width: 7, height: 7)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(isActive ? file.color.opacity(0.06) : Color.white)
                    .shadow(
                        color: isActive ? file.color.opacity(0.12) : .black.opacity(0.03),
                        radius: isActive ? 8 : 4, y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(
                        isActive ? file.color.opacity(0.3) : IQColors.border.opacity(0.4),
                        lineWidth: isActive ? 1.2 : 0.6
                    )
            )
        }
        .buttonStyle(FileTabPressStyle())
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8).delay(Double(index) * 0.05)) {
                appeared = true
            }
        }
    }
}

// MARK: - Button Style

private struct FileTabPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
