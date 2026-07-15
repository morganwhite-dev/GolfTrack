import SwiftUI
import SwiftData

/// Live read on whether the current pace of play would beat the round's target score —
/// projects the current score-to-par rate (over holes actually played) across the full round
/// and compares it to the target's overall score-to-par.
struct PaceStatus {
    let projectedToPar: Int
    let targetToPar: Int
    var onPace: Bool { projectedToPar <= targetToPar }
    var difference: Int { projectedToPar - targetToPar }
}

/// Surfaces the player's own history on this exact hole at this course — a live caddie note
/// instead of only post-round analysis. Built entirely from data already being tracked.
struct CaddieNote {
    let timesPlayed: Int
    let averageScoreToPar: Double
    let commonMiss: MissDirection?

    var summary: String {
        let avgText = scoreToParText(Int(averageScoreToPar.rounded()))
        var text = "You've played this hole \(timesPlayed)\(timesPlayed == 1 ? " time" : " times"), averaging \(avgText)."
        if let commonMiss, commonMiss != .good, commonMiss != .na {
            text += " Common miss: \(commonMiss.displayName)."
        }
        return text
    }
}

struct RoundCoachNudge {
    let icon: String
    let color: Color
    let title: String
    let message: String
}

struct RoundProgressView: View {
    @Bindable var round: GolfRound
    var onPause: () -> Void
    var onSwitchRound: (GolfRound) -> Void
    var onFinish: () -> Void
    var onDiscard: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("activeProfileID") private var activeProfileIDString: String = ""
    @AppStorage("profileSwitchResumeRoundID") private var profileSwitchResumeRoundIDString: String = ""
    @Query(sort: \UserProfile.createdDate) private var allProfiles: [UserProfile]
    @Query(filter: #Predicate<GolfRound> { !$0.isComplete }, sort: \GolfRound.date, order: .reverse)
    private var allInProgressRounds: [GolfRound]
    @Query(filter: #Predicate<GolfRound> { $0.isComplete }, sort: \GolfRound.date, order: .reverse)
    private var allCompletedRounds: [GolfRound]
    @State private var currentIndex: Int = 0
    @State private var showEndConfirm = false
    @State private var showDiscardConfirm = false
    @State private var showPlayerSwitcher = false
    @State private var liveActivityState: LiveActivityState = .checking
    @State private var lastLiveActivityRevision = 0
    @State private var didHandleLiveActivityFinish = false
    @State private var completedHoleIDs: Set<UUID> = []

    private enum LiveActivityState {
        case checking, active, unavailable
    }

    private var holes: [HoleScore] { round.sortedHoleScores }

    private var pastRoundsAtThisCourse: [GolfRound] {
        guard let course = round.course else { return [] }
        return allCompletedRounds.filter {
            $0.id != round.id && $0.course?.id == course.id && $0.profile?.id == round.profile?.id
        }
    }

    private func caddieNote(for hole: HoleScore) -> CaddieNote? {
        let past = pastRoundsAtThisCourse
            .flatMap { $0.sortedHoleScores }
            .filter { $0.holeNumber == hole.holeNumber && $0.strokes > 0 }
        guard !past.isEmpty else { return nil }
        let avgToPar = Double(past.reduce(0) { $0 + $1.scoreToPar }) / Double(past.count)
        let misses = past.map(\.missDirection).filter { $0 != .good && $0 != .na }
        let missCounts = Dictionary(grouping: misses, by: { $0 }).mapValues(\.count)
        let commonMiss = missCounts.max(by: { $0.value < $1.value })?.key
        return CaddieNote(timesPlayed: past.count, averageScoreToPar: avgToPar, commonMiss: commonMiss)
    }

    private var paceStatus: PaceStatus? {
        guard let target = round.targetScore else { return nil }
        let completed = holes.filter { $0.strokes > 0 }
        guard !completed.isEmpty else { return nil }
        let scoreToParSoFar = completed.reduce(0) { $0 + $1.scoreToPar }
        let projected = Int((Double(scoreToParSoFar) / Double(completed.count) * Double(holes.count)).rounded())
        let targetToPar = target - round.totalPar
        return PaceStatus(projectedToPar: projected, targetToPar: targetToPar)
    }

    private var currentHole: HoleScore? {
        holes.indices.contains(currentIndex) ? holes[currentIndex] : nil
    }

    private var currentProfileName: String {
        let name = round.profile?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Golfer" : name
    }

    private var roundCoachNudge: RoundCoachNudge? {
        let played = holes.filter { $0.strokes > 0 }
        let threePutts = played.filter { $0.isThreePutt }.count
        if threePutts >= 2 {
            return RoundCoachNudge(
                icon: "smallcircle.filled.circle",
                color: .warningAmber,
                title: "Putting Reset",
                message: "Two 3-putts already. Favor speed control over trying to make everything."
            )
        }

        let penalties = played.reduce(0) { $0 + $1.penalties }
        if penalties >= 2 {
            return RoundCoachNudge(
                icon: "exclamationmark.triangle.fill",
                color: .alertCoral,
                title: "Course Management",
                message: "Penalties are adding up. Aim at the widest safe zone, not the perfect line."
            )
        }

        if let pace = paceStatus, !pace.onPace {
            return RoundCoachNudge(
                icon: "target",
                color: .warningAmber,
                title: "Target Pace",
                message: "You're projected \(pace.difference) over target. Pick safer targets for the next couple holes."
            )
        }

        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            holeStrip
            Divider()
            if holes.indices.contains(currentIndex) {
                HoleEntryView(
                    holeScore: holes[currentIndex],
                    caddieNote: caddieNote(for: holes[currentIndex]),
                    onScoreChanged: { updateLiveActivity() }
                )
            }
            Divider()
            bottomBar
        }
        .appBackground()
        .onAppear {
            currentIndex = activeHoleIndexFromRound() ?? activeHoleIndexFromStore() ?? firstIncompleteIndex()
            completedHoleIDs = Set(holes.prefix(currentIndex).map(\.id))
            lastLiveActivityRevision = LiveActivityRoundStore.revision
            persistActiveHole()
            syncFromLiveActivityStore(force: true)
            startLiveActivity()
        }
        .onChange(of: currentIndex) { _, _ in
            persistActiveHole()
            updateLiveActivity()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                syncFromLiveActivityStore(force: false)
                finishFromLiveActivityIfNeeded()
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            guard scenePhase == .active else { return }
            syncFromLiveActivityStore(force: false)
            finishFromLiveActivityIfNeeded()
        }
    }

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(round.course?.name ?? "Round").font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
                    Text("\(currentProfileName) • \(round.totalStrokes) strokes • \(scoreToParText(round.scoreToPar))")
                        .font(.caption).foregroundStyle(.textSecondary)
                }
                Spacer()
                Button {
                    pauseRound()
                } label: {
                    Image(systemName: "house.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.textPrimary)
                        .frame(width: 31, height: 31)
                        .background(Color.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Pause round and return home")

                Button {
                    hapticTap()
                    showPlayerSwitcher = true
                } label: {
                    Label("Players", systemImage: "person.2.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.emerald)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.emerald.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Switch player")

                Menu {
                    Button("End Round Early", role: .destructive) { showEndConfirm = true }
                    Button("Discard Round", role: .destructive) { showDiscardConfirm = true }
                } label: {
                    Label("Round", systemImage: "flag.checkered")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08), in: Capsule())
                }
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

            if let pace = paceStatus {
                paceBadge(pace)
            }
            if liveActivityState != .checking {
                liveActivityBadge
            }
            if liveActivityState == .active {
                liveActivityFastLogNote
            }
            if let nudge = roundCoachNudge {
                roundCoachCard(nudge)
            }
        }
        .padding()
        .sheet(isPresented: $showPlayerSwitcher) {
            PlayerSwitcherSheet(
                currentProfileID: round.profile?.id,
                profiles: allProfiles,
                inProgressRounds: allInProgressRounds,
                onSwitch: switchToProfile
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .preferredColorScheme(.dark)
        }
    }

    private var liveActivityBadge: some View {
        let isActive = liveActivityState == .active
        return HStack(spacing: 6) {
            Image(systemName: isActive ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.caption.weight(.semibold))
            Text(liveActivityBadgeText)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(isActive ? Color.emerald : Color.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background((isActive ? Color.emerald : Color.white).opacity(isActive ? 0.14 : 0.07), in: Capsule())
    }

    private var liveActivityBadgeText: String {
        switch liveActivityState {
        case .checking: return "Checking Lock Screen scoring"
        case .active: return "Lock Screen scoring active"
        case .unavailable: return "Live Activities unavailable"
        }
    }

    private var liveActivityFastLogNote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "bolt.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.emerald)
                .frame(width: 18, height: 18)
                .background(Color.emerald.opacity(0.14), in: Circle())
            Text("Fast log records strokes, putts, and hole changes. Open the app for clubs, misses, penalties, notes, and full shot details.")
                .font(.caption2)
                .foregroundStyle(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.emerald.opacity(0.12), lineWidth: 1)
        )
    }

    private func paceBadge(_ pace: PaceStatus) -> some View {
        let color: Color = pace.onPace ? .emerald : .warningAmber
        return HStack(spacing: 6) {
            Image(systemName: pace.onPace ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.caption)
            Text(pace.onPace
                 ? "On pace to beat your target (\(scoreToParText(pace.targetToPar)))"
                 : "Off pace by \(pace.difference) — target \(scoreToParText(pace.targetToPar))")
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(color.opacity(0.14), in: Capsule())
    }

    private func roundCoachCard(_ nudge: RoundCoachNudge) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: nudge.icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(nudge.color)
                .frame(width: 24, height: 24)
                .background(nudge.color.opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(nudge.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(nudge.color)
                Text(nudge.message)
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(nudge.color.opacity(0.18), lineWidth: 1)
        )
    }

    private var holeStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(holes.enumerated()), id: \.element.id) { index, hole in
                    Button {
                        currentIndex = index
                    } label: {
                        VStack(spacing: 3) {
                            Text("\(hole.holeNumber)").font(.caption.weight(.semibold)).foregroundStyle(.textPrimary)
                            Group {
                                if completedHoleIDs.contains(hole.id) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 7, weight: .black))
                                        .foregroundStyle(Color.emerald)
                                } else {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 5, height: 5)
                                }
                            }
                            .frame(width: 10, height: 8)
                        }
                        .frame(width: 36, height: 36)
                        .background(index == currentIndex ? Color.emerald.opacity(0.15) : Color.clear, in: Circle())
                    }
                    .buttonStyle(.bouncy)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                moveToPreviousHole()
            } label: {
                Label("Previous", systemImage: "chevron.left").font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.textPrimary)
            .disabled(currentIndex == 0)
            .opacity(currentIndex == 0 ? 0.4 : 1)

            Spacer()

            if currentIndex == holes.count - 1 {
                Button("Finish Round") { finishRound() }
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(LinearGradient.emerald, in: Capsule())
                    .foregroundStyle(.black)
            } else {
                Button {
                    moveToNextHole()
                } label: {
                    Label("Next", systemImage: "chevron.right").font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.textPrimary)
            }
        }
        .padding()
        .background(Color.cardFill)
    }

    private func firstIncompleteIndex() -> Int {
        holes.firstIndex(where: { $0.strokes == 0 }) ?? max(0, holes.count - 1)
    }

    private func activeHoleIndexFromStore() -> Int? {
        guard let activeHoleNumber = LiveActivityRoundStore.activeHoleNumber else { return nil }
        return holes.firstIndex { $0.holeNumber == activeHoleNumber }
    }

    private func activeHoleIndexFromRound() -> Int? {
        guard let activeHoleNumber = round.activeHoleNumber else { return nil }
        return holes.firstIndex { $0.holeNumber == activeHoleNumber }
    }

    private func finishRound() {
        round.activeHoleNumber = nil
        round.isComplete = true
        try? context.save()
        Task { await LiveActivityManager.end(for: round) }
        onFinish()
    }

    private func discardRound() {
        Task { await LiveActivityManager.end(for: round) }
        context.delete(round)
        try? context.save()
        onDiscard()
    }

    private func switchToProfile(_ profile: UserProfile) {
        guard profile.id != round.profile?.id else {
            showPlayerSwitcher = false
            return
        }
        hapticTap(.medium)
        persistActiveHole()
        try? context.save()
        profileSwitchResumeRoundIDString = ""
        activeProfileIDString = profile.id.uuidString
        showPlayerSwitcher = false
        Task { await LiveActivityManager.end(for: round) }
        if let targetRound = allInProgressRounds.first(where: { $0.profile?.id == profile.id }) {
            onSwitchRound(targetRound)
        } else {
            onPause()
        }
    }

    private func pauseRound() {
        hapticTap(.medium)
        persistActiveHole()
        Task {
            guard holes.indices.contains(currentIndex) else { return }
            await LiveActivityManager.update(for: round, holeNumber: holes[currentIndex].holeNumber)
        }
        onPause()
    }

    private func startLiveActivity() {
        guard holes.indices.contains(currentIndex) else { return }
        Task {
            let didStart = await LiveActivityManager.start(for: round, holeNumber: holes[currentIndex].holeNumber)
            liveActivityState = didStart ? .active : .unavailable
        }
    }

    private func updateLiveActivity() {
        guard holes.indices.contains(currentIndex), !round.isComplete else { return }
        Task {
            await LiveActivityManager.update(for: round, holeNumber: holes[currentIndex].holeNumber)
        }
    }

    private func moveToNextHole() {
        guard holes.indices.contains(currentIndex), currentIndex < holes.count - 1 else { return }
        completedHoleIDs.insert(holes[currentIndex].id)
        currentIndex += 1
    }

    private func moveToPreviousHole() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    private func persistActiveHole() {
        guard holes.indices.contains(currentIndex) else { return }
        round.activeHoleNumber = holes[currentIndex].holeNumber
        try? context.save()
    }

    @MainActor
    private func syncFromLiveActivityStore(force: Bool) {
        let revision = LiveActivityRoundStore.revision
        guard force || revision != lastLiveActivityRevision else {
            context.processPendingChanges()
            return
        }
        lastLiveActivityRevision = revision

        guard let snapshot = LiveActivityRoundStore.snapshot(for: round.id) else {
            context.processPendingChanges()
            return
        }

        round.isComplete = snapshot.isComplete

        let currentHoles = round.sortedHoleScores
        for snapshotHole in snapshot.holes {
            if let hole = currentHoles.first(where: { $0.id == snapshotHole.id || $0.holeNumber == snapshotHole.holeNumber }) {
                hole.strokes = snapshotHole.strokes
                hole.putts = snapshotHole.putts
                hole.penalties = snapshotHole.penalties
            }
        }

        if let activeHoleNumber = snapshot.activeHoleNumber,
           let index = currentHoles.firstIndex(where: { $0.holeNumber == activeHoleNumber }) {
            completedHoleIDs.formUnion(currentHoles.prefix(index).map(\.id))
            round.activeHoleNumber = activeHoleNumber
            currentIndex = index
        }

        context.processPendingChanges()
    }

    @MainActor
    private func finishFromLiveActivityIfNeeded() {
        guard round.isComplete, !didHandleLiveActivityFinish else { return }
        didHandleLiveActivityFinish = true
        onFinish()
    }
}

