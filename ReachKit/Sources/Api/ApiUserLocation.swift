import Foundation

/// User location data.
public enum RKApiUserLocation: Hashable, Equatable {
    /// Path to the user location endpoint.
    private static let path: [String] = ["SetBoarderLocation"]

    /// JSON response data.
    private struct RKJSONResponse: Codable {
        /// Whether the location was set.
        let done: Bool

        enum CodingKeys: String, CodingKey {
            case done = "done"
        }

        /// Convert the integer to a boolean.
        /// - Parameter decoder: The decoder.
        /// - Throws: DecodingError
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            done = try container.decode(Int.self, forKey: .done) == 1
        }
    }

    /// Request data.
    private struct RKJSONRequest: Codable {
        /// Auth token.
        let authToken: String
        /// Contact ID.
        let contactID: Int
        /// Location ID.
        let locationID: Int
        /// Request ID.
        let requestID: Int?

        // Unknown fields.
        let c: Double
        let sd: String
        let sdcid: Int

        enum CodingKeys: String, CodingKey {
            case authToken = "authToken"
            case contactID = "cid"
            case locationID = "locID"
            case requestID = "reqID"
            case c = "c"
            case sd = "sd"
            case sdcid = "sdcid"
        }

        /// Initialize the request.
        /// - Parameters:
        ///  - authToken: The authentication token.
        ///  - contactID: The contact ID.
        ///  - locationID: The location ID.
        ///  - requestID: The request ID.
        /// - Returns: The request.
        public init(authToken: String, contactID: Int, locationID: Int, requestID: Int?) {
            self.authToken = authToken
            self.contactID = contactID
            self.locationID = locationID
            self.requestID = requestID
            self.c = -1
            self.sd = ""
            self.sdcid = 0
        }

    }

    /// Error data.
    public enum RKError: Error, LocalizedError {
        /// URL request failed.
        case urlRequestFailed(Error)
        /// JSON decoding failed.
        case jsonDecodingFailed(Error)

        public var errorDescription: String? {
            switch self {
            case .urlRequestFailed(let error):
                return String(
                    format: String(localized: "api.userLocation.urlRequestFailed"),
                    error.localizedDescription)
            case .jsonDecodingFailed(let error):
                return String(
                    format: String(localized: "api.userLocation.jsonDecodingFailed"),
                    error.localizedDescription)
            }
        }
    }

    /// Set the user's location.
    /// - Parameters:
    ///  - auth: RKApiAuth
    ///  - contactID: The contact ID.
    ///  - locationID: The location ID.
    ///  - requestID: The request ID.
    /// - Returns: Result with Bool or RKError
    public static func setUserLocation(
        auth: RKApiAuth, contactID: Int, locationID: Int, requestID: Int?
    ) async -> Result<Bool, RKError> {
        let url = auth.appending(path: path)

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let requestData = RKJSONRequest(
            authToken: auth.token, contactID: contactID, locationID: locationID,
            requestID: requestID)
        request.httpBody = try? JSONEncoder().encode(requestData)

        // Send request
        let result: Data
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            result = data
        } catch {
            return .failure(.urlRequestFailed(error))
        }

        // Parse response
        let decoder = JSONDecoder()
        do {
            let response = try decoder.decode(RKJSONResponse.self, from: result)
            return .success(response.done)
        } catch {
            return .failure(.jsonDecodingFailed(error))
        }
    }

}
