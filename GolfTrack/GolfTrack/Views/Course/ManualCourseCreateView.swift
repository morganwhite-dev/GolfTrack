import SwiftUI
import SwiftData

struct ManualCourseCreateView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var existingCourse: GolfCourse?
    var onSave: (GolfCourse) -> Void

    @State private var name = ""
    @State private var location = ""
    @State private var courseType: CourseType = .standard
    @State private var holeCount = 18
    @State private var pars: [Int] = []
    @State private var yardageTexts: [String] = []
    @State private var ratingText = ""
    @State private var slopeText = ""
    @State private var teeBoxName = ""
    @State private var didCustomizePars = false

    private var totalPar: Int { pars.reduce(0, +) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Course Info", icon: "mappin.and.ellipse")
                        InputField(placeholder: "Course name", text: $name)
                        InputField(placeholder: "City / State (optional)", text: $location)
                    }
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Course Type", icon: "flag.fill")
                        HStack(spacing: 10) {
                            ForEach(CourseType.allCases) { type in
                                ChoiceChip(label: type.displayName, isSelected: courseType == type) {
                                    courseType = type
                                    if !didCustomizePars { applyDefaultPars() }
                                }
                            }
                        }

                        Divider()

                        Text("Number of Holes").font(.subheadline.weight(.semibold))
                        HStack(spacing: 10) {
                            ChoiceChip(label: "9 holes", isSelected: holeCount == 9) { setHoleCount(9) }
                            ChoiceChip(label: "18 holes", isSelected: holeCount == 18) { setHoleCount(18) }
                        }
                    }
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            SectionHeader(title: "Hole Pars", subtitle: "Total par: \(totalPar)", icon: "number.circle.fill")
                            Spacer()
                            Button("Reset Defaults") {
                                didCustomizePars = false
                                applyDefaultPars()
                            }
                            .font(.caption)
                        }
                        VStack(spacing: 10) {
                            ForEach(0..<holeCount, id: \.self) { index in
                                HoleParRow(
                                    holeNumber: index + 1,
                                    par: Binding(
                                        get: { pars.indices.contains(index) ? pars[index] : 4 },
                                        set: { newValue in
                                            didCustomizePars = true
                                            if pars.indices.contains(index) { pars[index] = newValue }
                                        }
                                    ),
                                    yardageText: Binding(
                                        get: { yardageTexts.indices.contains(index) ? yardageTexts[index] : "" },
                                        set: { newValue in
                                            if yardageTexts.indices.contains(index) { yardageTexts[index] = newValue }
                                        }
                                    )
                                )
                            }
                        }
                    }
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Optional Details", icon: "ellipsis.circle")
                        InputField(placeholder: "Tee box name (e.g. White, Blue)", text: $teeBoxName)
                        InputField(placeholder: "Course rating (e.g. 71.2)", text: $ratingText, keyboardType: .decimalPad)
                        InputField(placeholder: "Slope rating (e.g. 128)", text: $slopeText, keyboardType: .numberPad)
                    }
                    .cardStyle()

                    Button(existingCourse == nil ? "Save Course" : "Save Changes") { save() }
                        .buttonStyle(.primaryGolf)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(existingCourse == nil ? "New Course" : "Edit Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear { loadExistingIfNeeded() }
    }

    private func setHoleCount(_ count: Int) {
        let oldCount = holeCount
        holeCount = count
        if count > oldCount {
            pars.append(contentsOf: Array(repeating: 4, count: count - oldCount))
            yardageTexts.append(contentsOf: Array(repeating: "", count: count - oldCount))
            if !didCustomizePars { applyDefaultPars() }
        } else {
            pars = Array(pars.prefix(count))
            yardageTexts = Array(yardageTexts.prefix(count))
        }
    }

    private func applyDefaultPars() {
        pars = Self.defaultPars(courseType: courseType, holeCount: holeCount)
    }

    private func loadExistingIfNeeded() {
        guard let course = existingCourse, pars.isEmpty else {
            if pars.isEmpty { applyDefaultPars(); yardageTexts = Array(repeating: "", count: holeCount) }
            return
        }
        name = course.name
        location = course.location
        courseType = course.courseType
        holeCount = course.numberOfHoles
        teeBoxName = course.teeBoxName ?? ""
        ratingText = course.courseRating.map { String($0) } ?? ""
        slopeText = course.slopeRating.map { String($0) } ?? ""
        let sorted = course.sortedHoles
        pars = sorted.map(\.par)
        yardageTexts = sorted.map { $0.yardage.map { String($0) } ?? "" }
        didCustomizePars = true
    }

    private func save() {
        let course = existingCourse ?? GolfCourse(name: "", courseType: .standard, numberOfHoles: holeCount)
        course.name = name.trimmingCharacters(in: .whitespaces)
        course.location = location.trimmingCharacters(in: .whitespaces)
        course.courseType = courseType
        course.numberOfHoles = holeCount
        course.teeBoxName = teeBoxName.isEmpty ? nil : teeBoxName
        course.courseRating = Double(ratingText)
        course.slopeRating = Int(slopeText)
        course.isCustom = true

        for hole in course.holes ?? [] { context.delete(hole) }
        var newHoles: [GolfHole] = []
        for index in 0..<holeCount {
            let par = pars.indices.contains(index) ? pars[index] : 4
            let yardage = yardageTexts.indices.contains(index) ? Int(yardageTexts[index]) : nil
            let hole = GolfHole(holeNumber: index + 1, par: par, yardage: yardage)
            hole.course = course
            newHoles.append(hole)
            context.insert(hole)
        }
        course.holes = newHoles

        if existingCourse == nil {
            context.insert(course)
        }
        try? context.save()
        onSave(course)
        dismiss()
    }

    static func defaultPars(courseType: CourseType, holeCount: Int) -> [Int] {
        let nine: [Int]
        switch courseType {
        case .par3:
            nine = Array(repeating: 3, count: 9)
        case .executive:
            nine = [3, 3, 4, 3, 3, 4, 3, 3, 4]
        case .standard, .other:
            nine = [4, 4, 3, 5, 4, 4, 3, 5, 4]
        }
        return holeCount == 9 ? nine : nine + nine
    }
}

private struct HoleParRow: View {
    let holeNumber: Int
    @Binding var par: Int
    @Binding var yardageText: String

    var body: some View {
        HStack(spacing: 12) {
            Text("Hole \(holeNumber)")
                .font(.subheadline.weight(.medium))
                .frame(width: 64, alignment: .leading)

            Stepper(value: $par, in: 3...6) {
                Text("Par \(par)")
            }

            TextField("yds", text: $yardageText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 56)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}