private struct PlayerSwitcherSheet: View {
    let currentProfileID: UUID?
    let profiles: [UserProfile]
    let inProgressRounds: [GolfRound]
    var onSwitch: (UserProfile) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    VStack(spacing: 10) {
                        ForEach(profiles) { profile in
                            profileRow(profile)
                        }
                    }
                }
                .padding()
            }
            .appBackground()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    ToolbarPillButton(title: "Cancel") {
                        hapticTap()
                        dismiss()
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Switch Player")
                .font(.title2.weight(.bold))
                .foregroundStyle(.textPrimary)
            Text("Your current round is saved in progress. If the next player already has a round going, it opens right away.")
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func profileRow(_ profile: UserProfile) -> some View {
        let isCurrent = profile.id == currentProfileID
        let round = activeRound(for: profile)
        return Button {
            if isCurrent {
                dismiss()
            } else {
                onSwitch(profile)
            }
        } label: {
            HStack(spacing: 12) {
                IconBadge(icon: isCurrent ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle.fill", color: isCurrent ? .emerald : .slateGray, size: 42)
                VStack(alignment: .leading, spacing: 3) {
                    Text(profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Golfer" : profile.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.textPrimary)
                    Text(statusText(for: profile, round: round, isCurrent: isCurrent))
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                }
                Spacer()
                if isCurrent {
                    Pill(text: "Now", color: .emerald)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.emerald)
                }
            }
            .padding(12)
            .background(Color.white.opacity(isCurrent ? 0.08 : 0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isCurrent ? Color.emerald.opacity(0.22) : Color.white.opacity(0.07), lineWidth: 1)
            )
        }
        .buttonStyle(.bouncy)
    }

    private func activeRound(for profile: UserProfile) -> GolfRound? {
        inProgressRounds.first { $0.profile?.id == profile.id }
    }

    private func statusText(for profile: UserProfile, round: GolfRound?, isCurrent: Bool) -> String {
        if isCurrent { return "Scoring right now" }
        guard let round else { return "No round in progress" }
        let entered = round.sortedHoleScores.filter { $0.strokes > 0 }.count
        let total = max(round.holesPlayed, 1)
        return "Resume \(round.course?.name ?? "round") • \(entered)/\(total) holes entered"
    }
}
