// AppToast.swift
// Figma source: bubbles-kit > node 108:4229 "Toast Message"
//
// Variants: default (info), success, warning, error — each with distinct icon, background, and text colors.
// Supports: message, description (subtext), action pill button, trailing icon button, dismiss button.
// All interactive elements trigger haptic feedback (UIImpactFeedbackGenerator light).
//
// Usage:
//   AppToast(message: "Saved!", variant: .success, dismissible: true)
//   AppToast(message: "Done", variant: .default, actionLabel: "View") { viewDetails() }
//   AppToast(message: "Archived", trailingIconButton: ToastTrailingIconButton(
//       icon: AnyView(Image(systemName: "arrow.uturn.backward").resizable().scaledToFit()),
//       action: { undoArchive() }
//   ))
//
// Presentation helper:
//   .toastOverlay(isPresented: $showToast) { AppToast(message: "Done") }

import SwiftUI

// MARK: - Toast Variant

public enum AppToastVariant: Hashable {
    case `default`       // Info icon + message + optional description
    case success         // Check icon, green tint
    case warning         // Warning icon, orange tint
    case error           // Error icon, red tint
}

// MARK: - Toast Trailing Icon Button

public struct ToastTrailingIconButton {
    let icon: AnyView
    let action: () -> Void

    public init(icon: AnyView, action: @escaping () -> Void) {
        self.icon = icon
        self.action = action
    }
}

// MARK: - Toast Spec

private struct ToastSpec {
    let background: Color
    let borderColor: Color
    let iconName: String        // SF Symbol fallback -- in production swap for Ph icon
    let iconColor: Color
    let textColor: Color
    let descColor: Color
    /// Whether description text needs reduced opacity (for onBrand variants)
    let descOpacity: Double
}

// MARK: - Variant Spec Resolution

private func specForVariant(_ variant: AppToastVariant) -> ToastSpec {
    // All variants use inverse (dark in light mode, light in dark mode) background
    switch variant {
    case .default:
        return ToastSpec(
            background: .surfacesInversePrimary,
            borderColor: .clear,
            iconName: "info.circle.fill",
            iconColor: .typographyInversePrimary,
            textColor: .typographyInversePrimary,
            descColor: .typographyInverseSecondary,
            descOpacity: 1.0
        )
    case .success:
        return ToastSpec(
            background: .surfacesInversePrimary,
            borderColor: .clear,
            iconName: "checkmark.circle.fill",
            iconColor: .iconsSuccess,
            textColor: .typographyInversePrimary,
            descColor: .typographyInverseSecondary,
            descOpacity: 1.0
        )
    case .warning:
        return ToastSpec(
            background: .surfacesInversePrimary,
            borderColor: .clear,
            iconName: "exclamationmark.triangle.fill",
            iconColor: .iconsWarning,
            textColor: .typographyInversePrimary,
            descColor: .typographyInverseSecondary,
            descOpacity: 1.0
        )
    case .error:
        return ToastSpec(
            background: .surfacesInversePrimary,
            borderColor: .clear,
            iconName: "xmark.circle.fill",
            iconColor: .iconsError,
            textColor: .typographyInversePrimary,
            descColor: .typographyInverseSecondary,
            descOpacity: 1.0
        )
    }
}

// MARK: - AppToast

/// A notification toast matching the Figma "Toast Message" component (node 108:4229).
///
/// Four semantic variants (default/success/warning/error) each render with an inverse
/// (dark-on-light / light-on-dark) background, a variant-specific status icon, and
/// themed text colors. The toast is a full-width capsule containing:
///   `[status icon] [message + optional description] [Spacer] [action pill?] [trailing icon?] [dismiss X?]`
///
/// All interactive elements (action pill, trailing icon button, dismiss button) fire
/// light haptic feedback on tap.
///
/// Use the `.toastOverlay(isPresented:duration:content:)` modifier to present a toast
/// anchored to the bottom of any view with slide+fade animation and auto-dismiss.
///
/// **Key properties:** `message`, `variant`, `description`, `actionLabel`, `onAction`,
/// `trailingIconButton`, `dismissible`, `onDismiss`
public struct AppToast: View {

