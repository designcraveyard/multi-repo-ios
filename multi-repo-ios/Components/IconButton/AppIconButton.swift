// AppIconButton.swift
// Figma source: bubbles-kit › node 76:208 "IconButton Component Set"
//
// ┌─────────────────────────────────────────────────────────────────────────────┐
// │  ALL style values come from DesignTokens.swift — no hardcoded hex/numbers.  │
// │  Color tokens: Color.surfaces*, Color.icons*, Color.border*                 │
// │  Spacing tokens: CGFloat.space* (4px grid)                                  │
// │  Icon size tokens: .iconSizeSm(16) / .iconSizeMd(20) / .iconSizeLg(24)     │
// └─────────────────────────────────────────────────────────────────────────────┘
//
// Usage:
//   AppIconButton(icon: AnyView(Ph.heart.regular), label: "Like") {}
//   AppIconButton(icon: AnyView(Ph.trash.regular), label: "Delete", variant: .danger) {}
//   AppIconButton(icon: AnyView(Ph.plus.regular),  label: "Add",    variant: .secondary, size: .md) {}

import SwiftUI
import PhosphorSwift

// MARK: - Types

/// Visual style of the icon button, matching Figma IconButton component set variants.
public enum AppIconButtonVariant {
    case primary      // Surfaces/BrandInteractive       → icon Icons/OnBrandPrimary
    case secondary    // Surfaces/BrandInteractiveLowContrast → icon Icons/Primary
    case tertiary     // Surfaces/BasePrimary + border    → icon Icons/Primary
    case quarternary  // transparent (no bg/border)       → icon Icons/Primary
    case success      // Surfaces/SuccessSolid            → icon Icons/OnBrandPrimary
    case danger       // Surfaces/ErrorSolid              → icon Icons/OnBrandPrimary
}

/// Size tier, matching Figma IconButton sizes.
public enum AppIconButtonSize {
    case sm  // 24×24 container · icon 16px
    case md  // 36×36 container · icon 20px
    case lg  // 48×48 container · icon 24px
}

// MARK: - Size Spec

private struct IconButtonSizeSpec {
    let containerSize: CGFloat
    let iconSize:      CGFloat
}

private extension AppIconButtonSize {
    var spec: IconButtonSizeSpec {
        switch self {
        case .sm: return IconButtonSizeSpec(containerSize: 24, iconSize: .iconSizeSm)   // 24px / 16px
        case .md: return IconButtonSizeSpec(containerSize: 36, iconSize: .iconSizeMd)   // 36px / 20px
        case .lg: return IconButtonSizeSpec(containerSize: 48, iconSize: .iconSizeLg)   // 48px / 24px
        }
    }
}

// MARK: - Color Spec

private struct IconButtonColorSpec {
    let background:       Color
    let backgroundActive: Color
    let iconColor:        Color
    let border:           Color?
    let hapticStyle:      UIImpactFeedbackGenerator.FeedbackStyle
}

