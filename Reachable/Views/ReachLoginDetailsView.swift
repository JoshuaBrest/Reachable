//
//  ReachLoginDetailsView.swift
//  Reachable
//
//  Created by Josh on 6/28/24.
//

import SwiftUI
import ReachKit
@preconcurrency import WebKit

struct ReachLoginDetailsView: View {
    let reach: RKApiSearchSchools.RKSchool
    @State private var reachDetails: RKApiAuthSchoolData.RKSchoolData? = nil
    @State private var error: Error? = nil
    @State private var isLoading: Bool = false
    @State private var reachError: Error? = nil
    @State private var samlShowing: Bool = false

    @ObservedObject var data = RKDatabase.shared

    private struct SAMLLogin: UIViewRepresentable {
        let url: URL
        let schoolBase: String
        let authCallback: (_ result: String?) -> Void

        func makeUIView(context: Context) -> WKWebView {
            let config = WKWebViewConfiguration()
            config.userContentController.addUserScript(getDisableScript())
            config.websiteDataStore = .nonPersistent()
            return WKWebView(frame: .zero, configuration: config)
        }

        func updateUIView(_ uiView: WKWebView, context: Context) {
            let request = URLRequest(url: url)
            uiView.load(request);
            uiView.navigationDelegate = context.coordinator
        }

        static func dismantleUIView(_ uiView: WKWebView, coordinator: ()) {
            uiView.stopLoading()
        }

        func makeCoordinator() -> Coordinator {
            return Coordinator(authCallback: authCallback, schoolBase: schoolBase)
        }

        private func getDisableScript() -> WKUserScript {
            let source: String = """
                // Disable zoom
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                var head = document.getElementsByTagName('head')[0];
                head.appendChild(meta);
                """
            return WKUserScript(
                source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        }

        class Coordinator: NSObject, WKNavigationDelegate {
            let authCallback: (_ result: String?) -> Void
            let schoolBase: String

            init(authCallback: @escaping (_ result: String?) -> Void, schoolBase: String) {
                self.authCallback = authCallback
                self.schoolBase = schoolBase
            }

            private func getJavaScriptString(
                _ wk: WKWebView, _ key: String, _ completion: @escaping (String?) -> Void
            ) {
                var result: String? = nil
                wk.evaluateJavaScript(
                    key,
                    completionHandler: { (value, error) in
                        if let value = value as? String {
                            result = value
                        }
                        completion(result)
                    })
            }

            public func webView(
                _ webView: WKWebView,
                decidePolicyFor navigationAction: WKNavigationAction,
                decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
            ) {
                guard let url = navigationAction.request.url else {
                    // Decision handler has to be called on MainActor
                    DispatchQueue.main.async { @MainActor in
                        decisionHandler(.allow)
                    }
                    return
                }

                if url.host == schoolBase, url.path == "/samlACS" {
                    DispatchQueue.main.async { @MainActor in
                        decisionHandler(.cancel)
                    }
                    self.getJavaScriptString(
                        webView, "document.querySelector('form input[name=\"SAMLResponse\"]').value"
                    ) { res in
                        if let res = res {
                            self.authCallback(res)
                        } else {
                            self.authCallback(nil)
                        }
                    }
                    return
                }

                DispatchQueue.main.async { @MainActor in
                    decisionHandler(.allow)
                }
            }
        }

    }

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else if let error = error {
                Text(
                    String(
                        format: String(localized: "reachLoginDetails.error"),
                        error.localizedDescription)
                )
                .foregroundColor(.red)
            } else if reachDetails == nil {
                VStack {}
            } else {
                if let reachDetails = reachDetails {
                    VStack(alignment: .leading, spacing: 20) {
                        Spacer()
                        HStack(spacing: 16) {
                            // If image is available
                            if let emblem = reachDetails.schoolEmblem {
                                AsyncImage(url: emblem) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                }
                                // Fit image into frame
                                .padding(10)
                                .frame(width: 72, height: 72)
                                .background(.thickMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            // Format string
                            Text(
                                String(
                                    format: String(localized: "reachLoginDetails.schoolLogin"),
                                    reachDetails.schoolName)
                            )
                            .font(.title2)
                            .bold()
                            Spacer()
                        }
                        if let saml = reachDetails.samlData {
                            Button {
                                samlShowing = true
                            } label: {
                                Text("reachLoginDetails.samlLogin")
                                    .padding(4)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .sheet(isPresented: $samlShowing) {
                                SAMLLogin(
                                    url: saml.idpUrl, schoolBase: reachDetails.reachDomain,
                                    authCallback: { result in
                                        samlShowing = false
                                        guard let result = result else {
                                            reachError = NSError(
                                                domain: "reachplus", code: 0,
                                                userInfo: [
                                                    NSLocalizedDescriptionKey: "SAML login failed"
                                                ])
                                            return
                                        }

                                        Task {
                                            let result = await RKApiAuthLoginSAML.preformLogin(
                                                reach: reachDetails.reachDomain, token: result)
                                            switch result {
                                            case .success(let res):
                                                switch res {
                                                case .success(let auth):
                                                    data.data.auth = auth
                                                case .failure(let fail):
                                                    reachError = fail
                                                }
                                            case .failure(let fail):
                                                reachError = fail
                                            }
                                        }
                                    })
                            }

                        }
                        if reachDetails.samlData == nil {
                            Text("reachLoginDetails.noLogin")
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
            }
        }
        .alert(
            String(
                format: String(localized: "reachLoginDetails.loginError"),
                reachError?.localizedDescription ?? ""
            ), isPresented: .constant(reachError != nil)
        ) {
            Button("common.okay", role: .cancel) {
                reachError = nil
            }
        }
        .onAppear {
            loadDetails(reach)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("reachLoginDetails.title")
    }

    private func loadDetails(_ reach: RKApiSearchSchools.RKSchool) {
        withAnimation {
            isLoading = true
            error = nil
        }

        Task {
            // Fetch school details
            let result = await RKApiAuthSchoolData.getSchoolDetails(reach: reach.reachDomain)

            DispatchQueue.main.async {
                withAnimation {
                    switch result {
                    case .success(let details):
                        withAnimation {
                            reachDetails = details
                            isLoading = false
                        }
                    case .failure(let error):
                        withAnimation {
                            self.error = error
                            isLoading = false
                        }
                    }
                }
            }
        }
        return
    }
}

#Preview {
    ReachLoginDetailsView(reach: RKApiSearchSchools.RKSchool.example)
}