    let message: String
    let variant: AppToastVariant
    let description: String?
    let actionLabel: String?
    let onAction: (() -> Void)?
    let trailingIconButton: ToastTrailingIconButton?
    let dismissible: Bool
    let onDismiss: (() -> Void)?

    // MARK: - Properties

    public init(
        message: String,
        variant: AppToastVariant = .default,
        description: String? = nil,
        actionLabel: String? = nil,
        onAction: (() -> Void)? = nil,
        trailingIconButton: ToastTrailingIconButton? = nil,
        dismissible: Bool = false,
        onDismiss: (() -> Void)? = nil
    ) {
        self.message = message
        self.variant = variant
        self.description = description
        self.actionLabel = actionLabel
        self.onAction = onAction
        self.trailingIconButton = trailingIconButton
        self.dismissible = dismissible
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    public var body: some View {
        let spec = specForVariant(variant)

        HStack(alignment: .center, spacing: CGFloat.space3) {
            // --- Status icon (variant-specific)
            Image(systemName: spec.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: .iconSizeSm, height: .iconSizeSm)
                .foregroundStyle(spec.iconColor)

            // --- Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(message)
                    .font(.appBodySmallEm)
                    .foregroundStyle(spec.textColor)
                    .lineLimit(2)
                if let description {
                    Text(description)
                        .font(.appCaptionMedium)
                        .foregroundStyle(spec.descColor.opacity(spec.descOpacity))
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            // --- Action pill button (with haptics)
            if let label = actionLabel, let action = onAction {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    action()
                }) {
                    Text(label)
                        .font(.appCTASmall)
                        .foregroundStyle(spec.textColor)
                        .padding(.horizontal, CGFloat.space3)
                        .padding(.vertical, CGFloat.space1)
                        .background(Color.surfacesBasePrimary.opacity(0.2))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            // --- Trailing icon button (with haptics)
            if let trailingIconButton {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    trailingIconButton.action()
                } label: {
                    trailingIconButton.icon
                        .frame(width: CGFloat.iconSizeMd, height: CGFloat.iconSizeMd)
                        .foregroundStyle(spec.textColor.opacity(0.8))
                }
                .buttonStyle(.plain)
            }

            // --- Dismiss button (with haptics)
            if dismissible {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onDismiss?()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(spec.textColor.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, CGFloat.space5)
        .padding(.vertical, CGFloat.space3)
        .background(
            Capsule()
                .fill(spec.background)
                .overlay(Capsule().strokeBorder(spec.borderColor, lineWidth: 1))
        )
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Toast Overlay Modifier

/// ViewModifier that presents a toast at the bottom of the screen with spring animation.
/// Auto-dismisses after `duration` seconds (default 3s); set duration to 0 to disable.
public struct ToastOverlay<ToastContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let duration: TimeInterval
    let toastContent: () -> ToastContent

    public func body(content: Content) -> some View {
        ZStack {
            content
            if isPresented {
                VStack {
                    Spacer()
                    toastContent()
                        .padding(.horizontal, CGFloat.space4)
                        .padding(.bottom, CGFloat.space8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .onAppear {
                    if duration > 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isPresented = false
                            }
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
    }
}

public extension View {
    func toastOverlay<T: View>(
        isPresented: Binding<Bool>,
        duration: TimeInterval = 3.0,
        @ViewBuilder content: @escaping () -> T
    ) -> some View {
        modifier(ToastOverlay(isPresented: isPresented, duration: duration, toastContent: content))
    }
}

// MARK: - Preview

#Preview("Toast Variants") {
    VStack(spacing: CGFloat.space4) {
        AppToast(message: "Settings saved", variant: .default, description: "Your preferences updated.", dismissible: true)
        AppToast(message: "Upload complete!", variant: .success, description: "Your file is ready to share.")
        AppToast(message: "Connection unstable", variant: .warning, actionLabel: "Retry", onDismiss: {})
        AppToast(message: "Failed to save", variant: .error, description: "Check your connection.", dismissible: true)
        AppToast(
            message: "Item archived",
            variant: .default,
            description: "Moved to trash.",
            trailingIconButton: ToastTrailingIconButton(
                icon: AnyView(Image(systemName: "arrow.uturn.backward").resizable().scaledToFit()),
                action: {}
            )
        )
    }
    .padding(CGFloat.space4)
    .background(Color.appBorderDefault)
}
