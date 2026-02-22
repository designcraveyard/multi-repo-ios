// AppAlertPopup.swift
// Style source: NativeComponentStyling.swift › NativeAlertStyling
//
// Usage:
//   someView.appAlert(
//       isPresented: $showAlert,
//       title: "Delete Item?",
//       message: "This action cannot be undone.",
//       buttons: [
//           .destructive("Delete") { deleteItem() },
//           .cancel()
//       ]
//   )
//
//   // Simple confirmation:
//   someView.appAlert(isPresented: $showConfirm, title: "Saved!",
//                     buttons: [.default("OK")])

import SwiftUI

// MARK: - AppAlertButton

/// Represents a single button in an alert popup.
public struct AppAlertButton {
    let label: String
    let role: ButtonRole?
    let handler: () -> Void

    /// Standard alert button (appears in system blue).
    public static func `default`(_ label: String,
                                  handler: @escaping () -> Void = {}) -> AppAlertButton {
        AppAlertButton(label: label, role: nil, handler: handler)
    }

    /// Destructive alert button (iOS renders it in red automatically).
    public static func destructive(_ label: String,
                                    handler: @escaping () -> Void) -> AppAlertButton {
        AppAlertButton(label: label, role: .destructive, handler: handler)
    }

    /// Cancel button (iOS renders it bold and positions it at the bottom).
    public static func cancel(_ label: String = "Cancel",
                               handler: @escaping () -> Void = {}) -> AppAlertButton {
        AppAlertButton(label: label, role: .cancel, handler: handler)
    }
}

// MARK: - AppAlertModifier

/// ViewModifier that presents a system alert with the provided buttons.
private struct AppAlertModifier: ViewModifier {

    @Binding var isPresented: Bool
    let title: String
    let message: String?
    let buttons: [AppAlertButton]

    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented) {
                ForEach(Array(buttons.enumerated()), id: \.offset) { _, button in
                    Button(button.label, role: button.role, action: button.handler)
                }
            } message: {
                if let message {
                    Text(message)
                        .font(NativeAlertStyling.Typography.message)
                }
            }
    }
}

// MARK: - View Extension

extension View {
    /// Presents a styled system alert over the current view.
    ///
    /// - Parameters:
    ///   - isPresented: Binding that controls alert visibility.
    ///   - title:       The bold alert title.
    ///   - message:     Optional descriptive message below the title.
    ///   - buttons:     The alert buttons. Defaults to a single `.cancel()` dismiss button.
    public func appAlert(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        buttons: [AppAlertButton] = [.cancel()]
    ) -> some View {
        modifier(AppAlertModifier(
            isPresented: isPresented,
            title: title,
            message: message,
            buttons: buttons
        ))
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var showDelete = false
    @Previewable @State var showConfirm = false

    VStack(spacing: 20) {
        Button("Delete Alert")  { showDelete = true }
            .appAlert(
                isPresented: $showDelete,
                title: "Delete Item?",
                message: "This action cannot be undone.",
                buttons: [
                    .destructive("Delete") { },
                    .cancel()
                ]
            )

        Button("Confirm Alert") { showConfirm = true }
            .appAlert(
                isPresented: $showConfirm,
                title: "Changes Saved",
                buttons: [.default("OK")]
            )
    }
}
