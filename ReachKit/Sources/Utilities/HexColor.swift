import Foundation

/// A hex color.
public struct RKHexColor: Sendable, Codable, Hashable, Equatable {
    /// Red component.
    public let red: Int
    /// Green component.
    public let green: Int
    /// Blue component.
    public let blue: Int

    /// Initialize with a hex string.
    /// - Parameter decoder: Decoder
    /// - Throws: DecodingError
    public init(from decoder: Decoder) throws {
        // Decode as string
        let container = try decoder.singleValueContainer()
        let hexString = try container.decode(String.self)

        // "#" must be first character
        guard hexString.hasPrefix("#") else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid hex string")
        }

        // Remove "#"
        let start = hexString.index(hexString.startIndex, offsetBy: 1)

        // Convert to int
        let scanner = Scanner(string: String(hexString[start...]))
        var hexNumber: UInt64 = 0
        guard scanner.scanHexInt64(&hexNumber) else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid hex string")
        }

        // Set values
        red = Int((hexNumber & 0xFF0000) >> 16)
        green = Int((hexNumber & 0x00FF00) >> 8)
        blue = Int(hexNumber & 0x0000FF)
    }

    /// Encode as a hex string.
    /// - Parameter encoder: Encoder
    /// - Throws: EncodingError
    public func encode(to encoder: Encoder) throws {
        // Convert to hex string
        let hexString = String(format: "#%02X%02X%02X", red, green, blue)

        // Encode as string
        var container = encoder.singleValueContainer()
        try container.encode(hexString)
    }
}
