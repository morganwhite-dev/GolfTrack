import SwiftUI
import SwiftData

struct ClubDetailView: View {
    @Bindable var stats: ClubStats
    @Environment(\.modelContext) private var context

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Image(systemName: "figure.golf").font(.title).foregroundStyle(.emerald)
                    Text(stats.club.displayName).font(.title2.weight(.bold)).foregroundStyle(.textPrimary)
                    Text("\(stats.timesUsed) shots tracked").font(.subheadline).foregroundStyle(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .cardStyle(raised: true)

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Performance", icon: "chart.bar.fill")
                    StatRow(label: "Good Shots", value: "\(stats.goodShots)", valueColor: .emerald)
                    StatRow(label: "Bad Shots", value: "\(stats.badShots)")
                    StatRow(label: "Good Shot Rate", value: "\(Int(stats.goodShotRate * 100))%")
                    StatRow(label: "Average Confidence", value: stats.averageConfidence > 0 ? String(format: "%.1f / 3", stats.averageConfidence) : "—")
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Miss Breakdown", icon: "scope")
                    StatRow(label: "Left", value: "\(stats.missLeft)")
                    StatRow(label: "Right", value: "\(stats.missRight)")
                    StatRow(label: "Short", value: "\(stats.missShort)")
                    StatRow(label: "Long", value: "\(stats.missLong)")
                    StatRow(label: "Fat", value: "\(stats.fatShots)")
                    StatRow(label: "Thin", value: "\(stats.thinShots)")
                    StatRow(label: "Topped", value: "\(stats.toppedShots)")
                    StatRow(label: "Chunked", value: "\(stats.chunkedShots)")
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Notes", icon: "note.text")
                    InputField(placeholder: "Optional notes about this club", text: $stats.notes)
                        .onChange(of: stats.notes) { _, _ in try? context.save() }
                }
                .cardStyle()
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Club Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
