import SwiftUI
import SwiftData

struct StartRoundTabView: View {
    @Bindable var profile: UserProfile
    @State private var showCourseSearch = false
    @State private var selectedCourse: GolfCourse?
    @State private var showRoundSetup = false

    @Query(sort: \GolfRound.date, order: .reverse) private var allRounds: [GolfRound]

    private var recentCourses: [GolfCourse] {
        var seen = Set<UUID>()
        var result: [GolfCourse] = []
        for round in allRounds {
            guard let course = round.course, !seen.contains(course.id) else { continue }
            seen.insert(course.id)
            result.append(course)
            if result.count >= 4 { break }
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                topBar

                if let course = selectedCourse {
                    selectedCourseCard(course)
                    Button("Continue to Round Setup") { showRoundSetup = true }
                        .buttonStyle(.primaryGolf)
                } else {
                    heroCard
                    if !recentCourses.isEmpty {
                        recentCoursesSection
                    }
                }
            }
            .padding()
        }
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
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

    private var topBar: some View {
        Text("Start Round")
            .font(.title3.weight(.bold))
            .foregroundStyle(.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
    }

    private var heroCard: some View {
        ZStack(alignment: .topLeading) {
            GlowBlob(color: .emerald, size: 160)
                .offset(x: -40, y: -40)

            VStack(spacing: 14) {
                GolfFlagGraphic(size: 84)
                Text("Ready to play?").font(.title2.weight(.bold)).foregroundStyle(.textPrimary)
                Text("Pick a course to start tracking this round.")
                    .font(.subheadline).foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                Button("Choose Course") { showCourseSearch = true }
                    .buttonStyle(.primaryGolf)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
        }
        .cardStyle(raised: true)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func selectedCourseCard(_ course: GolfCourse) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                IconBadge(icon: courseIcon(course.courseType), color: .emerald, size: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(course.name).font(.headline).foregroundStyle(.textPrimary)
                    if !course.location.isEmpty {
                        Text(course.location).font(.caption).foregroundStyle(.textSecondary)
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                Pill(text: course.courseType.displayName)
                Pill(text: "\(course.numberOfHoles) holes", color: .charcoal)
                Pill(text: "Par \(course.totalPar)", color: .charcoal)
            }
            NavigationLink(value: course) {
                Text("View Course Details").font(.caption.weight(.semibold)).foregroundStyle(.emerald)
            }
            .buttonStyle(.bouncy)
            Button("Choose a Different Course") { showCourseSearch = true }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.textSecondary)
        }
        .cardStyle(raised: true)
    }

    private var recentCoursesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent Courses", icon: "clock.fill")
            VStack(spacing: 8) {
                ForEach(recentCourses) { course in
                    Button { selectedCourse = course } label: {
                        HStack(spacing: 12) {
                            IconBadge(icon: courseIcon(course.courseType), color: .emerald, size: 38)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(course.name).font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
                                Text("\(course.courseType.displayName) • \(course.numberOfHoles) holes").font(.caption).foregroundStyle(.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill").foregroundStyle(.emerald)
                        }
                    }
                    .buttonStyle(.bouncy)
                }
            }
        }
        .cardStyle()
    }

    private func courseIcon(_ type: CourseType) -> String {
        switch type {
        case .standard: return "flag.fill"
        case .par3: return "3.circle.fill"
        case .executive: return "briefcase.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
}
