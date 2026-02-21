// AppToast.swift
// Figma source: bubbles-kit › node 108:4229 "Toast Message"
//
// Default variant only: pill-shaped dark toast with info icon, message, optional action button, and dismiss button.
//
// Usage:
//   AppToast(message: "Saved!", dismissible: true)
//   AppToast(message: "Done", actionLabel: "View") { viewDetails() }
//
// Presentation helper:
//   .toastOverlay(isPresented: $showToast) { AppToast(message: "Done") }

import SwiftUI

// MARK: - Default Toast Spec

private struct ToastSpec {
    let background: Color
    let borderColor: Color
    let iconName: String        // SF Symbol fallback — in production swap for Ph icon
    let iconColor: Color
    let textColor: Color
    let descColor: Color
}

private let toastSpec = ToastSpec(
    background: .surfacesInversePrimary,
    borderColor: .clear,
    iconName: "info.circle.fill",
    iconColor: .typographyInversePrimary,
    textColor: .typographyInversePrimary,
    descColor: .typographyInverseSecondary
)

// MARK: - AppToast

public struct AppToast: View {

    let message: String
    let description: String?
    let actionLabel: String?
    let onAction: (() -> Void)?
    let dismissible: Bool
    let onDismiss: (() -> Void)?

    public init(
        message: String,
        description: String? = nil,
        actionLabel: String? = nil,
        onAction: (() -> Void)? = nil,
        dismissible: Bool = false,
        onDismiss: (() -> Void)? = nil
    ) {
        self.message = message
        self.description = description
        self.actionLabel = actionLabel
        self.onAction = onAction
        self.dismissible = dismissible
        self.onDismiss = onDismiss
    }

    public var body: some View {
        let spec = toastSpec

        HStack(alignment: .center, spacing: CGFloat.space3) {
            // Status icon
            Image(systemName: spec.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: .iconSizeSm, height: .iconSizeSm)
                .foregroundStyle(spec.iconColor)

            // Content
            Text(message)
                .font(.appBodySmallEm)
                .foregroundStyle(spec.textColor)
                .lineLimit(2)

            Spacer(minLength: 0)

            // Action pill button
            if let label = actionLabel, let action = onAction {
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
        .padding(.leading, CGFloat.space5)
        .padding(.trailing, CGFloat.space3)
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

#Preview("Toast Default") {
    VStack(spacing: CGFloat.space4) {
        AppToast(message: "Settings saved", dismissible: true)
        AppToast(message: "Upload complete!", actionLabel: "View") {}
    }
    .padding(CGFloat.space4)
    .background(Color.appBorderDefault)
}
