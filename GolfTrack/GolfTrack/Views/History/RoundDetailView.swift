import SwiftUI
import SwiftData

struct RoundDetailView: View {
    let round: GolfRound
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var page = 0
    @State private var showDeleteConfirm = false
    @State private var showEditRound = false

    /// Available pages — tags are fixed so taps and swipe order stay consistent
    /// regardless of which optional sections exist on this round.
    /// 0=Summary, 1=Holes, 2=Reflection, 3=Advice, 4=Practice Plan
    private var pages: [(tag: Int, title: String)] {
        var result = [(0, "Summary")]
        if !round.sortedHoleScores.isEmpty { result.append((1, "Holes")) }
        if round.reflection != nil { result.append((2, "Reflection")) }
        if round.advice != nil { result.append((3, "Advice")) }
        if round.practicePlan != nil { result.append((4, "Practice Plan")) }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            PushedScreenHeader("Round Detail") {
                Menu {
                    Button {
                        hapticTap()
                        showEditRound = true
                    } label: {
                        Label("Edit Round", systemImage: "pencil")
                    }
                    Button {
                        hapticTap()
                        shareDetailedRound()
                    } label: {
                        Label("Share Round Detail", systemImage: "list.bullet.rectangle")
                    }
                    Button {
                        hapticTap()
                        shareMinimalSummary()
                    } label: {
                        Label("Share Minimal Summary", systemImage: "square.and.arrow.up")
                    }
                    Divider()
                    Button(role: .destructive) {
                        hapticTap(.medium)
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete Round", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.emerald)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.05), in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Round actions")
            }
            .padding(.horizontal)
            pageHeader

            TabView(selection: $page) {
                ScrollView {
                    RoundSummaryView(round: round).padding()
                }
                .tag(0)

                if !round.sortedHoleScores.isEmpty {
                    ScrollView {
                        HoleByHoleView(round: round).padding()
                    }
                    .tag(1)
                }

                if let reflection = round.reflection {
                    ScrollView {
                        ReflectionReadOnlyView(reflection: reflection).padding()
                    }
                    .tag(2)
                }

                if let advice = round.advice {
                    ScrollView {
                        AdviceView(advice: advice).padding()
                    }
                    .tag(3)
                }

                if let plan = round.practicePlan {
                    ScrollView {
                        PracticePlanView(plan: plan).padding()
                    }
                    .tag(4)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showEditRound) {
            RoundEditView(round: round)
                .preferredColorScheme(.dark)
        }
        .confirmationDialog("Delete This Round?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Round", role: .destructive) { deleteRound() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes this round and its stats. This can't be undone.")
        }
    }

    // MARK: - Share

    private func shareDetailedRound() {
        let renderer = ImageRenderer(content: RoundDetailShareCardView(round: round))
        renderer.scale = 3.0
        presentShareSheet(image: renderer.uiImage)
    }

    private func shareMinimalSummary() {
        let renderer = ImageRenderer(content: RoundShareCardView(round: round))
        renderer.scale = 3.0
        presentShareSheet(image: renderer.uiImage)
    }

    // UIActivityViewController can't be embedded in a SwiftUI .sheet — it must be
    // presented directly on the UIKit view controller hierarchy.
    private func presentShareSheet(image: UIImage?) {
        guard let image else { return }
        let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let root = windowScene.windows.first(where: \.isKeyWindow)?.rootViewController
        else { return }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        top.present(vc, animated: true)
    }

    private func deleteRound() {
        let profile = round.profile
        context.delete(round)
        try? context.save()
        if let profile {
            ClubStatsService.recompute(for: profile, in: context)
        }
        dismiss()
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

// MARK: - Edit Round

private struct RoundEditView: View {
    @Bindable var round: GolfRound
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var selectedHole: HoleScore?
    @State private var holePendingDelete: HoleScore?

    private var holes: [HoleScore] { round.sortedHoleScores }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    roundDetailsCard
                    holesCard
                }
                .padding()
            }
            .appBackground()
            .navigationTitle("Edit Round")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    ToolbarPillButton(title: "Done") {
                        saveAndDismiss()
                    }
                }
            }
            .sheet(item: $selectedHole) { hole in
                NavigationStack {
                    HoleEntryView(holeScore: hole)
                        .navigationTitle("Hole \(hole.holeNumber)")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                ToolbarPillButton(title: "Done") {
                                    hapticTap()
                                    try? context.save()
                                    selectedHole = nil
                                }
                            }
                        }
                }
                .preferredColorScheme(.dark)
            }
            .alert("Delete This Hole?", isPresented: Binding(
                get: { holePendingDelete != nil },
                set: { if !$0 { holePendingDelete = nil } }
            )) {
                Button("Delete Hole", role: .destructive) {
                    if let holePendingDelete {
                        deleteHole(holePendingDelete)
                    }
                    holePendingDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    holePendingDelete = nil
                }
            } message: {
                Text("Use this for extra holes that were added by mistake. Existing hole scores on that hole will be removed.")
            }
        }
    }

    private var roundDetailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Round Details", icon: "pencil.circle.fill")
            DatePicker("Date", selection: $round.date, displayedComponents: .date)
                .tint(.emerald)
                .foregroundStyle(.textPrimary)
            InputField(placeholder: "Tee box", text: optionalStringBinding(\.teeBoxName))
            InputField(placeholder: "Weather / wind notes", text: optionalStringBinding(\.weatherNotes))

            Text("Walking or Cart").font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
            HStack(spacing: 10) {
                ChoiceChip(label: "Walking", isSelected: round.walkOrCart == .walking) { toggle(.walking) }
                ChoiceChip(label: "Cart", isSelected: round.walkOrCart == .cart) { toggle(.cart) }
            }
        }
        .cardStyle()
    }

    private var holesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Scorecard", subtitle: "Tap a hole to edit it. Delete extra holes that do not exist on the course.", icon: "list.number")
            ForEach(holes) { hole in
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Button {
                            selectedHole = hole
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Hole \(hole.holeNumber)")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(.textPrimary)
                                    Text(hole.strokes > 0 ? "\(hole.strokes) strokes • \(hole.putts) putts • \(scoreToParText(hole.scoreToPar))" : "No score entered")
                                        .font(.caption)
                                        .foregroundStyle(.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.textTertiary)
                            }
                        }
                        .buttonStyle(.plain)

                        Button {
                            hapticTap(.medium)
                            holePendingDelete = hole
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.alertCoral)
                                .frame(width: 34, height: 34)
                                .background(Color.alertCoral.opacity(0.1), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Delete hole \(hole.holeNumber)")
                        .disabled(holes.count <= 1)
                        .opacity(holes.count <= 1 ? 0.35 : 1)
                    }

                    Stepper("Par \(hole.par)", value: Binding(
                        get: { hole.par },
                        set: { hole.par = $0 }
                    ), in: 2...6)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.textSecondary)
                }
                .padding(.vertical, 8)

                if hole.id != holes.last?.id {
                    Divider().background(Color.white.opacity(0.06))
                }
            }
        }
        .cardStyle()
    }

    private func deleteHole(_ hole: HoleScore) {
        let remaining = holes.filter { $0.id != hole.id }
        round.holeScores = remaining
        round.holesPlayed = remaining.count
        if round.activeHoleNumber == hole.holeNumber {
            round.activeHoleNumber = remaining.first?.holeNumber
        }
        context.delete(hole)
        try? context.save()
    }

    private func optionalStringBinding(_ keyPath: ReferenceWritableKeyPath<GolfRound, String?>) -> Binding<String> {
        Binding(
            get: { round[keyPath: keyPath] ?? "" },
            set: { round[keyPath: keyPath] = $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
        )
    }

    private func toggle(_ value: WalkOrCart) {
        round.walkOrCart = (round.walkOrCart == value) ? nil : value
    }

    private func saveAndDismiss() {
        hapticTap()
        round.holesPlayed = holes.count
        try? context.save()
        if let profile = round.profile {
            ClubStatsService.recompute(for: profile, in: context)
        }
        dismiss()
    }
}

