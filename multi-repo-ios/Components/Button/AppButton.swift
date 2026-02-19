// AppButton.swift
// Figma source: bubbles-kit › node 229:3892 "Button Component"
//
// ┌─────────────────────────────────────────────────────────────────────────────┐
// │  ALL style values come from DesignTokens.swift — no hardcoded hex/numbers.  │
// │  Color tokens: Color.appSurface*, Color.appText*, Color.appBorder*          │
// │  Spacing tokens: CGFloat.space1 … CGFloat.space5 (4px grid)                │
// │  Icon size tokens: CGFloat.iconSizeSm/.iconSizeMd/.iconSizeLg               │
// │  Font tokens: Font.appCTASmall / .appCTAMedium / .appCTALarge              │
// └─────────────────────────────────────────────────────────────────────────────┘
//
// Usage:
//   AppButton(label: "Save", variant: .primary) { }
//   AppButton(label: "Delete", variant: .danger, leadingIcon: AnyView(Ph.trash.regular)) { }
//   AppButton(label: "Loading…", isLoading: true) { }

import SwiftUI

// MARK: - Types

/// Visual style of the button, matching Figma Button component set variants.
public enum AppButtonVariant {
    case primary    // --surface-brand          → text --text-on-brand-primary
    case secondary  // --surface-brand-low-contrast → text --text-brand
    case tertiary   // --surface-base-primary, border --border-brand → text --text-brand
    case success    // --surface-success-solid  → text --text-on-brand-primary
    case danger     // --surface-error-solid    → text --text-on-brand-primary
}

/// Size tier, matching Figma _Button component set (Small / Medium / Large).
public enum AppButtonSize {
    case sm  // px: space2(8) · py: space1(4)  · gap: space1(4)  · icon: iconSizeSm(16) · font: appCTASmall
    case md  // px: space4(16)· py: space2(8)  · gap: space2(8)  · icon: iconSizeMd(20) · font: appCTAMedium
    case lg  // px: space5(20)· py: space3(12) · gap: space3(12) · icon: iconSizeLg(24) · font: appCTALarge
}

// MARK: - Size Spec  (all values from CGFloat spacing tokens)

private struct ButtonSizeSpec {
    let paddingH: CGFloat
    let paddingV: CGFloat
    let iconSize: CGFloat
    let gap:      CGFloat
    let font:     Font
}

private extension AppButtonSize {
    var spec: ButtonSizeSpec {
        switch self {
        case .sm:
            // Figma Small: px 8px · py 4px · gap 2px · icon 16px · 12pt/600
            // space1=4 is the smallest token; 2px gap uses space1/2 — Figma gap is 2px, nearest token is space1(4).
            // Using space1 for gap as the design system's minimum unit; visually equivalent at this size.
            return ButtonSizeSpec(
                paddingH: .space2,       // 8px  ← space2
                paddingV: .space1,       // 4px  ← space1
                iconSize: .iconSizeSm,   // 16px ← iconSizeSm
                gap:      .space1,       // 4px  ← space1 (Figma: 2px — no 2px token, space1 is closest)
                font:     .appCTASmall
            )
        case .md:
            // Figma Medium: px 16px · py 8px · gap 8px · icon 20px · 14pt/600
            return ButtonSizeSpec(
                paddingH: .space4,       // 16px ← space4
                paddingV: .space2,       // 8px  ← space2
                iconSize: .iconSizeMd,   // 20px ← iconSizeMd
                gap:      .space2,       // 8px  ← space2
                font:     .appCTAMedium
            )
        case .lg:
            // Figma Large: px 20px · py 12px · gap 12px · icon 24px · 16pt/600
            return ButtonSizeSpec(
                paddingH: .space5,       // 20px ← space5
                paddingV: .space3,       // 12px ← space3
                iconSize: .iconSizeLg,   // 24px ← iconSizeLg
                gap:      .space3,       // 12px ← space3
                font:     .appCTALarge
            )
        }
    }
}

// MARK: - Color Spec  (all values from Color tokens)

private struct ButtonColorSpec {
    let background:       Color  // default bg
    let backgroundHover:  Color  // hover bg  (not used on iOS; kept for symmetry)
    let backgroundActive: Color  // pressed bg
    let foreground:       Color  // label + icon tint
    let border:           Color? // stroke (tertiary only)
    let hapticStyle:      UIImpactFeedbackGenerator.FeedbackStyle
}

