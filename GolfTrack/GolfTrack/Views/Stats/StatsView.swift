import SwiftUI

/// Placeholder — replaced with the full stats dashboard in the Stats checkpoint.
struct StatsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.fill").font(.system(size: 40)).foregroundStyle(.golfGreen)
            Text("Scoring trends and stats are coming in a later checkpoint.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .navigationTitle("Stats")
    }
}
