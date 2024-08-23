import Foundation

/// Get school data API.
public enum RKApiAuthSchoolData {
    /// Request path.
    private static let path: [String] = ["RenderSite"]

    /// JSON response.
    private struct RKReachInternallJSON: Sendable, Codable {
        /// Reach domain
        var reachDomain: String
        /// School name
        var schoolName: String
        /// Login background
        var loginBackground: String?
        /// School emblem
        var schoolEmblem: String?

        /// Disable reach login
        var disableReachLogin: String
        /// Forgotten password link
        var reachForgottenPasswordLink: String

        /// Enable SAML
        var usingSAML: String
        /// SAML label
        var samlLabel: String?
        /// SAML IDP URL
        var samlIDPURL: String?

        /// Enable Blackbaud
        var usingBlackbaud: String
        /// Blackbaud label
        var blackbaudLabel: String?
        /// Blackbaud SSO URL
        var blackbaudSSOURL: String?

        /// Coding keys
        enum CodingKeys: String, CodingKey {
            case reachDomain = "baseURL"
            case schoolName = "schoolName"
            case loginBackground = "loginBkg"
            case schoolEmblem = "schoolEmblem"
            case disableReachLogin = "hideManualLogin"
            case reachForgottenPasswordLink = "fpLink"
            case usingSAML = "samlm"
            case samlLabel = "samlLabel"
            case samlIDPURL = "samlIDPURL"
            case usingBlackbaud = "blackbaudSSOEnabled"
            case blackbaudLabel = "bbLabel"
            case blackbaudSSOURL = "blackbaudSSOURL"
        }

        /// Convert to school data.
        func toSchoolData() throws -> RKSchoolData {
            // Reach info
            let loginBackground: URL? =
                if let loginBackground = self.loginBackground {
                    URL(string: loginBackground)
                } else { nil }
            let schoolEmblem: URL? =
                if let schoolEmblem = self.schoolEmblem {
                    URL(string: schoolEmblem)
                } else { nil }

            // Reach login data
            let reachLoginData: RKSchoolReachData? =
                if self.disableReachLogin == "0",
                    let forgotPasswordLink = URL(string: self.reachForgottenPasswordLink)
                {
                    RKSchoolReachData(forgotPasswordLink: forgotPasswordLink)
                } else { nil }

            // SAML data
            let samlData: RKSchoolSAMLData? =
                if self.usingSAML == "1", let samlIDPURL = URL(string: self.samlIDPURL ?? ""),
                    let samlLabel = self.samlLabel
                {
                    RKSchoolSAMLData(idpURL: samlIDPURL, label: samlLabel)
                } else { nil }

            // Blackbaud data
            let blackbaudData: RKSchoolBlackbaudData? =
                if self.usingBlackbaud == "1",
                    let blackbaudSSOURL = URL(string: self.blackbaudSSOURL ?? ""),
                    let blackbaudLabel = self.blackbaudLabel
                {
                    RKSchoolBlackbaudData(ssoURL: blackbaudSSOURL, label: blackbaudLabel)
                } else { nil }

            return RKSchoolData(
                reachDomain: self.reachDomain,
                schoolName: self.schoolName,
                loginBackground: loginBackground,
                schoolEmblem: schoolEmblem,
                reachLoginData: reachLoginData,
                samlData: samlData,
                blackbaudData: blackbaudData
            )
        }

    }

    /// School data reach login.
    public struct RKSchoolReachData: Sendable, Hashable, Equatable {
        /// Forgot password link
        public var forgotPasswordLink: URL
    }

    /// School data SAML.
    public struct RKSchoolSAMLData: Sendable, Hashable, Equatable {
        /// SAML IDP URL
        public var idpURL: URL
        /// SAML label
        public var label: String
    }

    /// School data Blackbaud.
    public struct RKSchoolBlackbaudData: Sendable, Hashable, Equatable {
        /// SS0 URL
        public var ssoURL: URL
        /// Blackbaud label
        public var label: String
    }

    /// School data.
    public struct RKSchoolData: Sendable, Hashable, Equatable {
        /// Reach domain
        public var reachDomain: String
        /// School name
        public var schoolName: String
        /// Login background
        public var loginBackground: URL?
        /// School emblem
        public var schoolEmblem: URL?
        /// Reach login data
        public var reachLoginData: RKSchoolReachData?
        /// SAML data
        public var samlData: RKSchoolSAMLData?
        /// Blackbaud data
        public var blackbaudData: RKSchoolBlackbaudData?
    }

    /// Errors for when login fails.
    public enum RKError: Sendable, Error, LocalizedError {
        /// URL construction failed.
        case urlConstructionFailed
        /// URL request error.
        case urlRequestError(Error)
        /// JSON decoding error.
        case jsonDecodingFailed(Error)
        /// RKSchoolData conversion error.
        case schoolDataConversionFailed(Error)

        public var errorDescription: String? {
            switch self {
            case .urlConstructionFailed:
                return String(localized: "api.authSchoolData.urlConstructionFailed")
            case .urlRequestError(let error):
                return String(
                    format: String(localized: "api.authSchoolData.urlRequestError"),
                    error.localizedDescription)
            case .jsonDecodingFailed(let error):
                return String(
                    format: String(localized: "api.authSchoolData.jsonDecodingFailed"),
                    error.localizedDescription)
            case .schoolDataConversionFailed(let error):
                return String(
                    format: String(localized: "api.authSchoolData.schoolDataConversionFailed"),
                    error.localizedDescription)
            }
        }
    }

    /// Get school details.
    /// - Parameters:
    ///  - auth: Reach domain
    /// - Returns: School details
    public static func getSchoolDetails(reach: String) async -> Result<
        RKSchoolData, RKError
    > {
        // Get URL
        let testURL = URL(string: "https://\(reach)")
        guard let ogURL = testURL else {
            return .failure(.urlConstructionFailed)
        }
        var url = ogURL

        for component in path {
            url.appendPathComponent(component)
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = RKFormData(withDictionary: ["data": "1"]).asData()

        // Make request
        let result: Data
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            result = data
        } catch {
            return .failure(.urlRequestError(error))
        }

        // Parse response
        let response: RKReachInternallJSON
        do {
            response = try JSONDecoder().decode(RKReachInternallJSON.self, from: result)
        } catch {
            return .failure(.jsonDecodingFailed(error))
        }

        // Convert to school data
        let schoolData: RKSchoolData
        do {
            schoolData = try response.toSchoolData()
        } catch {
            return .failure(.schoolDataConversionFailed(error))
        }

        return .success(schoolData)
    }
}
