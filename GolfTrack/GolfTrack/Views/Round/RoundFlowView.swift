import SwiftUI

/// Placeholder — replaced with the full play/summary/reflection/advice/practice-plan flow
/// across the Hole Entry, Round Summary, Reflection, Advice, and Practice Plan checkpoints.
struct RoundFlowView: View {
    let round: GolfRound
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text(round.course?.name ?? "Round").font(.title2.bold())
            Text("Hole-by-hole entry is coming in a later checkpoint.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Close") { dismiss() }
                .buttonStyle(.primaryGolf)
                .padding(.horizontal)
        }
    }
}
