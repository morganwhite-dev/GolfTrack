import SwiftUI
import SwiftData

struct ProfileView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var context
    @State private var handicapText: String = ""
    @State private var showSavedToast = false

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

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Main Goals", icon: "checkmark.seal.fill")
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

                Text("Member since \(profile.createdDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Profile")
        .onAppear {
            if let h = profile.estimatedHandicap { handicapText = String(h) }
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
}
