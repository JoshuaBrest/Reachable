//
//  MenuBarView.swift
//  Reachable
//

#if os(macOS)

    import SwiftUI
    import ReachKit

    struct MenuBarView: View {
        @ObservedObject var data = RKDatabase.shared
        @Environment(\.openWindow) var openWindow

        @State private var error: Error? = nil

        @State private var locationLoadingID = -1

        var body: some View {
            Group {
                if let auth = data.data.auth, let config = data.data.schoolConfig {
                    Menu("manageLocation.title") {
                        if !data.data.appConfig.favoriteLocations.isEmpty {
                            Picker("manageLocation.favorites", selection: $locationLoadingID) {
                                ForEach(
                                    config.locations.filter {
                                        data.data.appConfig.favoriteLocations.contains($0.id)
                                    }
                                ) { location in
                                    Text(location.name)
                                        .tag(location.id)
                                }
                            }
                            .pickerStyle(.inline)
                            .onChange(of: locationLoadingID) { value in
                                Task {
                                    let result = await RKApiUserLocation.setUserLocation(
                                        auth: auth,
                                        contactID: auth.contactID,
                                        locationID: value,
                                        requestID: nil
                                    )
                                    DispatchQueue.main.async {
                                        withAnimation {
                                            switch result {
                                            case .success:
                                                data.data.userContact?.locationID = value
                                            case .failure(let error):
                                                self.error = error
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            Text("menuBar.manageLocation.noFavorites")
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("menuBar.notLoggedIn")
                        .foregroundColor(.secondary)
                }
                Divider()
                Button {
                    NSApp.setActivationPolicy(.regular)
                    if #available(macOS 14.0, *) {
                        NSApp.activate()
                    } else {
                        NSApp.activate(ignoringOtherApps: true)
                    }
                    if let win = NSApp.windows.first(where: { $0.canBecomeMain }) {
                        win.makeKeyAndOrderFront(nil)
                        win.makeMain()
                        win.orderFrontRegardless()
                    } else {
                        openWindow(id: "app-main-window")
                    }
                } label: {
                    Text("menuBar.show")
                }
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("menuBar.close")
                }
            }
            .alert(
                String(
                    format: String(localized: "common.errorTitle"),
                    error?.localizedDescription ?? ""
                ), isPresented: .constant(error != nil)
            ) {
                Button("common.okay", role: .cancel) {
                    error = nil
                }
            }
        }
    }

    #Preview {
        MenuBarView()
    }

#endif
