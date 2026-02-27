//
//  AssistantView.swift
//  multi-repo-ios
//
//  Loads the Assistant web app in an embedded WebView.
//  // responsive: N/A — single full-screen WebView on all form factors.
//

import SwiftUI

// MARK: - AssistantView

/// A full-screen view that embeds the Assistant web app via `AppWebView`.
/// Detects system theme changes and reloads the WebView with the appropriate theme parameter.
/// // responsive: N/A — single full-screen WebView on all form factors.
struct AssistantView: View {

    // MARK: - State

    @State private var isLoading = true
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Constants

    private let baseURL = "https://lifegraph-agent.vercel.app/"

    // MARK: - Computed

    private var assistantURL: URL {
        let theme = colorScheme == .dark ? "dark" : "light"
        return URL(string: "\(baseURL)?theme=\(theme)")!
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppWebView(
                url: assistantURL,
                isLoading: $isLoading,
                allowsRefresh: true
            )
            .id(colorScheme) // Force WebView recreation on theme change

            if isLoading {
                AppProgressLoader(label: "Loading Assistant...")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AssistantView()
}
