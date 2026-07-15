import SwiftUI
import SwiftData

struct HoleEntryView: View {
    @Bindable var holeScore: HoleScore
    var caddieNote: CaddieNote?
    var onScoreChanged: () -> Void = {}
    @Environment(\.modelContext) private var context
    @State private var showMoreDetails = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header

                if let caddieNote {
                    caddieNoteCard(caddieNote)
                }

                HStack(spacing: 12) {
                    BigStepperBox(title: "Strokes", value: $holeScore.strokes, range: 0...15)
                    BigStepperBox(title: "Putts", value: $holeScore.putts, range: 0...10)
                    BigStepperBox(title: "Penalties", value: $holeScore.penalties, range: 0...8)
                }

                fieldSection(title: "Tee Club") {
                    ChipScrollRow(items: ClubType.orderedAll, selected: holeScore.teeClub) { club in
                        holeScore.teeClub = club
                        syncClubShots()
                    }
                }

                // Tee Shot Result doubles as miss direction — picking Left/Right/Short/Long
                // here auto-populates the per-hole missDirection used in stats and caddie notes,
                // so there's no separate redundant "Miss Direction" field.
                fieldSection(title: "Tee Shot Result") {
                    ChipScrollRow(items: ShotResult.teeShotQuickOptions, selected: holeScore.teeShotResult) { result in
                        holeScore.teeShotResult = result
                        switch result {
                        case .left:  holeScore.missDirection = .left
                        case .right: holeScore.missDirection = .right
                        case .short: holeScore.missDirection = .short
                        case .long:  holeScore.missDirection = .long
                        case .good:  holeScore.missDirection = .good
                        default: break
                        }
                        syncClubShots()
                    }
                }

                fieldSection(title: "Contact Quality") {
                    ChipScrollRow(items: ContactQuality.allCases, selected: holeScore.contactQuality) { quality in
                        holeScore.contactQuality = quality
                        syncClubShots()
                    }
                }

