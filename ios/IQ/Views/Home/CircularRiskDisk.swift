import SwiftUI

/// Original liquid-glass disc layout: frosted rings, four rim words, inner arc gauge, center % + risk pill.
/// Colors use vivid flat tones + materials (no gradients).
struct CircularRiskDisk: View {

    let risk: FlareRisk
    /// Kept for call-site compatibility; disc layout matches the classic design (fixed quadrants / gauge).
    var mlPrediction: OnDevicePrediction? = nil

    private let words: [String] = ["SYMPTOMS", "FOOD", "FLARE", "TRENDS"]
    private let discSize: CGFloat = 260

    @State private var glowPulse: CGFloat = 1.0
    @State private var arcShown = false

    var body: some View {
        ZStack {
            // Layer 1: Outer glow — layered flat vivid colors + blur (glassy depth)
            Circle()
                .fill(IQColors.pinkVivid.opacity(0.42))
                .frame(width: discSize + 20, height: discSize + 20)
                .blur(radius: 18)
                .scaleEffect(glowPulse)
            Circle()
                .fill(IQColors.lavenderVivid.opacity(0.28))
                .frame(width: discSize + 28, height: discSize + 28)
                .blur(radius: 22)

            // Layer 2: Main frosted disc
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: discSize, height: discSize)
                .overlay(
                    Circle()
                        .stroke(IQColors.lavenderVivid.opacity(0.55), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.14), radius: 18, x: 0, y: 9)
                .shadow(color: IQColors.pinkVivid.opacity(0.22), radius: 28, x: 0, y: 0)

            // Layer 3: Inner glass ring (creates inner “divisions” visually)
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: discSize - 40, height: discSize - 40)
                .overlay(
                    Circle()
                        .stroke(IQColors.pinkVivid.opacity(0.38), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)

            // Layer 4: Rim words (90° spacing)
            ForEach(Array(words.enumerated()), id: \.offset) { idx, word in
                let angle = (360.0 / Double(words.count)) * Double(idx) - 90
                let radians = angle * .pi / 180
                let radius = (discSize - 40) / 2 - 14

                Text(word)
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(2.5)
                    .foregroundStyle(IQColors.rimWordColor(index: idx))
                    .rotationEffect(.degrees(angle + 90))
                    .position(
                        x: discSize / 2 + radius * CGFloat(cos(radians)),
                        y: discSize / 2 + radius * CGFloat(sin(radians))
                    )
            }
            .frame(width: discSize, height: discSize)

            // Layer 5: Centre gauge + score
            ZStack {
                Circle()
                    .fill(.regularMaterial)
                    .frame(width: 140, height: 140)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.55), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 5)

                Circle()
                    .trim(from: 0.1, to: 0.9)
                    .stroke(
                        IQColors.borderStrong.opacity(0.85),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .frame(width: 118, height: 118)
                    .rotationEffect(.degrees(90))

                let pct = Double(risk.overallScore) / 100
                let fillEnd = arcShown ? (0.1 + 0.8 * pct) : 0.1
                Circle()
                    .trim(from: 0.1, to: fillEnd)
                    .stroke(
                        arcFillColor,
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .frame(width: 118, height: 118)
                    .rotationEffect(.degrees(90))
                    .animation(.spring(response: 0.85, dampingFraction: 0.72), value: risk.overallScore)
                    .animation(.easeOut(duration: 0.9), value: arcShown)

                VStack(spacing: 4) {
                    HStack(alignment: .top, spacing: 1) {
                        Text("\(risk.overallScore)")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundStyle(riskDigitColor)
                        Text("%")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)
                    }
                    Text(risk.level.label)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(arcFillColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(arcFillColor.opacity(0.18))
                                .overlay(
                                    Capsule()
                                        .stroke(arcFillColor.opacity(0.35), lineWidth: 0.5)
                                )
                        )
                }
            }
        }
        .frame(width: discSize + 20, height: discSize + 20)
        .onAppear {
            arcShown = true
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                glowPulse = 1.025
            }
        }
    }

    private var arcFillColor: Color {
        switch risk.level {
        case .low:      return IQColors.lavenderVivid
        case .moderate: return IQColors.blushVivid
        case .high:     return IQColors.pinkVivid
        }
    }

    /// Risk level colors the numeric score only (percent sign stays secondary).
    private var riskDigitColor: Color {
        switch risk.level {
        case .low:      return Color(hex: "22C55E")
        case .moderate: return Color(hex: "F59E0B")
        case .high:     return Color(hex: "DC2626")
        }
    }
}
