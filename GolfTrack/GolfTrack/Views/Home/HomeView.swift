import SwiftUI
import SwiftData

struct HomeView: View {
    @Bindable var profile: UserProfile
    @Binding var selection: MainTabView.Tab

    @Query(filter: #Predicate<GolfRound> { !$0.isComplete }, sort: \GolfRound.date, order: .reverse)
    private var inProgressRounds: [GolfRound]

    @Query(filter: #Predicate<GolfRound> { $0.isComplete }, sort: \GolfRound.date, order: .reverse)
    private var completedRounds: [GolfRound]

    @State private var resumeRound: GolfRound?
    @State private var showNotifications = false

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
                    inProgressCard(round)
                }

                todaysFocusCard
                practicePlanCard
                recentWeaknessCard
                suggestedDrillsCard
                logRoundButton
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $resumeRound) { round in
            RoundFlowView(round: round)
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsSheet(inProgressRound: inProgressRounds.first, mostRecentRound: mostRecentRound)
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        ZStack {
            Text("GolfTrack").font(.title3.weight(.bold)).foregroundStyle(.textPrimary)
            HStack {
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

    // MARK: - In progress

    private func inProgressCard(_ round: GolfRound) -> some View {
        let holesEntered = round.sortedHoleScores.filter { $0.strokes > 0 }.count
        let total = max(round.holesPlayed, 1)
        return Button { resumeRound = round } label: {
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
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.textSecondary)
            }
            .cardStyle()
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.warningAmber.opacity(0.35), lineWidth: 1.5)
            )
        }
        .buttonStyle(.bouncy)
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