// MARK: - Share card

private struct RoundDetailShareCardView: View {
    let round: GolfRound

    private var stats: RoundStats { RoundStats(round: round) }
    private var holes: [HoleScore] { round.sortedHoleScores }
    private let bg = Color(red: 0.07, green: 0.09, blue: 0.11)
    private let surface = Color(red: 0.13, green: 0.16, blue: 0.19)
    private let emerald = Color(red: 0.24, green: 0.82, blue: 0.59)
    private let amber = Color(red: 0.93, green: 0.58, blue: 0.27)
    private let coral = Color(red: 0.95, green: 0.38, blue: 0.38)

    private var cardHeight: CGFloat {
        var height = 260 + CGFloat(max(holes.count, 1)) * 44
        if round.reflection != nil { height += 126 }
        if round.advice != nil { height += 108 }
        if round.practicePlan != nil { height += 84 }
        return max(height, 640)
    }

    var body: some View {
        ZStack {
            bg
            VStack(alignment: .leading, spacing: 18) {
                header
                summaryGrid
                scorecard
                if let reflection = round.reflection {
                    detailSection(
                        title: "Reflection",
                        icon: "text.bubble.fill",
                        lines: reflectionLines(reflection)
                    )
                }
                if let advice = round.advice {
                    detailSection(
                        title: "Advice",
                        icon: "lightbulb.fill",
                        lines: [advice.bestPart, advice.mainIssue, advice.nextRoundGoal].filter { !$0.isEmpty }
                    )
                }
                if let plan = round.practicePlan {
                    detailSection(
                        title: "Practice Plan",
                        icon: "figure.golf",
                        lines: [plan.mainFocus, plan.secondaryFocus, plan.nextRoundGoal].filter { !$0.isEmpty }
                    )
                }
                Spacer(minLength: 0)
                footer
            }
            .padding(26)
        }
        .frame(width: 430, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("GOLFTRACK", systemImage: "figure.golf")
                    .font(.caption.weight(.heavy))
                    .tracking(2.0)
                    .foregroundStyle(emerald)
                Spacer()
                Text(round.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))
            }
            Text(stats.courseName)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            Text("\(stats.holesPlayed)-hole round • Par \(stats.totalPar)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.48))
        }
    }

    private var summaryGrid: some View {
        HStack(spacing: 8) {
            shareMetric("Score", "\(stats.totalStrokes)", scoreToParText(stats.scoreToPar), color: scoreColor(stats.scoreToPar))
            shareMetric("Putts", "\(stats.totalPutts)", String(format: "%.1f / hole", stats.averagePuttsPerHole), color: emerald)
            shareMetric("Penalties", "\(stats.totalPenalties)", "\(stats.holesWithPenalties) holes", color: stats.totalPenalties > 0 ? coral : emerald)
        }
    }

    private var scorecard: some View {
        VStack(alignment: .leading, spacing: 8) {
            shareSectionTitle("Scorecard", icon: "list.number")
            VStack(spacing: 0) {
                ForEach(holes) { hole in
                    HStack(spacing: 10) {
                        Text("H\(hole.holeNumber)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 34, alignment: .leading)
                        Text("P\(hole.par)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.42))
                            .frame(width: 28, alignment: .leading)
                        Text(hole.strokes > 0 ? "\(hole.strokes)" : "-")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(hole.strokes > 0 ? scoreColor(hole.scoreToPar) : .white.opacity(0.32))
                            .frame(width: 28)
                        Text(holeDetailText(hole))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.66))
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.vertical, 7)
                    if hole.id != holes.last?.id {
                        Rectangle().fill(.white.opacity(0.06)).frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var footer: some View {
        Text("golftrack.app")
            .font(.caption2.weight(.medium))
            .tracking(0.8)
            .foregroundStyle(.white.opacity(0.22))
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private func shareMetric(_ title: String, _ value: String, _ subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption2.weight(.bold)).foregroundStyle(.white.opacity(0.38))
            Text(value).font(.system(size: 24, weight: .black, design: .rounded)).foregroundStyle(.white)
            Text(subtitle).font(.caption2.weight(.semibold)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func detailSection(title: String, icon: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            shareSectionTitle(title, icon: icon)
            VStack(alignment: .leading, spacing: 5) {
                ForEach(Array(lines.prefix(3).enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func shareSectionTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption.weight(.bold)).foregroundStyle(emerald)
            Text(title).font(.caption.weight(.heavy)).foregroundStyle(.white.opacity(0.82))
        }
    }

    private func holeDetailText(_ hole: HoleScore) -> String {
        var parts = ["\(hole.putts) putts"]
        if hole.penalties > 0 { parts.append("+\(hole.penalties) pen") }
        if let club = hole.teeClub { parts.append(club.displayName) }
        if hole.missDirection != .na, hole.missDirection != .good { parts.append("Miss \(hole.missDirection.displayName)") }
        if !hole.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { parts.append(hole.notes) }
        return parts.joined(separator: " • ")
    }

    private func reflectionLines(_ reflection: RoundReflection) -> [String] {
        var lines: [String] = []
        if let miss = reflection.biggestMiss { lines.append("Biggest miss: \(miss.displayName)") }
        if !reflection.feltBestText.isEmpty { lines.append("Best: \(reflection.feltBestText)") }
        if !reflection.frustratedText.isEmpty { lines.append("Frustrated by: \(reflection.frustratedText)") }
        if !reflection.improveNextText.isEmpty { lines.append("Next: \(reflection.improveNextText)") }
        return lines.isEmpty ? ["No reflection notes logged."] : lines
    }

    private func scoreColor(_ scoreToPar: Int) -> Color {
        switch scoreToPar {
        case ..<0: return emerald
        case 0...4: return scoreToPar == 0 ? .white : amber
        default: return coral
        }
    }
}

struct RoundShareCardView: View {
    let round: GolfRound

    private var stats: RoundStats { RoundStats(round: round) }

    // Explicit values — not theme aliases — so ImageRenderer always sees the dark palette.
    private let bg      = Color(red: 0.07, green: 0.09, blue: 0.11)
    private let surface = Color(red: 0.13, green: 0.16, blue: 0.19)
    private let emerald = Color(red: 0.24, green: 0.82, blue: 0.59)
    private let amber   = Color(red: 0.93, green: 0.58, blue: 0.27)
    private let coral   = Color(red: 0.95, green: 0.38, blue: 0.38)

    private var scoreColor: Color {
        switch stats.scoreToPar {
        case ..<0:   return emerald
        case 0:      return .white
        case 1...4:  return amber
        default:     return coral
        }
    }

    private var bestHole: HoleScore? {
        round.sortedHoleScores.filter { $0.strokes > 0 }.min(by: { $0.scoreToPar < $1.scoreToPar })
    }

    var body: some View {
        ZStack {
            bg
            // Subtle emerald glow from the top centre
            RadialGradient(
                colors: [emerald.opacity(0.14), Color.clear],
                center: .init(x: 0.5, y: 0.0),
                startRadius: 0,
                endRadius: 280
            )

            VStack(spacing: 0) {
                brandBar
                Divider().background(emerald.opacity(0.18))
                mainContent
                Spacer(minLength: 0)
                footerBar
            }
        }
        .frame(width: 390, height: 520)
        .clipShape(RoundedRectangle(cornerRadius: 0))  // flat edges — nicer as a PNG share card
    }

    // MARK: - Sections

    private var brandBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "figure.golf")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(emerald)
            Text("GOLFTRACK")
                .font(.caption.weight(.heavy))
                .tracking(2.5)
                .foregroundStyle(emerald)
            Spacer()
            Text(round.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.38))
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
    }

    private var mainContent: some View {
        VStack(spacing: 20) {
            // Course name + format
            VStack(spacing: 5) {
                Text(stats.courseName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("\(stats.holesPlayed)-hole round")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }

            // Big score circle
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(0.11))
                    .overlay(Circle().strokeBorder(scoreColor.opacity(0.6), lineWidth: 1.5))
                    .frame(width: 128, height: 128)

                VStack(spacing: 1) {
                    Text("\(stats.totalStrokes)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text(scoreToParText(stats.scoreToPar))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(scoreColor)
                }
            }

            // Stats row
            HStack(spacing: 0) {
                statCell("\(stats.totalPutts)", "Putts")
                separator
                statCell(String(format: "%.1f", stats.averageStrokesPerHole), "Avg / Hole")
                if stats.totalPenalties > 0 {
                    separator
                    statCell("\(stats.totalPenalties)", "Penalties")
                }
            }
            .padding(.vertical, 14)
            .background(surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            // Best hole pill
            if let best = bestHole {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill").font(.caption).foregroundStyle(emerald)
                    Text("Best: Hole \(best.holeNumber) — \(holeName(best.scoreToPar))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(emerald.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(emerald.opacity(0.25), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }

    private var footerBar: some View {
        Text("golftrack.app")
            .font(.caption2.weight(.medium))
            .tracking(0.8)
            .foregroundStyle(.white.opacity(0.18))
            .padding(.bottom, 18)
    }

    // MARK: - Helpers

    private var separator: some View {
        Rectangle()
            .fill(.white.opacity(0.08))
            .frame(width: 1, height: 34)
    }

    private func statCell(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.42))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private func holeName(_ toPar: Int) -> String {
        switch toPar {
        case ..<(-2): return "Double Eagle"
        case -2: return "Eagle"
        case -1: return "Birdie"
        case 0:  return "Par"
        case 1:  return "Bogey"
        case 2:  return "Double Bogey"
        default: return "+\(toPar)"
        }
    }
}

// MARK: - Holes Page

private struct HoleByHoleView: View {
    let round: GolfRound

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Hole by Hole", icon: "list.number",
                          info: "Every hole you played this round — strokes, putts, penalties, club used, and your miss direction.")
            VStack(spacing: 2) {
                ForEach(round.sortedHoleScores) { hole in
                    HoleHistoryRow(hole: hole)
                    if hole.holeNumber < round.sortedHoleScores.count {
                        Divider().background(Color.white.opacity(0.06))
                    }
                }
            }
        }
        .cardStyle()
    }
}

private struct HoleHistoryRow: View {
    let hole: HoleScore

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 1) {
                Text("H\(hole.holeNumber)").font(.caption.weight(.bold)).foregroundStyle(.textSecondary)
                Text("P\(hole.par)").font(.caption2).foregroundStyle(.textTertiary)
            }
            .frame(width: 30)

            if hole.strokes > 0 {
                ScoreBadge(scoreToPar: hole.scoreToPar, size: 34)
            } else {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 34, height: 34)
                    .overlay(Text("—").font(.caption2).foregroundStyle(.textTertiary))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(hole.strokes > 0 ? "\(hole.strokes) strokes" : "Not played")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
                    if hole.penalties > 0 {
                        Pill(text: "+\(hole.penalties) pen", color: .alertCoral)
                    }
                }
                HStack(spacing: 4) {
                    if hole.putts > 0 {
                        Text("\(hole.putts) putts").font(.caption).foregroundStyle(.textSecondary)
                    }
                    if let club = hole.teeClub {
                        Text("·").font(.caption).foregroundStyle(.textTertiary)
                        Text(club.displayName).font(.caption).foregroundStyle(.textSecondary)
                    }
                    if hole.missDirection != .na && hole.missDirection != .good {
                        Text("·").font(.caption).foregroundStyle(.textTertiary)
                        Text("Miss \(hole.missDirection.displayName)")
                            .font(.caption).foregroundStyle(.warningAmber)
                    }
                }
            }

            Spacer()

            if let contact = hole.contactQuality {
                contactDot(contact)
            }
        }
        .padding(.vertical, 8)
    }

    private func contactDot(_ contact: ContactQuality) -> some View {
        let color: Color = contact == .pure || contact == .good ? .emerald : contact == .okay ? .warningAmber : .alertCoral
        return Circle()
            .fill(color.opacity(0.8))
            .frame(width: 8, height: 8)
    }
}

