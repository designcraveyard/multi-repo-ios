// AppWebView.swift
// A reusable WKWebView wrapper using UIViewRepresentable.
//
// Usage:
//   // Basic:
//   AppWebView(url: URL(string: "https://example.com")!)
//
//   // With loading state:
//   @State private var isLoading = true
//   AppWebView(url: myURL, isLoading: $isLoading)
//
//   // With error handler:
//   AppWebView(url: myURL, isLoading: $isLoading) { error in
//       print("WebView error: \(error)")
//   }

import SwiftUI
import WebKit

// MARK: - AppWebView

/// A styled wrapper around `WKWebView` via `UIViewRepresentable`.
/// JavaScript is enabled by default.
struct AppWebView: UIViewRepresentable {

    // MARK: - Properties

    /// The URL to load in the web view.
    let url: URL

    /// Binding that reflects whether the web view is currently loading content.
    @Binding var isLoading: Bool

    /// Optional callback invoked when a navigation error occurs.
    var onError: ((Error) -> Void)?

    // MARK: - Init

    init(
        url: URL,
        isLoading: Binding<Bool> = .constant(false),
        onError: ((Error) -> Void)? = nil
    ) {
        self.url = url
        self._isLoading = isLoading
        self.onError = onError
    }

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear

        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Reload only if the URL has changed
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: AppWebView

        init(parent: AppWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.onError?(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.onError?(error)
        }
    }
}

// MARK: - Preview

#Preview {
    AppWebView(url: URL(string: "https://example.com")!)
}
