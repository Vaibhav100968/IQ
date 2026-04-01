import SwiftUI

// MARK: - Page View

struct FolderPageView: View {
    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: "000000"))
                .frame(height: 6)
            ForEach(0..<8, id: \.self) { _ in
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "7b80cc"))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "9498dc").opacity(0.7))
                        .frame(height: 6)
                }
            }
        }
        .padding(12)
        .frame(width: 128)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "9EA2E0"),
                    Color(hex: "8B8FD6")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(12)
        .shadow(color: Color(hex: "5057d5").opacity(0.18), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Folder Interaction View

struct FolderInteraction: View {
    @State private var isOpen: Bool = false

    struct PageConfig {
        let offsetX: CGFloat
        let offsetY: CGFloat
        let rotation: Double
        let openOffsetX: CGFloat
        let openOffsetY: CGFloat
        let openRotation: Double
        let zIndex: Double
    }

    let pages: [PageConfig] = [
        PageConfig(offsetX: -38, offsetY: 2, rotation: -3, openOffsetX: -70, openOffsetY: -55, openRotation: -8, zIndex: 1),
        PageConfig(offsetX: 0, offsetY: 0, rotation: 0, openOffsetX: 2, openOffsetY: -75, openRotation: 1, zIndex: 2),
        PageConfig(offsetX: 42, offsetY: 1, rotation: 3.5, openOffsetX: 75, openOffsetY: -60, openRotation: 9, zIndex: 1),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {

            // Folder body
            ZStack {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    FolderPageView()
                        .offset(
                            x: isOpen ? page.openOffsetX : page.offsetX,
                            y: isOpen ? page.openOffsetY : page.offsetY
                        )
                        .rotationEffect(.degrees(isOpen ? page.openRotation : page.rotation))
                        .zIndex(page.zIndex)
                        .animation(
                            .spring(response: 0.55, dampingFraction: 0.78, blendDuration: 0),
                            value: isOpen
                        )
                }
            }
            .frame(width: 280, height: 208)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "E8E9FF"),
                                Color(hex: "DFE0FC")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(hex: "CDD0F8").opacity(0.4), radius: 16, x: 0, y: 0)
            )

            // Folder front flap
            FolderFlapShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "CDD0F8"),
                            Color(hex: "D8DAF9")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    FolderFlapShape()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color(hex: "B0B4F0").opacity(0.3)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.8
                        )
                )
                .frame(width: 282, height: 176)
                .rotation3DEffect(
                    .degrees(isOpen ? -40 : 0),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .bottom,
                    perspective: 0.5
                )
                .animation(.spring(response: 0.5, dampingFraction: 0.75), value: isOpen)
                .zIndex(3)
        }
        .frame(width: 320, height: 208)
        .onTapGesture {
            withAnimation {
                isOpen.toggle()
            }
        }
    }
}


// MARK: - Folder Flap Shape



struct FolderFlapShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: w * 0.445, y: 0))
        path.addLine(to: CGPoint(x: w * 0.141, y: 0))
        path.addCurve(
            to: CGPoint(x: w * 0.056, y: h * 0.008),
            control1: CGPoint(x: w * 0.12, y: 0),
            control2: CGPoint(x: w * 0.08, y: h * 0.004)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: h * 0.093),
            control1: CGPoint(x: w * 0.024, y: h * 0.026),
            control2: CGPoint(x: 0, y: h * 0.056)
        )
        path.addLine(to: CGPoint(x: w * 0.052, y: h * 0.942))
        path.addCurve(
            to: CGPoint(x: w * 0.091, y: h),
            control1: CGPoint(x: w * 0.053, y: h * 0.965),
            control2: CGPoint(x: w * 0.068, y: h * 0.988)
        )
        path.addLine(to: CGPoint(x: w * 0.916, y: h))
        path.addCurve(
            to: CGPoint(x: w * 0.957, y: h * 0.985),
            control1: CGPoint(x: w * 0.934, y: h),
            control2: CGPoint(x: w * 0.948, y: h * 0.994)
        )
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.44),
            control1: CGPoint(x: w * 0.978, y: h * 0.963),
            control2: CGPoint(x: w, y: h * 0.72)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.624, y: h * 0.351),
            control1: CGPoint(x: w, y: h * 0.351),
            control2: CGPoint(x: w * 0.812, y: h * 0.351)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.566, y: h * 0.29),
            control1: CGPoint(x: w * 0.609, y: h * 0.351),
            control2: CGPoint(x: w * 0.59, y: h * 0.328)
        )
        path.addLine(to: CGPoint(x: w * 0.483, y: h * 0.042))
        path.addCurve(
            to: CGPoint(x: w * 0.445, y: 0),
            control1: CGPoint(x: w * 0.475, y: h * 0.024),
            control2: CGPoint(x: w * 0.462, y: h * 0.008)
        )
        path.closeSubpath()
        return path
    }
}
