import SwiftUI

/// Placeholder for the Start Round tab — replaced with full course/date/holes setup in the Round Setup checkpoint.
struct StartRoundTabView: View {
    @Bindable var profile: UserProfile
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "flag.fill").font(.system(size: 40)).foregroundStyle(.golfGreen)
            Text("Start Round setup is coming in the next checkpoint.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .navigationTitle("Start Round")
    }
}
