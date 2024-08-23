import Foundation

/// User contacts API.
public enum RKApiUserContacts {
    /// Request path.
    private static let path: [String] = ["GAC"]

    /// JSON response.
    private struct RKReachInternallJSON: Sendable, Codable {
        /// Contact ID
        let contactID: Int
        /// User defined field id
        let userDefinedFieldID: Int
        /// User defined field value
        let locationID: Int
        /// First name
        let firstName: String
        /// Last name
        let lastName: String
        /// Preferred name
        let preferredName: String
        /// Home phone
        let homePhone: String
        /// Work phone
        let workPhone: String
        /// Mobile phone
        let mobilePhone: String
        /// Email
        let email: String
        /// Profile picture ID
        let profilePictureID: String
        /// Address line 1
        let addressLine1: String
        /// Address line 2
        let addressLine2: String
        /// City
        let city: String
        /// State
        let state: String
        /// Postal code
        let postalCode: String
        /// Country
        let country: String

        /// Coding keys
        enum CodingKeys: String, CodingKey {
            case contactID = "cid"
            case userDefinedFieldID = "uid"
            case locationID = "lid"
            case firstName = "f"
            case lastName = "l"
            case preferredName = "pn"
            case homePhone = "hp"
            case workPhone = "wp"
            case mobilePhone = "m"
            case email = "e"
            case profilePictureID = "ph"
            case addressLine1 = "a1"
            case addressLine2 = "a2"
            case city = "su"
            case state = "st"
            case postalCode = "pc"
            case country = "cou"
        }

        /// Check if a string key is empty.
        private static func isEmpty(_ key: String) -> Bool {
            key == "" || key == "N/A"
        }

        /// Convert to user contact.
        public func toUserContact() -> RKUserContact {
            // Address
            let address: RKAddress? =
                if Self.isEmpty(addressLine1) || Self.isEmpty(city) || Self.isEmpty(state)
                    || Self.isEmpty(postalCode) || Self.isEmpty(country)
                {
                    nil
                } else {
                    RKAddress(
                        addressLine1: addressLine1,
                        addressLine2: Self.isEmpty(addressLine2) ? "" : addressLine2,
                        city: city,
                        state: state,
                        postalCode: postalCode,
                        country: country
                    )
                }

            return RKUserContact(
                contactID: contactID,
                userDefinedFieldID: userDefinedFieldID,
                locationID: locationID,
                firstName: firstName,
                lastName: lastName,
                preferredName: Self.isEmpty(preferredName) ? nil : preferredName,
                homePhone: Self.isEmpty(homePhone) ? nil : homePhone,
                workPhone: Self.isEmpty(workPhone) ? nil : workPhone,
                mobilePhone: Self.isEmpty(mobilePhone) ? nil : mobilePhone,
                email: Self.isEmpty(email) ? nil : email,
                profilePictureID: Self.isEmpty(profilePictureID) ? nil : profilePictureID,
                address: address
            )
        }
    }

    /// Address data.
    public struct RKAddress: Sendable, Codable, Hashable, Equatable {
        /// Address line 1
        public var addressLine1: String
        /// Address line 2
        public var addressLine2: String
        /// City
        public var city: String
        /// State
        public var state: String
        /// Postal code
        public var postalCode: String
        /// Country
        public var country: String
    }

    /// User contact data.
    public struct RKUserContact: Sendable, Codable, Hashable, Equatable {
        /// Contact ID
        public var contactID: Int
        /// User defined field ID
        public var userDefinedFieldID: Int
        /// Location ID
        public var locationID: Int
        /// First name
        public var firstName: String
        /// Last name
        public var lastName: String
        /// Preferred name
        public var preferredName: String?
        /// Home phone
        public var homePhone: String?
        /// Work phone
        public var workPhone: String?
        /// Mobile phone
        public var mobilePhone: String?
        /// Email
        public var email: String?
        /// Profile picture ID
        public var profilePictureID: String?
        /// Address
        public var address: RKAddress?
    }

    /// JSON response.
    private struct RKJSONResponse: Sendable, Codable {
        /// User contacts.
        let contacts: [RKReachInternallJSON]

        /// Coding keys
        enum CodingKeys: String, CodingKey {
            case contacts = "c"
        }
    }

    /// JSON request.
    private struct RKJSONRequest: Sendable, Codable {
        /// Authentication token.
        let authToken: String
    }

    /// Errors for user contacts.
    public enum RKError: Sendable, Error, LocalizedError {
        /// URL request failed.
        case urlRequestFailed(Error)
        /// JSON decoding failed.
        case jsonDecodingFailed(Error)

        public var errorDescription: String? {
            switch self {
            case .urlRequestFailed(let error):
                return String(
                    format: String(localized: "api.userContacts.urlRequestFailed"),
                    error.localizedDescription)
            case .jsonDecodingFailed(let error):
                return String(
                    format: String(localized: "api.userContacts.jsonDecodingFailed"),
                    error.localizedDescription)
            }
        }
    }

    /// Fetch user contacts.
    /// - Parameter auth: Authentication data.
    /// - Returns: User contacts.
    public static func getUserContacts(auth: RKApiAuth) async -> Result<[RKUserContact], RKError> {
        // Create URL
        let url = auth.appending(path: path)

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let requestData = RKJSONRequest(authToken: auth.token)
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
            return .success(response.contacts.map { $0.toUserContact() })
        } catch {
            return .failure(.jsonDecodingFailed(error))
        }
    }
}
