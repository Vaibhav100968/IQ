import Foundation

// ── Weights (mirrors JS flare-engine.ts exactly) ───────────────────────────
private enum W {
    static let symptom:   Double = 35
    static let trigger:   Double = 25
    static let trend:     Double = 20
    static let pattern:   Double = 10
    static let nlSignal:  Double = 10
}

// ── Date helpers ───────────────────────────────────────────────────────────
private func last24h() -> (Date, Date) {
    let end = Date(); let start = Calendar.current.date(byAdding: .hour, value: -24, to: end)!
    return (start, end)
}
private func last48h() -> (Date, Date) {
    let end = Date(); let start = Calendar.current.date(byAdding: .hour, value: -48, to: end)!
    return (start, end)
}
private func last7d() -> (Date, Date) {
    let end = Date(); let start = Calendar.current.date(byAdding: .day, value: -7, to: end)!
    return (start, end)
}
private func lastNDays(_ n: Int) -> (Date, Date) {
    let end = Date(); let start = Calendar.current.date(byAdding: .day, value: -n, to: end)!
    return (start, end)
}
private func inRange(_ date: Date, _ start: Date, _ end: Date) -> Bool {
    date >= start && date <= end
}

// ── Risk Increase / Decrease keywords ─────────────────────────────────────
private let riskIncreasing = ["worse","worsening","severe","unbearable","excruciating","constant","spreading","bloody","bleeding","intense","sharp","stabbing","awful","terrible","horrible","very bad","extremely","much worse","getting worse","can't stand","can't sleep"]
private let riskDecreasing = ["better","improving","mild","slight","manageable","subsiding","easing","tolerable","okay","fine","good","great","resolved","gone","relieved","less","reduced","improving","getting better","feeling okay"]

// ── Scoring functions ──────────────────────────────────────────────────────

private func symptomScore(_ symptoms: [SymptomEntry]) -> Int {
    let (start, end) = last24h()
    let recent = symptoms.filter { inRange($0.timestamp, start, end) }
    guard !recent.isEmpty else { return 0 }
    let avgSeverity = recent.map(\.severity).reduce(0, +) / Double(recent.count)
    let countFactor = min(Double(recent.count) / 5, 1)
    let severityFactor = avgSeverity / 10
    return Int((severityFactor * 0.7 + countFactor * 0.3) * W.symptom)
}

private func triggerScore(_ foods: [FoodEntry], knownTriggers: [FoodTag]) -> Int {
    let (start, end) = last48h()
    let recent = foods.filter { inRange($0.timestamp, start, end) }
    guard !recent.isEmpty else { return 0 }
    var count = 0
    for food in recent { for tag in food.tags { if knownTriggers.contains(tag) { count += 1 } } }
    return Int(min(Double(count) / 4, 1) * W.trigger)
}

private func trendScore(_ symptoms: [SymptomEntry]) -> Int {
    let (start, end) = last7d()
    let recent = symptoms.filter { inRange($0.timestamp, start, end) }
    guard recent.count >= 3 else { return Int(W.trend * 0.3) }
    let sorted = recent.sorted { $0.timestamp < $1.timestamp }
    let half = sorted.count / 2
    let firstAvg = sorted[..<half].map(\.severity).reduce(0,+) / Double(half)
    let secondAvg = sorted[half...].map(\.severity).reduce(0,+) / Double(sorted.count - half)
    let dir = secondAvg - firstAvg
    if dir > 2   { return Int(W.trend) }
    if dir > 0.5 { return Int(W.trend * 0.7) }
    if dir > -0.5{ return Int(W.trend * 0.4) }
    return Int(W.trend * 0.1)
}

private func patternScore(_ symptoms: [SymptomEntry]) -> Int {
    let dayOfWeek = Calendar.current.component(.weekday, from: Date())
    let historical = symptoms.filter {
        Calendar.current.component(.weekday, from: $0.timestamp) == dayOfWeek && $0.severity >= 6
    }
    let (start, end) = last24h()
    let recentHigh = symptoms.filter { inRange($0.timestamp, start, end) && $0.severity >= 7 }
    var score = 0.0
    if historical.count >= 2 { score += W.pattern * 0.5 }
    if recentHigh.count >= 2  { score += W.pattern * 0.5 }
    return Int(score)
}

