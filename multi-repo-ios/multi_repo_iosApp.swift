//
//  multi_repo_iosApp.swift
//  multi-repo-ios
//
//  Created by abhishekverma on 19/02/26.
//

import SwiftUI

@main
struct multi_repo_iosApp: App {

    init() {
        // Apply UITabBar appearance tokens before any TabView renders.
        NativeBottomNavStyling.applyAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
