import SwiftUI

/// Placeholder — replaced with full club performance tracking in the Club Stats checkpoint.
struct ClubStatsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.golf").font(.system(size: 40)).foregroundStyle(.golfGreen)
            Text("Club performance stats are coming in a later checkpoint.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .navigationTitle("Clubs")
    }
}
