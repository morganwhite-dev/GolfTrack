import SwiftUI
import SwiftData

struct CourseDetailView: View {
    @Bindable var course: GolfCourse
    var onSelect: ((GolfCourse) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(course.name).font(.title2.weight(.bold)).foregroundStyle(.textPrimary)
                    if !course.location.isEmpty {
                        Text(course.location).font(.subheadline).foregroundStyle(.textSecondary)
                    }
                    HStack(spacing: 8) {
                        Pill(text: course.courseType.displayName)
                        Pill(text: "\(course.numberOfHoles) holes", color: .charcoal)
                        Pill(text: "Par \(course.totalPar)", color: .charcoal)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle(raised: true)

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Details", icon: "info.circle.fill")
                    DetailRow(label: "Tee Box", value: course.teeBoxName ?? "Not set")
                    DetailRow(label: "Course Rating", value: course.courseRating.map { String(format: "%.1f", $0) } ?? "Not set")
                    DetailRow(label: "Slope Rating", value: course.slopeRating.map { String($0) } ?? "Not set")
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Hole Pars", icon: "number.circle.fill")
                    VStack(spacing: 6) {
                        ForEach(course.sortedHoles) { hole in
                            HStack {
                                Text("Hole \(hole.holeNumber)").font(.subheadline).foregroundStyle(.textPrimary)
                                Spacer()
                                Text("Par \(hole.par)").font(.subheadline.weight(.medium)).foregroundStyle(.textPrimary)
                                if let yardage = hole.yardage {
                                    Text("\(yardage) yds").font(.caption).foregroundStyle(.textSecondary).frame(width: 64, alignment: .trailing)
                                }
                            }
                            .padding(.vertical, 4)
                            if hole.id != course.sortedHoles.last?.id {
                                Divider()
                            }
                        }
                    }
                }
                .cardStyle()

                if let onSelect {
                    Button("Select This Course") {
                        onSelect(course)
                        dismiss()
                    }
                    .buttonStyle(.primaryGolf)
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Course Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) {
            ManualCourseCreateView(existingCourse: course) { _ in }
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.textSecondary)
            Spacer()
            Text(value).font(.subheadline.weight(.medium)).foregroundStyle(.textPrimary)
        }
    }
}
