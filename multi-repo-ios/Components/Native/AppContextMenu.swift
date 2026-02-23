// AppContextMenu.swift
// Style source: NativeComponentStyling.swift › NativeContextMenuStyling
//
// Two components in this file:
//
//   1. appContextMenu(items:) — long-press .contextMenu modifier
//      someView.appContextMenu(items: [
//          .item("Edit", icon: AnyView(Ph.pencilSimple.regular)) { edit() },
//          .destructive("Delete", icon: AnyView(Ph.trash.regular)) { delete() }
//      ])
//
//   2. AppPopoverMenu — tap-triggered popover with custom card
//      AppPopoverMenu(isPresented: $showMenu, items: [...]) {
//          Ph.dotsThreeCircle.regular.iconSize(.lg)
//      }

import SwiftUI
import PhosphorSwift

// MARK: - AppContextMenuItem

/// Represents a single item in a context menu or popover menu.
public struct AppContextMenuItem {
    let label: String
    let icon: AnyView?          // Any icon view (e.g. Phosphor icon)
    let role: ButtonRole?
    let handler: () -> Void

    /// A standard menu item. Renders in the default text color.
    public static func item(_ label: String,
                             icon: AnyView? = nil,
                             handler: @escaping () -> Void) -> AppContextMenuItem {
        AppContextMenuItem(label: label, icon: icon, role: nil, handler: handler)
    }

    /// A destructive menu item. iOS .contextMenu renders it red automatically.
    /// AppPopoverMenu uses NativeContextMenuStyling.Colors.destructiveText explicitly.
    public static func destructive(_ label: String,
                                    icon: AnyView? = nil,
                                    handler: @escaping () -> Void) -> AppContextMenuItem {
        AppContextMenuItem(label: label, icon: icon, role: .destructive, handler: handler)
    }
}

// MARK: - appContextMenu ViewModifier

/// Attaches a long-press .contextMenu to the view.
private struct AppContextMenuModifier: ViewModifier {
    let items: [AppContextMenuItem]

    func body(content: Content) -> some View {
        content.contextMenu {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Button(role: item.role, action: item.handler) {
                    if let icon = item.icon {
                        Label {
                            Text(item.label)
                        } icon: {
                            icon
                        }
                    } else {
                        Text(item.label)
                    }
                }
            }
        }
    }
}

extension View {
    /// Attaches a long-press context menu to the view.
    /// iOS styles and positions the menu automatically.
    public func appContextMenu(items: [AppContextMenuItem]) -> some View {
        modifier(AppContextMenuModifier(items: items))
    }
}

// MARK: - AppPopoverMenu

/// A tap-triggered popover menu with a custom-styled card.
/// Use instead of .contextMenu when you need a button-triggered (not long-press) menu.
///
/// - Parameters:
///   - isPresented: Binding that controls popover visibility.
///   - items:       The menu items to display.
///   - label:       The view that acts as the menu trigger (e.g. an ellipsis icon button).
public struct AppPopoverMenu<Label: View>: View {

    @Binding var isPresented: Bool
    let items: [AppContextMenuItem]
    @ViewBuilder let label: () -> Label

    public var body: some View {
        Button { isPresented = true } label: { label() }
            .popover(isPresented: $isPresented) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        Button(role: item.role) {
                            item.handler()
                            isPresented = false
                        } label: {
                            HStack(spacing: NativeContextMenuStyling.Layout.itemIconSpacing) {
                                if let icon = item.icon {
                                    icon
                                        .foregroundStyle(item.role == .destructive
                                            ? NativeContextMenuStyling.Colors.destructiveText
                                            : NativeContextMenuStyling.Colors.itemText)
                                }
                                Text(item.label)
                                    .font(NativeContextMenuStyling.Typography.item)
                                    .foregroundStyle(item.role == .destructive
                                        ? NativeContextMenuStyling.Colors.destructiveText
                                        : NativeContextMenuStyling.Colors.itemText)
                                Spacer()
                            }
                            .padding(.horizontal, NativeContextMenuStyling.Layout.itemPaddingH)
                            .padding(.vertical, NativeContextMenuStyling.Layout.itemPaddingV)
                        }
                        .buttonStyle(.plain)

                        // Divider between rows, but not after the last row
                        if index < items.count - 1 {
                            Divider()
                                .overlay(NativeContextMenuStyling.Colors.rowDivider)
                        }
                    }
                }
                .frame(minWidth: NativeContextMenuStyling.Layout.minWidth)
                .background(NativeContextMenuStyling.Colors.background)
                .clipShape(RoundedRectangle(cornerRadius: NativeContextMenuStyling.Layout.cornerRadius))
                // Prevents the popover expanding to a sheet on compact size classes
                .presentationCompactAdaptation(.popover)
            }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var showPopover = false

    VStack(spacing: 32) {
        // Long-press context menu
        Text("Long-press me")
            .padding()
            .background(Color.appSurfaceBaseLowContrast, in: RoundedRectangle(cornerRadius: .radiusMD))
            .appContextMenu(items: [
                .item("Edit", icon: AnyView(Ph.pencilSimple.regular)) { },
                .item("Share", icon: AnyView(Ph.share.regular)) { },
                .destructive("Delete", icon: AnyView(Ph.trash.regular)) { }
            ])

        // Tap-triggered popover menu
        AppPopoverMenu(isPresented: $showPopover, items: [
            .item("Edit", icon: AnyView(Ph.pencilSimple.regular)) { },
            .destructive("Delete", icon: AnyView(Ph.trash.regular)) { }
        ]) {
            Ph.dotsThreeCircle.regular
                .iconSize(.lg)
                .iconColor(.appIconPrimary)
        }
    }
    .padding()
}
