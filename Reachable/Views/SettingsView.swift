//
//  SettingsView.swift
//  Reachable
//
//  Created by Josh on 6/28/24.
//

import SwiftUI
import ReachKit

struct SettingsView: View {
    @ObservedObject var data = RKDatabase.shared

    var body: some View {
        VStack {
            List {
                Section(header: Text("settings.account")) {
                    Button {
                        data.data.auth = nil
                    } label: {
                        HStack {
                            Text("settings.account.logout")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                        }
                    }
                }
                Section(header: Text("settings.appInfo")) {
                    // App version
                    HStack {
                        Text("settings.appInfo.version")
                        Spacer()
                        Text(
                            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                                ?? "Unknown")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .navigationTitle("settings.title")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}

#Preview {
    SettingsView()
}
