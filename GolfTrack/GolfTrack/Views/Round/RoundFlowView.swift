import SwiftUI
import SwiftData

struct RoundFlowView: View {
    @Bindable var round: GolfRound
    var onPause: () -> Void = {}
    var onSwitchRound: (GolfRound) -> Void = { _ in }
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var stage: Stage = .play
    @State private var showCelebration = false

    enum Stage { case play, summary, cleanup, reflection, advice, practicePlan }

    var body: some View {
        Group {
            switch stage {
            case .play:
                RoundProgressView(
                    round: round,
                    onPause: {
                        onPause()
                        dismiss()
                    },
                    onSwitchRound: onSwitchRound,
                    onFinish: {
                        stage = .summary
                        showCelebration = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                            withAnimation(.easeOut(duration: 0.4)) { showCelebration = false }
                        }
                    },
                    onDiscard: { dismiss() }
                )
            case .summary:
                ScrollView {
                    RoundSummaryView(
                        round: round,
                        onContinue: { withAnimation { stage = .cleanup } },
                        continueTitle: "Review Round Details"
                    )
                        .padding()
                }
                .appBackground()
            case .cleanup:
                RoundDetailCleanupView(
                    round: round,
                    onContinue: { withAnimation { stage = .reflection } }
                )
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
        .overlay {
            if showCelebration {
                RoundCompleteOverlay()
                    .transition(.opacity)
            }
        }
        .buttonStyle(.bouncy)
    }

    private func generateAdviceAndPlan() {
        let stats = RoundStats(round: round)
        let profile = round.profile
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
        if let profile {
            ClubStatsService.recompute(for: profile, in: context)
        }
    }
}

private struct RoundDetailCleanupView: View {
    @Bindable var round: GolfRound
    var onContinue: () -> Void
    @Environment(\.modelContext) private var context
    @State private var selectedHoleID: UUID?
    @State private var showingHoleEditor = false

    private var holes: [HoleScore] {
        round.sortedHoleScores
    }

    private var holesNeedingDetail: [HoleScore] {
        holes.filter { !$0.detailIsStrong }
    }

    private var selectedHole: HoleScore? {
        guard let selectedHoleID else { return nil }
        return holes.first { $0.id == selectedHoleID }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                explanationCard

                if holesNeedingDetail.isEmpty {
                    completeCard
                } else {
                    missingDetailsCard
                }

                Button(holesNeedingDetail.isEmpty ? "Continue to Reflection" : "Skip for Now") {
                    saveAndContinue()
                }
                .buttonStyle(.primaryGolf)
            }
            .padding()
        }
        .appBackground()
        .sheet(isPresented: $showingHoleEditor) {
            if let selectedHole {
                NavigationStack {
                    HoleEntryView(holeScore: selectedHole)
                        .navigationTitle("Hole \(selectedHole.holeNumber)")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                ToolbarPillButton(title: "Done") {
                                    hapticTap()
                                    try? context.save()
                                    showingHoleEditor = false
                                }
                            }
                        }
                }
                .preferredColorScheme(.dark)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Add Details While Fresh")
                .font(.title2.weight(.bold))
                .foregroundStyle(.textPrimary)
            Text("Fast scoring captured the round. A few details help the app understand what actually happened.")
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var explanationCard: some View {
        HStack(alignment: .top, spacing: 12) {
            IconBadge(icon: "sparkles", color: .emerald, size: 38)
            VStack(alignment: .leading, spacing: 4) {
                Text("Better details, better advice")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.textPrimary)
                Text("Add a miss, contact note, club, penalty context, or quick note on the holes you remember. You can skip anything you do not care about.")
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(raised: true)
    }

    private var completeCard: some View {
        HStack(spacing: 12) {
            IconBadge(icon: "checkmark.seal.fill", color: .emerald, size: 42)
            VStack(alignment: .leading, spacing: 3) {
                Text("Looks ready")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.textPrimary)
                Text("This round has enough detail for useful advice.")
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
            }
            Spacer()
        }
        .cardStyle()
    }

    private var missingDetailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick Review", subtitle: "\(holesNeedingDetail.count) hole\(holesNeedingDetail.count == 1 ? "" : "s") could use more detail", icon: "list.bullet.clipboard.fill")

            ForEach(holesNeedingDetail, id: \.id) { hole in
                Button {
                    selectedHoleID = hole.id
                    showingHoleEditor = true
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hole \(hole.holeNumber)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.textPrimary)
                            Text(missingDetailText(for: hole))
                                .font(.caption)
                                .foregroundStyle(.textSecondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.textTertiary)
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)

                if hole.id != holesNeedingDetail.last?.id {
                    Divider().overlay(Color.white.opacity(0.08))
                }
            }
        }
        .cardStyle()
    }

    private func missingDetailText(for hole: HoleScore) -> String {
        var missing: [String] = []
        if hole.teeClub == nil { missing.append("tee club") }
        if hole.teeShotResult == nil { missing.append("tee result") }
        if hole.contactQuality == nil { missing.append("contact") }
        if hole.penalties > 0 && hole.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append("penalty note")
        }
        if hole.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append("notes")
        }
        return missing.isEmpty ? "Add anything you remember." : "Missing \(missing.prefix(3).joined(separator: ", "))"
    }

    private func saveAndContinue() {
        try? context.save()
        onContinue()
    }
}

private extension HoleScore {
    var detailIsStrong: Bool {
        if strokes <= 0 { return true }
        let hasShotDetail = teeShotResult != nil || contactQuality != nil || teeClub != nil
        let hasNote = !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let penaltyNeedsNote = penalties > 0 && !hasNote
        return (hasShotDetail || hasNote) && !penaltyNeedsNote
    }
}
