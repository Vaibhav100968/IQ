import SwiftUI

// MARK: - Models

struct RevealItem: Identifiable {
    let id = UUID()
    var text: String
    var imageUrl: String
}

// MARK: - Size Config

struct CircularRevealConfig {
    var containerSize: CGFloat
    var fontSize: CGFloat
    var letterSpacing: CGFloat
    var radius: CGFloat
    var gapDegrees: CGFloat
    var imageSize: CGFloat

    static let small = CircularRevealConfig(containerSize: 300, fontSize: 11, letterSpacing: 3, radius: 115, gapDegrees: 40, imageSize: 0.75)
    static let medium = CircularRevealConfig(containerSize: 400, fontSize: 12, letterSpacing: 3.5, radius: 155, gapDegrees: 30, imageSize: 0.75)
    static let large = CircularRevealConfig(containerSize: 500, fontSize: 13.5, letterSpacing: 4, radius: 195, gapDegrees: 20, imageSize: 0.75)
}

// MARK: - Circular Text Ring

struct CircularTextRing: View {
    let items: [RevealItem]
    let config: CircularRevealConfig
    let rotation: Double
    var onHover: ((String?) -> Void)? = nil

    var body: some View {
        ZStack {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                CircularTextSegment(
                    text: item.text,
                    index: index,
                    total: items.count,
                    config: config,
                    imageUrl: item.imageUrl,
                    onHover: onHover
                )
            }
        }
        .rotationEffect(.degrees(rotation))
        .frame(width: config.containerSize, height: config.containerSize)
    }
}

// MARK: - Single Text Segment on Arc

struct CircularTextSegment: View {
    let text: String
    let index: Int
    let total: Int
    let config: CircularRevealConfig
    let imageUrl: String
    var onHover: ((String?) -> Void)? = nil

    @State private var isHovered = false

    var startAngle: Double {
        let totalGap = config.gapDegrees * Double(total)
        let available = 360.0 - totalGap
        let segment = available / Double(total)
        return Double(index) * (segment + config.gapDegrees) - 90
    }

    var body: some View {
        let characters = Array(text)
        let totalGap = config.gapDegrees * Double(total)
        let available = 360.0 - totalGap
        let segmentDeg = available / Double(total)
        let charSpacing = segmentDeg / Double(max(characters.count, 1))

        ZStack {
            ForEach(Array(characters.enumerated()), id: \.offset) { charIndex, char in
                let angleDeg = startAngle + Double(charIndex) * charSpacing + charSpacing / 2
                let angleRad = angleDeg * .pi / 180

                Text(String(char))
                    .font(.system(size: config.fontSize, weight: .semibold, design: .monospaced))
                    .kerning(config.letterSpacing)
                    .textCase(.uppercase)
                    .foregroundColor(isHovered ? Color.primary : Color(white: 0.35))
                    .offset(
                        x: config.radius * CGFloat(cos(angleRad)),
                        y: config.radius * CGFloat(sin(angleRad))
                    )
                    .rotationEffect(.degrees(angleDeg + 90))
            }
        }
        .frame(width: config.containerSize, height: config.containerSize)
        .contentShape(Circle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered.toggle()
            }
            onHover?(isHovered ? imageUrl : nil)
        }
    }
}

// MARK: - Main Component

struct CircularRevealHeading: View {
    let items: [RevealItem]
    let centerContent: AnyView
    var size: CircularRevealConfig = .medium

    @State private var rotation: Double = 0
    @State private var activeImageUrl: String? = nil
    @State private var showImage: Bool = false

    let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Neumorphic base circle
            Circle()
                .fill(Color(white: 0.91))
                .frame(width: size.containerSize, height: size.containerSize)
                .shadow(color: Color(white: 0.75), radius: 20, x: 12, y: 12)
                .shadow(color: Color.white, radius: 20, x: -12, y: -12)

            // Inner ring 1
            Circle()
                .fill(Color(white: 0.91))
                .frame(width: size.containerSize - 4, height: size.containerSize - 4)
                .shadow(color: Color(white: 0.82).opacity(0.8), radius: 8, x: 5, y: 5)
                .shadow(color: Color.white.opacity(0.9), radius: 8, x: -5, y: -5)

            // Inner ring 2
            Circle()
                .fill(Color(white: 0.91))
                .frame(width: size.containerSize - 24, height: size.containerSize - 24)
                .shadow(color: Color(white: 0.82).opacity(0.6), radius: 6, x: 4, y: 4)
                .shadow(color: Color.white.opacity(0.8), radius: 6, x: -4, y: -4)

            // Image overlay
            if let url = activeImageUrl, showImage {
                AsyncImage(url: URL(string: url)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: size.containerSize * size.imageSize,
                            height: size.containerSize * size.imageSize
                        )
                        .clipShape(Circle())
                        .brightness(-0.05)
                } placeholder: {
                    ProgressView()
                }
                .transition(.opacity)
                .zIndex(2)
            }

            // Center text (hidden when image showing)
            if !showImage {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(white: 0.91))
                        .shadow(color: Color(white: 0.82), radius: 6, x: 4, y: 4)
                        .shadow(color: Color.white, radius: 6, x: -4, y: -4)
                        .padding(8)

                    centerContent
                }
                .frame(width: size.containerSize * 0.38, height: size.containerSize * 0.22)
                .transition(.opacity)
                .zIndex(1)
            }

            // Rotating text ring
            CircularTextRing(
                items: items,
                config: size,
                rotation: rotation,
                onHover: { imageUrl in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        activeImageUrl = imageUrl
                        showImage = imageUrl != nil
                    }
                }
            )
            .zIndex(3)
        }
        .frame(width: size.containerSize, height: size.containerSize)
        .onReceive(timer) { _ in
            rotation += 0.2
            if rotation >= 360 { rotation = 0 }
        }
    }
}
