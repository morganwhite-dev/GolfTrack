import SwiftUI

/// Placeholder — replaced with full round history list in the History checkpoint.
struct HistoryView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.fill").font(.system(size: 40)).foregroundStyle(.golfGreen)
            Text("Round history is coming in a later checkpoint.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .navigationTitle("History")
    }
}
