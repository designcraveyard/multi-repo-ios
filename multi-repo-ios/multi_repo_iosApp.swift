//
//  multi_repo_iosApp.swift
//  multi-repo-ios
//
//  Created by abhishekverma on 19/02/26.
//

import SwiftUI
import GoogleSignIn
import Supabase

@main
struct multi_repo_iosApp: App {
    @State private var authManager = AuthManager()

    init() {
        // Apply UITabBar appearance tokens before any TabView renders.
        NativeBottomNavStyling.applyAppearance()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoading {
                    AppProgressLoader()
                } else if authManager.currentUser != nil {
                    ContentView()
                } else {
                    LoginView()
                }
            }
            .environment(authManager)
            .onOpenURL { url in
                // Handle Google Sign-In callback
                GIDSignIn.sharedInstance.handle(url)
                // Handle Supabase OAuth callback
                Task {
                    try? await SupabaseManager.shared.client.auth.handle(url)
                }
            }
        }
    }
}
