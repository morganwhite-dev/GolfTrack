import SwiftUI

struct RoundDetailView: View {
    let round: GolfRound

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                RoundSummaryView(round: round)

                if let reflection = round.reflection {
                    ReflectionReadOnlyView(reflection: reflection)
                }

                if let advice = round.advice {
                    SectionHeader(title: "Advice", icon: "lightbulb.fill")
                    AdviceView(advice: advice)
                }

                if let plan = round.practicePlan {
                    SectionHeader(title: "Practice Plan", icon: "figure.golf")
                    PracticePlanView(plan: plan)
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Round Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ReflectionReadOnlyView: View {
    let reflection: RoundReflection

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Reflection", icon: "text.bubble.fill")

            VStack(alignment: .leading, spacing: 10) {
                feelRow("Tee Shots", reflection.teeShotFeel)
                feelRow("Iron Play", reflection.ironPlayFeel)
                feelRow("Wedge Play", reflection.wedgePlayFeel)
                feelRow("Short Game", reflection.shortGameFeel)
                feelRow("Putting", reflection.puttingFeel)
                if let miss = reflection.biggestMiss {
                    StatRow(label: "Biggest Miss", value: miss.displayName)
                }
                StatRow(label: "Mental Mistakes", value: reflection.hadMentalMistakes ? "Yes" : "No")
            }
            .cardStyle()

            if !reflection.feltBestText.isEmpty {
                freeTextCard(title: "What felt best", text: reflection.feltBestText)
            }
            if !reflection.frustratedText.isEmpty {
                freeTextCard(title: "What frustrated you most", text: reflection.frustratedText)
            }
            if !reflection.improveNextText.isEmpty {
                freeTextCard(title: "Wanted to improve next round", text: reflection.improveNextText)
            }
        }
    }

    private func feelRow(_ label: String, _ feel: FeelRating?) -> some View {
        StatRow(label: label, value: feel?.displayName ?? "—")
    }

    private func freeTextCard(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
            Text(text).font(.subheadline).foregroundStyle(.textSecondary)
        }
        .cardStyle()
    }
}
