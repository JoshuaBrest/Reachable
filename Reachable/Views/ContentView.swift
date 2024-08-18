//
//  ContentView.swift
//  Reachable
//

import SwiftUI
import ReachKit

struct ContentView: View {
    @ObservedObject var data = RKDatabase.shared

    var body: some View {
        if data.data.auth != nil {
            TabView {
                NavigationStack {
                    HomeView()
                }
                .tabItem {
                    Label("home.title", systemImage: "house")
                }
                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("settings.title", systemImage: "gear")
                }
            }
        } else {
            ReachLoginView()
        }
    }
}
