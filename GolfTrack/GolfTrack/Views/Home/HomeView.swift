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
        .navigationDestination(for: GolfRound.self) { round in
            RoundDetailView(round: round)
        }
        .fullScreenCover(item: $resumeRound) { round in
            RoundFlowView(round: round)
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        ZStack {
            Text("GolfTrack").font(.title3.weight(.bold)).foregroundStyle(.textPrimary)
            HStack {
                Spacer()
                Image(systemName: "bell")
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.05), in: Circle())
            }
        }
        .padding(.top, 6)
    }

    private var greetingRow: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.emerald.opacity(0.16)).frame(width: 46, height: 46)
                Image(systemName: "person.crop.circle.fill").font(.title2).foregroundStyle(.emerald)
            }
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
        return Button { resumeRound = round } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.warningAmber.opacity(0.16)).frame(width: 46, height: 46)
                    Image(systemName: "arrow.clockwise").foregroundStyle(.warningAmber).font(.title3)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text("Round in Progress").font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
                    Text(round.course?.name ?? "Course")
                        .font(.caption).foregroundStyle(.textSecondary)
                    ProgressView(value: Double(holesEntered), total: Double(max(round.holesPlayed, 1)))
                        .tint(.warningAmber)
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
        .buttonStyle(.plain)
    }

    // MARK: - Today's Focus

    private var todaysFocusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(title: "Today's Focus")
                Spacer()
                if let plan = latestPlan, let category = plan.recommendedDrills?.first?.category {
                    Pill(text: category.displayName, color: .emerald)
                }
            }

            if let plan = latestPlan {
                Text(plan.mainFocus)
                    .font(.title2.weight(.bold)).foregroundStyle(.textPrimary)
                if let hook = plan.recommendedDrills?.first?.relatedSkill, !hook.isEmpty {
                    Text(hook).font(.subheadline).foregroundStyle(.textSecondary)
                }

                NavigationLink(value: mostRecentRound) {
                    Text("View Insight")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16).padding(.vertical, 9)
                        .background(Color.textPrimary, in: Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Text("Play your first round").font(.title3.weight(.bold)).foregroundStyle(.textPrimary)
                Text("We'll build a personalized focus area from your round data.")
                    .font(.subheadline).foregroundStyle(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(raised: true)
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "flag.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.emerald.opacity(0.08))
                .padding(14)
        }
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

            if let drill = latestPlan?.recommendedDrills?.first {
                NavigationLink(value: mostRecentRound) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.emerald.opacity(0.16)).frame(width: 40, height: 40)
                            Image(systemName: "flag.fill").font(.subheadline).foregroundStyle(.emerald)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(drill.title).font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
                            Text("\(drill.timeMinutes) min • Focus: \(drill.relatedSkill)")
                                .font(.caption).foregroundStyle(.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.textTertiary)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Text("No drills yet — finish a round to get a practice plan.")
                    .font(.caption).foregroundStyle(.textSecondary)
            }
        }
        .cardStyle()
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
                VStack(spacing: 6) {
                    Text(weekdaySymbols[offset]).font(.caption2.weight(.semibold)).foregroundStyle(.textSecondary)
                    Circle()
                        .fill(hasActivity ? Color.emerald : Color.white.opacity(0.15))
                        .frame(width: 6, height: 6)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    Circle().strokeBorder(isToday ? Color.emerald : Color.clear, lineWidth: 1.5)
                        .padding(4)
                )
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
                if mostRecentRound != nil {
                    NavigationLink(value: mostRecentRound) {
                        Text("See All").font(.caption.weight(.semibold)).foregroundStyle(.emerald)
                    }
                }
            }

            if let drills = latestPlan?.recommendedDrills, !drills.isEmpty {
                VStack(spacing: 10) {
                    ForEach(Array(drills.prefix(3)), id: \.id) { drill in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(Color.emerald.opacity(0.16)).frame(width: 36, height: 36)
                                Image(systemName: "flag.fill").font(.caption).foregroundStyle(.emerald)
                            }
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
