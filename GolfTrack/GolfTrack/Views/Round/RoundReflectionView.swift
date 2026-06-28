import SwiftUI
import SwiftData

struct RoundReflectionView: View {
    @Bindable var round: GolfRound
    var onContinue: () -> Void
    @Environment(\.modelContext) private var context

    @State private var reflection: RoundReflection

    init(round: GolfRound, onContinue: @escaping () -> Void) {
        self.round = round
        self.onContinue = onContinue
        _reflection = State(initialValue: round.reflection ?? RoundReflection())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                feelQuestion(title: "How did your tee shots feel today?", reflection.teeShotFeel) { reflection.teeShotFeel = $0 }
                feelQuestion(title: "How was your iron play?", reflection.ironPlayFeel) { reflection.ironPlayFeel = $0 }
                feelQuestion(title: "How was your wedge play?", reflection.wedgePlayFeel) { reflection.wedgePlayFeel = $0 }
                feelQuestion(title: "How was your short game / chipping?", reflection.shortGameFeel) { reflection.shortGameFeel = $0 }
                feelQuestion(title: "How was your putting?", reflection.puttingFeel) { reflection.puttingFeel = $0 }

                VStack(alignment: .leading, spacing: 10) {
                    Text("What was your biggest miss today?").font(.subheadline.weight(.semibold))
                    ChipScrollRow(items: BiggestMiss.allCases, selected: reflection.biggestMiss) { reflection.biggestMiss = $0 }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Any mental mistakes or blow-up holes?", isOn: $reflection.hadMentalMistakes)
                        .tint(.brandRed)
                        .font(.subheadline.weight(.semibold))
                    if reflection.hadMentalMistakes {
                        InputField(placeholder: "What happened?", text: $reflection.mentalMistakesNote)
                    }
                }
                .cardStyle()

                freeTextQuestion(title: "What felt best today?", text: $reflection.feltBestText)
                freeTextQuestion(title: "What frustrated you the most?", text: $reflection.frustratedText)
                freeTextQuestion(title: "What do you want to improve next round?", text: $reflection.improveNextText)

                Button("Continue") { save() }
                    .buttonStyle(.primaryGolf)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("How Did It Go?").font(.title2.weight(.bold))
            Text("A few quick questions to help tailor your advice.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func feelQuestion(title: String, _ selected: FeelRating?, onSelect: @escaping (FeelRating?) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.subheadline.weight(.semibold))
            ChipScrollRow(items: FeelRating.allCases, selected: selected, onSelect: onSelect)
        }
        .cardStyle()
    }

    private func freeTextQuestion(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold))
            InputField(placeholder: "Optional", text: text)
        }
        .cardStyle()
    }

    private func save() {
        if round.reflection == nil {
            context.insert(reflection)
            round.reflection = reflection
        }
        try? context.save()
        onContinue()
    }
}