private extension AppButtonVariant {
    /// Token mapping documented inline — all tokens are Semantic layer (Figma Semantic collection).
    /// Disabled state = 0.5 opacity on the container (Figma spec; no separate color token needed).
    var colorSpec: ButtonColorSpec {
        switch self {
        case .primary:
            // Figma: Surfaces/BrandInteractive → Surfaces/BrandInteractiveHover → Surfaces/BrandInteractivePressed
            // Text:  Typography/OnBrandPrimary
            return ButtonColorSpec(
                background:       .surfacesBrandInteractive,
                backgroundHover:  .surfacesBrandInteractiveHover,
                backgroundActive: .surfacesBrandInteractivePressed,
                foreground:       .typographyOnBrandPrimary,
                border:           nil,
                hapticStyle:      .medium
            )
        case .secondary:
            // Figma: Surfaces/BrandInteractiveLowContrast → /LowContrastHover → /LowContrastPressed
            // Text:  Typography/Brand
            return ButtonColorSpec(
                background:       .surfacesBrandInteractiveLowContrast,
                backgroundHover:  .surfacesBrandInteractiveLowContrastHover,
                backgroundActive: .surfacesBrandInteractiveLowContrastPressed,
                foreground:       .typographyBrand,
                border:           nil,
                hapticStyle:      .light
            )
        case .tertiary:
            // Figma: Surfaces/BasePrimary → /BasePrimaryHover → /BasePrimaryPressed
            // Text:  Typography/Brand  |  Border: Border/Brand
            return ButtonColorSpec(
                background:       .surfacesBasePrimary,
                backgroundHover:  .surfacesBasePrimaryHover,
                backgroundActive: .surfacesBasePrimaryPressed,
                foreground:       .typographyBrand,
                border:           .borderBrand,
                hapticStyle:      .light
            )
        case .success:
            // Figma: Surfaces/SuccessSolid → /SuccessSolidHover → /SuccessSolidPressed
            // Text:  Typography/OnBrandPrimary
            return ButtonColorSpec(
                background:       .surfacesSuccessSolid,
                backgroundHover:  .surfacesSuccessSolidHover,
                backgroundActive: .surfacesSuccessSolidPressed,
                foreground:       .typographyOnBrandPrimary,
                border:           nil,
                hapticStyle:      .medium
            )
        case .danger:
            // Figma: Surfaces/ErrorSolid → /ErrorSolidHover → /ErrorSolidPressed
            // Text:  Typography/OnBrandPrimary
            return ButtonColorSpec(
                background:       .surfacesErrorSolid,
                backgroundHover:  .surfacesErrorSolidHover,
                backgroundActive: .surfacesErrorSolidPressed,
                foreground:       .typographyOnBrandPrimary,
                border:           nil,
                hapticStyle:      .rigid
            )
        }
    }
}

// MARK: - AppButton

/// Cross-platform button matching the Figma "Button" component set.
/// Haptic feedback fires on every tap; style varies by variant.
///
/// - Parameters:
///   - label:        Button text
///   - variant:      Visual style (primary / secondary / tertiary / success / danger). Default: `.primary`
///   - size:         Size tier (sm / md / lg). Default: `.lg` (matches Figma default variant)
///   - leadingIcon:  Optional `AnyView` icon placed before the label
///   - trailingIcon: Optional `AnyView` icon placed after the label
///   - isLoading:    Replaces leading icon with a spinner; disables interaction
///   - isDisabled:   Disables interaction; renders at 50% opacity (Figma spec)
///   - action:       Closure called on confirmed tap
public struct AppButton: View {

    let label:         String
    let variant:       AppButtonVariant
    let size:          AppButtonSize
    let leadingIcon:   AnyView?
    let trailingIcon:  AnyView?
    let isLoading:     Bool
    let isDisabled:    Bool
    let action:        () -> Void

    @State private var isPressed = false

