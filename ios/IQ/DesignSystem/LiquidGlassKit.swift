// LiquidGlassKit.swift
// Full SDK — Liquid Glass primitives used across the IQ app
import SwiftUI

// MARK: - Variants

public enum LiquidVariant {
    case primary   // blue-tinted
    case soft      // light / frosted
    case glass     // pure frosted white
}

public enum LiquidButtonSize {
    case small, medium, large
}

// MARK: - Button

public struct LiquidGlassButton: View {

    public var title: String
    public var variant: LiquidVariant
    public var size: LiquidButtonSize
    public var action: () -> Void

    @State private var isPressed = false

    public init(
        title: String,
        variant: LiquidVariant = .glass,
        size: LiquidButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.size = size
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(gradient)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(
                        color: .black.opacity(0.15),
                        radius: isPressed ? 4 : 10,
                        x: 0,
                        y: isPressed ? 2 : 6
                    )

                Text(title)
                    .font(font)
                    .foregroundColor(textColor)
                    .padding(padding)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .brightness(isPressed ? -0.05 : 0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

private extension LiquidGlassButton {

    var cornerRadius: CGFloat {
        switch size { case .small: 14; case .medium: 18; case .large: 22 }
    }

    var font: Font {
        switch size {
        case .small:  .system(size: 14, weight: .medium)
        case .medium: .system(size: 16, weight: .semibold)
        case .large:  .system(size: 18, weight: .bold)
        }
    }

    var padding: EdgeInsets {
        switch size {
        case .small:  EdgeInsets(top:  8, leading: 16, bottom:  8, trailing: 16)
        case .medium: EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
        case .large:  EdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32)
        }
    }

    var textColor: Color {
        switch variant { case .primary: .white; case .soft: .black.opacity(0.8); case .glass: .white }
    }

    var gradient: LinearGradient {
        switch variant {
        case .primary:
            LinearGradient(colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.3)],
                           startPoint: .top, endPoint: .bottom)
        case .soft:
            LinearGradient(colors: [Color.white.opacity(0.4), Color.gray.opacity(0.1)],
                           startPoint: .top, endPoint: .bottom)
        case .glass:
            LinearGradient(colors: [Color.white.opacity(0.25), Color.white.opacity(0.05)],
                           startPoint: .top, endPoint: .bottom)
        }
    }
}

// MARK: - Glass Card modifier

/// Apply liquid glass styling to any container
struct LiquidGlassCard: ViewModifier {
    var cornerRadius: CGFloat
    var tint: Color

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Blur layer
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    // Tint wash
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.18), tint.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                ZStack {
                    // Outer border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.30), lineWidth: 1)
                    // Inner highlight — top edge
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.55), Color.clear],
                                startPoint: .top, endPoint: .center
                            ),
                            lineWidth: 0.8
                        )
                }
            )
            .shadow(color: tint.opacity(0.10), radius: 12, x: 0, y: 4)
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func liquidGlassCard(cornerRadius: CGFloat = 18, tint: Color = .white) -> some View {
        modifier(LiquidGlassCard(cornerRadius: cornerRadius, tint: tint))
    }
}

// MARK: - Frosted Pill  (replaces opaque tag capsules inside glass cards)

struct FrostedPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
                    .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 0.75))
            )
    }
}

// MARK: - Frosted Icon Well  (replaces opaque icon backgrounds inside glass cards)

struct FrostedIconWell: View {
    let systemName: String
    let color: Color
    var size: CGFloat = 38

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Circle()
                        .fill(color.opacity(0.15))
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(0.35), lineWidth: 0.75)
                )
                .frame(width: size, height: size)

            Image(systemName: systemName)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundColor(color)
        }
    }
}