// MARK: - Reflection page

private struct ReflectionReadOnlyView: View {
    let reflection: RoundReflection

    private var feelItems: [(label: String, icon: String, feel: FeelRating?)] {
        [
            ("Tee Shots", "flag.fill", reflection.teeShotFeel),
            ("Iron Play", "arrow.up.right", reflection.ironPlayFeel),
            ("Wedge Play", "wind", reflection.wedgePlayFeel),
            ("Short Game", "figure.golf", reflection.shortGameFeel),
            ("Putting", "smallcircle.filled.circle", reflection.puttingFeel),
        ]
    }

    private var hasAnyData: Bool {
        feelItems.contains { $0.feel != nil }
            || reflection.biggestMiss != nil
            || !reflection.feltBestText.isEmpty
            || !reflection.frustratedText.isEmpty
            || !reflection.improveNextText.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "How It Felt",
                icon: "text.bubble.fill",
                info: "Your own read on each part of your game right after the round — Good/Okay/Poor, your call, not a calculated stat."
            )

            if hasAnyData {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(feelItems, id: \.label) { item in
                        FeelTile(label: item.label, icon: item.icon, feel: item.feel)
                    }
                }

                HStack(spacing: 10) {
                    if let miss = reflection.biggestMiss {
                        Pill(text: "Biggest miss: \(miss.displayName)", color: .warningAmber)
                    }
                    Pill(
                        text: reflection.hadMentalMistakes ? "Mental mistakes" : "Stayed focused",
                        color: reflection.hadMentalMistakes ? .alertCoral : .emerald
                    )
                    Spacer()
                }

