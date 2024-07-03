import Foundation

/// School configuration data.
public enum RKApiSchoolConfig: Hashable, Equatable {
    /// Path to the school configuration endpoint.
    private static let path: [String] = ["LoadRes"]

    /// School configuration data.
    public struct RKSchoolReachConfig: Sendable, Codable, Hashable, Equatable {
        /// Storage base URL
        public var storageBase: URL

        enum CodingKeys: String, CodingKey {
            case storageBase = "storageBaseURL"
        }
    }

    /// School configuration data.
    public struct RKSchoolLocation: Sendable, Codable, Identifiable, Hashable, Equatable {
        /// The location's ID.
        public let id: Int
        /// The location's name.
        public let name: String
        /// The location's color.
        public let color: RKHexColor
        /// Whether the location is visible.
        public let visible: Bool

        enum CodingKeys: String, CodingKey {
            case id = "i"
            case name = "l"
            case color = "c"
            case visible = "vis"
        }

        /// Initialize a location.
        /// - Parameter decoder: The decoder.
        /// - Throws: DecodingError
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(Int.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            color = try container.decode(RKHexColor.self, forKey: .color)
            visible = try container.decode(Int.self, forKey: .visible) == 1
        }

        /// Encode a location.
        /// - Parameter encoder: The encoder.
        /// - Throws: EncodingError
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(color, forKey: .color)
            try container.encode(visible ? 1 : 0, forKey: .visible)
        }
    }

    /// School configuration data.
    public struct RKSchoolConfig: Sendable, Codable, Hashable, Equatable {
        /// Reach configuration.
        public let reach: RKSchoolReachConfig
        /// Locations.
        public let locations: [RKSchoolLocation]

        enum CodingKeys: String, CodingKey {
            case locations = "loc"
            case reach = "reach"
        }
    }

    /// JSON wrapper for school configuration data.
    private struct RKJSONSchoolConfig: Codable, Hashable, Equatable {
        /// School configuration data.
        public let config: RKSchoolConfig
    }

    /// Request data for school configuration.
    private struct RKJSONRequest: Codable, Hashable, Equatable {
        /// Authentication token.
        public let authToken: String
    }

    /// Errors for school configuration.
    public enum RKError: Sendable, Error, LocalizedError {
        /// URL request failed.
        case urlRequestError(Error)
        /// JSON decoding failed.
        case jsonDecodingFailed(Error)
    }

    /// Load school configuration data.
    /// - Parameter auth: RKApiAuth
    /// - Returns: Result with RKSchoolConfig or RKError
    public static func getSchoolConfig(auth: RKApiAuth) async -> Result<RKSchoolConfig, RKError> {
        // Create URL
        let url = auth.appending(path: path)

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(RKJSONRequest(authToken: auth.token))

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
            let jsonConfig = try decoder.decode(RKJSONSchoolConfig.self, from: result)
            return .success(jsonConfig.config)
        } catch {
            return .failure(.jsonDecodingFailed(error))
        }
    }

}
