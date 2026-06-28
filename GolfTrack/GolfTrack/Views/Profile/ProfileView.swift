import SwiftUI
import SwiftData

struct ProfileView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var context
    @State private var handicapText: String = ""
    @State private var showSavedToast = false

    @State private var knows18 = false
    @State private var par18 = 72
    @State private var score18 = 95

    @State private var knows9 = false
    @State private var par9 = 36
    @State private var score9 = 48

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Your Name", icon: "person.fill")
                    InputField(placeholder: "Name", text: $profile.name)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Skill Level", icon: "chart.bar.fill")
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

                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "Scoring Baseline", icon: "target")
                    Text("Relative to par, so this applies the same way to standard, par-3, and executive courses.")
                        .font(.caption).foregroundStyle(.secondary)

                    Divider()
                    RelativeToParInput(
                        title: "Average 18-hole score",
                        helpText: "Set the par for the 18 holes you usually play, then what you typically shoot.",
                        isEnabled: $knows18, par: $par18, score: $score18, parRange: 54...80
                    )

                    Divider()
                    RelativeToParInput(
                        title: "Average 9-hole score",
                        helpText: "E.g. for a 9-hole par-3 course, set par to 27, then enter what you typically shoot there.",
                        isEnabled: $knows9, par: $par9, score: $score9, parRange: 24...45
                    )
                }
                .cardStyle()
                .onChange(of: knows18) { _, _ in syncBaselineToProfile() }
                .onChange(of: par18) { _, _ in syncBaselineToProfile() }
                .onChange(of: score18) { _, _ in syncBaselineToProfile() }
                .onChange(of: knows9) { _, _ in syncBaselineToProfile() }
                .onChange(of: par9) { _, _ in syncBaselineToProfile() }
                .onChange(of: score9) { _, _ in syncBaselineToProfile() }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Main Goals", icon: "checkmark.seal.fill")
                    VStack(spacing: 8) {
                        ForEach(GolfGoal.allCases) { goal in
                            SelectableRow(label: goal.displayName, isSelected: profile.goals.contains(goal)) {
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

                Text("Member since \(profile.createdDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Profile")
        .onAppear {
            if let h = profile.estimatedHandicap { handicapText = String(h) }
            if let rel = profile.average18RelativeToPar { knows18 = true; score18 = par18 + rel }
            if let rel = profile.average9RelativeToPar { knows9 = true; score9 = par9 + rel }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    try? context.save()
                    showSavedToast = true
                }
            }
        }
        .alert("Profile Saved", isPresented: $showSavedToast) {
            Button("OK", role: .cancel) {}
        }
    }

    private func syncBaselineToProfile() {
        profile.average18RelativeToPar = knows18 ? score18 - par18 : nil
        profile.average9RelativeToPar = knows9 ? score9 - par9 : nil
    }
}
