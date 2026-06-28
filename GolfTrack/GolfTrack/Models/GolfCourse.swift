import Foundation
import SwiftData

@Model
final class GolfCourse: Hashable {
    var id: UUID = UUID()
    var name: String = ""
    var location: String = ""
    var courseTypeRaw: String = CourseType.standard.rawValue
    var numberOfHoles: Int = 18
    var courseRating: Double?
    var slopeRating: Int?
    var teeBoxName: String?
    var latitude: Double?
    var longitude: Double?
    var isCustom: Bool = true
    var createdDate: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \GolfHole.course)
    var holes: [GolfHole]? = []

    @Relationship(deleteRule: .nullify, inverse: \GolfRound.course)
    var rounds: [GolfRound]? = []

    init(name: String, location: String = "", courseType: CourseType = .standard, numberOfHoles: Int = 18) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.courseTypeRaw = courseType.rawValue
        self.numberOfHoles = numberOfHoles
        self.createdDate = Date()
    }

    var courseType: CourseType {
        get { CourseType(rawValue: courseTypeRaw) ?? .standard }
        set { courseTypeRaw = newValue.rawValue }
    }

    var sortedHoles: [GolfHole] {
        (holes ?? []).sorted { $0.holeNumber < $1.holeNumber }
    }

    var totalPar: Int {
        sortedHoles.reduce(0) { $0 + $1.par }
    }

    static func == (lhs: GolfCourse, rhs: GolfCourse) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

@Model
final class GolfHole {
    var id: UUID = UUID()
    var holeNumber: Int = 1
    var par: Int = 4
    var yardage: Int?
    var course: GolfCourse?

    init(holeNumber: Int, par: Int, yardage: Int? = nil) {
        self.id = UUID()
        self.holeNumber = holeNumber
        self.par = par
        self.yardage = yardage
    }
}