                if !reflection.feltBestText.isEmpty {
                    freeTextCard(title: "What felt best", icon: "star.fill", color: .emerald, text: reflection.feltBestText)
                }
                if !reflection.frustratedText.isEmpty {
                    freeTextCard(title: "What frustrated you most", icon: "exclamationmark.triangle.fill", color: .warningAmber, text: reflection.frustratedText)
                }
                if !reflection.improveNextText.isEmpty {
                    freeTextCard(title: "Wanted to improve next round", icon: "arrow.up.forward.circle.fill", color: .emerald, text: reflection.improveNextText)
                }
            } else {
                Text("No reflection was logged for this round.")
                    .font(.subheadline).foregroundStyle(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
        }
    }

    private func freeTextCard(title: String, icon: String, color: Color, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption).foregroundStyle(color)
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
            }
            Text(text).font(.subheadline).foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

private struct FeelTile: View {
    let label: String
    let icon: String
    let feel: FeelRating?

    private var color: Color {
        switch feel {
        case .good: return .emerald
        case .okay: return .warningAmber
        case .poor: return .alertCoral
        case nil: return .slateGray
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            IconBadge(icon: icon, color: color, size: 36)
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(.textPrimary)
            Pill(text: feel?.displayName ?? "—", color: color, filled: feel != nil)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .cardStyle(padding: 8, cornerRadius: 14)
    }
}
