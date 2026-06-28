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
                                .font(.subheadline).foregroundStyle(.secondary)
                        } else {
                            VStack(spacing: 4) {
                                ForEach(filteredSaved) { course in
                                    Button { select(course) } label: {
                                        CourseRow(course: course)
                                    }
                                    .buttonStyle(.plain)
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
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Select Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
        }
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
                                Text(result.name).font(.subheadline.weight(.semibold))
                                Text(result.address).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill").foregroundStyle(.emerald)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        } else {
            if let nearbyMessage {
                Text(nearbyMessage).font(.caption).foregroundStyle(.secondary)
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
                Text(course.name).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Color(.tertiaryLabel))
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
