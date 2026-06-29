import SwiftUI

struct StartRoundTabView: View {
    @Bindable var profile: UserProfile
    @State private var showCourseSearch = false
    @State private var selectedCourse: GolfCourse?
    @State private var showRoundSetup = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let course = selectedCourse {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Selected Course", icon: "flag.fill")
                        NavigationLink(value: course) {
                            CourseRow(course: course)
                        }
                        .buttonStyle(.plain)
                        Button("Choose a Different Course") { showCourseSearch = true }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.emerald)
                    }
                    .cardStyle()

                    Button("Continue to Round Setup") { showRoundSetup = true }
                        .buttonStyle(.primaryGolf)
                } else {
                    VStack(spacing: 14) {
                        ZStack {
                            Circle().fill(Color.emerald.opacity(0.16)).frame(width: 64, height: 64)
                            Image(systemName: "flag.fill").font(.title2).foregroundStyle(.emerald)
                        }
                        Text("Pick a course to begin").font(.headline).foregroundStyle(.textPrimary)
                        Button("Choose Course") { showCourseSearch = true }
                            .buttonStyle(.primaryGolf)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .cardStyle(raised: true)
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Start Round")
        .navigationDestination(for: GolfCourse.self) { course in
            CourseDetailView(course: course)
        }
        .navigationDestination(isPresented: $showRoundSetup) {
            if let course = selectedCourse {
                RoundSetupView(course: course)
            }
        }
        .sheet(isPresented: $showCourseSearch) {
            CourseSearchView { course in
                selectedCourse = course
            }
        }
    }
}
