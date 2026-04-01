import SwiftUI

/// Short education copy: rule-based score vs on-device ML — they need not match.
struct RiskScoreFootnote: View {
    enum Style {
        /// Home screen — under the circular disk (rule-based %).
        case homeDisk
        /// Gut Intelligence — under AI Flare Risk card.
        case aiIntelligence
        /// Analytics Summary — under Current Flare Risk card.
        case analyticsRuleBased
    }

    let style: Style

    var body: some View {
        Text(copy)
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
    }

    private var copy: String {
        switch style {
        case .homeDisk:
            return "This number is your rule-based flare index: it adds up recent symptoms, meals, and simple trends in fixed time windows. AI Flare Risk in Analysis uses the on-device model instead — both can differ and stay useful."
        case .aiIntelligence:
            return "AI Flare Risk blends Core ML with your history and trends. “Current Flare Risk” in Summary below is a separate rule-based score from the same logs. Different math on purpose — neither % has to match the other."
        case .analyticsRuleBased:
            return "This score is rule-based (0–100): symptoms, trigger foods, and patterns over recent days. AI Flare Risk above uses the ML pipeline. They measure similar reality two ways, so percentages often won’t match — that’s expected."
        }
    }
}
