// AppBottomNavBar.swift
// Style source: NativeComponentStyling.swift › NativeBottomNavStyling
//
// IMPORTANT: Call NativeBottomNavStyling.applyAppearance() once in
//            multi_repo_iosApp.init() so UIKit picks up the styles before
//            any TabView renders. This is already done in multi_repo_iosApp.swift.
//
// Usage:
//   @State private var tab = 0
//
//   AppBottomNavBar(selectedTab: $tab) {
//       HomeView()
//           .tabItem { Label("Home", systemImage: "house") }
//           .tag(0)
//       SearchView()
//           .tabItem { Label("Search", systemImage: "magnifyingglass") }
//           .tag(1)
//       ProfileView()
//           .tabItem { Label("Profile", systemImage: "person") }
//           .tag(2)
//   }
//
//   // With badge on a tab item:
//   NotificationsView()
//       .tabItem { Label("Alerts", systemImage: "bell") }
//       .tag(3)
//       .badge(5)   ← standard SwiftUI .badge() modifier

import SwiftUI

// MARK: - AppBottomNavBar

/// A styled wrapper around SwiftUI's `TabView`.
/// Tab bar appearance (colors, fonts) is applied globally via UIKit in
/// `NativeBottomNavStyling.applyAppearance()` — called once at app startup.
///
/// Each tab child view must use SwiftUI's standard `.tabItem { Label(...) }` modifier.
public struct AppBottomNavBar<Content: View>: View {

    // MARK: - Properties

    /// The index of the currently selected tab. Bind to a `@State` variable.
    @Binding var selectedTab: Int

    /// The tab content views, each decorated with `.tabItem {}` and `.tag(N)`.
    let content: Content

    // MARK: - Init

    public init(selectedTab: Binding<Int>, @ViewBuilder content: () -> Content) {
        self._selectedTab = selectedTab
        self.content = content()
    }

    // MARK: - Body

    public var body: some View {
        TabView(selection: $selectedTab) {
            content
        }
        // TabView itself has no additional styling here.
        // All color/font customization is in NativeBottomNavStyling.applyAppearance().
        // To change the bar style, edit NativeBottomNavStyling in NativeComponentStyling.swift.
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var tab = 0

    AppBottomNavBar(selectedTab: $tab) {
        Text("Home").tabItem { Label("Home", systemImage: "house") }.tag(0)
        Text("Search").tabItem { Label("Search", systemImage: "magnifyingglass") }.tag(1)
        Text("Alerts").tabItem { Label("Alerts", systemImage: "bell") }.tag(2).badge(3)
        Text("Profile").tabItem { Label("Profile", systemImage: "person") }.tag(3)
    }
}