private extension AppIconButtonVariant {
    var colorSpec: IconButtonColorSpec {
        switch self {
        case .primary:
            // Surfaces/BrandInteractive → /BrandInteractivePressed
            // Icons/OnBrandPrimary
            return IconButtonColorSpec(
                background:       .surfacesBrandInteractive,
                backgroundActive: .surfacesBrandInteractivePressed,
                iconColor:        .iconsOnBrandPrimary,
                border:           nil,
                hapticStyle:      .medium
            )
        case .secondary:
            // Surfaces/BrandInteractiveLowContrast → /LowContrastPressed
            // Icons/Primary
            return IconButtonColorSpec(
                background:       .surfacesBrandInteractiveLowContrast,
                backgroundActive: .surfacesBrandInteractiveLowContrastPressed,
                iconColor:        .iconsPrimary,
                border:           nil,
                hapticStyle:      .light
            )
        case .tertiary:
            // Surfaces/BasePrimary → /BasePrimaryPressed
            // Border/Brand · Icons/Primary
            return IconButtonColorSpec(
                background:       .surfacesBasePrimary,
                backgroundActive: .surfacesBasePrimaryPressed,
                iconColor:        .iconsPrimary,
                border:           .borderBrand,
                hapticStyle:      .light
            )
        case .quarternary:
            // Transparent bg → Surfaces/BasePrimaryPressed on press
            // No border · Icons/Primary
            return IconButtonColorSpec(
                background:       .clear,
                backgroundActive: .surfacesBasePrimaryPressed,
                iconColor:        .iconsPrimary,
                border:           nil,
                hapticStyle:      .light
            )
        case .success:
            // Surfaces/SuccessSolid → /SuccessSolidPressed
            // Icons/OnBrandPrimary
            return IconButtonColorSpec(
                background:       .surfacesSuccessSolid,
                backgroundActive: .surfacesSuccessSolidPressed,
                iconColor:        .iconsOnBrandPrimary,
                border:           nil,
                hapticStyle:      .medium
            )
        case .danger:
            // Surfaces/ErrorSolid → /ErrorSolidPressed
            // Icons/OnBrandPrimary
            return IconButtonColorSpec(
                background:       .surfacesErrorSolid,
                backgroundActive: .surfacesErrorSolidPressed,
                iconColor:        .iconsOnBrandPrimary,
                border:           nil,
                hapticStyle:      .rigid
            )
        }
    }
}

// MARK: - AppIconButton

/// Icon-only button matching the Figma "IconButton" component set.
/// Renders a perfectly square, circle-clipped tap target containing a single icon.
/// Haptic feedback fires on every tap; style varies by variant.
///
/// - Parameters:
///   - icon:       The icon to display — pass any `AnyView`, typically `AnyView(Ph.name.weight)`
///   - label:      Accessibility label (not visible; used for VoiceOver)
///   - variant:    Visual style. Default: `.primary`
///   - size:       Size tier (sm/md/lg). Default: `.lg`
///   - isLoading:  Replaces icon with a spinner; disables interaction
///   - isDisabled: Disables interaction; renders at 50% opacity (Figma spec)
///   - action:     Closure called on confirmed tap
public struct AppIconButton: View {

    let icon:        AnyView
    let label:       String
    let variant:     AppIconButtonVariant
    let size:        AppIconButtonSize
    let isLoading:   Bool
    let isDisabled:  Bool
    let action:      () -> Void

    @State private var isPressed = false

    public init(
        icon:        AnyView,
        label:       String,
        variant:     AppIconButtonVariant = .primary,
        size:        AppIconButtonSize    = .lg,
        isLoading:   Bool = false,
        isDisabled:  Bool = false,
        action:      @escaping () -> Void
    ) {
        self.icon       = icon
        self.label      = label
        self.variant    = variant
        self.size       = size
        self.isLoading  = isLoading
        self.isDisabled = isDisabled
        self.action     = action
    }

    private var isInteractionDisabled: Bool { isDisabled || isLoading }

    public var body: some View {
        let spec   = size.spec
        let colors = variant.colorSpec

        buttonContent(spec: spec, colors: colors)
            .opacity(isInteractionDisabled ? 0.5 : 1.0)
            .allowsHitTesting(!isInteractionDisabled)
            .animation(.easeOut(duration: 0.15), value: isPressed)
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private func buttonContent(spec: IconButtonSizeSpec, colors: IconButtonColorSpec) -> some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(colors.iconColor)
                    .scaleEffect(spec.iconSize / .iconSizeMd)
            } else {
                icon
                    .frame(width: spec.iconSize, height: spec.iconSize)
                    .foregroundStyle(colors.iconColor)
            }
        }
        .frame(width: spec.containerSize, height: spec.containerSize)
        .background(isPressed ? colors.backgroundActive : colors.background)
        .clipShape(Circle())
        .overlay(borderOverlay(colors: colors))
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed { isPressed = true }
                }
                .onEnded { _ in
                    isPressed = false
                    handleTap()
                }
        )
    }

    @ViewBuilder
    private func borderOverlay(colors: IconButtonColorSpec) -> some View {
        if let borderColor = colors.border {
            Circle().strokeBorder(borderColor, lineWidth: 1)
        }
    }

    private func handleTap() {
        guard !isInteractionDisabled else { return }
        let generator = UIImpactFeedbackGenerator(style: variant.colorSpec.hapticStyle)
        generator.prepare()
        generator.impactOccurred()
        action()
    }
}