private func nlSignalScore(_ symptoms: [SymptomEntry]) -> Int {
    let (start, end) = last24h()
    let recent = symptoms.filter { inRange($0.timestamp, start, end) && $0.notes != nil }
    guard !recent.isEmpty else { return Int(W.nlSignal * 0.3) }
    var totalSignal = 0.0
    var analyzed = 0
    for s in recent {
        guard let note = s.notes else { continue }
        let lower = note.lowercased()
        analyzed += 1
        var sig = 0.0
        for kw in riskIncreasing { if lower.contains(kw) { sig += 1 } }
        for kw in riskDecreasing { if lower.contains(kw) { sig -= 1 } }
        totalSignal += sig
    }
    guard analyzed > 0 else { return Int(W.nlSignal * 0.3) }
    let normalized = max(0, min(1, (totalSignal / Double(analyzed) + 3) / 6))
    return Int(normalized * W.nlSignal)
}

// ── Explanation ────────────────────────────────────────────────────────────
private func explanation(_ symptoms: [SymptomEntry], _ foods: [FoodEntry],
                          knownTriggers: [FoodTag],
                          ss: Int, ts: Int, trendS: Int, ps: Int) -> String {
    var factors: [String] = []
    let (s24, e24) = last24h()
    let (s48, e48) = last48h()
    if ss > Int(W.symptom * 0.5) {
        let r = symptoms.filter { inRange($0.timestamp, s24, e24) }
        let avg = r.isEmpty ? 0 : r.map(\.severity).reduce(0,+) / Double(r.count)
        factors.append(String(format: "symptom severity averaging %.1f/10 over %d entries in 24h", avg, r.count))
    }
    if ts > Int(W.trigger * 0.5) {
        let rf = foods.filter { inRange($0.timestamp, s48, e48) }
        let tags = Set(rf.flatMap(\.tags).filter { knownTriggers.contains($0) })
        factors.append("trigger foods detected: \(tags.map(\.label).joined(separator: ", "))")
    }
    if trendS > Int(W.trend * 0.5) { factors.append("symptom severity trending upward over 7 days") }
    if ps > Int(W.pattern * 0.5)   { factors.append("current pattern matches previous pre-flare periods") }
    if factors.isEmpty { return "Your symptoms are stable. Keep tracking!" }
    return "Risk driven by \(factors.joined(separator: "; "))."
}

// ── Public API ─────────────────────────────────────────────────────────────

func calculateFlareRisk(symptoms: [SymptomEntry], foods: [FoodEntry], profile: UserProfile?) -> FlareRisk {
    let kt = profile?.knownTriggers ?? []
    let ss = symptomScore(symptoms)
    let ts = triggerScore(foods, knownTriggers: kt)
    let trs = trendScore(symptoms)
    let ps = patternScore(symptoms)
    let nls = nlSignalScore(symptoms)
    let overall = min(ss + ts + trs + ps + nls, 100)
    let level: RiskLevel = overall <= 30 ? .low : overall <= 60 ? .moderate : .high
    let window: String = {
        if overall <= 30 { return "Low risk period" }
        if overall <= 50 { return "Next 48-72 hrs" }
        if overall <= 70 { return "Next 24-48 hrs" }
        return "Next 12-24 hrs"
    }()
    return FlareRisk(overallScore: overall, level: level, timeWindow: window,
                     explanation: explanation(symptoms, foods, knownTriggers: kt, ss: ss, ts: ts, trendS: trs, ps: ps),
                     symptomScore: ss, triggerScore: ts, trendScore: trs, patternScore: ps)
}

