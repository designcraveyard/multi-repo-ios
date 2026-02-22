// AppActionSheet.swift
// Style source: NativeComponentStyling.swift › NativeActionSheetStyling
//
// Usage:
//   someView.appActionSheet(
//       isPresented: $showActions,
//       title: "Post Options",
//       message: "What would you like to do?",
//       actions: [
//           .default("Edit Post") { editPost() },
//           .destructive("Delete Post") { deletePost() },
//           .cancel()
//       ]
//   )

import SwiftUI

// MARK: - AppActionSheetAction

/// Represents a single button in an action sheet.
public struct AppActionSheetAction {
    let label: String
    let role: ButtonRole?
    let handler: () -> Void

    /// A standard action button (appears in the default system blue color).
    public static func `default`(_ label: String,
                                  handler: @escaping () -> Void) -> AppActionSheetAction {
        AppActionSheetAction(label: label, role: nil, handler: handler)
    }

    /// A destructive action button (iOS renders it in red automatically).
    public static func destructive(_ label: String,
                                    handler: @escaping () -> Void) -> AppActionSheetAction {
        AppActionSheetAction(label: label, role: .destructive, handler: handler)
    }

    /// A cancel button (iOS positions it at the bottom with bold weight).
    public static func cancel(_ label: String = "Cancel",
                               handler: @escaping () -> Void = {}) -> AppActionSheetAction {
        AppActionSheetAction(label: label, role: .cancel, handler: handler)
    }
}

// MARK: - AppActionSheetModifier

/// ViewModifier that presents a confirmationDialog with the provided actions.
private struct AppActionSheetModifier: ViewModifier {

    @Binding var isPresented: Bool
    let title: String
    let message: String?
    let actions: [AppActionSheetAction]

    func body(content: Content) -> some View {
        content
            .confirmationDialog(title, isPresented: $isPresented, titleVisibility: .visible) {
                ForEach(Array(actions.enumerated()), id: \.offset) { _, action in
                    Button(role: action.role, action: action.handler) {
                        Text(action.label)
                    }
                }
            } message: {
                if let message {
                    Text(message)
                        .font(NativeActionSheetStyling.Typography.message)
                }
            }
    }
}

// MARK: - View Extension

extension View {
    /// Presents a styled action sheet (confirmationDialog) over the current view.
    ///
    /// - Parameters:
    ///   - isPresented: Binding that controls visibility.
    ///   - title:       The bold title shown at the top of the action sheet.
    ///   - message:     Optional secondary message shown below the title.
    ///   - actions:     The array of actions to show. Always include a `.cancel()` action.
    public func appActionSheet(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        actions: [AppActionSheetAction]
    ) -> some View {
        modifier(AppActionSheetModifier(
            isPresented: isPresented,
            title: title,
            message: message,
            actions: actions
        ))
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var show = false

    Button("Show Action Sheet") { show = true }
        .appActionSheet(
            isPresented: $show,
            title: "Post Options",
            message: "Choose an action for this post.",
            actions: [
                .default("Edit")    { },
                .destructive("Delete") { },
                .cancel()
            ]
        )
}
