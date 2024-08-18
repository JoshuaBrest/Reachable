//
//  ReachableApp.swift
//  Reachable
//

import SwiftUI
import ReachKit

@main
struct ReachableApp: App {
    #if os(macOS)
        @ObservedObject var data = RKDatabase.shared

        @NSApplicationDelegateAdaptor private var appDelegate: AppDelegateMacOS
    #endif

    var body: some Scene {
        WindowGroup(id: "app-main-window") {
            ContentView()
                #if os(macOS)
                    .frame(minWidth: 500, minHeight: 600)
                    .onDisappear {
                        NSApp.setActivationPolicy(.accessory)
                    }
                    .onAppear {
                        NSWindow.allowsAutomaticWindowTabbing = false
                        NSApp.setActivationPolicy(.regular)
                    }
                #endif
        }
        #if os(macOS)
            .handlesExternalEvents(matching: .init())
        #endif
        #if os(macOS)
            .commands {
                CommandGroup(replacing: .newItem) {}
            }
        #endif
        #if os(macOS)
            MenuBarExtra("common.appName", image: "MenuBarIcon") {
                MenuBarView()
            }
        #endif
    }
}
