import Foundation

/// Utility to create a x-www-form-urlencoded body.
struct RKFormData {
    /// Form data
    private var data: [String: String] = [:]

    /// Set a key-value pair to the form data.
    /// - Parameters:
    ///   - key: Key
    ///   - value: Value
    public mutating func set(key: String, value: String) {
        data[key] = value
    }

    /// Remove a key from the form data.
    /// - Parameter key: Key
    public mutating func remove(key: String) {
        data.removeValue(forKey: key)
    }

    /// Get the form data as a string.
    /// - Returns: Form data string
    public func asString() -> String {
        return data.map { key, value in
            return
                "\(RKFormData.encodeString(string: key))=\(RKFormData.encodeString(string: value))"
        }.joined(separator: "&")
    }

    /// Get the form data as a data object.
    /// - Returns: Form data as data
    public func asData(withEncoding encoding: String.Encoding = .utf8) -> Data? {
        return asString().data(using: encoding)
    }

    /// Get the form data as a dictionary.
    /// - Returns: Form data as dictionary
    public func asDictionary() -> [String: String] {
        return data
    }

    /// Initialize a form data object with a dictionary.
    /// - Parameter data: [String: String]
    public init(withDictionary data: [String: String]) {
        self.data = data
    }

    /// Initialize a form data object with a string.
    /// - Parameter string: String
    public init(withString string: String) {
        let pairs = string.split(separator: "&")
        for pair in pairs {
            let keyValue = pair.split(separator: "=")
            if keyValue.count == 2 {
                let key = RKFormData.decodeString(string: String(keyValue[0]))
                let value = RKFormData.decodeString(string: String(keyValue[1]))
                guard let key = key, let value = value else {
                    continue
                }
                data[key] = value
            }
        }
    }

    /// Encode a string as URL query allowed.
    /// - Parameter string: String to encode
    /// - Returns: Encoded string
    public static func encodeString(string: String) -> String {
        return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
            .replacingOccurrences(of: "+", with: "%2B") ?? ""
    }

    /// Decode a string from URL query allowed.
    /// - Parameter string: String to decode
    /// - Returns: Decoded string or nil
    public static func decodeString(string: String) -> String? {
        return string.removingPercentEncoding
    }
}
