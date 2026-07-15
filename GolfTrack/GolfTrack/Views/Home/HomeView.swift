import SwiftUI
import SwiftData

struct HomeView: View {
    @Bindable var profile: UserProfile
    @Binding var selection: MainTabView.Tab
    var onOpenRound: (GolfRound) -> Void

    @Query(filter: #Predicate<GolfRound> { !$0.isComplete }, sort: \GolfRound.date, order: .reverse)
    private var allInProgressRounds: [GolfRound]

    @Query(filter: #Predicate<GolfRound> { $0.isComplete }, sort: \GolfRound.date, order: .reverse)
    private var allCompletedRounds: [GolfRound]

    @Query(sort: \UserProfile.createdDate) private var allProfiles: [UserProfile]
    @AppStorage("activeProfileID") private var activeProfileIDString: String = ""
    @AppStorage("profileSwitchResumeRoundID") private var profileSwitchResumeRoundIDString: String = ""

    /// Scoped to the active profile — multiple local profiles on this device never see each other's rounds.
    private var inProgressRounds: [GolfRound] { allInProgressRounds.filter { $0.profile?.id == profile.id } }
    private var completedRounds: [GolfRound] { allCompletedRounds.filter { $0.profile?.id == profile.id } }

    @State private var showNotifications = false
    @State private var showProfileSwitcher = false
    @State private var showAddProfile = false
    @State private var cascadeTrigger = 0
    @State private var weekOffset = 0
    @State private var selectedDayRound: GolfRound?
    @State private var cachedWeaknessMetric: WeaknessMetric? = nil

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var mostRecentRound: GolfRound? { completedRounds.first }
    private var latestPlan: PracticePlan? { mostRecentRound?.practicePlan }
    private var recentRounds: [GolfRound] { Array(completedRounds.prefix(5)) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                topBar
                greetingRow

                if let round = inProgressRounds.first {
                    inProgressCard(round).staggeredAppear(0, trigger: cascadeTrigger)
                } else {
                    nextStepCard.staggeredAppear(0, trigger: cascadeTrigger)
                }

                goalProgressCard.staggeredAppear(2, trigger: cascadeTrigger)
                todaysFocusCard.staggeredAppear(3, trigger: cascadeTrigger)
                practicePlanCard.staggeredAppear(4, trigger: cascadeTrigger)
                recentWeaknessCard.staggeredAppear(5, trigger: cascadeTrigger)
                recentFormCard.staggeredAppear(6, trigger: cascadeTrigger)
                logRoundButton.staggeredAppear(7, trigger: cascadeTrigger)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showNotifications) {
            NotificationsSheet(inProgressRound: inProgressRounds.first, mostRecentRound: mostRecentRound)
        }
        .sheet(isPresented: $showProfileSwitcher) {
            HomeProfileSwitcherSheet(
                currentProfileID: profile.id,
                profiles: allProfiles,
                inProgressRounds: allInProgressRounds,
                onSelect: switchToProfile,
                onAddProfile: {
                    showProfileSwitcher = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        showAddProfile = true
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showAddProfile) {
            ProfileSetupView()
        }
        .navigationDestination(item: $selectedDayRound) { round in
            RoundDetailView(round: round)
        }
        .onChange(of: selection) { _, newValue in
            if newValue == .home { cascadeTrigger += 1 }
        }
        .onAppear {
            cachedWeaknessMetric = weaknessMetric
        }
        .onChange(of: allCompletedRounds.count) { _, _ in cachedWeaknessMetric = weaknessMetric }
    }

    // MARK: - Top bar

    private var topBar: some View {
        ZStack {
            Text("GolfTrack").font(.title3.weight(.bold)).foregroundStyle(.textPrimary)
            HStack {
                Button {
                    hapticTap()
                    showProfileSwitcher = true
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.caption.weight(.semibold))
                        Text(profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Golfer" : profile.name)
                            .font(.caption.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .black))
                    }
                    .foregroundStyle(.emerald)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.emerald.opacity(0.12), in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.emerald.opacity(0.22), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Switch profile")

                Spacer()
                Button { showNotifications = true } label: {
                    Image(systemName: "bell")
                        .font(.subheadline)
                        .foregroundStyle(.textSecondary)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.05), in: Circle())
                }
                .buttonStyle(.bouncy)
            }
        }
        .padding(.top, 6)
    }

