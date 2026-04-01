import SwiftUI

struct MLInsightsSection: View {
    @EnvironmentObject var appVM: AppViewModel

    @State private var simSleep: Double = 7
    @State private var simStress: Double = 5
    @State private var simDairy: Bool = false
    @State private var simSpicy: Bool = false
    @State private var simResult: OnDeviceSimulation? = nil

    var body: some View {
        VStack(spacing: 16) {
            sectionHeader

            if appVM.isMLLoading {
                loadingCard
            } else if let p = appVM.mlPrediction {
                riskScoreCard(p)
                personalizationBadge(p)
                riskFactorsList(p)
                contributionBars(p)
                whatIfSimulator
            } else {
                unavailableCard
            }
        }
        .onAppear { appVM.fetchMLPrediction() }
    }

    private var sectionHeader: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.body.bold())
                    .foregroundStyle(IQColors.lavenderDark)
                Text("AI Intelligence")
                    .font(.title3.bold())
            }
            Spacer()
            Text("On-Device")
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(IQColors.lavenderDark, in: Capsule())
        }
        .padding(.horizontal, 16)
    }

    private var loadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Running analysis…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .iqVibrantMaterialCard()
        .padding(.horizontal, 16)
    }

    private var unavailableCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundStyle(.quaternary)
            Text("Core ML model not loaded")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            if let err = appVM.mlError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            Button("Retry") { appVM.fetchMLPrediction() }
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(IQColors.lavenderDark, in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .iqVibrantMaterialCard()
        .padding(.horizontal, 16)
    }

    private func riskScoreCard(_ p: OnDevicePrediction) -> some View {
        VStack(spacing: 14) {
            HStack {
                Text("AI Flare Risk")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(p.riskLabel)
                    .font(.caption.bold())
                    .foregroundStyle(riskColor(p))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(riskColor(p).opacity(0.15), in: Capsule())
            }

            HStack(alignment: .bottom, spacing: 4) {
                Text("\(p.riskPercent)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text("%")
                    .font(.title3.bold())
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 7)
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Combined score blends the two below.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.trailing)
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("General prediction")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                            Text("\(Int(p.globalProb * 100))%")
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                        }
                        if let pp = p.personalProb {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Personalized prediction")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.secondary)
                                Text("\(Int(pp * 100))%")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(IQColors.lavenderDark)
                            }
                        } else {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Personalized prediction")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.secondary)
                                Text("—")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color(.systemGray5)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(riskColor(p))
                        .frame(width: geo.size.width * p.finalRisk, height: 6)
                        .animation(.spring(response: 0.7), value: p.finalRisk)
                }
            }
            .frame(height: 6)

            RiskScoreFootnote(style: .aiIntelligence)
        }
        .padding(16)
        .iqVibrantMaterialCard()
        .padding(.horizontal, 16)
    }

    private func personalizationBadge(_ p: OnDevicePrediction) -> some View {
        HStack(spacing: 8) {
            Image(systemName: p.personalizationWeight == 1 ? "person.fill.checkmark" : "person.fill.questionmark")
                .font(.caption)
                .foregroundStyle(p.personalizationWeight == 1 ? IQColors.lavenderDark : .secondary)
            Text(p.personalizationStatus)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(12)
        .background(IQColors.lavenderVivid.opacity(0.18), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(IQColors.lavenderVivid.opacity(0.25), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
    }

    private func riskFactorsList(_ p: OnDevicePrediction) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Why this score?")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            if p.riskFactors.isEmpty && p.protectiveFactors.isEmpty {
                Text("Log more days to see personalized insights")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            ForEach(p.riskFactors, id: \.self) { factor in
                factorRow(text: factor, isRisk: true)
            }
            ForEach(p.protectiveFactors, id: \.self) { factor in
                factorRow(text: factor, isRisk: false)
            }
        }
        .padding(16)
        .iqVibrantMaterialCard()
        .padding(.horizontal, 16)
    }

    private func factorRow(text: String, isRisk: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isRisk ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundColor(isRisk ? IQColors.pinkVivid : IQColors.lavenderVivid)
                .font(.system(size: 14))
            Text(text)
                .font(.caption)
                .foregroundStyle(.primary)
        }
    }

    private func contributionBars(_ p: OnDevicePrediction) -> some View {
        let sorted = p.featureContributions.sorted { $0.value > $1.value }.prefix(6)
        let labels: [String: String] = [
            "pain": "Pain", "stress": "Stress", "diarrhea": "Diarrhea",
            "sleep": "Sleep Quality", "recency": "Flare Recency",
            "dairy": "Dairy", "spicy_food": "Spicy Food"
        ]

        return VStack(alignment: .leading, spacing: 12) {
            Text("Feature Contributions")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            ForEach(sorted, id: \.key) { key, value in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(labels[key] ?? key.capitalized)
                            .font(.caption.bold())
                        Spacer()
                        Text(String(format: "%.0f%%", value * 100))
                            .font(.caption.bold())
                            .foregroundStyle(value >= 0.55 ? IQColors.pinkVivid : .secondary)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(Color(.systemGray5)).frame(height: 5)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(value >= 0.65 ? IQColors.pinkVivid : value >= 0.45 ? IQColors.blushVivid : IQColors.lavenderVivid)
                                .frame(width: geo.size.width * min(value, 1), height: 5)
                        }
                    }
                    .frame(height: 5)
                }
            }
        }
        .padding(16)
        .iqVibrantMaterialCard()
        .padding(.horizontal, 16)
    }

    private var whatIfSimulator: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What-If Simulator")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            sliderRow(label: "Sleep", value: $simSleep, range: 3...10, format: { "\(Int($0))h" }, icon: "moon.fill")
            sliderRow(label: "Stress", value: $simStress, range: 0...10, format: { "\(Int($0))/10" }, icon: "brain")
            toggleRow(label: "Dairy", icon: "cup.and.saucer.fill", isOn: $simDairy)
            toggleRow(label: "Spicy Food", icon: "flame.fill", isOn: $simSpicy)

            if let sim = simResult {
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Simulated Risk")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(alignment: .bottom, spacing: 3) {
                            Text("\(sim.newRiskPercent)%")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                            Text(sim.isImprovement ? "↓\(sim.deltaPercent)%" : "↑\(sim.deltaPercent)%")
                                .font(.subheadline.bold())
                                .foregroundStyle(sim.isImprovement ? IQColors.lavenderDark : IQColors.pinkVivid)
                                .padding(.bottom, 4)
                        }
                    }
                    Spacer()
                    Text(sim.interpretation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 140)
                }
                .padding(12)
                .background(
                    (sim.isImprovement ? IQColors.riskLowBg : IQColors.riskHighBg).opacity(0.3),
                    in: RoundedRectangle(cornerRadius: 12)
                )
            }
        }
        .padding(16)
        .iqVibrantMaterialCard()
        .padding(.horizontal, 16)
        .onChange(of: simSleep)  { _ in runSim() }
        .onChange(of: simStress) { _ in runSim() }
        .onChange(of: simDairy)  { _ in runSim() }
        .onChange(of: simSpicy)  { _ in runSim() }
        .onAppear {
            simSleep = appVM.currentFeatures.sleep_hours
            simStress = appVM.currentFeatures.stress
            simDairy = appVM.currentFeatures.dairy == 1
            simSpicy = appVM.currentFeatures.spicy_food == 1
        }
    }

    private func sliderRow(label: String, value: Binding<Double>, range: ClosedRange<Double>, format: (Double) -> String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.caption).foregroundStyle(IQColors.lavenderDark).frame(width: 20)
            Text(label).font(.subheadline).frame(width: 60, alignment: .leading)
            Slider(value: value, in: range, step: 1).tint(IQColors.lavenderDark)
            Text(format(value.wrappedValue)).font(.caption.bold()).frame(width: 36, alignment: .trailing)
        }
    }

    private func toggleRow(label: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.caption).foregroundStyle(IQColors.lavenderDark).frame(width: 20)
            Text(label).font(.subheadline)
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(IQColors.pinkDark)
        }
    }

    private func runSim() {
        let changes: [String: Double] = [
            "sleep_hours": simSleep, "stress": simStress,
            "dairy": simDairy ? 1 : 0, "spicy_food": simSpicy ? 1 : 0,
        ]
        simResult = appVM.runSimulate(changes: changes)
    }

    private func riskColor(_ p: OnDevicePrediction) -> Color {
        switch p.riskLabel {
        case "Low": return IQColors.riskLow
        case "Moderate": return IQColors.riskModerate
        default: return IQColors.riskHigh
        }
    }
}
