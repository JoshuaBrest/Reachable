//
//  ContentView.swift
//  Reachable
//
//  Created by Josh on 6/28/24.
//

import SwiftUI
import ReachKit

struct ContentView: View {
    // Observed object
    @ObservedObject var data = RKDatabase.shared

    var body: some View {
        NavigationView {
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
}