                    NavigationLink(destination: RoundInsightDestination(round: round)) {
                        Text("View Insight")
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
            HStack {
                SectionHeader(title: "Your Practice Plan")
                Spacer()
                Text("This Week").font(.caption.weight(.semibold)).foregroundStyle(.textSecondary)
                Image(systemName: "chevron.down").font(.caption2.weight(.bold)).foregroundStyle(.textTertiary)
            }

            weekStrip

            if let plan = latestPlan, let round = mostRecentRound {
                Divider().background(Color.white.opacity(0.08))
                HStack(spacing: 0) {
                    planStat(title: "Main Focus", value: plan.mainFocus)
                    planStat(title: "Secondary", value: plan.secondaryFocus)
                    planStat(title: "Time", value: "\(plan.estimatedPracticeTime) min")
                }
                NavigationLink(destination: PracticePlanDestination(round: round)) {
                    Text("View Full Plan")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.emerald)
                }
                .buttonStyle(.bouncy)
            } else {
                Text("No plan yet — finish a round to get one.")
                    .font(.caption).foregroundStyle(.textSecondary)
            }
        }
        .cardStyle()
    }

    private func drillIcon(for category: DrillCategory) -> String {
        switch category {
        case .putting: return "smallcircle.filled.circle"
        case .chipping: return "figure.golf"
        case .wedges: return "wind"
        case .irons: return "arrow.up.right"
        case .driver: return "bolt.fill"
        case .teeShots: return "flag.fill"
        case .contact: return "scope"
        case .alignment: return "arrow.left.and.right"
        case .distanceControl: return "ruler.fill"
        case .mentalGame: return "brain.head.profile"
        case .courseManagement: return "map.fill"
        }
    }

    private func planStat(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.caption.weight(.bold)).foregroundStyle(.textPrimary).lineLimit(1).minimumScaleFactor(0.8)
            Text(title).font(.caption2).foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var weekStrip: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekdaySymbols = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let weekdayOfToday = (calendar.component(.weekday, from: today) + 5) % 7 // 0 = Mon
        let startOfWeek = calendar.date(byAdding: .day, value: -weekdayOfToday, to: today) ?? today
        let roundDates = Set(completedRounds.map { calendar.startOfDay(for: $0.date) })

        return HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { offset in
                let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek) ?? startOfWeek
                let isToday = calendar.isDate(day, inSameDayAs: today)
                let hasActivity = roundDates.contains(day)
                let dayNumber = calendar.component(.day, from: day)
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
        }
    }

    // MARK: - Recent Weakness

    private struct WeaknessMetric {
        let label: String
        let value: String
        let caption: String
        let needsWork: Bool
    }

    private var weaknessMetric: WeaknessMetric? {
        guard !recentRounds.isEmpty else { return nil }
        let statsList = recentRounds.map { RoundStats(round: $0) }
        let avgThreePutts = Double(statsList.reduce(0) { $0 + $1.threePutts }) / Double(statsList.count)
        let avgPenalties = Double(statsList.reduce(0) { $0 + $1.totalPenalties }) / Double(statsList.count)
        let fairwayPcts = statsList.compactMap(\.fairwayHitPercentage)
        let avgFairway = fairwayPcts.isEmpty ? nil : fairwayPcts.reduce(0, +) / Double(fairwayPcts.count)

        if avgThreePutts >= 1.0 {
            return WeaknessMetric(label: "3-Putts / Round", value: String(format: "%.1f", avgThreePutts), caption: "Average 3-putts across your last \(statsList.count) rounds.", needsWork: true)
        }
        if avgPenalties >= 1.5 {
            return WeaknessMetric(label: "Penalties / Round", value: String(format: "%.1f", avgPenalties), caption: "Average penalty strokes across your last \(statsList.count) rounds.", needsWork: true)
        }
        if let avgFairway, avgFairway < 40 {
            return WeaknessMetric(label: "Fairways Hit", value: "\(Int(avgFairway))%", caption: "Fairway accuracy across your last \(statsList.count) rounds.", needsWork: true)
        }
        return WeaknessMetric(label: "3-Putts / Round", value: String(format: "%.1f", avgThreePutts), caption: "Average 3-putts across your last \(statsList.count) rounds.", needsWork: false)
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

            if let metric = weaknessMetric {
                HStack {
                    Text(metric.label).font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
                    Pill(text: metric.needsWork ? "Needs Work" : "Good", color: metric.needsWork ? .alertCoral : .emerald)
                    Spacer()
                    Image(systemName: "chart.bar.fill").font(.title3).foregroundStyle(.emerald.opacity(0.5))
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(metric.value).font(.system(size: 30, weight: .bold, design: .rounded)).foregroundStyle(.textPrimary)
                    Text("per round").font(.caption).foregroundStyle(.textSecondary)
                }
                Text(metric.caption).font(.caption).foregroundStyle(.textSecondary)
            } else {
                Text("Play a few rounds to see your trends here.").font(.caption).foregroundStyle(.textSecondary)
            }
        }
        .cardStyle()
    }

    // MARK: - Suggested Drills

    private var suggestedDrillsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Suggested Drills")
                Spacer()
                if let round = mostRecentRound {
                    NavigationLink(destination: PracticePlanDestination(round: round)) {
                        Text("See All").font(.caption.weight(.semibold)).foregroundStyle(.emerald)
                    }
                }
            }

            if let drills = latestPlan?.recommendedDrills, !drills.isEmpty {
                VStack(spacing: 10) {
                    ForEach(Array(drills.prefix(3)), id: \.id) { drill in
                        HStack(spacing: 12) {
                            IconBadge(icon: drillIcon(for: drill.category), color: .emerald, size: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(drill.title).font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
                                Text(drill.relatedSkill).font(.caption).foregroundStyle(.textSecondary)
                            }
                            Spacer()
                            Text("\(drill.timeMinutes) min").font(.caption).foregroundStyle(.textSecondary)
                        }
                    }
                }
            } else {
                Text("Finish a round to unlock drill recommendations.").font(.caption).foregroundStyle(.textSecondary)
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

/// Focused, read-only view of just a round's advice — what "View Insight" on Today's Focus opens.
/// Deliberately separate from the full Practice Plan destination and from History's full
/// RoundDetailView so each entry point on Home leads somewhere distinct, not a repeat of the others.
private struct RoundInsightDestination: View {
    let round: GolfRound
    var body: some View {
        ScrollView {
            if let advice = round.advice {
                AdviceView(advice: advice).padding()
            }
        }
        .appBackground()
        .navigationTitle("Round Insight")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PracticePlanDestination: View {
    let round: GolfRound
    var body: some View {
        ScrollView {
            if let plan = round.practicePlan {
                PracticePlanView(plan: plan).padding()
            }
        }
        .appBackground()
        .navigationTitle("Practice Plan")
        .navigationBarTitleDisplayMode(.inline)
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
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(.emerald)
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
