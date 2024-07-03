import Foundation

/// Authentication Login SAML.
public enum RKApiAuthLoginSAML {
    /// Request path.
    private static let path: [String] = ["samlACS"]

    /// Errors for when login fails.
    public enum RKError: Sendable, Error, LocalizedError {
        /// URL construction failed.
        case urlConstructionFailed
        /// Matrix decoding error.
        case matrixDecodingError(RKApiAuthExtract.RKError)
        /// URL request error.
        case urlRequestError(Error)
        /// Parsing error.
        case decodingError
    }

    /// Login with SAML.
    /// - Parameters:
    ///  - reach: Reach domain
    ///  - token: Token
    public static func preformLogin(reach: String, token: String) async -> Result<
        Result<RKApiAuth, RKApiAuthExtract.RKReachError>, RKError
    > {
        // Get URL
        let testUrl = URL(string: "https://\(reach)")
        guard let ogUrl = testUrl else {
            return .failure(.urlConstructionFailed)
        }
        var url = ogUrl

        for component in path {
            url.appendPathComponent(component)
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = RKFormData(withDictionary: ["SAMLResponse": token]).asData()

        // Make request
        let result: Data
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            result = data
        } catch {
            return .failure(.urlRequestError(error))
        }

        // Parse response
        guard let response = String(data: result, encoding: .utf8) else {
            return .failure(.decodingError)
        }

        // Extract token and matrix
        let tokenMatrixData = RKApiAuthExtract.extractTokenAndMatrix(fromHTML: response)

        // Check for errors
        switch tokenMatrixData {
        case .success(.success(let data)):
            let (token, matrix) = data
            return .success(
                .success(RKApiAuth(reachDomain: ogUrl, token: token, contactID: matrix.contactID)))
        case .success(.failure(let error)):
            return .success(.failure(error))
        case .failure(let error):
            return .failure(.matrixDecodingError(error))
        }
    }
}
