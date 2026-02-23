// AppBottomNavBar.swift
// Style source: NativeComponentStyling.swift › NativeBottomNavStyling
//
// IMPORTANT: Call NativeBottomNavStyling.applyAppearance() once in
//            multi_repo_iosApp.init() so UIKit picks up the styles before
//            any TabView renders. This is already done in multi_repo_iosApp.swift.
//
// Usage:
//
//   @State private var tab = 0
//
//   // Icon + Label (default)
//   AppBottomNavBar(
//       selectedTab: $tab,
//       style: .iconLabel,
//       tabs: [
//           AppNavTab(id: 0, label: "Home",    icon: "house"),
//           AppNavTab(id: 1, label: "Search",  icon: "magnifyingglass"),
//           AppNavTab(id: 2, label: "Alerts",  icon: "bell", badge: 5),
//           AppNavTab(id: 3, label: "Profile", icon: "person"),
//       ]
//   ) {
//       HomeView()
//       SearchView()
//       AlertsView()
//       ProfileView()
//   }
//
//   // Icon only (no visible label text)
//   AppBottomNavBar(selectedTab: $tab, style: .iconOnly, tabs: [...]) { ... }
//
// Notes:
//   - Do NOT add .tabItem or .tag to the content views — AppBottomNavBar manages
//     those internally using the `tabs` metadata.
//   - The active tab automatically renders the filled SF Symbol (.iconFill);
//     inactive tabs render the outline variant (.icon).
//   - `iconFill` defaults to `icon + ".fill"` when omitted.
//   - badge: Int = 0 hides the badge (SwiftUI treats count 0 as hidden).

import SwiftUI

// MARK: - AppNavTab

/// Metadata for a single tab in `AppBottomNavBar`.
///
/// The `id` must match the 0-based position of the corresponding content view
/// in the `@ViewBuilder` block, and is used as SwiftUI's tab selection `.tag`.
public struct AppNavTab {
    public let id: Int
    public let label: String
    /// SF Symbol name for the **unselected** (outline) state.
    public let icon: String
    /// SF Symbol name for the **selected** (filled) state. Defaults to `icon + ".fill"`.
    public let iconFill: String
    /// Numeric badge overlaid on the tab icon. `0` hides the badge.
    public let badge: Int

    public init(
        id: Int,
        label: String,
        icon: String,
        iconFill: String? = nil,
        badge: Int = 0
    ) {
        self.id = id
        self.label = label
        self.icon = icon
        self.iconFill = iconFill ?? "\(icon).fill"
        self.badge = badge
    }
}

// MARK: - AppBottomNavStyle

/// Controls how tab items are presented in the tab bar.
public enum AppBottomNavStyle {
    /// Icon + text label below each icon (standard iOS tab bar). Default.
    case iconLabel
    /// Icon only — no visible text label. The label is still used for accessibility.
    case iconOnly
}

// MARK: - AppBottomNavBar

/// A styled wrapper around SwiftUI's `TabView` with two presentation styles.
///
/// **Active tab** → filled SF Symbol variant.
/// **Inactive tabs** → outline SF Symbol variant.
///
/// Tab bar appearance (colors, fonts) is applied globally via UIKit in
/// `NativeBottomNavStyling.applyAppearance()` — called once at app startup.
///
/// Supply one content view **per tab** in the `@ViewBuilder` block, in the same
/// order as the `tabs` array. Do **not** attach `.tabItem` or `.tag` to children;
/// `AppBottomNavBar` applies those modifiers internally.
public struct AppBottomNavBar<Content: View>: View {

    // MARK: - Properties

    @Binding var selectedTab: Int
    let style: AppBottomNavStyle
    let tabs: [AppNavTab]
    private let contentViews: [AnyView]

    // MARK: - Init

    public init(
        selectedTab: Binding<Int>,
        style: AppBottomNavStyle = .iconLabel,
        tabs: [AppNavTab],
        @ViewBuilder content: () -> Content
    ) {
        self._selectedTab = selectedTab
        self.style = style
        self.tabs = tabs
        self.contentViews = Self.extractViews(from: content())
    }

    // MARK: - Body

    public var body: some View {
        TabView(selection: $selectedTab) {
            // Pair each tab definition with its corresponding content view by position.
            ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
                if index < contentViews.count {
                    contentViews[index]
                        .tabItem { tabLabel(for: tab) }
                        .tag(tab.id)
                        .badge(tab.badge)
                }
            }
        }
    }

    // MARK: - Helpers

    /// Builds the `.tabItem` label for a tab.
    /// Active tab uses the filled icon; inactive uses the outline icon.
    @ViewBuilder
    private func tabLabel(for tab: AppNavTab) -> some View {
        let iconName = selectedTab == tab.id ? tab.iconFill : tab.icon
        switch style {
        case .iconLabel:
            Label(tab.label, systemImage: iconName)
        case .iconOnly:
            Image(systemName: iconName)
                .accessibilityLabel(tab.label)
        }
    }

    /// Unpacks the `@ViewBuilder` result into individual `AnyView` instances.
    ///
    /// When a `@ViewBuilder` block contains multiple sibling views, SwiftUI wraps
    /// them in a `TupleView<(V1, V2, ...)>`. Mirror reflection on the inner tuple
    /// exposes each child at runtime. Single-view content is returned as-is.
    private static func extractViews(from content: Content) -> [AnyView] {
        let contentMirror = Mirror(reflecting: content)

        // TupleView stores its children in a single `value` property (a Swift tuple).
        if let tupleValue = contentMirror.children.first(where: { $0.label == "value" })?.value {
            let tupleMirror = Mirror(reflecting: tupleValue)
            if tupleMirror.displayStyle == .tuple {
                let views = tupleMirror.children.compactMap { child -> AnyView? in
                    guard let view = child.value as? any View else { return nil }
                    return AnyView(view)
                }
                if !views.isEmpty { return views }
            }
        }

        // Fallback: single view in the @ViewBuilder block.
        return [AnyView(content)]
    }
}

// MARK: - Preview

#Preview("Icon + Label") {
    @Previewable @State var tab = 0

    AppBottomNavBar(
        selectedTab: $tab,
        style: .iconLabel,
        tabs: [
            AppNavTab(id: 0, label: "Home",    icon: "house"),
            AppNavTab(id: 1, label: "Search",  icon: "magnifyingglass"),
            AppNavTab(id: 2, label: "Alerts",  icon: "bell",   badge: 3),
            AppNavTab(id: 3, label: "Profile", icon: "person"),
        ]
    ) {
        Text("Home")
        Text("Search")
        Text("Alerts")
        Text("Profile")
    }
}

#Preview("Icon Only") {
    @Previewable @State var tab = 0

    AppBottomNavBar(
        selectedTab: $tab,
        style: .iconOnly,
        tabs: [
            AppNavTab(id: 0, label: "Home",    icon: "house"),
            AppNavTab(id: 1, label: "Search",  icon: "magnifyingglass"),
            AppNavTab(id: 2, label: "Alerts",  icon: "bell", badge: 3),
        ]
    ) {
        Text("Home")
        Text("Search")
        Text("Alerts")
    }
}
