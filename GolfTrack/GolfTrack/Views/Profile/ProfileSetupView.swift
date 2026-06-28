import SwiftUI
import SwiftData

struct ProfileSetupView: View {
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var skillLevel: SkillLevel = .beginner
    @State private var handicapText = ""
    @State private var selectedGoals: Set<GolfGoal> = []
    @State private var customGoalText = ""

    @State private var knows18 = false
    @State private var par18 = 72
    @State private var score18 = 95

    @State private var knows9 = false
    @State private var par9 = 36
    @State private var score9 = 48

    private var knowsHandicap: Bool { !handicapText.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle().fill(Color.brandRed.opacity(0.12)).frame(width: 64, height: 64)
                        Image(systemName: "flag.fill").font(.title2).foregroundStyle(.brandRed)
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

                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "Scoring Baseline", subtitle: "Optional — helps tailor early feedback", icon: "target")
                    Text("Not sure yet? Skip this — once you log a few rounds, GolfTrack calculates this automatically from your real scores.")
                        .font(.caption).foregroundStyle(.secondary)

                    if !knowsHandicap {
                        Divider()
                        RelativeToParInput(
                            title: "Average 18-hole score",
                            helpText: "Set the par for the 18 holes you usually play, then what you typically shoot.",
                            isEnabled: $knows18, par: $par18, score: $score18, parRange: 54...80
                        )
                    }

                    Divider()
                    RelativeToParInput(
                        title: "Average 9-hole score",
                        helpText: "E.g. Wendell Coffee is a 9-hole par-3 course — par 27. Set par to 27, then enter what you typically shoot there.",
                        isEnabled: $knows9, par: $par9, score: $score9, parRange: 24...45
                    )
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Main Goals", icon: "checkmark.seal.fill")
                    VStack(spacing: 8) {
                        ForEach(GolfGoal.allCases) { goal in
                            SelectableRow(label: goal.displayName, isSelected: selectedGoals.contains(goal)) {
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
        profile.average18RelativeToPar = (knowsHandicap || !knows18) ? nil : score18 - par18
        profile.average9RelativeToPar = knows9 ? score9 - par9 : nil
        profile.goals = Array(selectedGoals)
        profile.customGoalText = selectedGoals.contains(.other) ? customGoalText : nil
        context.insert(profile)
        try? context.save()
    }
}
