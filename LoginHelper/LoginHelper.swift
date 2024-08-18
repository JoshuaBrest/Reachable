//
//  main.swift
//  LoginHelper
//

import AppKit

@main
struct LoginHelperApp {
    /// The main app bundle identifier
    static let mainAppIdentifier: String? =
        Bundle.main.object(forInfoDictionaryKey: "AppMainIdentifier") as? String

    /// Entry point for the helper app
    public static func main() {
        logData("Helper app started")
        if !attemptToLaunchMainApp() {
            exit(0)
        }

        // Block the main thread
        RunLoop.main.run()
    }

    private static func logData(_ logMessage: String) {
        print("LoginHelperApp: \(logMessage)")
    }

    private static func attemptToLaunchMainApp() -> Bool {
        guard let mainBundleID = mainAppIdentifier else {
            logData("Main app bundle identifier not found")
            return false
        }

        logData("Main app bundle identifier: \(mainBundleID)")

        // Check if the main app is running
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = runningApps.contains { $0.bundleIdentifier == mainBundleID }
        if isRunning {
            logData("Main app is already running")
            return false
        }

        // Find the main app path
        guard
            let mainAppPath = NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: mainBundleID)
        else {
            logData("Main app path not found")
            return false
        }

        logData("Main app path: \(mainAppPath)")

        // Launch the main app
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(
            at: mainAppPath,
            configuration: configuration
        ) { app, error in
            if let error = error {
                logData("Error launching main app: \(error)")
            } else {
                logData("Done launching...")
            }
            exit(0)
        }

        return true
    }
}
