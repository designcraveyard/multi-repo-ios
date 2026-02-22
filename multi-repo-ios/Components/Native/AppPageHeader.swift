// AppPageHeader.swift
// Style source: NativeComponentStyling.swift › NativePageHeaderStyling
//
// This is a ViewModifier applied INSIDE a NavigationStack view body.
// The caller owns the NavigationStack — this modifier just configures the bar.
//
// Usage:
//   NavigationStack {
//       MyContentView()
//           .appPageHeader(title: "Home")
//
//       // Inline title with trailing button:
//       MyContentView()
//           .appPageHeader(title: "Settings", displayMode: .inline,
//                          trailingActions: [AnyView(Button("Edit") { })])
//   }

import SwiftUI

// MARK: - Display Mode

/// Controls whether the navigation title is large (collapsing) or inline (fixed).
public enum AppPageHeaderDisplayMode {
    /// Large title shown below the nav bar, collapses to inline on scroll.
    case large
    /// Small title always shown inside the nav bar (no collapsing).
    case inline
}

// MARK: - AppPageHeaderModifier

/// ViewModifier that configures the NavigationStack's toolbar with design-token styling.
/// All visual tokens come from `NativePageHeaderStyling` in `NativeComponentStyling.swift`.
public struct AppPageHeaderModifier: ViewModifier {

    // MARK: - Properties

    /// The navigation title text.
    let title: String

    /// Whether the title is large-collapsing or always-inline.
    var displayMode: AppPageHeaderDisplayMode = .large

    /// Views rendered in the trailing (right) toolbar slot.
    /// Wrap each view in `AnyView(...)` at the call site.
    var trailingActions: [AnyView] = []

    // MARK: - Body

    public func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(displayMode == .large ? .large : .inline)
            // Fill the navigation bar with the token background color
            .toolbarBackground(NativePageHeaderStyling.Colors.background, for: .navigationBar)
            // Force the background to always be visible (even when content scrolls under)
            .toolbarBackground(.visible, for: .navigationBar)
            // Tints back button chevron + any ToolbarItem buttons with this color
            .tint(NativePageHeaderStyling.Colors.tint)
            .toolbar {
                if !trailingActions.isEmpty {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        ForEach(Array(trailingActions.enumerated()), id: \.offset) { _, view in
                            view
                        }
                    }
                }
            }
    }
}

// MARK: - View Extension

extension View {
    /// Configures the enclosing NavigationStack's bar with design-token styling.
    ///
    /// Must be applied to a view that is inside a `NavigationStack`.
    ///
    /// - Parameters:
    ///   - title:           The navigation title string.
    ///   - displayMode:     `.large` (collapsing) or `.inline` (fixed). Defaults to `.large`.
    ///   - trailingActions: Views rendered in the trailing toolbar slot.
    ///                      Wrap each in `AnyView(...)`.
    public func appPageHeader(
        title: String,
        displayMode: AppPageHeaderDisplayMode = .large,
        trailingActions: [AnyView] = []
    ) -> some View {
        modifier(AppPageHeaderModifier(
            title: title,
            displayMode: displayMode,
            trailingActions: trailingActions
        ))
    }
}

// MARK: - Preview

#Preview("Large Title") {
    NavigationStack {
        List {
            ForEach(1...20, id: \.self) { i in
                Text("Row \(i)")
            }
        }
        .appPageHeader(
            title: "Home",
            trailingActions: [
                AnyView(Button { } label: { Image(systemName: "bell") }),
                AnyView(Button { } label: { Image(systemName: "person.circle") })
            ]
        )
    }
}

#Preview("Inline Title") {
    NavigationStack {
        List {
            ForEach(1...10, id: \.self) { i in Text("Row \(i)") }
        }
        .appPageHeader(title: "Settings", displayMode: .inline)
    }
}
