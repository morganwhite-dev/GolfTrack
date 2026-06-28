import SwiftUI

/// Placeholder — replaced with the full round detail (summary + reflection + advice + plan) in the History checkpoint.
struct RoundDetailView: View {
    let round: GolfRound
    var body: some View {
        VStack(spacing: 12) {
            Text(round.course?.name ?? "Round").font(.title2.bold())
            Text(round.date.formatted(date: .abbreviated, time: .omitted)).foregroundStyle(.secondary)
            Text("\(round.totalStrokes) strokes (\(scoreToParText(round.scoreToPar)))")
        }
        .navigationTitle("Round Detail")
    }
}
