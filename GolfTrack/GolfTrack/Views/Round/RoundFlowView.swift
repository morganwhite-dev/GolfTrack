import SwiftUI
import SwiftData

struct RoundFlowView: View {
    @Bindable var round: GolfRound
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var stage: Stage = .play

    enum Stage { case play, summary, reflection, advice, practicePlan }

    var body: some View {
        Group {
            switch stage {
            case .play:
                RoundProgressView(
                    round: round,
                    onFinish: { withAnimation { stage = .summary } },
                    onDiscard: { dismiss() }
                )
            case .summary:
                ScrollView {
                    RoundSummaryView(round: round, onContinue: { withAnimation { stage = .reflection } })
                        .padding()
                }
                .appBackground()
            case .reflection:
                RoundReflectionView(round: round, onContinue: {
                    generateAdviceAndPlan()
                    withAnimation { stage = .advice }
                })
            case .advice:
                if let advice = round.advice {
                    ScrollView {
                        AdviceView(advice: advice, onContinue: { withAnimation { stage = .practicePlan } })
                            .padding()
                    }
                    .appBackground()
                }
            case .practicePlan:
                if let plan = round.practicePlan {
                    ScrollView {
                        PracticePlanView(plan: plan, onDone: { dismiss() })
                            .padding()
                    }
                    .appBackground()
                }
            }
        }
    }

    private func generateAdviceAndPlan() {
        let stats = RoundStats(round: round)
        let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first
        let advice = RoundAnalysisService.generateAdvice(round: round, stats: stats, profile: profile)
        round.advice = advice
        context.insert(advice)

        let plan = PracticePlanService.generatePlan(round: round, stats: stats, advice: advice)
        round.practicePlan = plan
        context.insert(plan)
        for drill in plan.recommendedDrills ?? [] {
            context.insert(drill)
        }

        try? context.save()
        ClubStatsService.recompute(in: context)
    }
}
