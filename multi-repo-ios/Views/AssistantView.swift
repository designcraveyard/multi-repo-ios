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
struct AssistantView: View {

    // MARK: - State

    @State private var isLoading = true

    // MARK: - Constants

    private let assistantURL = URL(string: "http://192.168.1.6:3000/assistant-embed")!

    // MARK: - Body

    var body: some View {
        ZStack {
            AppWebView(
                url: assistantURL,
                isLoading: $isLoading
            )

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
