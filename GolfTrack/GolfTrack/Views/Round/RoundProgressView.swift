import SwiftUI
import SwiftData

struct RoundProgressView: View {
    @Bindable var round: GolfRound
    var onFinish: () -> Void
    var onDiscard: () -> Void

    @Environment(\.modelContext) private var context
    @State private var currentIndex: Int = 0
    @State private var showEndConfirm = false
    @State private var showDiscardConfirm = false

    private var holes: [HoleScore] { round.sortedHoleScores }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            holeStrip
            Divider()
            if holes.indices.contains(currentIndex) {
                HoleEntryView(holeScore: holes[currentIndex])
            }
            Divider()
            bottomBar
        }
        .onAppear { currentIndex = firstIncompleteIndex() }
        .confirmationDialog("End Round Early?", isPresented: $showEndConfirm, titleVisibility: .visible) {
            Button("End Round", role: .destructive) { finishRound() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Any holes you haven't entered will be left at 0 strokes.")
        }
        .confirmationDialog("Discard This Round?", isPresented: $showDiscardConfirm, titleVisibility: .visible) {
            Button("Discard Round", role: .destructive) { discardRound() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes this round. This can't be undone.")
        }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(round.course?.name ?? "Round").font(.subheadline.weight(.semibold))
                Text("\(round.totalStrokes) strokes • \(scoreToParText(round.scoreToPar))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                Button("End Round Early", role: .destructive) { showEndConfirm = true }
                Button("Discard Round", role: .destructive) { showDiscardConfirm = true }
            } label: {
                Image(systemName: "ellipsis.circle").font(.title3).foregroundStyle(.primary)
            }
        }
        .padding()
    }

    private var holeStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(holes.enumerated()), id: \.element.id) { index, hole in
                    Button { currentIndex = index } label: {
                        VStack(spacing: 3) {
                            Text("\(hole.holeNumber)").font(.caption.weight(.semibold))
                            Circle()
                                .fill(hole.strokes > 0 ? Color.emerald : Color.secondary.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                        .frame(width: 36, height: 36)
                        .background(index == currentIndex ? Color.emerald.opacity(0.15) : Color.clear, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                currentIndex = max(0, currentIndex - 1)
            } label: {
                Label("Previous", systemImage: "chevron.left").font(.subheadline.weight(.semibold))
            }
            .disabled(currentIndex == 0)
            .opacity(currentIndex == 0 ? 0.4 : 1)

            Spacer()

            if currentIndex == holes.count - 1 {
                Button("Finish Round") { finishRound() }
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(LinearGradient.emerald, in: Capsule())
                    .foregroundStyle(.white)
            } else {
                Button {
                    currentIndex = min(holes.count - 1, currentIndex + 1)
                } label: {
                    Label("Next", systemImage: "chevron.right").font(.subheadline.weight(.semibold))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private func firstIncompleteIndex() -> Int {
        holes.firstIndex(where: { $0.strokes == 0 }) ?? max(0, holes.count - 1)
    }

    private func finishRound() {
        round.isComplete = true
        try? context.save()
        onFinish()
    }

    private func discardRound() {
        context.delete(round)
        try? context.save()
        onDiscard()
    }
}
