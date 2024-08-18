//
//  ReachCoordinatedBlackbaudLoginModel.swift
//  Reachable
//

import Foundation
import WebKit

/// Coordinated SAML login model.
struct ReachCoordinatedBlackbaudLoginModel: Sendable, ReachCoordinatedLoginModel
        .CordinatedLoginContext
{
    /// Callback data.
    public struct OkayData: Sendable {
        var token: String
    }

    /// Error data.
    public enum ErrorData: Sendable, Error {
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
        if url.host() != reach || !url.pathComponents.contains("blackbaud")
            || !url.pathComponents.contains("sso")
        {
            callback(.allow)
            return
        }

        // Get token in url
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let components = components,
            let token = components.queryItems?.first(where: { $0.name == "sso_token" })?.value
        else {
            callback(.allow)
            return
        }

        callback(.finish(.success(OkayData(token: token))))
    }
}
