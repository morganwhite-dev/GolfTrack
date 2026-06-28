import SwiftUI
import SwiftData

struct ProfileView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var context
    @State private var handicapText: String = ""
    @State private var showSavedToast = false

    var body: some View {
        Form {
            Section("About You") {
                TextField("Name", text: $profile.name)
                Picker("Skill level", selection: $profile.skillLevel) {
                    ForEach(SkillLevel.allCases) { Text($0.displayName).tag($0) }
                }
            }

            Section {
                TextField("Estimated handicap", text: $handicapText)
                    .keyboardType(.numbersAndPunctuation)
                    .onChange(of: handicapText) { _, newValue in
                        profile.estimatedHandicap = Double(newValue)
                    }
                Picker("Avg 18-hole score (vs. par)", selection: $profile.average18ScoreRange) {
                    Text("Not sure").tag(Optional<Average18ScoreRange>.none)
                    ForEach(Average18ScoreRange.allCases) { Text($0.displayName).tag(Optional($0)) }
                }
                Picker("Avg 9-hole score (vs. par)", selection: $profile.average9ScoreRange) {
                    Text("Not sure").tag(Optional<Average9ScoreRange>.none)
                    ForEach(Average9ScoreRange.allCases) { Text($0.displayName).tag(Optional($0)) }
                }
            } header: {
                Text("Scoring Baseline")
            } footer: {
                Text("Both are relative to par, so they apply the same way to standard, par-3, and executive courses.")
            }

            Section("Main Golf Goals") {
                ForEach(GolfGoal.allCases) { goal in
                    Button {
                        var goals = profile.goals
                        if let idx = goals.firstIndex(of: goal) { goals.remove(at: idx) } else { goals.append(goal) }
                        profile.goals = goals
                    } label: {
                        HStack {
                            Text(goal.displayName).foregroundStyle(.primary)
                            Spacer()
                            if profile.goals.contains(goal) {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.brandRed)
                            } else {
                                Image(systemName: "circle").foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                if profile.goals.contains(.other) {
                    TextField("Describe your goal", text: Binding(
                        get: { profile.customGoalText ?? "" },
                        set: { profile.customGoalText = $0 }
                    ))
                }
            }

            Section {
                Text("Member since \(profile.createdDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
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