// MARK: - Preview

#Preview("IconButton Variants") {
    ScrollView {
        VStack(alignment: .leading, spacing: .space4) {

            Group {
                Text("Primary").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                HStack(spacing: .space3) {
                    AppIconButton(icon: AnyView(Ph.heart.regular), label: "Like", variant: .primary, size: .lg) {}
                    AppIconButton(icon: AnyView(Ph.heart.regular), label: "Like", variant: .primary, size: .md) {}
                    AppIconButton(icon: AnyView(Ph.heart.regular), label: "Like", variant: .primary, size: .sm) {}
                }
            }

            Divider()

            Group {
                Text("Secondary").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                HStack(spacing: .space3) {
                    AppIconButton(icon: AnyView(Ph.bookmark.regular), label: "Save", variant: .secondary, size: .lg) {}
                    AppIconButton(icon: AnyView(Ph.bookmark.regular), label: "Save", variant: .secondary, size: .md) {}
                    AppIconButton(icon: AnyView(Ph.bookmark.regular), label: "Save", variant: .secondary, size: .sm) {}
                }
            }

            Divider()

            Group {
                Text("Tertiary").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                HStack(spacing: .space3) {
                    AppIconButton(icon: AnyView(Ph.share.regular), label: "Share", variant: .tertiary, size: .lg) {}
                    AppIconButton(icon: AnyView(Ph.share.regular), label: "Share", variant: .tertiary, size: .md) {}
                    AppIconButton(icon: AnyView(Ph.share.regular), label: "Share", variant: .tertiary, size: .sm) {}
                }
            }

            Divider()

            Group {
                Text("Quarternary").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                HStack(spacing: .space3) {
                    AppIconButton(icon: AnyView(Ph.dotsThree.regular), label: "More", variant: .quarternary, size: .lg) {}
                    AppIconButton(icon: AnyView(Ph.dotsThree.regular), label: "More", variant: .quarternary, size: .md) {}
                    AppIconButton(icon: AnyView(Ph.dotsThree.regular), label: "More", variant: .quarternary, size: .sm) {}
                }
            }

            Divider()

            Group {
                Text("Success").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                HStack(spacing: .space3) {
                    AppIconButton(icon: AnyView(Ph.check.regular), label: "Confirm", variant: .success, size: .lg) {}
                    AppIconButton(icon: AnyView(Ph.check.regular), label: "Confirm", variant: .success, size: .md) {}
                    AppIconButton(icon: AnyView(Ph.check.regular), label: "Confirm", variant: .success, size: .sm) {}
                }
            }

            Divider()

            Group {
                Text("Danger").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                HStack(spacing: .space3) {
                    AppIconButton(icon: AnyView(Ph.trash.regular), label: "Delete", variant: .danger, size: .lg) {}
                    AppIconButton(icon: AnyView(Ph.trash.regular), label: "Delete", variant: .danger, size: .md) {}
                    AppIconButton(icon: AnyView(Ph.trash.regular), label: "Delete", variant: .danger, size: .sm) {}
                }
            }

            Divider()

            Group {
                Text("States").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                HStack(spacing: .space3) {
                    AppIconButton(icon: AnyView(Ph.heart.regular), label: "Loading", variant: .primary, isLoading: true) {}
                    AppIconButton(icon: AnyView(Ph.heart.regular), label: "Disabled", variant: .primary, isDisabled: true) {}
                    AppIconButton(icon: AnyView(Ph.trash.regular), label: "Disabled", variant: .danger,  isDisabled: true) {}
                }
            }
        }
        .padding(.space4)
    }
    .background(Color.surfacesBasePrimary)
}
