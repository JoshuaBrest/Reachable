import Foundation

/// Store data for the database.
@MainActor
public class RKDatabase: ObservableObject, Sendable {
    /// One only
    public static let shared = RKDatabase()

    /// Database file (shared in a group)
    private static let dbFile = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: "group.cx.bashed.Reachable")?
        .appendingPathComponent("ReachableInfo")
        .appendingPathComponent("database.json")

    /// App config.
    public struct RKAppConfig: Codable, Hashable, Equatable {
        public var favoriteLocations: [Int] = []
    }

    /// Database
    public struct RKDatabaseData: Codable, Hashable, Equatable {
        /// Authentication data
        public var auth: RKApiAuth?
        /// Cached school configuration
        public var schoolConfig: RKApiSchoolConfig.RKSchoolConfig?
        /// Cached user contact
        public var userContact: RKApiUserContacts.RKUserContact?
        /// App config
        public var appConfig: RKAppConfig = RKAppConfig()

        /// From basic db
        static func fromBasic(basic: RKBasicDB) -> Self {
            RKDatabaseData(
                auth: basic.auth,
                schoolConfig: nil,
                userContact: nil,
                appConfig: RKAppConfig()
            )
        }
    }

    /// Basic DB, so if there is corruption, the user doesn't get logged out
    struct RKBasicDB: Codable, Hashable, Equatable {
        /// Authentication data
        public var auth: RKApiAuth?
    }

    /// Database data
    @Published public var data: RKDatabaseData {
        didSet {
            saveDb(data)
        }
    }

    /// Initialize the database.
    private init() {
        data = RKDatabase.loadDb()
    }

    /// Load the database.
    /// - Returns: Database data
    private static func loadDb() -> RKDatabaseData {
        guard let dbFile = RKDatabase.dbFile else {
            return RKDatabaseData()
        }

        guard let data = try? Data(contentsOf: dbFile) else {
            return RKDatabaseData()
        }
        guard let decoded = try? JSONDecoder().decode(RKDatabaseData.self, from: data) else {
            guard let decodedSafe = try? JSONDecoder().decode(RKBasicDB.self, from: data) else {
                return RKDatabaseData()
            }
            return RKDatabaseData.fromBasic(basic: decodedSafe)
        }
        return decoded
    }

    /// Save the database.
    /// - Parameter data: Data
    private func saveDb(_ data: RKDatabaseData) {
        guard let dbFile = RKDatabase.dbFile else {
            return
        }
        if !FileManager.default.fileExists(atPath: dbFile.path) {
            try? FileManager.default.createDirectory(
                at: dbFile.deletingLastPathComponent(), withIntermediateDirectories: true,
                attributes: nil)
            FileManager.default.createFile(atPath: dbFile.path(), contents: "".data(using: .utf8))
        }
        guard let encoded = try? JSONEncoder().encode(data) else {
            return
        }
        try? encoded.write(to: dbFile)
    }
}