func detectPreFlare(symptoms: [SymptomEntry]) -> PreFlareWarning {
    let (s48, e48) = last48h()
    let recent48 = symptoms.filter { inRange($0.timestamp, s48, e48) }
    var confidence = 0

    if recent48.count >= 3 {
        let sorted = recent48.sorted { $0.timestamp < $1.timestamp }
        let half = Int(ceil(Double(sorted.count) / 2))
        let firstAvg = sorted[..<half].map(\.severity).reduce(0,+) / Double(half)
        let secondAvg = sorted[half...].map(\.severity).reduce(0,+) / Double(sorted.count - half)
        if secondAvg - firstAvg > 1.5 { confidence += 30 }
    }
    let uniqueTypes = Set(recent48.map(\.type))
    if recent48.count >= 2 && uniqueTypes.count >= 3 { confidence += 25 }
    let highSev = recent48.filter { $0.severity >= 7 }
    if highSev.count >= 2 { confidence += 25 }

    var alarmCount = 0
    for s in recent48 {
        if let note = s.notes, riskIncreasing.contains(where: { note.lowercased().contains($0) }) {
            alarmCount += 1
        }
    }
    if alarmCount >= 2 { confidence += 20 }

    confidence = min(confidence, 100)
    let detected = confidence >= 50
    return PreFlareWarning(
        detected: detected,
        confidence: confidence,
        message: detected ? "Pre-flare patterns detected. Your symptoms over the past 48 hours match previous pre-flare periods." : "No pre-flare patterns detected. Keep tracking."
    )
}

func simulateScenario(input: String, currentScore: Int, symptoms: [SymptomEntry], foods: [FoodEntry], profile: UserProfile?) -> ScenarioResult {
    let lower = input.lowercased()
    let kt = profile?.knownTriggers ?? []

    let tagChecks: [([String], FoodTag)] = [
        (["dairy","milk","cheese","yogurt","ice cream"], .dairy),
        (["gluten","bread","wheat","pasta"], .gluten),
        (["spicy","hot sauce","chili"], .spicy),
        (["fried","fry","french fries"], .fried),
        (["fiber","beans","lentils","broccoli"], .high_fiber),
        (["raw","salad","sushi"], .raw),
        (["alcohol","beer","wine"], .alcohol),
        (["coffee","caffeine","energy drink"], .caffeine),
        (["processed","fast food","junk food"], .processed),
        (["sugar","candy","chocolate","dessert"], .sugar),
    ]

    for (keywords, tag) in tagChecks {
        if keywords.contains(where: { lower.contains($0) }) {
            let isTrigger = kt.contains(tag)
            let (s30, e30) = lastNDays(30)
            let past = foods.filter { inRange($0.timestamp, s30, e30) && $0.tags.contains(tag) }.count
            let delta = isTrigger ? Int(15 + min(Double(past) * 2, 15)) : Int(5 + min(Double(past), 10))
            let projected = min(currentScore + delta, 100)
            return ScenarioResult(currentScore: currentScore, projectedScore: projected, delta: delta,
                explanation: isTrigger
                    ? "\(tag.label) is a known trigger. Eating it would increase risk by ~\(delta)% to \(projected)%."
                    : "\(tag.label) has a mild impact. Risk would rise ~\(delta)% to \(projected)%.")
        }
    }

    if ["stress","anxious","worried"].contains(where: { lower.contains($0) }) {
        let d = 12
        return ScenarioResult(currentScore: currentScore, projectedScore: min(currentScore+d,100), delta: d,
            explanation: "High stress increases inflammation. Risk would rise ~\(d)%. Try deep breathing or meditation.")
    }
    if ["sleep","rest"].contains(where: { lower.contains($0) }) {
        let d = 10
        return ScenarioResult(currentScore: currentScore, projectedScore: min(currentScore+d,100), delta: d,
            explanation: "Poor sleep correlates with flares. Missing sleep could raise risk ~\(d)%.")
    }
    if lower.contains("skip") && ["meal","dinner","lunch"].contains(where: { lower.contains($0) }) {
        return ScenarioResult(currentScore: currentScore, projectedScore: max(currentScore-5,0), delta: -5,
            explanation: "Skipping a meal may reduce risk slightly (~5%), but don't skip meals regularly.")
    }

    return ScenarioResult(currentScore: currentScore, projectedScore: currentScore, delta: 0,
        explanation: "Couldn't determine the impact. Try asking about a specific food, stress, or sleep.")
}