    private func openRound(_ round: GolfRound) {
        onOpenRound(round)
    }

    private func switchToProfile(_ selectedProfile: UserProfile) {
        hapticTap(.medium)
        showProfileSwitcher = false
        let targetRound = allInProgressRounds.first { $0.profile?.id == selectedProfile.id }
        if selectedProfile.id == profile.id {
            if let targetRound {
                openRound(targetRound)
            }
            return
        }
        profileSwitchResumeRoundIDString = targetRound?.id.uuidString ?? ""
        activeProfileIDString = selectedProfile.id.uuidString
    }

    private var greetingRow: some View {
        HStack(spacing: 12) {
            IconBadge(icon: "person.crop.circle.fill", color: .emerald, size: 46)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(greeting), \(profile.name.isEmpty ? "Golfer" : profile.name)")
                    .font(.title3.weight(.bold)).foregroundStyle(.textPrimary)
                Text("Let's keep improving.").font(.subheadline).foregroundStyle(.textSecondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Next step

    private var nextIncompleteDrill: PracticeDrill? {
        guard let drills = latestPlan?.recommendedDrills else { return nil }
        return drills
            .sorted { $0.timeMinutes > $1.timeMinutes }
            .first { !$0.isComplete }
    }

    private var nextStepCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Next Step", icon: "arrow.forward.circle.fill")
                Spacer()
                Pill(text: nextStepPillText, color: .emerald)
            }

            Text(nextStepTitle)
                .font(.title3.weight(.bold))
                .foregroundStyle(.textPrimary)
                .lineLimit(2)

            Text(nextStepSubtitle)
                .font(.subheadline)
                .foregroundStyle(.textSecondary)

            nextStepAction
        }
        .cardStyle(raised: true)
    }

    private var nextStepPillText: String {
        if nextIncompleteDrill != nil { return "Practice" }
        if mostRecentRound?.advice != nil { return "Insight" }
        return "Start"
    }

    private var nextStepTitle: String {
        if let drill = nextIncompleteDrill {
            return drill.title
        }
        if let plan = latestPlan {
            return "Review your \(plan.mainFocus.lowercased()) plan"
        }
        return "Play your first tracked round"
    }

    private var nextStepSubtitle: String {
        if let drill = nextIncompleteDrill {
            return "\(drill.timeMinutes) minutes toward \(drill.relatedSkill.lowercased())."
        }
        if mostRecentRound != nil {
            return "Turn your latest round into one focused practice session."
        }
        return "You’ll get score tracking, round insights, and a practice plan after you finish."
    }

