//
//  ReachCoordinatedSAMLLoginModel.swift
//  Reachable
//

import Foundation
import WebKit

/// Coordinated SAML login model.
struct ReachCoordinatedSAMLLoginModel: Sendable, ReachCoordinatedLoginModel.CordinatedLoginContext {
    /// Callback data.
    public struct OkayData: Sendable {
        var token: String
    }

    /// Error data.
    public enum ErrorData: Sendable, Error {
        case tokenNotString
    }

    /// Reach domain
    var reach: String
    /// SAML IDP URL
    var samlIDPURL: URL

    /// Initial URL
    public func initialURL() -> URL {
        return samlIDPURL
    }

    /// Handle URL
    @MainActor public func willNavigate(
        to url: URL,
        with webView: WKWebView,
        action callback: @escaping (NavigationAction) -> Void
    ) {
        if url.host() != reach || !url.pathComponents.contains("samlACS") {
            callback(.allow)
            return
        }

        // Get token via js
        let js = """
            document.querySelector("form input[name=\\"SAMLResponse\\"]").value
            """
        webView.evaluateJavaScript(js) { result, error in
            if error != nil {
                callback(.allow)
                return
            }

            guard let token = result as? String else {
                callback(.allow)
                return
            }

            callback(.finish(.success(OkayData(token: token))))
        }
    }
}
