import SwiftUI
import SwiftData

struct ProfileSetupView: View {
    @Environment(\.modelContext) private var context

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
                        Circle().fill(Color.emerald.opacity(0.12)).frame(width: 64, height: 64)
                        Image(systemName: "flag.fill").font(.title2).foregroundStyle(.emerald)
                    }
                    Text("Welcome to GolfTrack").font(.title2.weight(.bold))
                    Text("Let's set up your profile so advice and stats are tailored to you.")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Your Name", icon: "person.fill")
                    InputField(placeholder: "Name", text: $name)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Skill Level", icon: "chart.bar.fill")
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
                    SectionHeader(title: "Main Goals", icon: "checkmark.seal.fill")
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
        .background(Color(.systemGroupedBackground))
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
    }
}
