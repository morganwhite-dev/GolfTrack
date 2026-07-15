import SwiftUI
import SwiftData

struct PracticePlanView: View {
    let plan: PracticePlan
    var onDone: (() -> Void)? = nil

    private var drills: [PracticeDrill] {
        (plan.recommendedDrills ?? []).sorted { $0.timeMinutes > $1.timeMinutes }
    }

    private var completedCount: Int {
        drills.filter(\.isComplete).count
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                ZStack {
                    Circle().fill(Color.emerald.opacity(0.16)).frame(width: 64, height: 64)
                    Image(systemName: "figure.golf").font(.title2).foregroundStyle(.emerald)
                }
                Text("Practice Plan").font(.title2.weight(.bold)).foregroundStyle(.textPrimary)
                Text("\(plan.estimatedPracticeTime) min total").font(.subheadline).foregroundStyle(.textSecondary)
                if !drills.isEmpty {
                    Text("\(completedCount) of \(drills.count) drills complete")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(completedCount == drills.count ? .emerald : .textSecondary)
                        .contentTransition(.numericText())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .cardStyle(raised: true)

            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Recommended Drills", icon: "list.bullet.clipboard.fill")
                VStack(spacing: 10) {
                    ForEach(drills) { drill in
                        DrillRow(drill: drill)
                    }
                }
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
    @Bindable var drill: PracticeDrill
    @Environment(\.modelContext) private var context

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                drill.isComplete.toggle()
                drill.completedDate = drill.isComplete ? Date() : nil
            }
            try? context.save()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: drill.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(drill.isComplete ? .emerald : .textTertiary)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(drill.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(drill.isComplete ? .textSecondary : .textPrimary)
                            .strikethrough(drill.isComplete, color: .textSecondary)
                        Spacer()
                        Pill(text: "\(drill.timeMinutes) min", color: .charcoal)
                    }
                    Text(drill.details).font(.caption).foregroundStyle(.textSecondary)
                    HStack(spacing: 6) {
                        Pill(text: drill.category.displayName)
                        if drill.isComplete {
                            Pill(text: "Done", color: .emerald, filled: true)
                        }
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.bouncy)
    }
}
