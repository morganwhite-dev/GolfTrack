import SwiftUI
import SwiftData

struct ProfileView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<GolfRound> { $0.isComplete }, sort: \GolfRound.date, order: .reverse) private var allCompletedRounds: [GolfRound]
    @Query(sort: \UserProfile.createdDate) private var allProfiles: [UserProfile]
    @AppStorage("activeProfileID") private var activeProfileIDString: String = ""
    @State private var handicapText: String = ""
    @State private var showSavedToast = false
    @State private var showClearDataConfirm = false
    @State private var showAddProfile = false
    @State private var isEditing = false
    @State private var showGuide = false

    private var completedRounds: [GolfRound] { allCompletedRounds.filter { $0.profile?.id == profile.id } }

    private var bestScoreText: String {
        guard let best = completedRounds.map({ RoundStats(round: $0).totalStrokes }).min() else { return "—" }
        return "\(best)"
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenTitleBar("Profile") {
                HStack(spacing: 10) {
                    Button {
                        hapticTap()
                        showGuide = true
                    } label: {
                        Image(systemName: "info.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.emerald)
                    }
                    .buttonStyle(.bouncy)

                    Button {
                        hapticTap()
                        if isEditing {
                            try? context.save()
                            showSavedToast = true
                        }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isEditing.toggle()
                        }
                    } label: {
                        Text(isEditing ? "Save" : "Edit")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.emerald)
                    }
                    .buttonStyle(.bouncy)
                }
            }
            .padding(.horizontal)

            profileContent
        }
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            if let h = profile.estimatedHandicap { handicapText = String(h) }
        }
        .alert("Profile Saved", isPresented: $showSavedToast) {
            Button("OK", role: .cancel) {}
        }
        .navigationDestination(isPresented: $showGuide) {
            AppGuideView()
        }
    }

    private var profileContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                identityCard
                profileSwitcherSection

                if isEditing {
                    editingSections
                } else {
                    readOnlySections
                }
            }
            .padding()
        }
    }

    // MARK: - Read-only sections

    private var readOnlySections: some View {
        VStack(spacing: 20) {
            // Name
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Your Name", icon: "person.fill")
                Text(profile.name.isEmpty ? "No name set" : profile.name)
                    .font(.subheadline).foregroundStyle(profile.name.isEmpty ? .textTertiary : .textPrimary)
            }
            .cardStyle()

            // Skill Level — read-only with optional upgrade suggestion
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(
                    title: "Skill Level",
                    icon: "chart.bar.fill",
                    info: "This tunes the tone of your advice. Update it whenever your recent scoring starts to outgrow it."
                )
                Pill(text: profile.skillLevel.displayName, color: .emerald, filled: true)

                if let suggestion = skillLevelSuggestion {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill").font(.caption).foregroundStyle(.warningAmber).padding(.top, 2)
                        Text(suggestion).font(.caption).foregroundStyle(.textSecondary)
                    }
                    .padding(10)
                    .background(Color.warningAmber.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .cardStyle()

            // Handicap
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Handicap", icon: "number")
                Text(profile.estimatedHandicap.map { String(format: "%.1f", $0) } ?? "Not set")
                    .font(.subheadline).foregroundStyle(profile.estimatedHandicap == nil ? .textTertiary : .textPrimary)
            }
            .cardStyle()

            // Goals
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(
                    title: "Main Goals",
                    icon: "checkmark.seal.fill",
                    info: "Score goals adjust to course par, so a par-3 round and standard course still compare fairly."
                )
                if profile.goals.isEmpty {
                    Text("No goals set").font(.subheadline).foregroundStyle(.textTertiary)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(profile.goals, id: \.self) { goal in
                            Pill(text: goal.displayName, color: .emerald, filled: true)
                        }
                    }
                    if let custom = profile.customGoalText, !custom.isEmpty, profile.goals.contains(.other) {
                        Text(custom).font(.caption).foregroundStyle(.textSecondary)
                    }
                }
                Text("Tap Edit to change your goals or skill level.")
                    .font(.caption2).foregroundStyle(.textTertiary)
            }
            .cardStyle()

            dataSectionCard
        }
    }

    // MARK: - Editing sections

    private var editingSections: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Your Name", icon: "person.fill")
                InputField(placeholder: "Name", text: $profile.name)
            }
            .cardStyle()

            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(
                    title: "Skill Level",
                    icon: "chart.bar.fill",
                    info: "This tunes the tone of your advice. Update it whenever your recent scoring starts to outgrow it."
                )
                VStack(spacing: 8) {
                    ForEach(SkillLevel.allCases) { level in
                        SelectableRow(label: level.displayName, isSelected: profile.skillLevel == level) {
                            profile.skillLevel = level
                        }
                    }
                }
            }
            .cardStyle()

            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Handicap", subtitle: "Optional, if known", icon: "number")
                InputField(placeholder: "Estimated handicap", text: $handicapText, keyboardType: .numbersAndPunctuation)
                    .onChange(of: handicapText) { _, newValue in
                        profile.estimatedHandicap = Double(newValue)
                    }
            }
            .cardStyle()

            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(
                    title: "Main Goals",
                    icon: "checkmark.seal.fill",
                    info: "Score goals adjust to course par, so a par-3 round and standard course still compare fairly."
                )
                VStack(spacing: 8) {
                    ForEach(GolfGoal.allCases) { goal in
                        SelectableRow(label: goal.displayName, subtitle: goal.parOffsetSubtitle, isSelected: profile.goals.contains(goal)) {
                            var goals = profile.goals
                            if let idx = goals.firstIndex(of: goal) { goals.remove(at: idx) } else { goals.append(goal) }
                            profile.goals = goals
                        }
                    }
                }
                if profile.goals.contains(.other) {
                    InputField(placeholder: "Describe your goal", text: Binding(
                        get: { profile.customGoalText ?? "" },
                        set: { profile.customGoalText = $0 }
                    ))
                }
            }
            .cardStyle()

            dataSectionCard
        }
    }

    // MARK: - Shared sections

    private var dataSectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Data", icon: "trash.fill")
            Text("Clears every round, stat, and practice plan — your profile and saved courses stay.")
                .font(.caption).foregroundStyle(.textSecondary)
            Button("Clear All Round Data", role: .destructive) { showClearDataConfirm = true }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.alertCoral)
                .confirmationDialog("Clear All Round Data?", isPresented: $showClearDataConfirm, titleVisibility: .visible) {
                    Button("Clear Everything", role: .destructive) { clearAllRoundData() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This permanently deletes every round, hole score, reflection, advice, and practice plan. Your profile and saved courses are kept. This can't be undone.")
                }
        }
        .cardStyle()
    }

    // MARK: - Skill suggestion

    // Compares the player's average recent score-to-par against the expected range for
    // their stated skill level and surfaces an upgrade nudge when the data warrants it.
    private var skillLevelSuggestion: String? {
        guard completedRounds.count >= 5 else { return nil }
        let recent = Array(completedRounds.prefix(5))
        let nineHole = recent.filter { $0.holesPlayed <= 9 }
        let eighteenHole = recent.filter { $0.holesPlayed > 9 }
        let rounds = nineHole.count >= eighteenHole.count ? nineHole : eighteenHole
        guard rounds.count >= 3 else { return nil }
        let isNine = (rounds.first?.holesPlayed ?? 9) <= 9
        let avgToPar = Double(rounds.reduce(0) { $0 + $1.scoreToPar }) / Double(rounds.count)

        switch profile.skillLevel {
        case .beginner:
            let threshold: Double = isNine ? 9 : 18
            if avgToPar < threshold {
                return "Your last \(rounds.count) rounds average \(scoreToParText(Int(avgToPar.rounded()))) — that's High Handicap territory. Consider updating your skill level."
            }
        case .highHandicap:
            let threshold: Double = isNine ? 4 : 8
            if avgToPar < threshold {
                return "You're averaging \(scoreToParText(Int(avgToPar.rounded()))) — consistently Mid Handicap performance. Consider moving up."
            }
        case .midHandicap:
            if avgToPar < 0 {
                return "You're consistently shooting under par — Low Handicap may be a more accurate level for you."
            }
        case .lowHandicap:
            let threshold: Double = isNine ? -6 : -12
            if avgToPar < threshold {
                return "You're averaging \(scoreToParText(Int(avgToPar.rounded()))) — Scratch or better. Consider updating your level."
            }
        case .scratch:
            return nil
        }
        return nil
    }

    // MARK: - Identity card

    private var identityCard: some View {
        VStack(spacing: 14) {
            IconBadge(icon: "person.crop.circle.fill", color: .emerald, size: 72)

            Text(profile.name.isEmpty ? "Golfer" : profile.name)
                .font(.title2.weight(.bold)).foregroundStyle(.textPrimary)

            HStack(spacing: 8) {
                Pill(text: profile.skillLevel.displayName, color: .emerald, filled: true)
                if let handicap = profile.estimatedHandicap {
                    Pill(text: "HCP \(String(format: "%.1f", handicap))", color: .charcoal)
                }
            }

            HStack(spacing: 32) {
                identityStat(value: "\(completedRounds.count)", label: "Rounds")
                identityStat(value: bestScoreText, label: "Best Score")
            }
            .padding(.top, 2)

            Text("Member since \(profile.createdDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption2).foregroundStyle(.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .cardStyle(raised: true)
    }

    private func identityStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.weight(.bold)).foregroundStyle(.textPrimary)
            Text(label).font(.caption2).foregroundStyle(.textSecondary)
        }
    }

    // MARK: - Profile switcher

    private var profileSwitcherSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(
                    title: "Profiles",
                    icon: "person.2.fill",
                    info: "Switch between local profiles on this device — each has its own rounds, stats, and practice plans. Nothing syncs or leaves this device."
                )
                Spacer()
                Button {
                    hapticTap()
                    showAddProfile = true
                } label: {
                    Image(systemName: "plus.circle.fill").font(.title3).foregroundStyle(.emerald)
                }
                .buttonStyle(.bouncy)
            }
            VStack(spacing: 8) {
                ForEach(allProfiles) { other in
                    let isActive = other.id == profile.id
                    Button {
                        hapticTap()
                        activeProfileIDString = other.id.uuidString
                    } label: {
                        HStack(spacing: 12) {
                            IconBadge(icon: "person.crop.circle.fill", color: isActive ? .emerald : .slateGray, size: 36)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(other.name.isEmpty ? "Golfer" : other.name).font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
                                Text(other.skillLevel.displayName).font(.caption).foregroundStyle(.textSecondary)
                            }
                            Spacer()
                            if isActive {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.emerald)
                            }
                        }
                    }
                    .buttonStyle(.bouncy)
                    .disabled(isActive)
                }
            }
        }
        .cardStyle()
        .sheet(isPresented: $showAddProfile) {
            ProfileSetupView()
        }
    }

    // MARK: - Data

    private func clearAllRoundData() {
        let myRounds = (try? context.fetch(FetchDescriptor<GolfRound>()))?.filter { $0.profile?.id == profile.id } ?? []
        for round in myRounds { context.delete(round) }
        try? context.save()
        ClubStatsService.recompute(for: profile, in: context)
    }
}

// Simple flow layout for goal pills in read-only mode
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, x + size.width)
            x += size.width + spacing
        }
        return CGSize(width: maxX, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let width = bounds.width
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        _ = width
    }
}
