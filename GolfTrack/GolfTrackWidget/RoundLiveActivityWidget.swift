import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct RoundLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RoundActivityAttributes.self) { context in
            RoundLiveActivityLockScreenView(context: context)
                .activityBackgroundTint(GolfActivityStyle.bgTop)
                .activitySystemActionForegroundColor(.clear)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.courseName)
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                        Text("Hole \(context.state.holeNumber)")
                            .font(.title3.weight(.bold))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("To Par")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(scoreToParText(context.state.totalStrokes - context.state.totalPar))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(GolfActivityStyle.emerald)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    RoundLiveActivityDashboardView(context: context)
                }
            } compactLeading: {
                Text("H\(context.state.holeNumber)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(GolfActivityStyle.emerald)
            } compactTrailing: {
                Text("S\(context.state.strokesThisHole)")
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
            } minimal: {
                Text("\(context.state.holeNumber)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(GolfActivityStyle.emerald)
            }
        }
    }
}

private struct RoundLiveActivityLockScreenView: View {
    let context: ActivityViewContext<RoundActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundLiveActivityHeaderView(context: context)
            RoundLiveActivitySummaryView(context: context)
            RoundLiveActivityControlsView(isFinalHole: context.state.isFinalHole)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(GolfActivityStyle.bgBottom.opacity(0.25))
        .sensoryFeedback(.selection, trigger: context.state.strokesThisHole)
        .sensoryFeedback(.selection, trigger: context.state.puttsThisHole)
    }
}

private struct RoundLiveActivityDashboardView: View {
    let context: ActivityViewContext<RoundActivityAttributes>

    var body: some View {
        VStack(spacing: 8) {
            RoundLiveActivitySummaryView(context: context)
            RoundLiveActivityControlsView(isFinalHole: context.state.isFinalHole)
        }
        .sensoryFeedback(.selection, trigger: context.state.strokesThisHole)
        .sensoryFeedback(.selection, trigger: context.state.puttsThisHole)
    }
}

private struct RoundLiveActivityHeaderView: View {
    let context: ActivityViewContext<RoundActivityAttributes>

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(GolfActivityStyle.emerald.opacity(0.18))
                Image(systemName: "flag.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(GolfActivityStyle.emerald)
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 1) {
                Text(context.attributes.courseName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .allowsTightening(true)
                HStack(spacing: 4) {
                    Text("Hole \(context.state.holeNumber) of \(context.attributes.totalHoles)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    if let paceText = context.state.paceText {
                        Text("•")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                        Text(paceText)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(paceText == "On pace" ? GolfActivityStyle.emerald : GolfActivityStyle.warningAmber)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            Text(scoreToParText(context.state.totalStrokes - context.state.totalPar))
                .font(.title3.weight(.black))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(GolfActivityStyle.emerald)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(GolfActivityStyle.emerald.opacity(0.14), in: Capsule())
                .frame(minWidth: 44)
        }
    }
}

private struct RoundLiveActivitySummaryView: View {
    let context: ActivityViewContext<RoundActivityAttributes>

    var body: some View {
        HStack(spacing: 8) {
            metric("Strokes", "\(context.state.strokesThisHole)")
            metric("Putts", "\(context.state.puttsThisHole)")
            metric("Total", "\(context.state.totalStrokes)")
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(value)
                .font(.headline.weight(.bold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, minHeight: 30)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct RoundLiveActivityControlsView: View {
    let isFinalHole: Bool

    var body: some View {
        HStack(spacing: 7) {
            controlPair(iconName: "figure.golf", removeIntent: RemoveStrokeIntent(), addIntent: AddStrokeIntent())
            controlPair(iconName: "smallcircle.filled.circle", removeIntent: RemovePuttIntent(), addIntent: AddPuttIntent())
            advanceButton
        }
    }

    private func controlPair<RemoveIntent: AppIntent, AddIntent: AppIntent>(
        iconName: String,
        removeIntent: RemoveIntent,
        addIntent: AddIntent
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: iconName)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 17, height: 17)
            actionButton(systemName: "minus", intent: removeIntent)
            actionButton(systemName: "plus", intent: addIntent)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 7)
        .frame(height: 36)
        .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func actionButton<I: AppIntent>(systemName: String, intent: I) -> some View {
        Button(intent: intent) {
            Image(systemName: systemName)
                .font(.caption.weight(.bold))
                .frame(width: 25, height: 25)
        }
        .buttonStyle(.plain)
        .foregroundStyle(GolfActivityStyle.emerald)
        .background(Color.white.opacity(0.13), in: Circle())
    }

    @ViewBuilder
    private var advanceButton: some View {
        if isFinalHole {
            Button(intent: FinishRoundIntent()) {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.black))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.black)
            .background(GolfActivityStyle.emerald, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            Button(intent: NextHoleIntent()) {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.black))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.black)
            .background(GolfActivityStyle.emerald, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

private enum GolfActivityStyle {
    static let bgTop = Color(red: 0.035, green: 0.09, blue: 0.065)
    static let bgBottom = Color(red: 0.01, green: 0.015, blue: 0.012)
    static let emerald = Color(red: 0.22, green: 0.86, blue: 0.55)
    static let warningAmber = Color(red: 0.93, green: 0.58, blue: 0.27)
}

private func scoreToParText(_ score: Int) -> String {
    if score == 0 { return "E" }
    return score > 0 ? "+\(score)" : "\(score)"
}
