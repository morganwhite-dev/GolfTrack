import Foundation

/// Set GooglePlacesConfig.apiKey to enable nearby course search. Leave it nil/empty and the
/// app still works fully using saved courses and manual creation — nearby search just won't
/// return results, and nothing else crashes or blocks round creation because of it.
enum GooglePlacesConfig {
    static var apiKey: String? = nil
}

struct NearbyCourseResult: Identifiable, Hashable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double

    func makeCourse() -> GolfCourse {
        let course = GolfCourse(name: name, location: address, courseType: .standard, numberOfHoles: 18)
        course.isCustom = false
        course.latitude = latitude
        course.longitude = longitude
        return course
    }
}

enum CourseSearchError: Error, LocalizedError {
    case missingAPIKey
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Nearby search needs a Google Places API key. You can still search saved courses or add one manually."
        case .requestFailed:
            return "Couldn't reach course search right now. You can still search saved courses or add one manually."
        }
    }
}

enum CourseSearchService {
    static func filterSavedCourses(_ courses: [GolfCourse], matching query: String) -> [GolfCourse] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return courses }
        return courses.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed) || $0.location.localizedCaseInsensitiveContains(trimmed)
        }
    }

    static func searchNearby(latitude: Double, longitude: Double, radiusMeters: Int = 25000) async -> Result<[NearbyCourseResult], CourseSearchError> {
        guard let apiKey = GooglePlacesConfig.apiKey, !apiKey.isEmpty else {
            return .failure(.missingAPIKey)
        }

        var components = URLComponents(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json")!
        components.queryItems = [
            URLQueryItem(name: "location", value: "\(latitude),\(longitude)"),
            URLQueryItem(name: "radius", value: "\(radiusMeters)"),
            URLQueryItem(name: "type", value: "golf_course"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        guard let url = components.url else { return .failure(.requestFailed) }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(PlacesResponse.self, from: data)
            let results = decoded.results.map {
                NearbyCourseResult(
                    id: $0.place_id,
                    name: $0.name,
                    address: $0.vicinity ?? "",
                    latitude: $0.geometry.location.lat,
                    longitude: $0.geometry.location.lng
                )
            }
            return .success(results)
        } catch {
            return .failure(.requestFailed)
        }
    }
}

private struct PlacesResponse: Decodable {
    let results: [PlaceResult]
}
private struct PlaceResult: Decodable {
    let place_id: String
    let name: String
    let vicinity: String?
    let geometry: PlaceGeometry
}
private struct PlaceGeometry: Decodable {
    let location: PlaceLatLng
}
private struct PlaceLatLng: Decodable {
    let lat: Double
    let lng: Double
}
