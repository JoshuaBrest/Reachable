//
//  ReachCoordinatedLoginModel.swift
//  Reachable
//

import Foundation
import WebKit
import SwiftUI

enum ReachCoordinatedLoginModel {
    /// A user script to inject into the web view.
    /// Preventing ugly zooming.
    @MainActor private static func getInjectableScript() -> WKUserScript {
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

    /// The navigation actions.
    public enum NavigationAction<Data: Sendable>: Sendable {
        /// Allow the navigation.
        case allow
        /// Cancel the navigation.
        case cancel
        /// Finish the navigation.
        case finish(Data)
    }

    /// The coordinator for the login view.
    /// Do not use this directly, use the `CordinatableLoginView` instead.
    public class Coordinator<LoginContext: CordinatedLoginContext>: NSObject, WKNavigationDelegate,
        @unchecked Sendable
    {
        private let authCallback: LoginContext.FinishCallback
        private let coordinatorContext: LoginContext

        private var hasIndicatedFinish = false

        init(authCallback: @escaping LoginContext.FinishCallback, context: LoginContext) {
            self.authCallback = authCallback
            self.coordinatorContext = context
        }

        /// Handle the page navigation.
        /// - Parameters:
        ///   - webView: The web view.
        ///   - policy: The navigation policy.
        ///   - action: A callback to call when the navigation is complete.
        private func handlePageNavigation(
            with webView: WKWebView, policy: WKNavigationAction, action: @escaping (Bool) -> Void
        ) {
            if hasIndicatedFinish {
                action(false)
                return
            }

            guard let url = policy.request.url else {
                action(false)
                return
            }

            Task {
                await MainActor.run {
                    coordinatorContext.willNavigate(
                        to: url, with: webView,
                        action: { [self] shouldNavigate in
                            switch shouldNavigate {
                            case .allow:
                                action(true)
                            case .cancel:
                                action(false)
                            case .finish(let data):
                                hasIndicatedFinish = true
                                action(false)

                                switch data {
                                case .success(let data):
                                    authCallback(.success(data))
                                case .failure(let error):
                                    authCallback(.failure(error))
                                }
                            }
                        })
                }
            }
        }

        // The SDK changed and is not backwards compatible
        #if compiler(>=6)
            public func webView(
                _ webView: WKWebView,
                decidePolicyFor navigationAction: WKNavigationAction,
                decisionHandler: @MainActor @escaping (WKNavigationActionPolicy) -> Void
            ) {
                handlePageNavigation(
                    with: webView, policy: navigationAction,
                    action: { result in
                        decisionHandler(result ? .allow : .cancel)
                    })
            }
        #else
            public func webView(
                _ webView: WKWebView,
                decidePolicyFor navigationAction: WKNavigationAction,
                decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
            ) {

                handlePageNavigation(
                    with: webView, policy: navigationAction,
                    action: { result in
                        decisionHandler(result ? .allow : .cancel)
                    })
            }
        #endif
    }

    /// A protocol for implementing login logic.
    public protocol CordinatedLoginContext: Sendable {
        /// The type of data to be passed to the finishing callback.
        associatedtype OkayData: Sendable
        /// The type of data to be passed to the finishing callback in case of an error.
        associatedtype ErrorData: Sendable, Error

        /// The callback data.
        typealias CallbackData = Result<OkayData, ErrorData>
        /// A return type for the navigation.
        typealias NavigationResult = CallbackData?
        /// The navigation action.
        typealias NavigationAction = ReachCoordinatedLoginModel.NavigationAction<CallbackData>
        /// The finishing callback, called when the login process is complete.
        typealias FinishCallback = (_ result: CallbackData) -> Void

        /// The initial URL to navigate to.
        func initialURL() -> URL

        @MainActor func willNavigate(
            to url: URL, with webView: WKWebView,
            action callback: @escaping (NavigationAction) -> Void)
    }

    /// A class to handle updating the title of the web view.
    @objc private class TitleObserver: NSObject {
        var title: Binding<String?>

        init(title: Binding<String?>) {
            self.title = title
        }

        @objc override func observeValue(
            forKeyPath keyPath: String?,
            of object: Any?,
            change: [NSKeyValueChangeKey: Any]?,
            context: UnsafeMutableRawPointer?
        ) {
            if keyPath == "title" {
                title.wrappedValue = change?[.newKey] as? String
            }
        }

        public func createObserver(with webKit: WKWebView) {
            webKit.addObserver(self, forKeyPath: "title", options: .new, context: nil)
        }

        public func removeObserver(with webKit: WKWebView) {
            webKit.removeObserver(self, forKeyPath: "title")
        }
    }

    #if os(macOS)
        public struct CordinatableLoginView<LoginContext: CordinatedLoginContext>:
            NSViewRepresentable
        {
            public var cordinatingContext: LoginContext
            public var authCallback: LoginContext.FinishCallback
            private var title: TitleObserver

            public init(
                title: Binding<String?>, context: LoginContext,
                authCallback: @escaping LoginContext.FinishCallback
            ) {
                self.cordinatingContext = context
                self.authCallback = authCallback
                self.title = TitleObserver(title: title)
            }

            public func makeNSView(context: Context) -> WKWebView {
                let config = WKWebViewConfiguration()
                config.websiteDataStore = .nonPersistent()
                config.userContentController.addUserScript(
                    ReachCoordinatedLoginModel.getInjectableScript())

                let webView = WKWebView(frame: .zero, configuration: config)

                let request = URLRequest(url: cordinatingContext.initialURL())
                webView.load(request);

                // Add observer for title
                title.createObserver(with: webView)

                return webView
            }

            public func updateNSView(_ nsView: WKWebView, context: Context) {
                nsView.navigationDelegate = context.coordinator
            }

            public static func dismantleNSView(
                _ nsView: WKWebView, coordinator: Coordinator<LoginContext>
            ) {
                nsView.stopLoading()
            }

            public func makeCoordinator() -> ReachCoordinatedLoginModel.Coordinator<LoginContext> {
                return ReachCoordinatedLoginModel.Coordinator(
                    authCallback: authCallback, context: cordinatingContext)
            }
        }
    #else
        public struct CordinatableLoginView<LoginContext: CordinatedLoginContext>:
            UIViewRepresentable
        {
            public var cordinatingContext: LoginContext
            public var authCallback: LoginContext.FinishCallback
            public var loaded: Bool = false
            private var title: TitleObserver

            public init(
                title: Binding<String?>, context: LoginContext,
                authCallback: @escaping LoginContext.FinishCallback
            ) {
                self.cordinatingContext = context
                self.authCallback = authCallback
                self.title = TitleObserver(title: title)
            }

            public func makeUIView(context: Context) -> WKWebView {
                let config = WKWebViewConfiguration()
                config.userContentController.addUserScript(
                    ReachCoordinatedLoginModel.getInjectableScript())
                config.websiteDataStore = .nonPersistent()

                let webKit = WKWebView(frame: .zero, configuration: config)

                let request = URLRequest(url: cordinatingContext.initialURL())
                webKit.load(request);

                // Add observer for title
                title.createObserver(with: webKit)

                return webKit
            }

            public func updateUIView(_ uiView: WKWebView, context: Context) {
                uiView.navigationDelegate = context.coordinator
            }

            public static func dismantleUIView(
                _ uiView: WKWebView, coordinator: Coordinator<LoginContext>
            ) {
                uiView.stopLoading()
            }

            public func makeCoordinator() -> ReachCoordinatedLoginModel.Coordinator<LoginContext> {
                return ReachCoordinatedLoginModel.Coordinator(
                    authCallback: authCallback, context: cordinatingContext)
            }
        }
    #endif
}
