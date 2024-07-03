import Foundation

/// Search Schools API.
///
/// Search schools by name.
public enum RKApiSearchSchools {
    /// Search results.
    private static let searchUrl =
        "https://us-central1-reach4-172100.cloudfunctions.net/SchoolSearch"

    /// A School.
    public struct RKSchool: Sendable, Codable, Hashable, Equatable {
        /// Exanple school.
        public static var example: RKSchool {
            RKSchool(
                id: 1,
                name: "Choate Rosemary Hall",
                reachPrefix: "choate",
                reachDomain: "choate.reachboarding.com",
                countryName: "United States of America",
                portalKey: "example"
            )
        }

        /// School ID
        public var id: Int
        /// School name
        public var name: String
        /// School reach prefix
        public var reachPrefix: String
        /// School reach domain
        public var reachDomain: String
        /// Country name (e.g. United States of America)
        public var countryName: String
        /// Portal key (Used for Websocket connection)
        public var portalKey: String

        /// Coding keys
        enum CodingKeys: String, CodingKey {
            case id = "c"
            case name = "l"
            case reachPrefix = "a"
            case reachDomain = "b"
            case countryName = "cou"
            case portalKey = "pk"
        }
    }

    /// JSON response wrapper.
    private struct RKSearchResults: Codable, Hashable, Equatable {
        /// Search results
        var results: [RKSchool]
    }

    /// Errors for school search.
    public enum RKError: Sendable, Error, LocalizedError {
        /// Failed to create URL.
        case urlCreationFailed
        /// Request failed.
        case urlRequestError(Error)
        /// Json decoding failed.
        case jsonDecodingFailed(Error)

    }

    /// Search schools by name.
    /// - Parameter name: School name
    /// - Returns: List of schools
    public static func searchSchools(byName name: String) async -> Result<[RKSchool], RKError> {
        // Create URL
        guard let url = URL(string: searchUrl) else {
            return .failure(.urlCreationFailed)
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = RKFormData(withDictionary: ["kw": name]).asData()

        // Make request
        let result: Data
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            result = data
        } catch {
            return .failure(.urlRequestError(error))
        }

        // Parse response
        let decoder = JSONDecoder()
        do {
            let results = try decoder.decode(RKSearchResults.self, from: result)
            return .success(results.results)
        } catch {
            return .failure(.jsonDecodingFailed(error))
        }
    }

}
