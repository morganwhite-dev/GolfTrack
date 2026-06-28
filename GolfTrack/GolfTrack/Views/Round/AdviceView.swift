import SwiftUI

struct AdviceView: View {
    let advice: RoundAdvice
    var onContinue: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            ratingCard

                section(title: "Strengths", icon: "checkmark.seal.fill", color: .emerald, items: advice.strengths)
                section(title: "Areas to Improve", icon: "arrow.up.forward.circle.fill", color: .warningAmber, items: advice.improvementAreas)

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Main Issue", icon: "exclamationmark.circle.fill")
                    Text(advice.mainIssue).font(.subheadline)
                    Divider()
                    SectionHeader(title: "Secondary Issue", icon: "exclamationmark.circle")
                    Text(advice.secondaryIssue).font(.subheadline)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Best Part of Your Round", icon: "star.fill")
                    Text(advice.bestPart).font(.subheadline)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Next Round Goal", icon: "flag.checkered")
                    Text(advice.nextRoundGoal).font(.subheadline.weight(.semibold))
                }
                .cardStyle()

                if let onContinue {
                    Button("View Practice Plan") { onContinue() }
                        .buttonStyle(.primaryGolf)
                }
        }
    }

    private var ratingCard: some View {
        VStack(spacing: 8) {
            Image(systemName: ratingIcon).font(.largeTitle).foregroundStyle(ratingColor)
            Text(advice.rating.displayName).font(.title2.weight(.bold))
            Text(ratingBlurb).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .cardStyle()
    }

    private var ratingIcon: String {
        switch advice.rating {
        case .great: return "trophy.fill"
        case .solid: return "checkmark.circle.fill"
        case .closeToGoal: return "target"
        case .average: return "equal.circle.fill"
        case .needsWork: return "wrench.and.screwdriver.fill"
        case .tough: return "cloud.rain.fill"
        }
    }

    private var ratingColor: Color {
        switch advice.rating {
        case .great, .solid: return .emerald
        case .closeToGoal, .average: return .warningAmber
        case .needsWork, .tough: return .slateGray
        }
    }

    private var ratingBlurb: String {
        switch advice.rating {
        case .great: return "A great round — your score matched or beat par."
        case .solid: return "A solid, consistent round overall."
        case .closeToGoal: return "You were close to your current goal. Useful focus areas below."
        case .average: return "An average round with some clear, fixable patterns."
        case .needsWork: return "A round that needs some work — but every round teaches you something."
        case .tough: return "A tough round, but useful data for what to work on next."
        }
    }

    private func section(title: String, icon: String, color: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: title, icon: icon)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle().fill(color).frame(width: 6, height: 6).padding(.top, 6)
                        Text(item).font(.subheadline)
                    }
                }
            }
        }
        .cardStyle()
    }
}