    @ViewBuilder
    private var nextStepAction: some View {
        if let round = mostRecentRound, latestPlan != nil {
            NavigationLink(destination: PracticePlanDestination(round: round)) {
                Label("Open Practice Plan", systemImage: "checklist")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primaryGolf)
        } else {
            Button { selection = .startRound } label: {
                Label("Start a Round", systemImage: "flag.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primaryGolf)
        }
    }

    // MARK: - In progress

    private func inProgressCard(_ round: GolfRound) -> some View {
        let holesEntered = round.sortedHoleScores.filter { $0.strokes > 0 }.count
        let total = max(round.holesPlayed, 1)
        let currentHole = round.activeHoleNumber ?? round.sortedHoleScores.first(where: { $0.strokes == 0 })?.holeNumber ?? 1
        return Button { openRound(round) } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    RingProgress(progress: Double(holesEntered) / Double(total), size: 50, color: .warningAmber) {
                        Text("\(holesEntered)/\(total)").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(.textPrimary)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Round in Progress").font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
                        Text(round.course?.name ?? "Course")
                            .font(.caption).foregroundStyle(.textSecondary)
                    }
                    Spacer()
                    Pill(text: "Hole \(currentHole)", color: .warningAmber)
                }

                HStack {
                    Text("Continue scoring")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.black)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(LinearGradient.emerald, in: Capsule())
            }
            .cardStyle()
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.warningAmber.opacity(0.35), lineWidth: 1.5)
            )
        }
        .buttonStyle(.bouncy)
    }

    // MARK: - Goal Progress

    private struct GoalEntry: Identifiable {
        let id: UUID
        let strokes: Int
        let target: Int
        var diff: Int { strokes - target }
        var hit: Bool { diff <= 0 }
    }

    private struct GoalProgressInfo {
        let goal: GolfGoal
        let entries: [GoalEntry]
        var hitCount: Int { entries.filter(\.hit).count }
        var summary: String {
            let total = entries.count
            guard total > 0 else { return "No rounds yet — keep going." }
            if hitCount == total { return "You've hit your goal in every recent round. You may be ready to move up." }
            if hitCount == 0 { return "Not yet — but the data shows exactly what to work on." }
            return "You've hit your goal \(hitCount) of your last \(total) rounds."
        }
    }

    private func computeGoalProgress() -> GoalProgressInfo? {
        let orderedGoals: [GolfGoal] = [
            .break36On9, .break40On9, .break45On9, .break50On9,
            .break80On18, .break90On18, .break100On18
        ]
        let offsets: [GolfGoal: (Int, Bool)] = [
            .break50On9: (14, true), .break45On9: (9, true), .break40On9: (4, true), .break36On9: (0, true),
            .break100On18: (28, false), .break90On18: (18, false), .break80On18: (8, false)
        ]
        for goal in orderedGoals where profile.goals.contains(goal) {
            guard let (offset, isNine) = offsets[goal] else { continue }
            let matching = completedRounds.filter { ($0.holesPlayed <= 9) == isNine }
            guard !matching.isEmpty else { continue }
            let entries = Array(matching.prefix(5)).map {
                GoalEntry(id: $0.id, strokes: $0.totalStrokes, target: $0.totalPar + offset)
            }
            return GoalProgressInfo(goal: goal, entries: entries)
        }
        return nil
    }

    @ViewBuilder
    private var goalProgressCard: some View {
        if let data = computeGoalProgress() {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionHeader(title: "Goal Progress", icon: "target")
                    Spacer()
                    Button("All Stats") { selection = .stats }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.emerald)
                }

                Text(data.goal.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.textPrimary)

                HStack(spacing: 0) {
                    // Empty placeholder slots (oldest, untracked) on the left
                    let emptyCount = max(0, 5 - data.entries.count)
                    ForEach(0..<emptyCount, id: \.self) { _ in
                        VStack(spacing: 5) {
                            Circle().fill(Color.white.opacity(0.10)).frame(width: 10, height: 10)
                            Text("—").font(.system(size: 9)).foregroundStyle(.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    // Actual rounds, oldest → newest (left → right)
                    ForEach(Array(data.entries.reversed())) { entry in
                        let color: Color = entry.hit ? .emerald : (entry.diff <= 5 ? .warningAmber : .alertCoral)
                        VStack(spacing: 5) {
                            Circle()
                                .fill(color.opacity(entry.hit ? 1 : 0.75))
                                .frame(width: 10, height: 10)
                            Text(entry.hit ? "✓" : "+\(entry.diff)")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(color)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                Text(data.summary)
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
            }
            .cardStyle()
        }
    }

    // MARK: - Today's Focus

    private var todaysFocusCard: some View {
        ZStack(alignment: .topTrailing) {
            GlowBlob(color: .emerald, size: 150)
                .offset(x: 50, y: -50)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionHeader(title: "Today's Focus")
                    Spacer()
                    if let plan = latestPlan, let category = plan.recommendedDrills?.first?.category {
                        Pill(text: category.displayName, color: .emerald)
                    }
                }

                if let plan = latestPlan, let round = mostRecentRound {
                    Text(plan.mainFocus)
                        .font(.title2.weight(.bold)).foregroundStyle(.textPrimary)
                    if let hook = plan.recommendedDrills?.first?.relatedSkill, !hook.isEmpty {
                        Text(hook).font(.subheadline).foregroundStyle(.textSecondary)
                    }

                    NavigationLink(destination: TodayFocusDestination(round: round)) {
                        Text("Open Focus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16).padding(.vertical, 9)
                            .background(Color.textPrimary, in: Capsule())
                    }
                    .buttonStyle(.bouncy)
                } else {
                    Text("Play your first round").font(.title3.weight(.bold)).foregroundStyle(.textPrimary)
                    Text("We'll build a personalized focus area from your round data.")
                        .font(.subheadline).foregroundStyle(.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            GolfFlagGraphic(size: 78)
                .opacity(0.85)
                .padding(.trailing, 4)
                .padding(.bottom, -8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .cardStyle(raised: true)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Practice Plan (this week)

    private var practicePlanCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Your Practice Plan",
                info: "Tap any highlighted day to see the round you played and the practice plan it generated."
            )

            weekNavRow
            weekStrip

            if let plan = latestPlan, let round = mostRecentRound {
                Divider().background(Color.white.opacity(0.08))
                VStack(spacing: 12) {
                    planFocusRow(icon: "target", title: "Main Focus", value: plan.mainFocus)
                    planFocusRow(icon: "arrow.triangle.2.circlepath", title: "Secondary", value: plan.secondaryFocus)
                    planFocusRow(icon: "clock.fill", title: "Practice Time", value: "\(plan.estimatedPracticeTime) min")
                }
                NavigationLink(destination: PracticePlanDestination(round: round)) {
                    Text("View Full Plan")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.emerald)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.bouncy)
            } else {
                Text("No plan yet — finish a round to get one.")
                    .font(.caption).foregroundStyle(.textSecondary)
            }
        }
        .cardStyle()
    }

    private func planFocusRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            IconBadge(icon: icon, color: .emerald, size: 32)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.caption2).foregroundStyle(.textSecondary)
                Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
            }
            Spacer()
        }
    }

    private let calendar = Calendar.current

    /// Monday-start date of the week at `weekOffset` weeks from the current week (0 = this week).
    private func weekStart(offset: Int) -> Date {
        let today = calendar.startOfDay(for: Date())
        let weekdayOfToday = (calendar.component(.weekday, from: today) + 5) % 7 // 0 = Mon
        let currentWeekStart = calendar.date(byAdding: .day, value: -weekdayOfToday, to: today) ?? today
        return calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart) ?? currentWeekStart
    }

    private var weekRangeLabel: String {
        if weekOffset == 0 { return "This Week" }
        let start = weekStart(offset: weekOffset)
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }

    private func completedRound(on day: Date) -> GolfRound? {
        completedRounds.first { calendar.isDate($0.date, inSameDayAs: day) }
    }

    private var weekNavRow: some View {
        HStack {
            Button { withAnimation { weekOffset -= 1 } } label: {
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.textSecondary)
                    .frame(width: 26, height: 26)
                    .background(Color.white.opacity(0.06), in: Circle())
            }
            .buttonStyle(.bouncy)

            Spacer()
            Text(weekRangeLabel).font(.caption.weight(.semibold)).foregroundStyle(.textSecondary)
            Spacer()

            Button { withAnimation { weekOffset += 1 } } label: {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(weekOffset < 0 ? .textSecondary : .textTertiary)
                    .frame(width: 26, height: 26)
                    .background(Color.white.opacity(0.06), in: Circle())
            }
            .buttonStyle(.bouncy)
            .disabled(weekOffset >= 0)
        }
    }

    private var weekStrip: some View {
        let today = calendar.startOfDay(for: Date())
        let weekdaySymbols = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let startOfWeek = weekStart(offset: weekOffset)
        let roundDates = Set(completedRounds.map { calendar.startOfDay(for: $0.date) })

        return HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { offset in
                let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek) ?? startOfWeek
                let isToday = calendar.isDate(day, inSameDayAs: today)
                let hasActivity = roundDates.contains(day)
                let dayNumber = calendar.component(.day, from: day)
                Button {
                    if let round = completedRound(on: day) { selectedDayRound = round }
                } label: {
                    VStack(spacing: 6) {
                        Text(weekdaySymbols[offset]).font(.caption2.weight(.semibold)).foregroundStyle(.textSecondary)
                        ZStack {
                            Circle()
                                .fill(hasActivity ? LinearGradient.emerald : LinearGradient(colors: [Color.white.opacity(0.07), Color.white.opacity(0.07)], startPoint: .top, endPoint: .bottom))
                            Circle()
                                .strokeBorder(isToday ? Color.emerald : Color.clear, lineWidth: 1.5)
                            Text("\(dayNumber)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(hasActivity ? .black : (isToday ? .emerald : .textSecondary))
                        }
                        .frame(width: 30, height: 30)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bouncy)
                .disabled(!hasActivity)
            }
        }
    }

    // MARK: - Recent Weakness

    private struct WeaknessMetric {
        let label: String
        let recentText: String
        let priorText: String?
        let caption: String
        let needsWork: Bool
    }

    private var weaknessMetric: WeaknessMetric? {
        guard !recentRounds.isEmpty else { return nil }

        // Once there's enough history, prefer the real before/after trend — it's proof, not a guess.
        if let trends = ProgressTrendService.trends(from: completedRounds.map { RoundStats(round: $0) }) {
            if let worst = trends.filter(\.declined).max(by: { abs($0.recentValue - $0.priorValue) < abs($1.recentValue - $1.priorValue) }) {
                return WeaknessMetric(
                    label: worst.label,
                    recentText: worst.recentText,
                    priorText: worst.priorText,
                    caption: "Compared to your previous \(ProgressTrendService.windowSize) rounds — still a focus area.",
                    needsWork: true
                )
            }
            if let best = trends.filter(\.improved).max(by: { abs($0.recentValue - $0.priorValue) < abs($1.recentValue - $1.priorValue) }) {
                return WeaknessMetric(
                    label: best.label,
                    recentText: best.recentText,
                    priorText: best.priorText,
                    caption: "Better than your previous \(ProgressTrendService.windowSize) rounds — the work is paying off.",
                    needsWork: false
                )
            }
        }

        // Not enough history yet for a real trend — fall back to a simple threshold on recent rounds.
        let statsList = recentRounds.map { RoundStats(round: $0) }
        let avgThreePutts = Double(statsList.reduce(0) { $0 + $1.threePutts }) / Double(statsList.count)
        let avgPenalties = Double(statsList.reduce(0) { $0 + $1.totalPenalties }) / Double(statsList.count)
        let fairwayPcts = statsList.compactMap(\.fairwayHitPercentage)
        let avgFairway = fairwayPcts.isEmpty ? nil : fairwayPcts.reduce(0, +) / Double(fairwayPcts.count)

        if avgThreePutts >= 1.0 {
            return WeaknessMetric(label: "3-Putts / Round", recentText: String(format: "%.1f", avgThreePutts), priorText: nil, caption: "Average across your last \(statsList.count) rounds.", needsWork: true)
        }
        if avgPenalties >= 1.5 {
            return WeaknessMetric(label: "Penalties / Round", recentText: String(format: "%.1f", avgPenalties), priorText: nil, caption: "Average across your last \(statsList.count) rounds.", needsWork: true)
        }
        if let avgFairway, avgFairway < 40 {
            return WeaknessMetric(label: "Fairways Hit", recentText: "\(Int(avgFairway))%", priorText: nil, caption: "Accuracy across your last \(statsList.count) rounds.", needsWork: true)
        }
        return WeaknessMetric(label: "3-Putts / Round", recentText: String(format: "%.1f", avgThreePutts), priorText: nil, caption: "Average across your last \(statsList.count) rounds.", needsWork: false)
    }

    private var recentWeaknessCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Recent Weakness")
                Spacer()
                if mostRecentRound != nil {
                    Button("More Insights") { selection = .stats }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.emerald)
                }
            }

            if let metric = cachedWeaknessMetric {
                HStack {
                    Text(metric.label).font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
                    Pill(text: metric.needsWork ? "Needs Work" : "Improving", color: metric.needsWork ? .alertCoral : .emerald)
                    Spacer()
                    Image(systemName: "chart.bar.fill").font(.title3).foregroundStyle(.emerald.opacity(0.5))
                }
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    if let priorText = metric.priorText {
                        Text(priorText).font(.title3.weight(.semibold)).foregroundStyle(.textTertiary)
                        Image(systemName: "arrow.right").font(.caption).foregroundStyle(.textTertiary)
                    }
                    Text(metric.recentText).font(.system(size: 30, weight: .bold, design: .rounded)).foregroundStyle(.textPrimary)
                }
                Text(metric.caption).font(.caption).foregroundStyle(.textSecondary)
            } else {
                Text("Play a few rounds to see your trends here.").font(.caption).foregroundStyle(.textSecondary)
            }
        }
        .cardStyle()
    }

    // MARK: - Recent Form

    private var recentFormCard: some View {
        let rounds = Array(completedRounds.prefix(3))
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Recent Form")
                Spacer()
                if !rounds.isEmpty {
                    Button("See All") { selection = .history }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.emerald)
                }
            }

            if rounds.isEmpty {
                Text("Finish a round to see your recent form here.")
                    .font(.caption).foregroundStyle(.textSecondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(rounds.enumerated()), id: \.element.id) { index, round in
                        let prev = index + 1 < rounds.count ? rounds[index + 1] : nil
                        FormRow(round: round, previousRound: prev)
                        if index < rounds.count - 1 {
                            Divider().background(Color.white.opacity(0.07))
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - CTA

    private var logRoundButton: some View {
        Button { selection = .startRound } label: {
            Label("Log a Round", systemImage: "flag.fill")
        }
        .buttonStyle(.primaryGolf)
    }
}

private struct HomeProfileSwitcherSheet: View {
    let currentProfileID: UUID
    let profiles: [UserProfile]
    let inProgressRounds: [GolfRound]
    var onSelect: (UserProfile) -> Void
    var onAddProfile: () -> Void
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

                    Button {
                        hapticTap()
                        dismiss()
                        onAddProfile()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Add Profile")
                                .font(.subheadline.weight(.bold))
                            Spacer()
                        }
                        .foregroundStyle(.emerald)
                        .padding(12)
                        .background(Color.emerald.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.emerald.opacity(0.18), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
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
        VStack(alignment: .leading, spacing: 5) {
            Text("Profiles")
                .font(.title2.weight(.bold))
                .foregroundStyle(.textPrimary)
            Text("Switch golfers fast. Active rounds open straight to scoring.")
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func profileRow(_ profile: UserProfile) -> some View {
        let isCurrent = profile.id == currentProfileID
        let activeRound = inProgressRounds.first { $0.profile?.id == profile.id }
        return Button {
            onSelect(profile)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                IconBadge(icon: isCurrent ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle.fill", color: isCurrent ? .emerald : .slateGray, size: 40)

                VStack(alignment: .leading, spacing: 3) {
                    Text(profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Golfer" : profile.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.textPrimary)
                    Text(statusText(for: activeRound, isCurrent: isCurrent))
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                if isCurrent {
                    Pill(text: "Current", color: .emerald)
                } else if activeRound != nil {
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

    private func statusText(for round: GolfRound?, isCurrent: Bool) -> String {
        guard let round else { return isCurrent ? "Current profile" : "No round in progress" }
        let hole = round.activeHoleNumber ?? round.sortedHoleScores.first(where: { $0.strokes == 0 })?.holeNumber ?? 1
        return "Hole \(hole) in progress"
    }
}

private struct FormRow: View {
    let round: GolfRound
    let previousRound: GolfRound?

    private var trendIcon: String? {
        guard let prev = previousRound else { return nil }
        if round.scoreToPar < prev.scoreToPar  { return "arrow.up.right" }
        if round.scoreToPar > prev.scoreToPar  { return "arrow.down.right" }
        return "equal"
    }
    private var trendColor: Color {
        guard let prev = previousRound else { return .textTertiary }
        if round.scoreToPar < prev.scoreToPar  { return .emerald }
        if round.scoreToPar > prev.scoreToPar  { return .alertCoral }
        return .textTertiary
    }

    var body: some View {
        HStack(spacing: 12) {
            ScoreBadge(scoreToPar: round.scoreToPar, size: 36, animated: false)

            VStack(alignment: .leading, spacing: 2) {
                Text(round.course?.name ?? "Unknown Course")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
                    .lineLimit(1)
                Text(round.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption).foregroundStyle(.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(round.totalStrokes)").font(.title3.weight(.bold)).foregroundStyle(.textPrimary)
                if let icon = trendIcon {
                    HStack(spacing: 2) {
                        Image(systemName: icon).font(.caption2.weight(.bold))
                        Text(scoreToParText(round.scoreToPar)).font(.caption2)
                    }
                    .foregroundStyle(trendColor)
                } else {
                    Text(scoreToParText(round.scoreToPar)).font(.caption2).foregroundStyle(.textSecondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

/// One immediate, category-aware action for Today's Focus. The full practice plan still owns
/// the complete drill list; this screen answers "what should I do today?"
private struct TodayFocusDestination: View {
    let round: GolfRound

    private var plan: PracticePlan? { round.practicePlan }
    private var primaryDrill: PracticeDrill? {
        guard let drills = plan?.recommendedDrills else { return nil }
        if let mainFocus = plan?.mainFocus.lowercased(),
           let matching = drills.first(where: {
               $0.relatedSkill.lowercased().contains(mainFocus) ||
               mainFocus.contains($0.category.displayName.lowercased())
           }) {
            return matching
        }
        return drills.first
    }

    private var category: DrillCategory {
        primaryDrill?.category ?? .contact
    }

    var body: some View {
        VStack(spacing: 0) {
            PushedScreenHeader("Today's Focus")
                .padding(.horizontal)

            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    if let primaryDrill {
                        drillCard(primaryDrill)
                    } else {
                        fallbackDrillCard
                    }
                    watchCard
                }
                .padding()
            }
        }
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                IconBadge(icon: iconName, color: .emerald, size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan?.mainFocus ?? "General Improvement")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.textPrimary)
                    Text(category.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.emerald)
                }
                Spacer()
                Pill(text: "\(primaryDrill?.timeMinutes ?? 10) min", color: .emerald)
            }

            Text(whyText)
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle(raised: true)
    }

    private func drillCard(_ drill: PracticeDrill) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Do This Today", icon: "checkmark.circle.fill")
            Text(drill.title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.textPrimary)
            Text(drill.details)
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if !drill.relatedSkill.isEmpty {
                Pill(text: drill.relatedSkill, color: .warningAmber)
            }
        }
        .cardStyle()
    }

    private var fallbackDrillCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Do This Today", icon: "checkmark.circle.fill")
            Text("10 focused reps")
                .font(.headline.weight(.bold))
                .foregroundStyle(.textPrimary)
            Text("Pick one simple swing thought, make slow balanced reps, and stop before the session turns into random tinkering.")
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
        }
        .cardStyle()
    }

    private var watchCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Watch Next Round", icon: "eye.fill")
            Text(plan?.nextRoundGoal.isEmpty == false ? plan?.nextRoundGoal ?? watchText : watchText)
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle()
    }

    private var iconName: String {
        switch category {
        case .putting: return "smallcircle.filled.circle"
        case .chipping, .wedges: return "scope"
        case .irons, .contact: return "figure.golf"
        case .driver, .teeShots: return "flag.fill"
        case .alignment, .distanceControl: return "target"
        case .mentalGame: return "brain.head.profile"
        case .courseManagement: return "map.fill"
        }
    }

    private var whyText: String {
        switch category {
        case .putting:
            return "Putting focus is about removing easy wasted strokes with cleaner speed control and calmer short putts."
        case .chipping, .wedges:
            return "Short-game focus helps turn misses around the green into manageable saves instead of extra stress."
        case .contact, .irons:
            return "Contact focus gives you a simple baseline: better strike quality before chasing distance or shape."
        case .driver, .teeShots:
            return "Tee-shot focus is about starting holes from playable spots instead of spending the round recovering."
        case .alignment, .distanceControl:
            return "Control focus helps you aim and pace shots with intention instead of hoping the swing bails you out."
        case .mentalGame:
            return "Mental-game focus keeps the next round from being decided by rushed decisions or one bad swing carrying into the next shot."
        case .courseManagement:
            return "Course-management focus is about saving strokes by choosing safer targets before trouble gets involved."
        }
    }

    private var watchText: String {
        switch category {
        case .putting:
            return "Track three-putts and whether your first putt finishes inside an easy cleanup range."
        case .chipping, .wedges:
            return "Notice whether chips, pitches, and wedges leave simple putts instead of forcing another recovery shot."
        case .contact:
            return "Watch fat/thin strikes and whether your confident swings produce more predictable distance."
        case .irons:
            return "Watch whether iron shots finish pin-high more often, even when they miss left or right."
        case .driver, .teeShots:
            return "Watch playable tee shots. A good result is a clear next shot, not a perfect drive."
        case .alignment:
            return "Watch start lines and whether misses are smaller because your setup is cleaner."
        case .distanceControl:
            return "Watch long/short misses and whether your first distance guess is getting closer."
        case .mentalGame:
            return "Watch your reset after mistakes: one breath, one decision, one committed swing."
        case .courseManagement:
            return "Watch penalties and big numbers. The win is choosing targets that keep the hole alive."
        }
    }
}

/// Focused, read-only view of just a round's advice — what Round Insight opens.
/// Deliberately separate from the full Practice Plan destination and from History's full
/// RoundDetailView so each entry point on Home leads somewhere distinct, not a repeat of the others.
private struct RoundInsightDestination: View {
    let round: GolfRound
    var body: some View {
        VStack(spacing: 0) {
            PushedScreenHeader("Round Insight")
                .padding(.horizontal)

            ScrollView {
                if let advice = round.advice {
                    AdviceView(advice: advice).padding()
                }
            }
        }
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct PracticePlanDestination: View {
    let round: GolfRound
    var body: some View {
        VStack(spacing: 0) {
            PushedScreenHeader("Practice Plan")
                .padding(.horizontal)

            ScrollView {
                if let plan = round.practicePlan {
                    PracticePlanView(plan: plan).padding()
                }
            }
        }
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// Real, data-derived notifications (not a placeholder feed) — surfaces whatever's actually
/// actionable right now (an in-progress round, a freshly-generated insight) instead of nothing.
private struct NotificationsSheet: View {
    let inProgressRound: GolfRound?
    let mostRecentRound: GolfRound?
    @Environment(\.dismiss) private var dismiss

    private var isRecentInsight: Bool {
        guard let date = mostRecentRound?.advice?.createdDate else { return false }
        return Date().timeIntervalSince(date) < 60 * 60 * 48
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if let round = inProgressRound {
                        NotificationRow(
                            icon: "arrow.clockwise",
                            tint: .warningAmber,
                            title: "Round in progress",
                            message: "You still have a round at \(round.course?.name ?? "your course") to finish."
                        )
                    }
                    if isRecentInsight, let round = mostRecentRound {
                        NotificationRow(
                            icon: "lightbulb.fill",
                            tint: .emerald,
                            title: "New insight",
                            message: "New insight ready for your round at \(round.course?.name ?? "your course")."
                        )
                    }
                    if inProgressRound == nil && !isRecentInsight {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").font(.largeTitle).foregroundStyle(.emerald)
                            Text("You're all caught up").font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
                            Text("No new notifications right now.").font(.caption).foregroundStyle(.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    }
                }
                .padding()
            }
            .appBackground()
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    ToolbarPillButton(title: "Done") {
                        hapticTap()
                        dismiss()
                    }
                }
            }
        }
        .tint(.emerald)
        .buttonStyle(.bouncy)
    }
}

private struct NotificationRow: View {
    let icon: String
    let tint: Color
    let title: String
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(icon: icon, color: tint, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
                Text(message).font(.caption).foregroundStyle(.textSecondary)
            }
            Spacer()
        }
        .cardStyle()
    }
}
