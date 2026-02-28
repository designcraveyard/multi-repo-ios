// AdaptiveNavShell.swift
// Adaptive navigation shell: bottom tabs on compact, collapsible sidebar on regular.
//
// Usage:
//
//   @State private var tab = 0
//
//   AdaptiveNavShell(
//       selectedTab: $tab,
//       tabs: [
//           AppNavTab(id: 0, label: "Home",    icon: "house"),
//           AppNavTab(id: 1, label: "Search",  icon: "magnifyingglass"),
//           AppNavTab(id: 2, label: "Settings", icon: "gearshape"),
//       ]
//   ) {
//       HomeView()
//       SearchView()
//       SettingsView()
//   }
//
// On iPhone / portrait iPad (.compact): renders AppBottomNavBar with bottom tabs.
// On iPad landscape / macOS (.regular): renders a collapsible icon-rail sidebar.
//
// Sidebar spec:
//   - Collapsed: 60pt wide (icon only)
//   - Expanded: 240pt wide (icon + label)
//   - Toggle button at the bottom of the sidebar
//   - Active tab highlighted with brand color
//   - Transition animated with spring

import SwiftUI

// MARK: - AdaptiveNavShell

/// Root navigation wrapper that adapts between bottom tabs and sidebar.
public struct AdaptiveNavShell<Content: View>: View {

    // MARK: - Properties

    @Environment(\.horizontalSizeClass) private var sizeClass
    @Binding var selectedTab: Int
    @State private var isSidebarExpanded = true
    let tabs: [AppNavTab]
    private let contentViews: [AnyView]

    // MARK: - Sidebar Layout Constants

    private let collapsedWidth: CGFloat = 60
    private let expandedWidth: CGFloat = 240

    private var sidebarWidth: CGFloat {
        isSidebarExpanded ? expandedWidth : collapsedWidth
    }

    // MARK: - Init

    public init(
        selectedTab: Binding<Int>,
        tabs: [AppNavTab],
        @ViewBuilder content: () -> Content
    ) {
        self._selectedTab = selectedTab
        self.tabs = tabs
        // Reuse the same tuple-reflection approach as AppBottomNavBar
        self.contentViews = Self.extractViews(from: content())
    }

    // MARK: - Body

    public var body: some View {
        if sizeClass == .regular {
            sidebarLayout
        } else {
            compactLayout
        }
    }

    // MARK: - Compact Layout (Bottom Tabs)

    private var compactLayout: some View {
        TabView(selection: $selectedTab) {
            ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
                if index < contentViews.count {
                    NavigationStack {
                        contentViews[index]
                    }
                    .tabItem {
                        let iconName = selectedTab == tab.id ? tab.iconFill : tab.icon
                        Label(tab.label, systemImage: iconName)
                    }
                    .tag(tab.id)
                    .badge(tab.badge)
                }
            }
        }
    }

    // MARK: - Sidebar Layout (Regular)

    private var sidebarLayout: some View {
        HStack(spacing: 0) {
            // --- Sidebar ---
            sidebar
                .frame(width: sidebarWidth)
                .background(Color.surfacesBasePrimary)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSidebarExpanded)

            // --- Divider ---
            Rectangle()
                .fill(Color.appBorderMuted)
                .frame(width: 1)

            // --- Content ---
            NavigationStack {
                if selectedTab < contentViews.count {
                    contentViews[selectedTab]
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Sidebar Content

    private var sidebar: some View {
        VStack(spacing: 0) {
            // Tab items
            ForEach(Array(tabs.enumerated()), id: \.element.id) { _, tab in
                sidebarItem(for: tab)
            }

            Spacer()

            // Collapse/expand toggle (left-aligned to match sidebar items)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isSidebarExpanded.toggle()
                }
            } label: {
                HStack(spacing: CGFloat.spaceSM) {
                    Image(systemName: isSidebarExpanded ? "sidebar.left" : "sidebar.right")
                        .font(.system(size: 18))
                        .frame(width: 24, height: 24)

                    if isSidebarExpanded {
                        Text(isSidebarExpanded ? "Collapse" : "Expand")
                            .font(.appBodyMedium)
                            .lineLimit(1)
                        Spacer()
                    }
                }
                .foregroundStyle(Color.typographySecondary)
                .padding(.horizontal, CGFloat.spaceMD)
                .frame(height: 48)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, CGFloat.spaceXS)
            .accessibilityLabel(isSidebarExpanded ? "Collapse sidebar" : "Expand sidebar")
            .padding(.bottom, CGFloat.spaceSM)
        }
        .padding(.top, CGFloat.spaceLG)
    }

    // MARK: - Sidebar Item

    private func sidebarItem(for tab: AppNavTab) -> some View {
        let isActive = selectedTab == tab.id
        let iconName = isActive ? tab.iconFill : tab.icon

        return Button {
            selectedTab = tab.id
        } label: {
            HStack(spacing: CGFloat.spaceSM) {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .frame(width: 24, height: 24)

                if isSidebarExpanded {
                    Text(tab.label)
                        .font(.appBodyMedium)
                        .lineLimit(1)
                    Spacer()

                    if tab.badge > 0 {
                        Text("\(tab.badge)")
                            .font(.appCaptionSmall)
                            .foregroundStyle(Color.typographyOnBrandPrimary)
                            .padding(.horizontal, CGFloat.spaceXS)
                            .padding(.vertical, 2)
                            .background(Color.surfacesBrandInteractive, in: Capsule())
                    }
                }
            }
            .foregroundStyle(isActive ? Color.surfacesBrandInteractive : Color.typographySecondary)
            .padding(.horizontal, CGFloat.spaceMD)
            .frame(height: 48)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isActive
                    ? Color.surfacesBrandInteractive.opacity(0.1)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: CGFloat.radiusMD)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, CGFloat.spaceXS)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    // MARK: - View Extraction

    /// Unpacks the `@ViewBuilder` result into individual `AnyView` instances.
    /// Mirrors the same approach used by AppBottomNavBar.
    private static func extractViews(from content: Content) -> [AnyView] {
        let contentMirror = Mirror(reflecting: content)

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

        return [AnyView(content)]
    }
}

// MARK: - Preview

#Preview("Compact") {
    @Previewable @State var tab = 0

    AdaptiveNavShell(
        selectedTab: $tab,
        tabs: [
            AppNavTab(id: 0, label: "Home",     icon: "house"),
            AppNavTab(id: 1, label: "Search",   icon: "magnifyingglass"),
            AppNavTab(id: 2, label: "Settings",  icon: "gearshape"),
        ]
    ) {
        Text("Home Content")
        Text("Search Content")
        Text("Settings Content")
    }
    .environment(\.horizontalSizeClass, .compact)
}

#Preview("Regular (Sidebar)") {
    @Previewable @State var tab = 0

    AdaptiveNavShell(
        selectedTab: $tab,
        tabs: [
            AppNavTab(id: 0, label: "Home",      icon: "house"),
            AppNavTab(id: 1, label: "Search",    icon: "magnifyingglass"),
            AppNavTab(id: 2, label: "Alerts",    icon: "bell", badge: 3),
            AppNavTab(id: 3, label: "Settings",   icon: "gearshape"),
        ]
    ) {
        Text("Home Content")
        Text("Search Content")
        Text("Alerts Content")
        Text("Settings Content")
    }
    .environment(\.horizontalSizeClass, .regular)
}
