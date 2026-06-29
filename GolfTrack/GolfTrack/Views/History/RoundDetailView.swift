import SwiftUI

struct RoundDetailView: View {
    let round: GolfRound
    @State private var page = 0

    /// Tag/title pairs for whichever sections actually exist on this round — tags are fixed
    /// (0=Summary, 1=Reflection, 2=Advice, 3=Practice Plan) so they always line up with the
    /// TabView's .tag() values below regardless of which sections are missing.
    private var pages: [(tag: Int, title: String)] {
        var result = [(0, "Summary")]
        if round.reflection != nil { result.append((1, "Reflection")) }
        if round.advice != nil { result.append((2, "Advice")) }
        if round.practicePlan != nil { result.append((3, "Practice Plan")) }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            pageHeader

            TabView(selection: $page) {
                ScrollView {
                    RoundSummaryView(round: round).padding()
                }
                .tag(0)

                if let reflection = round.reflection {
                    ScrollView {
                        ReflectionReadOnlyView(reflection: reflection).padding()
                    }
                    .tag(1)
                }

                if let advice = round.advice {
                    ScrollView {
                        AdviceView(advice: advice).padding()
                    }
                    .tag(2)
                }

                if let plan = round.practicePlan {
                    ScrollView {
                        PracticePlanView(plan: plan).padding()
                    }
                    .tag(3)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .appBackground()
        .navigationTitle("Round Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var pageHeader: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(pages, id: \.tag) { item in
                    Text(item.title)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(page == item.tag ? Color.emerald.opacity(0.18) : Color.white.opacity(0.05), in: Capsule())
                        .foregroundStyle(page == item.tag ? .emerald : .textSecondary)
                        .onTapGesture { withAnimation { page = item.tag } }
                }
            }
            HStack(spacing: 6) {
                ForEach(pages, id: \.tag) { item in
                    Capsule()
                        .fill(page == item.tag ? Color.emerald : Color.white.opacity(0.15))
                        .frame(width: page == item.tag ? 18 : 6, height: 6)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: page)
                }
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

private struct ReflectionReadOnlyView: View {
    let reflection: RoundReflection

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Reflection", icon: "text.bubble.fill")

            VStack(alignment: .leading, spacing: 10) {
                feelRow("Tee Shots", reflection.teeShotFeel)
                feelRow("Iron Play", reflection.ironPlayFeel)
                feelRow("Wedge Play", reflection.wedgePlayFeel)
                feelRow("Short Game", reflection.shortGameFeel)
                feelRow("Putting", reflection.puttingFeel)
                if let miss = reflection.biggestMiss {
                    StatRow(label: "Biggest Miss", value: miss.displayName)
                }
                StatRow(label: "Mental Mistakes", value: reflection.hadMentalMistakes ? "Yes" : "No")
            }
            .cardStyle()

            if !reflection.feltBestText.isEmpty {
                freeTextCard(title: "What felt best", text: reflection.feltBestText)
            }
            if !reflection.frustratedText.isEmpty {
                freeTextCard(title: "What frustrated you most", text: reflection.frustratedText)
            }
            if !reflection.improveNextText.isEmpty {
                freeTextCard(title: "Wanted to improve next round", text: reflection.improveNextText)
            }
        }
    }

    private func feelRow(_ label: String, _ feel: FeelRating?) -> some View {
        StatRow(label: label, value: feel?.displayName ?? "—")
    }

    private func freeTextCard(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
            Text(text).font(.subheadline).foregroundStyle(.textSecondary)
        }
        .cardStyle()
    }
}
