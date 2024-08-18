import Foundation

/// Authentication Extraction Data.
///
/// Encode and decode reach matrix data.
public enum RKApiAuthExtract: Hashable, Equatable {

    /// Matrix data (from JSON).
    public struct RKMatrixData: Sendable, Codable, Hashable, Equatable {
        // Contact ID (cid)
        public var contactID: Int
        // User Defined Field ID (uid)
        public var userDefinedFieldID: Int
        /// First name
        public var firstName: String
        /// Last name
        public var lastName: String
        // Role ID (RKSchoolConfig.Role)
        public var roleID: Int

        // Coding keys
        enum CodingKeys: String, CodingKey {
            case contactID = "cid"
            case userDefinedFieldID = "uid"
            case firstName = "f"
            case lastName = "l"
            case roleID = "r"
        }
    }

    /// Errors for authentication extraction.
    public enum RKError: Sendable, Error, LocalizedError {
        /// Regex initialization failed
        case regexInitializationFailed
        /// Token not found error
        case tokenNotFound
        /// Matrix not found error
        case matrixNotFound
        /// Matrix decoding error
        case matrixDecodingErrorStringDataConversion
        /// Matrix decoding error
        case matrixDecodingErrorString(Error)
        /// Matrix decoding error
        case matrixDecodingErrorDataDataConversion
        /// Matrix decoding error
        case matrixDecodingErrorData(Error)

        public var errorDescription: String? {
            switch self {
            case .regexInitializationFailed:
                return String(localized: "api.authExtract.regexInitializationFailed")
            case .tokenNotFound:
                return String(localized: "api.authExtract.tokenNotFound")
            case .matrixNotFound:
                return String(localized: "api.authExtract.matrixNotFound")
            case .matrixDecodingErrorStringDataConversion:
                return String(localized: "api.authExtract.matrixDecodingErrorStringDataConversion")
            case .matrixDecodingErrorString(let error):
                return String(
                    format: String(localized: "api.authExtract.matrixDecodingErrorString"),
                    error.localizedDescription)
            case .matrixDecodingErrorDataDataConversion:
                return String(localized: "api.authExtract.matrixDecodingErrorDataDataConversion")
            case .matrixDecodingErrorData(let error):
                return String(
                    format: String(localized: "api.authExtract.matrixDecodingErrorData"),
                    error.localizedDescription)
            }
        }
    }

    /// Errors for when login fails.
    public enum RKReachError: Sendable, Error, LocalizedError {
        /// User not found
        case userNotFound
        /// Unknown error
        case unknown
    }

    /// Extract token and matrix data from HTML.
    /// - Parameter html: HTML
    /// - Returns: Token and matrix data
    public static func extractTokenAndMatrix(fromHTML html: String) -> Result<
        Result<(token: String, matrix: RKMatrixData), RKReachError>, RKError
    > {
        let tokenRegex = try? Regex(#"var tokenID = ('|")(.*)(?:\1);"#)
        let matrixRegex = try? Regex(#"var matrix = (('|").*(?:\2));"#)
        // Safe get regex
        guard let tokenRegex = tokenRegex, let matrixRegex = matrixRegex else {
            return .failure(.regexInitializationFailed)
        }

        // Match
        guard let tokenMatch = try? tokenRegex.firstMatch(in: html)?[2] else {
            return .failure(.tokenNotFound)
        }
        guard let matrixMatch = try? matrixRegex.firstMatch(in: html)?[1] else {
            return .failure(.matrixNotFound)
        }

        // Substrings
        guard let tokenSub = tokenMatch.substring else {
            return .failure(.tokenNotFound)
        }
        guard let matrixSub = matrixMatch.substring else {
            return .failure(.matrixNotFound)
        }

        // Get as string
        let token = String(tokenSub)
        let matrix = String(matrixSub)

        // Check token not -1 or -2
        if token == "-1" {
            return .success(.failure(.userNotFound))
        } else if token == "-2" {
            return .success(.failure(.unknown))
        }

        // Decode matrix into String
        guard let matrixData = matrix.data(using: .utf8) else {
            return .failure(.matrixDecodingErrorStringDataConversion)
        }
        let matrixString: String
        do {
            matrixString = try JSONDecoder().decode(String.self, from: matrixData)
        } catch {
            return .failure(.matrixDecodingErrorString(error))
        }

        // Decode matrix into RKMatrixData
        guard let matrixDataString = matrixString.data(using: .utf8) else {
            return .failure(.matrixDecodingErrorDataDataConversion)
        }
        let matrixDecoded: RKMatrixData
        do {
            matrixDecoded = try JSONDecoder().decode(RKMatrixData.self, from: matrixDataString)
        } catch {
            return .failure(.matrixDecodingErrorData(error))
        }

        return .success(.success((token: token, matrix: matrixDecoded)))
    }
}
