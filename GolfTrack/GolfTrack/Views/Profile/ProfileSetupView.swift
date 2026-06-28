import SwiftUI
import SwiftData

struct ProfileSetupView: View {
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var skillLevel: SkillLevel = .beginner
    @State private var handicapText = ""
    @State private var average18: Average18ScoreRange?
    @State private var average9: Average9ScoreRange?
    @State private var selectedGoals: Set<GolfGoal> = []
    @State private var customGoalText = ""

    private var knowsHandicap: Bool { !handicapText.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("About You") {
                    TextField("Name", text: $name)
                }

                Section("Skill Level") {
                    Picker("Skill level", selection: $skillLevel) {
                        ForEach(SkillLevel.allCases) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Handicap (optional)") {
                    TextField("Estimated handicap, if known", text: $handicapText)
                        .keyboardType(.numbersAndPunctuation)
                }

                if !knowsHandicap {
                    Section("Average 18-Hole Score") {
                        Picker("Average 18-hole score range", selection: $average18) {
                            Text("Not sure").tag(Optional<Average18ScoreRange>.none)
                            ForEach(Average18ScoreRange.allCases) { range in
                                Text(range.displayName).tag(Optional(range))
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }
                }

                Section("Average 9-Hole Score (optional)") {
                    Picker("Average 9-hole score range", selection: $average9) {
                        Text("Not sure").tag(Optional<Average9ScoreRange>.none)
                        ForEach(Average9ScoreRange.allCases) { range in
                            Text(range.displayName).tag(Optional(range))
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Main Golf Goals") {
                    ForEach(GolfGoal.allCases) { goal in
                        Button {
                            toggle(goal)
                        } label: {
                            HStack {
                                Text(goal.displayName).foregroundStyle(.primary)
                                Spacer()
                                if selectedGoals.contains(goal) {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.golfGreen)
                                } else {
                                    Image(systemName: "circle").foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    if selectedGoals.contains(.other) {
                        TextField("Describe your goal", text: $customGoalText)
                    }
                }

                Section {
                    Button("Save Profile") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Set Up Your Profile")
        }
    }

    private func toggle(_ goal: GolfGoal) {
        if selectedGoals.contains(goal) { selectedGoals.remove(goal) } else { selectedGoals.insert(goal) }
    }

    private func save() {
        let profile = UserProfile(name: name.trimmingCharacters(in: .whitespaces), skillLevel: skillLevel)
        if let handicap = Double(handicapText) { profile.estimatedHandicap = handicap }
        profile.average18ScoreRange = average18
        profile.average9ScoreRange = average9
        profile.goals = Array(selectedGoals)
        profile.customGoalText = selectedGoals.contains(.other) ? customGoalText : nil
        context.insert(profile)
        try? context.save()
    }
}
