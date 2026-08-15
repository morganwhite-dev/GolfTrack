import SwiftUI
import SwiftData

private enum HoleSelectionMode {
    case fullCourse, front9, back9, custom
}

struct RoundSetupView: View {
    let course: GolfCourse
    let profile: UserProfile
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var holeSelectionMode: HoleSelectionMode
    @State private var customStartIndex = 0
    @State private var customHoleCount: Int
    @State private var teeBoxName = ""
    @State private var targetScoreText = ""
    @State private var weatherNotes = ""
    @State private var walkOrCart: WalkOrCart?
    @State private var createdRound: GolfRound?

    init(course: GolfCourse, profile: UserProfile) {
        self.course = course
        self.profile = profile
        _holeSelectionMode = State(initialValue: .fullCourse)
        _customHoleCount = State(initialValue: min(max(course.numberOfHoles, 1), 9))
        _teeBoxName = State(initialValue: course.teeBoxName ?? "")
    }

    private var availableHoleNumbers: [Int] {
        let saved = course.sortedHoles.map(\.holeNumber)
        if !saved.isEmpty { return saved }
        return Array(1...max(course.numberOfHoles, 1))
    }

    private var holeNumbers: [Int] {
        switch holeSelectionMode {
        case .fullCourse:
            return availableHoleNumbers
        case .front9:
            return Array(availableHoleNumbers.prefix(9))
        case .back9:
            return Array(availableHoleNumbers.dropFirst(9).prefix(9))
        case .custom:
            guard !availableHoleNumbers.isEmpty else { return [] }
            let safeCount = min(max(customHoleCount, 1), availableHoleNumbers.count)
            let maxStart = max(availableHoleNumbers.count - safeCount, 0)
            let safeStart = min(max(customStartIndex, 0), maxStart)
            return Array(availableHoleNumbers.dropFirst(safeStart).prefix(safeCount))
        }
    }

    private var totalParForSelection: Int {
        let pars = Dictionary(uniqueKeysWithValues: course.sortedHoles.map { ($0.holeNumber, $0.par) })
        return holeNumbers.reduce(0) { $0 + (pars[$1] ?? 0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            PushedScreenHeader("Round Setup")
                .padding(.horizontal)

            setupContent
        }
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $createdRound, onDismiss: { dismiss() }) { round in
            RoundFlowView(round: round)
        }
    }

    private var setupContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: course.name, subtitle: course.location.isEmpty ? nil : course.location, icon: "flag.fill")
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .tint(.emerald)
                        .foregroundStyle(.textPrimary)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Holes to Play", icon: "number.circle.fill")
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(course.name) has \(availableHoleNumbers.count) saved hole\(availableHoleNumbers.count == 1 ? "" : "s").")
                            .font(.subheadline)
                            .foregroundStyle(.textSecondary)

                        HStack(spacing: 10) {
                            ChoiceChip(label: "\(availableHoleNumbers.count) Holes", isSelected: holeSelectionMode == .fullCourse) {
                                holeSelectionMode = .fullCourse
                            }
                            if availableHoleNumbers.count >= 9 {
                                ChoiceChip(label: "Front 9", isSelected: holeSelectionMode == .front9) {
                                    holeSelectionMode = .front9
                                }
                            }
                            if availableHoleNumbers.count >= 18 {
                                ChoiceChip(label: "Back 9", isSelected: holeSelectionMode == .back9) {
                                    holeSelectionMode = .back9
                                }
                            }
                            ChoiceChip(label: "Custom", isSelected: holeSelectionMode == .custom) {
                                holeSelectionMode = .custom
                                clampCustomSelection()
                            }
                        }

                        if holeSelectionMode == .custom {
                            VStack(alignment: .leading, spacing: 10) {
                                Stepper("Holes: \(customHoleCount)", value: $customHoleCount, in: 1...availableHoleNumbers.count)
                                    .onChange(of: customHoleCount) { _, _ in clampCustomSelection() }
                                Stepper("Start at hole \(availableHoleNumbers[min(customStartIndex, availableHoleNumbers.count - 1)])", value: $customStartIndex, in: 0...max(availableHoleNumbers.count - customHoleCount, 0))
                                    .onChange(of: customStartIndex) { _, _ in clampCustomSelection() }
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.textPrimary)
                        }
                    }
                    Text("Playing holes \(holeNumbers.map(String.init).joined(separator: ", ")) • Par \(totalParForSelection)")
                        .font(.caption).foregroundStyle(.textSecondary)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Optional Details", icon: "plus.circle")
                    InputField(placeholder: "Tee box (e.g. White, Blue)", text: $teeBoxName)
                    InputField(placeholder: "Target score for this round", text: $targetScoreText, keyboardType: .numberPad)
                    InputField(placeholder: "Weather / wind notes", text: $weatherNotes)

                    Text("Walking or Cart").font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
                    HStack(spacing: 10) {
                        ChoiceChip(label: "Walking", isSelected: walkOrCart == .walking) { toggle(.walking) }
                        ChoiceChip(label: "Cart", isSelected: walkOrCart == .cart) { toggle(.cart) }
                    }
                }
                .cardStyle()

                Button("Start Round") { startRound() }
                    .buttonStyle(.primaryGolf)
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func toggle(_ value: WalkOrCart) {
        walkOrCart = (walkOrCart == value) ? nil : value
    }

    private func clampCustomSelection() {
        let maxCount = max(availableHoleNumbers.count, 1)
        customHoleCount = min(max(customHoleCount, 1), maxCount)
        customStartIndex = min(max(customStartIndex, 0), max(maxCount - customHoleCount, 0))
    }

    private func startRound() {
        let round = GolfRound(course: course, date: date, holesPlayed: holeNumbers.count)
        round.profile = profile
        round.teeBoxName = teeBoxName.isEmpty ? nil : teeBoxName
        round.targetScore = Int(targetScoreText)
        round.weatherNotes = weatherNotes.isEmpty ? nil : weatherNotes
        round.walkOrCart = walkOrCart

        let pars = Dictionary(uniqueKeysWithValues: course.sortedHoles.map { ($0.holeNumber, $0.par) })
        var scores: [HoleScore] = []
        for number in holeNumbers {
            let score = HoleScore(holeNumber: number, par: pars[number] ?? 4)
            score.round = round
            context.insert(score)
            scores.append(score)
        }
        round.holeScores = scores

        context.insert(round)
        try? context.save()
        createdRound = round
    }
}
