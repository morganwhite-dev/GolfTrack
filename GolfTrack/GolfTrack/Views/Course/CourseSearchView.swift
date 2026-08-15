import SwiftUI
import SwiftData
import Combine

struct CourseSearchView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \GolfCourse.name) private var savedCourses: [GolfCourse]
    @StateObject private var locationService = LocationService()

    var onSelect: (GolfCourse) -> Void

    @State private var searchText = ""
    @State private var showManualCreate = false
    @State private var isSearchingNearby = false
    @State private var nearbyResults: [NearbyCourseResult] = []
    @State private var nearbyMessage: String?
    @State private var coursePendingDelete: GolfCourse?

    private var filteredSaved: [GolfCourse] {
        CourseSearchService.filterSavedCourses(savedCourses, matching: searchText)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    InputField(placeholder: "Search saved courses", text: $searchText)

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Saved Courses", icon: "bookmark.fill")
                        if filteredSaved.isEmpty {
                            Text("No saved courses yet.")
                                .font(.subheadline).foregroundStyle(.textSecondary)
                        } else {
                            VStack(spacing: 4) {
                                ForEach(filteredSaved) { course in
                                    HStack(spacing: 10) {
                                        Button { select(course) } label: {
                                            CourseRow(course: course)
                                        }
                                        .buttonStyle(.bouncy)

                                        Button {
                                            hapticTap(.medium)
                                            coursePendingDelete = course
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.alertCoral)
                                                .frame(width: 34, height: 34)
                                                .background(Color.alertCoral.opacity(0.1), in: Circle())
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("Delete \(course.name)")
                                    }
                                }
                            }
                        }
                    }
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Nearby Courses", icon: "location.fill")
                        nearbyContent
                    }
                    .cardStyle()

                    Button("Create a Course Manually") { showManualCreate = true }
                        .buttonStyle(.primaryGolf)
                }
                .padding()
            }
            .appBackground()
            .navigationTitle("Select Course")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    ToolbarPillButton(title: "Cancel") {
                        hapticTap()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showManualCreate) {
                ManualCourseCreateView(existingCourse: nil) { course in
                    select(course)
                }
            }
            .onReceive(locationService.$currentLocation.compactMap { $0 }) { location in
                guard isSearchingNearby else { return }
                performNearbySearch(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            }
            .onReceive(locationService.$lastError.compactMap { $0 }) { error in
                guard isSearchingNearby else { return }
                nearbyMessage = error
                isSearchingNearby = false
            }
            .alert("Delete This Course?", isPresented: Binding(
                get: { coursePendingDelete != nil },
                set: { if !$0 { coursePendingDelete = nil } }
            )) {
                Button("Delete Course", role: .destructive) {
                    if let coursePendingDelete {
                        delete(coursePendingDelete)
                    }
                    coursePendingDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    coursePendingDelete = nil
                }
            } message: {
                Text("Rounds already played will stay in your history, but this course will be removed from saved courses.")
            }
        }
        .tint(.emerald)
        .buttonStyle(.bouncy)
    }

    @ViewBuilder
    private var nearbyContent: some View {
        if isSearchingNearby {
            HStack { Spacer(); ProgressView(); Spacer() }
        } else if !nearbyResults.isEmpty {
            VStack(spacing: 4) {
                ForEach(nearbyResults) { result in
                    Button { addNearby(result) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.name).font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
                                Text(result.address).font(.caption).foregroundStyle(.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill").foregroundStyle(.emerald)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.bouncy)
                }
            }
        } else {
            if let nearbyMessage {
                Text(nearbyMessage).font(.caption).foregroundStyle(.textSecondary)
            }
            Button("Find Nearby Courses") { searchNearby() }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.emerald)
        }
    }

    private func select(_ course: GolfCourse) {
        onSelect(course)
        dismiss()
    }

    private func delete(_ course: GolfCourse) {
        context.delete(course)
        try? context.save()
    }

    private func addNearby(_ result: NearbyCourseResult) {
        let course = result.makeCourse()
        context.insert(course)
        try? context.save()
        select(course)
    }

    private func searchNearby() {
        guard let key = GooglePlacesConfig.apiKey, !key.isEmpty else {
            nearbyMessage = CourseSearchError.missingAPIKey.localizedDescription
            return
        }
        nearbyMessage = nil
        isSearchingNearby = true
        locationService.requestLocation()
    }

    private func performNearbySearch(latitude: Double, longitude: Double) {
        isSearchingNearby = false
        Task {
            let result = await CourseSearchService.searchNearby(latitude: latitude, longitude: longitude)
            switch result {
            case .success(let results):
                nearbyResults = results
                if results.isEmpty { nearbyMessage = "No golf courses found nearby." }
            case .failure(let error):
                nearbyMessage = error.localizedDescription
            }
        }
    }
}

struct CourseRow: View {
    let course: GolfCourse
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(course.name).font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
                Text(subtitle).font(.caption).foregroundStyle(.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.textTertiary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private var subtitle: String {
        var parts = ["\(course.courseType.displayName)", "\(course.numberOfHoles) holes"]
        if !course.location.isEmpty { parts.append(course.location) }
        return parts.joined(separator: " • ")
    }
}
