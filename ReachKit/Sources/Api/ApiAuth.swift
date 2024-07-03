import Foundation

/// Authentication Data
/// This struct stores the authentication data used in all API endpoints.
public struct RKApiAuth: Sendable, Codable, Hashable, Equatable {
    /// Reach domain
    public var reachDomain: URL
    /// Token
    public var token: String
    /// Contact ID
    public var contactID: Int

    /// Append path to the reach domain.
    /// - Parameter path: Path
    /// - Returns: URL
    func appending(path: [String]) -> URL {
        var new = self.reachDomain
        for component in path {
            new.appendPathComponent(component)
        }
        return new
    }
}
