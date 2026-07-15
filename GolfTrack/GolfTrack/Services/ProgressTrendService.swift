import Foundation

/// A single metric compared between your most recent rounds and the equally-sized window of
/// rounds right before that — the "is what I've been working on actually working" proof.
struct ProgressTrend: Identifiable {
    let id = UUID()
    let label: String
    let recentValue: Double
    let priorValue: Double
    let lowerIsBetter: Bool
    let formatter: (Double) -> String

    private var delta: Double { recentValue - priorValue }

    var improved: Bool { lowerIsBetter ? delta < -0.01 : delta > 0.01 }
    var declined: Bool { lowerIsBetter ? delta > 0.01 : delta < -0.01 }

    var recentText: String { formatter(recentValue) }
    var priorText: String { formatter(priorValue) }
}

enum ProgressTrendService {
    /// Rounds per comparison window. Need two full windows of history before a trend means anything.
    static let windowSize = 5

    /// `stats` must already be sorted most-recent-first (the same order `completedRounds` queries in).
    static func trends(from stats: [RoundStats]) -> [ProgressTrend]? {
        guard stats.count >= windowSize * 2 else { return nil }
        let recent = Array(stats.prefix(windowSize))
        let prior = Array(stats[windowSize..<(windowSize * 2)])

        func average(_ values: [Double]) -> Double {
            values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
        }
        func averageInt(_ pick: (RoundStats) -> Int, in group: [RoundStats]) -> Double {
            average(group.map { Double(pick($0)) })
        }
        func averagePct(_ pick: (RoundStats) -> Double?, in group: [RoundStats]) -> Double {
            average(group.compactMap(pick))
        }

        return [
            ProgressTrend(
                label: "Scoring (to Par)",
                recentValue: averageInt(\.scoreToPar, in: recent),
                priorValue: averageInt(\.scoreToPar, in: prior),
                lowerIsBetter: true,
                formatter: { v in v == 0 ? "E" : (v > 0 ? "+\(String(format: "%.1f", v))" : String(format: "%.1f", v)) }
            ),
            ProgressTrend(
                label: "3-Putts / Round",
                recentValue: averageInt(\.threePutts, in: recent),
                priorValue: averageInt(\.threePutts, in: prior),
                lowerIsBetter: true,
                formatter: { String(format: "%.1f", $0) }
            ),
            ProgressTrend(
                label: "Penalties / Round",
                recentValue: averageInt(\.totalPenalties, in: recent),
                priorValue: averageInt(\.totalPenalties, in: prior),
                lowerIsBetter: true,
                formatter: { String(format: "%.1f", $0) }
            ),
            ProgressTrend(
                label: "Fairways Hit",
                recentValue: averagePct(\.fairwayHitPercentage, in: recent),
                priorValue: averagePct(\.fairwayHitPercentage, in: prior),
                lowerIsBetter: false,
                formatter: { "\(Int($0))%" }
            ),
            ProgressTrend(
                label: "Greens in Reg.",
                recentValue: averagePct(\.girPercentage, in: recent),
                priorValue: averagePct(\.girPercentage, in: prior),
                lowerIsBetter: false,
                formatter: { "\(Int($0))%" }
            ),
        ]
    }
}
