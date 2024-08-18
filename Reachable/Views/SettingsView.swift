//
//  SettingsView.swift
//  Reachable
//

import SwiftUI
import ReachKit
#if os(macOS)
    import ServiceManagement
#endif

struct SettingsView: View {
    @ObservedObject var data = RKDatabase.shared
    #if os(macOS)
        private let loginAppService: SMAppService? =
            if let helperID = Bundle.main.object(forInfoDictionaryKey: "AppLoginHelperIdentifier")
                as? String
            {
                SMAppService.loginItem(identifier: helperID)
            } else { nil }
        @State var loginItemEnabled = false
        @State var loginItemLoading = true
        @State var loginItemError: Error? = nil
        private var loginItemTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    #endif

    var body: some View {
        VStack {
            Form {
                Section(header: Text("settings.account")) {
                    Button {
                        data.data.auth = nil
                    } label: {
                        HStack(spacing: 4) {
                            Text("settings.account.logout")
                                .foregroundColor(.red)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                        }
                    }
                    .buttonStyle(.plain)
                }
                Section(header: Text("settings.appSettings")) {
                    #if os(macOS)
                        HStack(spacing: 4) {
                            Text("settings.appSettings.launchOnStartup")
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if loginItemLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .controlSize(.small)
                            } else {
                                Toggle(isOn: $loginItemEnabled) {}
                            }
                        }
                        HStack(spacing: 4) {
                            Text("settings.appSettings.sparkleAutoCheck")
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Toggle(isOn: $data.data.appConfig.macConfig.sparkleAutoCheck) {}
                        }
                        HStack(spacing: 4) {
                            Text("settings.appSettings.sparkleAutoDownload")
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Toggle(isOn: $data.data.appConfig.macConfig.sparkleAutoDownload) {}
                        }
                    #endif
                    HStack(spacing: 4) {
                        Text("settings.appSettings.version")
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(
                            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                                ?? "Unknown")
                    }
                }
            }
            .formStyle(.grouped)
        }
        .navigationTitle("settings.title")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        #if os(macOS)
            .onAppear {
                checkLoginState()
            }
            .onChange(of: loginItemEnabled) { value in
                updateLoginState(with: value)
            }
            .onReceive(
                loginItemTimer,
                perform: { _ in
                    checkLoginState()
                }
            )
            .alert(
                String(
                    format: String(localized: "common.errorTitle"),
                    loginItemError?.localizedDescription ?? ""
                ), isPresented: .constant(loginItemError != nil)
            ) {
                Button("common.okay", role: .cancel) {
                    loginItemError = nil
                }
            }
        #endif
    }

    #if os(macOS)
        private func checkLoginState() {
            DispatchQueue.main.async {
                withAnimation {
                    loginItemLoading = true
                }
            }

            guard let loginAppService = loginAppService else {
                return
            }

            DispatchQueue.main.async {
                withAnimation {
                    switch loginAppService.status {
                    case .notRegistered:
                        loginItemEnabled = false
                        loginItemLoading = false
                    case .enabled:
                        loginItemEnabled = true
                        loginItemLoading = false
                    case .requiresApproval:
                        loginItemEnabled = false
                        loginItemLoading = false
                    case .notFound:
                        loginItemEnabled = false
                        loginItemLoading = false
                    @unknown default:
                        loginItemEnabled = false
                        loginItemLoading = true
                    }
                }
            }
        }

        private func updateLoginState(with enabled: Bool) {
            DispatchQueue.main.async {
                withAnimation {
                    loginItemLoading = true
                }
            }

            guard let loginAppService = loginAppService else {
                return
            }

            DispatchQueue.main.async {
                do {
                    if loginItemEnabled {
                        try loginAppService.register()
                    } else {
                        try loginAppService.unregister()
                    }
                } catch {
                    withAnimation {
                        loginItemError = error
                    }
                }
            }
        }
    #endif
}

#Preview {
    SettingsView()
}
