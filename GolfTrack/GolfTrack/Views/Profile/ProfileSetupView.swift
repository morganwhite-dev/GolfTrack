import SwiftUI
import SwiftData

struct ProfileSetupView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("activeProfileID") private var activeProfileIDString: String = ""

    @State private var name = ""
    @State private var skillLevel: SkillLevel = .beginner
    @State private var handicapText = ""
    @State private var selectedGoals: Set<GolfGoal> = []
    @State private var customGoalText = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle().fill(Color.emerald.opacity(0.16)).frame(width: 64, height: 64)
                        Image(systemName: "flag.fill").font(.title2).foregroundStyle(.emerald)
                    }
                    Text("Welcome to GolfTrack").font(.title2.weight(.bold)).foregroundStyle(.textPrimary)
                    Text("Let's set up your profile so advice and stats are tailored to you.")
                        .font(.subheadline).foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "How GolfTrack Helps", icon: "sparkles")
                    onboardingValueRow(icon: "lock.fill", title: "Score without opening the app", text: "Log strokes and putts from the Lock Screen during a round.")
                    onboardingValueRow(icon: "lightbulb.fill", title: "Understand what cost you strokes", text: "After each round, GolfTrack turns your numbers into plain-language insights.")
                    onboardingValueRow(icon: "checkmark.seal.fill", title: "Practice with a purpose", text: "Your plan focuses on the few drills most likely to help your next round.")
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Your Name", icon: "person.fill")
                    InputField(placeholder: "Name", text: $name)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        title: "Skill Level",
                        icon: "chart.bar.fill",
                        info: "This tunes the tone of your advice. You can change it later as your scores improve."
                    )
                    VStack(spacing: 8) {
                        ForEach(SkillLevel.allCases) { level in
                            SelectableRow(label: level.displayName, isSelected: skillLevel == level) {
                                skillLevel = level
                            }
                        }
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Handicap", subtitle: "Optional, if known", icon: "number")
                    InputField(placeholder: "Estimated handicap", text: $handicapText, keyboardType: .numbersAndPunctuation)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        title: "Main Goals",
                        icon: "checkmark.seal.fill",
                        info: "Score goals are adjusted to the par of the course you actually play."
                    )
                    VStack(spacing: 8) {
                        ForEach(GolfGoal.allCases) { goal in
                            SelectableRow(label: goal.displayName, subtitle: goal.parOffsetSubtitle, isSelected: selectedGoals.contains(goal)) {
                                toggle(goal)
                            }
                        }
                    }
                    if selectedGoals.contains(.other) {
                        InputField(placeholder: "Describe your goal", text: $customGoalText)
                    }
                }
                .cardStyle()

                Button("Save Profile") { save() }
                    .buttonStyle(.primaryGolf)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .appBackground()
        .scrollDismissesKeyboard(.interactively)
    }

    private func toggle(_ goal: GolfGoal) {
        if selectedGoals.contains(goal) { selectedGoals.remove(goal) } else { selectedGoals.insert(goal) }
    }

    private func save() {
        let profile = UserProfile(name: name.trimmingCharacters(in: .whitespaces), skillLevel: skillLevel)
        if let handicap = Double(handicapText) { profile.estimatedHandicap = handicap }
        profile.goals = Array(selectedGoals)
        profile.customGoalText = selectedGoals.contains(.other) ? customGoalText : nil
        context.insert(profile)
        try? context.save()
        activeProfileIDString = profile.id.uuidString
        dismiss()
    }

    private func onboardingValueRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            IconBadge(icon: icon, color: .emerald, size: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
                Text(text).font(.caption).foregroundStyle(.textSecondary)
            }
            Spacer()
        }
    }
}
