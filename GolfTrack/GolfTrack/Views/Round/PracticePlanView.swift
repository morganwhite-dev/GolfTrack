import SwiftUI

struct PracticePlanView: View {
    let plan: PracticePlan
    var onDone: (() -> Void)? = nil

    private var drills: [PracticeDrill] {
        (plan.recommendedDrills ?? []).sorted { $0.timeMinutes > $1.timeMinutes }
    }

    var body: some View {
        VStack(spacing: 20) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle().fill(Color.emerald.opacity(0.12)).frame(width: 64, height: 64)
                        Image(systemName: "figure.golf").font(.title2).foregroundStyle(.emerald)
                    }
                    Text("Practice Plan").font(.title2.weight(.bold))
                    Text("\(plan.estimatedPracticeTime) minutes total").font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .cardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Focus Areas", icon: "scope")
                    StatRow(label: "Main Focus", value: plan.mainFocus, valueColor: .emerald)
                    StatRow(label: "Secondary Focus", value: plan.secondaryFocus)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Recommended Drills", icon: "list.bullet.clipboard.fill")
                    VStack(spacing: 10) {
                        ForEach(drills) { drill in
                            DrillRow(drill: drill)
                        }
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Next Round Goal", icon: "flag.checkered")
                    Text(plan.nextRoundGoal).font(.subheadline.weight(.semibold))
                }
                .cardStyle()

                if let onDone {
                    Button("Done") { onDone() }
                        .buttonStyle(.primaryGolf)
                }
        }
    }
}

private struct DrillRow: View {
    let drill: PracticeDrill
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(drill.title).font(.subheadline.weight(.semibold))
                Spacer()
                Pill(text: "\(drill.timeMinutes) min", color: .charcoal)
            }
            Text(drill.details).font(.caption).foregroundStyle(.secondary)
            Pill(text: drill.category.displayName)
        }
        .padding(.vertical, 6)
    }
}