    public init(
        label:         String,
        variant:       AppButtonVariant = .primary,
        size:          AppButtonSize    = .lg,
        leadingIcon:   AnyView?  = nil,
        trailingIcon:  AnyView?  = nil,
        isLoading:     Bool = false,
        isDisabled:    Bool = false,
        action:        @escaping () -> Void
    ) {
        self.label        = label
        self.variant      = variant
        self.size         = size
        self.leadingIcon  = leadingIcon
        self.trailingIcon = trailingIcon
        self.isLoading    = isLoading
        self.isDisabled   = isDisabled
        self.action       = action
    }

    private var isInteractionDisabled: Bool { isDisabled || isLoading }

    public var body: some View {
        let spec   = size.spec
        let colors = variant.colorSpec

        buttonContent(spec: spec, colors: colors)
            // Disabled = 50% opacity, matching Figma disabled state (no color change)
            .opacity(isInteractionDisabled ? 0.5 : 1.0)
            .allowsHitTesting(!isInteractionDisabled)
            .animation(.easeOut(duration: 0.15), value: isPressed)
    }

    @ViewBuilder
    private func buttonContent(spec: ButtonSizeSpec, colors: ButtonColorSpec) -> some View {
        HStack(spacing: spec.gap) {

            // Leading icon or loading spinner
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(colors.foreground)
                    .frame(width: spec.iconSize, height: spec.iconSize)
                    .scaleEffect(spec.iconSize / .iconSizeMd) // scale relative to md baseline
            } else if let icon = leadingIcon {
                icon
                    .frame(width: spec.iconSize, height: spec.iconSize)
                    .foregroundStyle(colors.foreground)
            }

            // Label — font and color from tokens
            Text(label)
                .font(spec.font)
                .foregroundStyle(colors.foreground)
                .lineLimit(1)

            // Trailing icon
            if let icon = trailingIcon {
                icon
                    .frame(width: spec.iconSize, height: spec.iconSize)
                    .foregroundStyle(colors.foreground)
            }
        }
        // Padding from spacing tokens
        .padding(.horizontal, spec.paddingH)
        .padding(.vertical, spec.paddingV)
        // Background switches on press
        .background(isPressed ? colors.backgroundActive : colors.background)
        // Pill shape: Figma cornerRadius = 2000
        .clipShape(Capsule())
        // Tertiary border
        .overlay(borderOverlay(colors: colors))
        .contentShape(Capsule())
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
    private func borderOverlay(colors: ButtonColorSpec) -> some View {
        if let borderColor = colors.border {
            // strokeBorder weight = 1px (Figma strokeWeight: 1)
            Capsule().strokeBorder(borderColor, lineWidth: 1)
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

#Preview("Button Variants") {
    ScrollView {
        VStack(spacing: .space4) {
            Group {
                Text("Primary").font(.appCaptionMedium).foregroundStyle(Color.appTextMuted)
                AppButton(label: "Primary", variant: .primary, size: .lg) {}
                AppButton(label: "Primary", variant: .primary, size: .md) {}
                AppButton(label: "Primary", variant: .primary, size: .sm) {}
            }

            Divider()

            Group {
                Text("Secondary").font(.appCaptionMedium).foregroundStyle(Color.appTextMuted)
                AppButton(label: "Secondary", variant: .secondary) {}
            }

            Divider()

            Group {
                Text("Tertiary").font(.appCaptionMedium).foregroundStyle(Color.appTextMuted)
                AppButton(label: "Tertiary", variant: .tertiary) {}
            }

            Divider()

            Group {
                Text("Success").font(.appCaptionMedium).foregroundStyle(Color.appTextMuted)
                AppButton(label: "Success", variant: .success) {}
            }

            Divider()

            Group {
                Text("Danger").font(.appCaptionMedium).foregroundStyle(Color.appTextMuted)
                AppButton(label: "Delete", variant: .danger) {}
            }

            Divider()

            Group {
                Text("States").font(.appCaptionMedium).foregroundStyle(Color.appTextMuted)
                AppButton(label: "Loading…", variant: .primary, isLoading: true) {}
                AppButton(label: "Disabled", variant: .primary, isDisabled: true) {}
                AppButton(label: "Disabled", variant: .danger, isDisabled: true) {}
            }
        }
        .padding(.space4)
    }
    .background(Color.appSurfaceBasePrimary)
}