                ExpandableSection(
                    title: "More Details",
                    subtitle: "Optional — only if you hit your approach or short game on this hole",
                    isExpanded: $showMoreDetails
                ) {
                    VStack(alignment: .leading, spacing: 16) {
                        fieldSection(title: "Approach Club", padded: false) {
                            ChipScrollRow(items: ClubType.orderedAll, selected: holeScore.approachClub) { club in
                                holeScore.approachClub = club
                                syncClubShots()
                            }
                        }
                        fieldSection(title: "Short Game Club", padded: false) {
                            ChipScrollRow(items: ClubType.orderedAll, selected: holeScore.shortGameClub) { club in
                                holeScore.shortGameClub = club
                                syncClubShots()
                            }
                        }
                        fieldSection(title: "Fairway Hit", padded: false) {
                            ChipScrollRow(items: YesNoNA.allCases, selected: holeScore.fairwayHit == .na ? nil : holeScore.fairwayHit, allowsDeselect: false) { value in
                                holeScore.fairwayHit = value ?? .na
                            }
                        }
                        fieldSection(title: "Green in Regulation", padded: false) {
                            ChipScrollRow(items: YesNoNA.allCases, selected: holeScore.greenInRegulation == .na ? nil : holeScore.greenInRegulation, allowsDeselect: false) { value in
                                holeScore.greenInRegulation = value ?? .na
                            }
                        }
                        fieldSection(title: "Shot Issue (technical fault, if any)", padded: false) {
                            ChipScrollRow(items: ShotIssue.allCases, selected: holeScore.shotIssue == .none ? nil : holeScore.shotIssue, allowsDeselect: false) { issue in
                                holeScore.shotIssue = issue ?? .none
                            }
                        }
                        fieldSection(title: "Confidence", padded: false) {
                            ChipScrollRow(items: Confidence.allCases, selected: holeScore.confidence) { confidence in
                                holeScore.confidence = confidence
                                syncClubShots()
                            }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes").font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
                            InputField(placeholder: "Optional notes", text: $holeScore.notes)
                        }
                    }
                }
            }
            .padding()
        }
        .onChange(of: holeScore.strokes) { _, _ in
            onScoreChanged()
        }
        .onChange(of: holeScore.putts) { _, _ in
            onScoreChanged()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hole \(holeScore.holeNumber)").font(.title2.weight(.bold)).foregroundStyle(.textPrimary)
                Text("Par \(holeScore.par)").font(.subheadline).foregroundStyle(.textSecondary)
            }
            Spacer()
            if holeScore.strokes > 0 {
                ScoreBadge(scoreToPar: holeScore.scoreToPar, size: 50)
            }
        }
    }

    private func caddieNoteCard(_ note: CaddieNote) -> some View {
        HStack(spacing: 12) {
            IconBadge(icon: "figure.golf.circle.fill", color: .warningAmber, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text("Caddie Note").font(.caption.weight(.bold)).foregroundStyle(.warningAmber).tracking(0.5)
                Text(note.summary).font(.subheadline).foregroundStyle(.textPrimary)
            }
            Spacer()
        }
        .cardStyle(raised: true)
    }

    @ViewBuilder
    private func fieldSection<Content: View>(title: String, padded: Bool = true, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
            content()
        }
        .modifier(ConditionalCard(applyCard: padded))
    }

    // Synthesizes a ShotResult for a given shot on this hole.
    // Tee shots use the full directional miss (from teeShotResult → missDirection);
    // approach and chip shots only use the shot issue, since hole-level miss direction
    // reflects the tee shot and applying it to wedges/putters would be inaccurate.
    private func synthesizedResult(includeDirectional: Bool) -> ShotResult {
        switch holeScore.shotIssue {
        case .thin:    return .thin
        case .fat:     return .fat
        case .topped:  return .topped
        case .chunked: return .chunked
        case .shanked: return .shanked
        case .pulled:  return .pulled
        case .pushed:  return .pushed
        case .sliced:  return .sliced
        case .hooked:  return .hooked
        case .none: break
        }
        if includeDirectional {
            switch holeScore.missDirection {
            case .left:       return .left
            case .right:      return .right
            case .short:      return .short
            case .long:       return .long
            case .good, .na:  return .good
            }
        }
        // Approach/chip: contact quality drives good/bad without a directional tag
        switch holeScore.contactQuality {
        case .pure, .good: return .good
        case .okay:        return .safeMiss
        case .poor:        return .thin
        case nil:          return .good
        }
    }

    private func syncClubShots() {
        var shots = holeScore.clubShots ?? []

        func upsert(shotType: ShotType, club: ClubType?, includeDirectional: Bool) {
            let result = synthesizedResult(includeDirectional: includeDirectional)
            if let club {
                if let existing = shots.first(where: { $0.shotType == shotType }) {
                    existing.club = club
                    existing.result = result
                    existing.contactQuality = holeScore.contactQuality
                    existing.confidence = holeScore.confidence
                } else {
                    let shot = ClubShot(club: club, shotType: shotType, result: result)
                    shot.contactQuality = holeScore.contactQuality
                    shot.confidence = holeScore.confidence
                    shot.holeScore = holeScore
                    context.insert(shot)
                    shots.append(shot)
                }
            } else if let existing = shots.first(where: { $0.shotType == shotType }) {
                context.delete(existing)
                shots.removeAll { $0.id == existing.id }
            }
        }

        upsert(shotType: .teeShot, club: holeScore.teeClub,      includeDirectional: true)
        upsert(shotType: .approach, club: holeScore.approachClub, includeDirectional: false)
        upsert(shotType: .chip,     club: holeScore.shortGameClub, includeDirectional: false)

        holeScore.clubShots = shots
    }
}

private struct ConditionalCard: ViewModifier {
    let applyCard: Bool
    func body(content: Content) -> some View {
        if applyCard {
            content.cardStyle()
        } else {
            content
        }
    }
}
