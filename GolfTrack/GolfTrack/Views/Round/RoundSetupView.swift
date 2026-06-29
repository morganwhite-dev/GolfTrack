import SwiftUI
import SwiftData

private enum NineHoleSelection {
    case front9, back9
}

struct RoundSetupView: View {
    let course: GolfCourse
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var playFullEighteen: Bool
    @State private var nineHoleSelection: NineHoleSelection = .front9
    @State private var teeBoxName = ""
    @State private var targetScoreText = ""
    @State private var weatherNotes = ""
    @State private var walkOrCart: WalkOrCart?
    @State private var createdRound: GolfRound?

    init(course: GolfCourse) {
        self.course = course
        _playFullEighteen = State(initialValue: course.numberOfHoles == 18)
        _teeBoxName = State(initialValue: course.teeBoxName ?? "")
    }

    private var holeNumbers: [Int] {
        if course.numberOfHoles == 9 { return Array(1...9) }
        if playFullEighteen { return Array(1...18) }
        return nineHoleSelection == .front9 ? Array(1...9) : Array(10...18)
    }

    private var totalParForSelection: Int {
        let pars = Dictionary(uniqueKeysWithValues: course.sortedHoles.map { ($0.holeNumber, $0.par) })
        return holeNumbers.reduce(0) { $0 + (pars[$1] ?? 0) }
    }

    var body: some View {
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
                    if course.numberOfHoles == 9 {
                        Text("This course has 9 holes.").font(.subheadline).foregroundStyle(.textSecondary)
                    } else {
                        HStack(spacing: 10) {
                            ChoiceChip(label: "18 Holes", isSelected: playFullEighteen) { playFullEighteen = true }
                            ChoiceChip(label: "9 Holes", isSelected: !playFullEighteen) { playFullEighteen = false }
                        }
                        if !playFullEighteen {
                            HStack(spacing: 10) {
                                ChoiceChip(label: "Front 9", isSelected: nineHoleSelection == .front9) { nineHoleSelection = .front9 }
                                ChoiceChip(label: "Back 9", isSelected: nineHoleSelection == .back9) { nineHoleSelection = .back9 }
                            }
                        }
                    }
                    Text("Par for these holes: \(totalParForSelection)")
                        .font(.caption).foregroundStyle(.textSecondary)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Optional Details", icon: "ellipsis.circle")
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
        .appBackground()
        .navigationTitle("Round Setup")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $createdRound, onDismiss: { dismiss() }) { round in
            RoundFlowView(round: round)
        }
    }

    private func toggle(_ value: WalkOrCart) {
        walkOrCart = (walkOrCart == value) ? nil : value
    }

    private func startRound() {
        let round = GolfRound(course: course, date: date, holesPlayed: holeNumbers.count)
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
