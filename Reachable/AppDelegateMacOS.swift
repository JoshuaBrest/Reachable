//
//  AppDelegateMacOS.swift
//  Reachable
//

#if os(macOS)
    import SwiftUI
    import ReachKit

    class AppDelegateMacOS: NSObject, NSApplicationDelegate {
        func application(_ application: NSApplication, open urls: [URL]) {
            NSApp.setActivationPolicy(.accessory)
        }

        func applicationDidFinishLaunching(_ notification: Notification) {
            // Close all non-main windows
            if RKDatabase.shared.data.auth != nil {
                NSApp.deactivate()
                NSApp.setActivationPolicy(.accessory)
                if #available(macOS 14.0, *) {
                    NSApp.activate()
                } else {
                    // Fallback on earlier versions
                    NSApp.activate(ignoringOtherApps: false)
                }
                NSApp.windows.filter { $0.canBecomeMain }.forEach { $0.close() }
            } else {
                NSApp.setActivationPolicy(.regular)
            }
        }

        func applicationWillFinishLaunching(_ notification: Notification) {
            UserDefaults.standard.register(defaults: ["NSQuitAlwaysKeepsWindows": false])
            NSApp.disableRelaunchOnLogin()
            NSApp.setActivationPolicy(.accessory)
        }

        func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
            return false
        }
    }

#endif
