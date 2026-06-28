import SwiftUI
import SwiftData

struct HoleEntryView: View {
    @Bindable var holeScore: HoleScore
    @Environment(\.modelContext) private var context
    @State private var showMoreDetails = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header

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

                fieldSection(title: "Tee Shot Result") {
                    ChipScrollRow(items: ShotResult.teeShotQuickOptions, selected: holeScore.teeShotResult) { result in
                        holeScore.teeShotResult = result
                    }
                }

                fieldSection(title: "Miss Direction") {
                    ChipScrollRow(items: MissDirection.allCases, selected: holeScore.missDirection == .na ? nil : holeScore.missDirection, allowsDeselect: false) { direction in
                        holeScore.missDirection = direction ?? .na
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
                        fieldSection(title: "Shot Issue (technical cause, if different from miss direction)", padded: false) {
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
                            Text("Notes").font(.subheadline.weight(.semibold))
                            InputField(placeholder: "Optional notes", text: $holeScore.notes)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hole \(holeScore.holeNumber)").font(.title2.weight(.bold))
                Text("Par \(holeScore.par)").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            if holeScore.strokes > 0 {
                ScoreBadge(scoreToPar: holeScore.scoreToPar, size: 50)
            }
        }
    }

    @ViewBuilder
    private func fieldSection<Content: View>(title: String, padded: Bool = true, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold))
            content()
        }
        .modifier(ConditionalCard(applyCard: padded))
    }

    private func synthesizedResult() -> ShotResult {
        switch holeScore.shotIssue {
        case .thin: return .thin
        case .fat: return .fat
        case .topped: return .topped
        case .chunked: return .chunked
        case .shanked: return .shanked
        case .pulled: return .pulled
        case .pushed: return .pushed
        case .sliced: return .sliced
        case .hooked: return .hooked
        case .none: break
        }
        switch holeScore.missDirection {
        case .left: return .left
        case .right: return .right
        case .short: return .short
        case .long: return .long
        case .good, .na: return .good
        }
    }

    private func syncClubShots() {
        var shots = holeScore.clubShots ?? []

        func upsert(shotType: ShotType, club: ClubType?) {
            if let club {
                if let existing = shots.first(where: { $0.shotType == shotType }) {
                    existing.club = club
                    existing.result = synthesizedResult()
                    existing.contactQuality = holeScore.contactQuality
                    existing.confidence = holeScore.confidence
                } else {
                    let shot = ClubShot(club: club, shotType: shotType, result: synthesizedResult())
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

        upsert(shotType: .teeShot, club: holeScore.teeClub)
        upsert(shotType: .approach, club: holeScore.approachClub)
        upsert(shotType: .chip, club: holeScore.shortGameClub)

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
