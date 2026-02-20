// AppToast.swift
// Figma source: bubbles-kit › node 108:4229 "Toast Message"
//
// Variants: Type(Default/Success/Warning/Error/Info) × has-action × has-dismiss
//
// Usage:
//   AppToast(variant: .success, message: "Saved!", dismissible: true)
//   AppToast(variant: .error, message: "Failed", description: "Check your connection", actionLabel: "Retry") { retry() }
//
// Presentation helper:
//   .toastOverlay(isPresented: $showToast) { AppToast(variant: .success, message: "Done") }

import SwiftUI

// MARK: - Types

public enum AppToastVariant {
    case `default`  // inverse bg
    case success
    case warning
    case error
    case info
}

// MARK: - Variant Spec

private struct ToastVariantSpec {
    let background: Color
    let borderColor: Color
    let iconName: String        // SF Symbol fallback — in production swap for Ph icon
    let iconColor: Color
    let textColor: Color
    let descColor: Color
}

private extension AppToastVariant {
    var spec: ToastVariantSpec {
        switch self {
        case .default:
            return ToastVariantSpec(
                background: .surfacesInversePrimary,
                borderColor: .clear,
                iconName: "info.circle.fill",
                iconColor: .typographyInversePrimary,
                textColor: .typographyInversePrimary,
                descColor: .typographyInverseSecondary
            )
        case .success:
            return ToastVariantSpec(
                background: .surfacesSuccessSubtle,
                borderColor: .borderSuccess,
                iconName: "checkmark.circle.fill",
                iconColor: .iconsSuccess,
                textColor: .typographySuccess,
                descColor: .typographySuccess
            )
        case .warning:
            return ToastVariantSpec(
                background: .surfacesWarningSubtle,
                borderColor: .borderWarning,
                iconName: "exclamationmark.triangle.fill",
                iconColor: .iconsWarning,
                textColor: .typographyWarning,
                descColor: .typographyWarning
            )
        case .error:
            return ToastVariantSpec(
                background: .surfacesErrorSubtle,
                borderColor: .borderError,
                iconName: "xmark.circle.fill",
                iconColor: .iconsError,
                textColor: .typographyError,
                descColor: .typographyError
            )
        case .info:
            return ToastVariantSpec(
                background: .surfacesAccentLowContrast,
                borderColor: .surfacesAccentPrimary,
                iconName: "info.circle.fill",
                iconColor: .iconsAccent,
                textColor: .typographyAccent,
                descColor: .typographyAccent
            )
        }
    }
}

// MARK: - AppToast

public struct AppToast: View {

    let variant: AppToastVariant
    let message: String
    let description: String?
    let actionLabel: String?
    let onAction: (() -> Void)?
    let dismissible: Bool
    let onDismiss: (() -> Void)?

    public init(
        variant: AppToastVariant = .default,
        message: String,
        description: String? = nil,
        actionLabel: String? = nil,
        onAction: (() -> Void)? = nil,
        dismissible: Bool = false,
        onDismiss: (() -> Void)? = nil
    ) {
        self.variant = variant
        self.message = message
        self.description = description
        self.actionLabel = actionLabel
        self.onAction = onAction
        self.dismissible = dismissible
        self.onDismiss = onDismiss
    }

    private var isDefault: Bool { variant == .default }

    public var body: some View {
        let spec = variant.spec

        HStack(alignment: isDefault ? .center : .top, spacing: CGFloat.space3) {
            // Status icon
            Image(systemName: spec.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: .iconSizeSm, height: .iconSizeSm)
                .foregroundStyle(spec.iconColor)

            // Content
            if isDefault {
                Text(message)
                    .font(.appBodySmallEm)
                    .foregroundStyle(spec.textColor)
                    .lineLimit(2)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(message)
                        .font(.appBodySmallEm)
                        .foregroundStyle(spec.textColor)
                        .lineLimit(3)

                    if let desc = description {
                        Text(desc)
                            .font(.appBodySmall)
                            .foregroundStyle(spec.descColor.opacity(0.8))
                            .lineLimit(2)
                    }

                    if let label = actionLabel, let action = onAction {
                        Button(action: action) {
                            Text(label)
                                .font(.appCTASmall)
                                .foregroundStyle(spec.textColor)
                                .underline()
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 2)
                    }
                }
            }

            Spacer(minLength: 0)

            // Action pill button (default variant only)
            if isDefault, let label = actionLabel, let action = onAction {
                Button(action: action) {
                    Text(label)
                        .font(.appCTASmall)
                        .foregroundStyle(spec.textColor)
                        .padding(.horizontal, CGFloat.space3)
                        .padding(.vertical, CGFloat.space1)
                        .background(Color.surfacesBasePrimary.opacity(0.9))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            // Dismiss button
            if dismissible {
                Button {
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
        .padding(.leading, isDefault ? CGFloat.space5 : CGFloat.space4)
        .padding(.trailing, isDefault ? CGFloat.space3 : CGFloat.space4)
        .padding(.vertical, CGFloat.space3)
        .background(
            Group {
                if isDefault {
                    Capsule()
                        .fill(spec.background)
                        .overlay(Capsule().strokeBorder(spec.borderColor, lineWidth: 1))
                } else {
                    RoundedRectangle(cornerRadius: .radiusMD)
                        .fill(spec.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: .radiusMD)
                                .strokeBorder(spec.borderColor, lineWidth: 1)
                        )
                }
            }
        )
        .shadow(color: isDefault ? .clear : Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .frame(maxWidth: isDefault ? .infinity : 360)
    }
}

// MARK: - Toast Overlay Modifier

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
    ScrollView {
        VStack(spacing: CGFloat.space4) {
            AppToast(variant: .default, message: "Settings saved", dismissible: true)
            AppToast(variant: .success, message: "Upload complete!", description: "Your file is ready to share.")
            AppToast(variant: .warning, message: "Connection unstable", actionLabel: "Retry") {}
            AppToast(variant: .error, message: "Failed to save", description: "Check your connection and try again.", dismissible: true)
            AppToast(variant: .info, message: "New update available", actionLabel: "Update now") {}
        }
        .padding(CGFloat.space4)
    }
    .background(Color.surfacesBaseHighContrast)
}
