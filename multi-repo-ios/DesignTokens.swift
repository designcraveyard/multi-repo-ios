// DesignTokens.swift
// Auto-synced from Figma "bubbles-kit"
// Layer 1: Primitives  (colorZinc950, colorGreen600, …)   — raw palette
// Layer 2: Semantic    (surfacesBrandInteractive, …)       — NeutralLight / NeutralDark
// DO NOT edit hex values manually — update tokens in Figma, then run /design-token-sync to regenerate.
//
// Usage:
//   .background(Color.surfacesBasePrimary)
//   .foregroundStyle(Color.typographyPrimary)
//   .padding(CGFloat.space4)
//   .font(.appBody)

import SwiftUI

// MARK: - Hex Color Initialiser

private extension Color {
    /// Creates a `Color` from a 6-digit hex string (with or without leading `#`).
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Adaptive (Light / Dark) Helper

private func adaptive(light: String, dark: String) -> Color {
    Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(Color(hex: dark))
            : UIColor(Color(hex: light))
    })
}

// MARK: - LAYER 1: Primitive Color Tokens  (Figma collection: "Primitives")
// Names: colorSlate50, colorZinc950, colorGreen600, …
// These are the raw Tailwind palette values — never use directly in UI code.
// UI code must reference Semantic tokens below.

extension Color {

    // ── Slate ─────────────────────────────────────────────────────────────────
    static let colorSlate50:  Color = Color(hex: "#F8FAFC")
    static let colorSlate100: Color = Color(hex: "#F1F5F9")
    static let colorSlate200: Color = Color(hex: "#E2E8F0")
    static let colorSlate300: Color = Color(hex: "#CBD5E1")
    static let colorSlate400: Color = Color(hex: "#94A3B8")
    static let colorSlate500: Color = Color(hex: "#64748B")
    static let colorSlate600: Color = Color(hex: "#475569")
    static let colorSlate700: Color = Color(hex: "#334155")
    static let colorSlate800: Color = Color(hex: "#1E293B")
    static let colorSlate900: Color = Color(hex: "#0F172A")
    static let colorSlate950: Color = Color(hex: "#020617")

    // ── Zinc ──────────────────────────────────────────────────────────────────
    static let colorZinc50:  Color = Color(hex: "#FAFAFA")
    static let colorZinc100: Color = Color(hex: "#F4F4F5")
    static let colorZinc200: Color = Color(hex: "#E4E4E7")
    static let colorZinc300: Color = Color(hex: "#D4D4D8")
    static let colorZinc400: Color = Color(hex: "#A1A1AA")
    static let colorZinc500: Color = Color(hex: "#71717A")
    static let colorZinc600: Color = Color(hex: "#52525B")
    static let colorZinc700: Color = Color(hex: "#3F3F46")
    static let colorZinc800: Color = Color(hex: "#27272A")
    static let colorZinc900: Color = Color(hex: "#18181B")
    static let colorZinc950: Color = Color(hex: "#09090B")

    // ── Neutral ───────────────────────────────────────────────────────────────
    static let colorNeutral50:  Color = Color(hex: "#FAFAFA")
    static let colorNeutral100: Color = Color(hex: "#F5F5F5")
    static let colorNeutral200: Color = Color(hex: "#E5E5E5")
    static let colorNeutral300: Color = Color(hex: "#D4D4D4")
    static let colorNeutral400: Color = Color(hex: "#A3A3A3")
    static let colorNeutral500: Color = Color(hex: "#737373")
    static let colorNeutral600: Color = Color(hex: "#525252")
    static let colorNeutral700: Color = Color(hex: "#404040")
    static let colorNeutral800: Color = Color(hex: "#262626")
    static let colorNeutral900: Color = Color(hex: "#171717")
    static let colorNeutral950: Color = Color(hex: "#0A0A0A")

    // ── Red ───────────────────────────────────────────────────────────────────
    static let colorRed50:  Color = Color(hex: "#FEF2F2")
    static let colorRed100: Color = Color(hex: "#FEE2E2")
    static let colorRed200: Color = Color(hex: "#FECACA")
    static let colorRed300: Color = Color(hex: "#FCA5A5")
    static let colorRed400: Color = Color(hex: "#F87171")
    static let colorRed500: Color = Color(hex: "#EF4444")
    static let colorRed600: Color = Color(hex: "#DC2626")
    static let colorRed700: Color = Color(hex: "#B91C1C")
    static let colorRed800: Color = Color(hex: "#991B1B")
    static let colorRed900: Color = Color(hex: "#7F1D1D")
    static let colorRed950: Color = Color(hex: "#450A0A")

    // ── Amber ─────────────────────────────────────────────────────────────────
    static let colorAmber50:  Color = Color(hex: "#FFFBEB")
    static let colorAmber100: Color = Color(hex: "#FEF3C7")
    static let colorAmber200: Color = Color(hex: "#FDE68A")
    static let colorAmber300: Color = Color(hex: "#FCD34D")
    static let colorAmber400: Color = Color(hex: "#FBBF24")
    static let colorAmber500: Color = Color(hex: "#F59E0B")
    static let colorAmber600: Color = Color(hex: "#D97706")
    static let colorAmber700: Color = Color(hex: "#B45309")
    static let colorAmber800: Color = Color(hex: "#92400E")
    static let colorAmber900: Color = Color(hex: "#78350F")
    static let colorAmber950: Color = Color(hex: "#431407")

    // ── Green ─────────────────────────────────────────────────────────────────
    static let colorGreen50:  Color = Color(hex: "#F0FDF4")
    static let colorGreen100: Color = Color(hex: "#DCFCE7")
    static let colorGreen200: Color = Color(hex: "#BBF7D0")
    static let colorGreen300: Color = Color(hex: "#86EFAC")
    static let colorGreen400: Color = Color(hex: "#4ADE80")
    static let colorGreen500: Color = Color(hex: "#22C55E")
    static let colorGreen600: Color = Color(hex: "#16A34A")
    static let colorGreen700: Color = Color(hex: "#15803D")
    static let colorGreen800: Color = Color(hex: "#166534")
    static let colorGreen900: Color = Color(hex: "#14532D")
    static let colorGreen950: Color = Color(hex: "#052E16")

    // ── Indigo ────────────────────────────────────────────────────────────────
    static let colorIndigo50:  Color = Color(hex: "#EEF2FF")
    static let colorIndigo100: Color = Color(hex: "#E0E7FF")
    static let colorIndigo200: Color = Color(hex: "#C7D2FE")
    static let colorIndigo300: Color = Color(hex: "#A5B4FC")
    static let colorIndigo400: Color = Color(hex: "#818CF8")
    static let colorIndigo500: Color = Color(hex: "#6366F1")
    static let colorIndigo600: Color = Color(hex: "#4F46E5")
    static let colorIndigo700: Color = Color(hex: "#4338CA")
    static let colorIndigo800: Color = Color(hex: "#3730A3")
    static let colorIndigo900: Color = Color(hex: "#312E81")
    static let colorIndigo950: Color = Color(hex: "#1E1B4B")

    // ── Base ──────────────────────────────────────────────────────────────────
    static let colorBaseBlack: Color = Color(hex: "#000000")
    static let colorBaseWhite: Color = Color(hex: "#FFFFFF")
}

// MARK: - LAYER 2: Semantic Color Tokens  (Figma collection: "Semantic")
// Names match Figma 1:1, camelCased:
//   Surfaces/BrandInteractive  →  surfacesBrandInteractive
//   Typography/OnBrandPrimary  →  typographyOnBrandPrimary
//   Border/Brand               →  borderBrand
//
// Each token uses adaptive(light:dark:) to alias Primitive tokens.

extension Color {

    // ── Surfaces/Base ──────────────────────────────────────────────────────────
    /// Figma: Surfaces/BasePrimary
    static let surfacesBasePrimary               = adaptive(light: "#FFFFFF", dark: "#000000")
    /// Figma: Surfaces/BasePrimaryHover
    static let surfacesBasePrimaryHover          = adaptive(light: "#F5F5F5", dark: "#262626")
    /// Figma: Surfaces/BasePrimaryPressed
    static let surfacesBasePrimaryPressed        = adaptive(light: "#E5E5E5", dark: "#404040")
    /// Figma: Surfaces/BaseLowContrast
    static let surfacesBaseLowContrast           = adaptive(light: "#F5F5F5", dark: "#171717")
    /// Figma: Surfaces/BaseLowContrastHover
    static let surfacesBaseLowContrastHover      = adaptive(light: "#E5E5E5", dark: "#404040")
    /// Figma: Surfaces/BaseLowContrastPressed
    static let surfacesBaseLowContrastPressed    = adaptive(light: "#D4D4D4", dark: "#525252")
    /// Figma: Surfaces/BaseHighContrast
    static let surfacesBaseHighContrast          = adaptive(light: "#E5E5E5", dark: "#262626")
    /// Figma: Surfaces/BaseHighContrastHover
    static let surfacesBaseHighContrastHover     = adaptive(light: "#D4D4D4", dark: "#525252")
    /// Figma: Surfaces/BaseHighContrastPressed
    static let surfacesBaseHighContrastPressed   = adaptive(light: "#A3A3A3", dark: "#737373")

    // ── Surfaces/Inverse ──────────────────────────────────────────────────────
    /// Figma: Surfaces/InversePrimary
    static let surfacesInversePrimary            = adaptive(light: "#000000", dark: "#FFFFFF")
    /// Figma: Surfaces/InversePrimaryHover
    static let surfacesInversePrimaryHover       = adaptive(light: "#27272A", dark: "#E4E4E7")
    /// Figma: Surfaces/InversePrimaryPressed
    static let surfacesInversePrimaryPressed     = adaptive(light: "#52525B", dark: "#A1A1AA")
    /// Figma: Surfaces/InverseLowContrast
    static let surfacesInverseLowContrast        = adaptive(light: "#171717", dark: "#F5F5F5")
    /// Figma: Surfaces/InverseLowContrastHover
    static let surfacesInverseLowContrastHover   = adaptive(light: "#262626", dark: "#E5E5E5")
    /// Figma: Surfaces/InverseLowContrastPressed
    static let surfacesInverseLowContrastPressed = adaptive(light: "#404040", dark: "#D4D4D4")
    /// Figma: Surfaces/InverseHighContrast
    static let surfacesInverseHighContrast       = adaptive(light: "#262626", dark: "#E5E5E5")

    // ── Surfaces/BrandInteractive ─────────────────────────────────────────────
    /// Figma: Surfaces/BrandInteractive
    static let surfacesBrandInteractive                      = adaptive(light: "#09090B", dark: "#FAFAFA")
    /// Figma: Surfaces/BrandInteractiveHover
    static let surfacesBrandInteractiveHover                 = adaptive(light: "#27272A", dark: "#E4E4E7")
    /// Figma: Surfaces/BrandInteractivePressed
    static let surfacesBrandInteractivePressed               = adaptive(light: "#3F3F46", dark: "#A1A1AA")
    /// Figma: Surfaces/BrandInteractiveLowContrast
    static let surfacesBrandInteractiveLowContrast           = adaptive(light: "#E4E4E7", dark: "#27272A")
    /// Figma: Surfaces/BrandInteractiveLowContrastHover
    static let surfacesBrandInteractiveLowContrastHover      = adaptive(light: "#D4D4D8", dark: "#3F3F46")
    /// Figma: Surfaces/BrandInteractiveLowContrastPressed
    static let surfacesBrandInteractiveLowContrastPressed    = adaptive(light: "#A1A1AA", dark: "#52525B")
    /// Figma: Surfaces/BrandInteractiveHighContrast
    static let surfacesBrandInteractiveHighContrast          = adaptive(light: "#D4D4D8", dark: "#3F3F46")
    /// Figma: Surfaces/BrandInteractiveHighContrastHover
    static let surfacesBrandInteractiveHighContrastHover     = adaptive(light: "#A1A1AA", dark: "#52525B")
    /// Figma: Surfaces/BrandInteractiveHighContrastPressed
    static let surfacesBrandInteractiveHighContrastPressed   = adaptive(light: "#71717A", dark: "#71717A")

    // ── Surfaces/Accent ───────────────────────────────────────────────────────
    /// Figma: Surfaces/AccentPrimary
    static let surfacesAccentPrimary             = adaptive(light: "#4F46E5", dark: "#818CF8")
    /// Figma: Surfaces/AccentPrimaryHover
    static let surfacesAccentPrimaryHover        = adaptive(light: "#4338CA", dark: "#A5B4FC")
    /// Figma: Surfaces/AccentPrimaryPressed
    static let surfacesAccentPrimaryPressed      = adaptive(light: "#3730A3", dark: "#C7D2FE")
    /// Figma: Surfaces/AccentLowContrast
    static let surfacesAccentLowContrast         = adaptive(light: "#C7D2FE", dark: "#3730A3")
    /// Figma: Surfaces/AccentHighContrast
    static let surfacesAccentHighContrast        = adaptive(light: "#A5B4FC", dark: "#4338CA")

    // ── Surfaces/Success ──────────────────────────────────────────────────────
    /// Figma: Surfaces/SuccessSolid
    static let surfacesSuccessSolid              = adaptive(light: "#16A34A", dark: "#86EFAC")
    /// Figma: Surfaces/SuccessSolidHover
    static let surfacesSuccessSolidHover         = adaptive(light: "#15803D", dark: "#BBF7D0")
    /// Figma: Surfaces/SuccessSolidPressed
    static let surfacesSuccessSolidPressed       = adaptive(light: "#166534", dark: "#DCFCE7")
    /// Figma: Surfaces/SuccessSubtle
    static let surfacesSuccessSubtle             = adaptive(light: "#DCFCE7", dark: "#052E16")

    // ── Surfaces/Warning ──────────────────────────────────────────────────────
    /// Figma: Surfaces/WarningSolid
    static let surfacesWarningSolid              = adaptive(light: "#D97706", dark: "#FCD34D")
    /// Figma: Surfaces/WarningSubtle
    static let surfacesWarningSubtle             = adaptive(light: "#FEF3C7", dark: "#431407")

    // ── Surfaces/Error ────────────────────────────────────────────────────────
    /// Figma: Surfaces/ErrorSolid
    static let surfacesErrorSolid               = adaptive(light: "#DC2626", dark: "#FCA5A5")
    /// Figma: Surfaces/ErrorSolidHover
    static let surfacesErrorSolidHover          = adaptive(light: "#B91C1C", dark: "#FECACA")
    /// Figma: Surfaces/ErrorSolidPressed
    static let surfacesErrorSolidPressed        = adaptive(light: "#991B1B", dark: "#FEE2E2")
    /// Figma: Surfaces/ErrorSubtle
    static let surfacesErrorSubtle              = adaptive(light: "#FEE2E2", dark: "#450A0A")

    // ── Typography ────────────────────────────────────────────────────────────
    /// Figma: Typography/Primary
    static let typographyPrimary                = adaptive(light: "#0F172A", dark: "#F8FAFC")
    /// Figma: Typography/Secondary
    static let typographySecondary              = adaptive(light: "#334155", dark: "#CBD5E1")
    /// Figma: Typography/Muted
    static let typographyMuted                  = adaptive(light: "#64748B", dark: "#94A3B8")
    /// Figma: Typography/InversePrimary
    static let typographyInversePrimary         = adaptive(light: "#F8FAFC", dark: "#020617")
    /// Figma: Typography/InverseSecondary
    static let typographyInverseSecondary       = adaptive(light: "#CBD5E1", dark: "#334155")
    /// Figma: Typography/InverseMuted
    static let typographyInverseMuted           = adaptive(light: "#64748B", dark: "#64748B")
    /// Figma: Typography/Brand
    static let typographyBrand                  = adaptive(light: "#09090B", dark: "#FAFAFA")
    /// Figma: Typography/OnBrandPrimary
    static let typographyOnBrandPrimary         = adaptive(light: "#FFFFFF", dark: "#000000")
    /// Figma: Typography/Accent
    static let typographyAccent                 = adaptive(light: "#4338CA", dark: "#A5B4FC")
    /// Figma: Typography/Success
    static let typographySuccess                = adaptive(light: "#15803D", dark: "#4ADE80")
    /// Figma: Typography/Warning
    static let typographyWarning                = adaptive(light: "#B45309", dark: "#FBBF24")
    /// Figma: Typography/Error
    static let typographyError                  = adaptive(light: "#B91C1C", dark: "#F87171")
    /// Figma: Typography/White
    static let typographyWhite                  = adaptive(light: "#FFFFFF", dark: "#FFFFFF")
    /// Figma: Typography/Black
    static let typographyBlack                  = adaptive(light: "#000000", dark: "#000000")

    // ── Icons ─────────────────────────────────────────────────────────────────
    /// Figma: Icons/Primary
    static let iconsPrimary                     = adaptive(light: "#020617", dark: "#F8FAFC")
    /// Figma: Icons/Secondary
    static let iconsSecondary                   = adaptive(light: "#475569", dark: "#94A3B8")
    /// Figma: Icons/Muted
    static let iconsMuted                       = adaptive(light: "#94A3B8", dark: "#334155")
    /// Figma: Icons/InversePrimary
    static let iconsInversePrimary              = adaptive(light: "#F8FAFC", dark: "#020617")
    /// Figma: Icons/InverseSecondary
    static let iconsInverseSecondary            = adaptive(light: "#94A3B8", dark: "#475569")
    /// Figma: Icons/InverseMuted
    static let iconsInverseMuted                = adaptive(light: "#1E293B", dark: "#94A3B8")
    /// Figma: Icons/Brand
    static let iconsBrand                       = adaptive(light: "#09090B", dark: "#FAFAFA")
    /// Figma: Icons/OnBrandPrimary
    static let iconsOnBrandPrimary              = adaptive(light: "#F8FAFC", dark: "#020617")
    /// Figma: Icons/Accent
    static let iconsAccent                      = adaptive(light: "#4338CA", dark: "#A5B4FC")
    /// Figma: Icons/Success
    static let iconsSuccess                     = adaptive(light: "#16A34A", dark: "#4ADE80")
    /// Figma: Icons/Warning
    static let iconsWarning                     = adaptive(light: "#F59E0B", dark: "#FBBF24")
    /// Figma: Icons/Error
    static let iconsError                       = adaptive(light: "#EF4444", dark: "#F87171")
    /// Figma: Icons/White
    static let iconsWhite                       = adaptive(light: "#FFFFFF", dark: "#FFFFFF")
    /// Figma: Icons/Black
    static let iconsBlack                       = adaptive(light: "#000000", dark: "#000000")

    // ── Border ────────────────────────────────────────────────────────────────
    /// Figma: Border/Brand
    static let borderBrand                      = adaptive(light: "#09090B", dark: "#FAFAFA")
    /// Figma: Border/Active
    static let borderActive                     = adaptive(light: "#020617", dark: "#F8FAFC")
    /// Figma: Border/Default
    static let borderDefault                    = adaptive(light: "#E5E5E5", dark: "#1E293B")
    /// Figma: Border/Muted
    static let borderMuted                      = adaptive(light: "#F5F5F5", dark: "#0F172A")
    /// Figma: Border/Success
    static let borderSuccess                    = adaptive(light: "#16A34A", dark: "#86EFAC")
    /// Figma: Border/Warning
    static let borderWarning                    = adaptive(light: "#D97706", dark: "#FCD34D")
    /// Figma: Border/Error
    static let borderError                      = adaptive(light: "#DC2626", dark: "#FCA5A5")

    // ── Legacy aliases — keeps existing call-sites compiling ──────────────────
    // These map old app* names to the new semantic names.

    // Surfaces
    static var appSurfaceBasePrimary:              Color { surfacesBasePrimary }
    static var appSurfaceBaseLowContrast:          Color { surfacesBaseLowContrast }
    static var appSurfaceBaseHighContrast:         Color { surfacesBaseHighContrast }
    static var appSurfaceInversePrimary:           Color { surfacesInversePrimary }
    static var appSurfaceInverseLowContrast:       Color { surfacesInverseLowContrast }
    static var appSurfaceInverseHighContrast:      Color { surfacesInverseHighContrast }
    static var appSurfaceBrand:                    Color { surfacesBrandInteractive }
    static var appSurfaceBrandHover:               Color { surfacesBrandInteractiveHover }
    static var appSurfaceBrandPressed:             Color { surfacesBrandInteractivePressed }
    static var appSurfaceBrandLowContrast:         Color { surfacesBrandInteractiveLowContrast }
    static var appSurfaceBrandHighContrast:        Color { surfacesBrandInteractiveHighContrast }
    static var appSurfaceBrandSecondaryPressed:    Color { surfacesBrandInteractiveLowContrastPressed }
    static var appSurfaceAccentPrimary:            Color { surfacesAccentPrimary }
    static var appSurfaceAccentLowContrast:        Color { surfacesAccentLowContrast }
    static var appSurfaceAccentHighContrast:       Color { surfacesAccentHighContrast }
    static var appSurfaceSuccessSolid:             Color { surfacesSuccessSolid }
    static var appSurfaceSuccessHover:             Color { surfacesSuccessSolidHover }
    static var appSurfaceSuccessPressed:           Color { surfacesSuccessSolidPressed }
    static var appSurfaceSuccessSubtle:            Color { surfacesSuccessSubtle }
    static var appSurfaceWarningSolid:             Color { surfacesWarningSolid }
    static var appSurfaceWarningSubtle:            Color { surfacesWarningSubtle }
    static var appSurfaceErrorSolid:               Color { surfacesErrorSolid }
    static var appSurfaceErrorHover:               Color { surfacesErrorSolidHover }
    static var appSurfaceErrorPressed:             Color { surfacesErrorSolidPressed }
    static var appSurfaceErrorSubtle:              Color { surfacesErrorSubtle }
    // Typography
    static var appTextPrimary:                     Color { typographyPrimary }
    static var appTextSecondary:                   Color { typographySecondary }
    static var appTextMuted:                       Color { typographyMuted }
    static var appTextInversePrimary:              Color { typographyInversePrimary }
    static var appTextInverseSecondary:            Color { typographyInverseSecondary }
    static var appTextInverseMuted:                Color { typographyInverseMuted }
    static var appTextBrand:                       Color { typographyBrand }
    static var appTextOnBrandPrimary:              Color { typographyOnBrandPrimary }
    static var appTextAccent:                      Color { typographyAccent }
    static var appTextSuccess:                     Color { typographySuccess }
    static var appTextWarning:                     Color { typographyWarning }
    static var appTextError:                       Color { typographyError }
    // Icons
    static var appIconPrimary:                     Color { iconsPrimary }
    static var appIconSecondary:                   Color { iconsSecondary }
    static var appIconMuted:                       Color { iconsMuted }
    static var appIconInversePrimary:              Color { iconsInversePrimary }
    static var appIconInverseSecondary:            Color { iconsInverseSecondary }
    static var appIconInverseMuted:                Color { iconsInverseMuted }
    static var appIconBrand:                       Color { iconsBrand }
    static var appIconOnBrandPrimary:              Color { iconsOnBrandPrimary }
    static var appIconSuccess:                     Color { iconsSuccess }
    static var appIconWarning:                     Color { iconsWarning }
    static var appIconError:                       Color { iconsError }
    // Border
    static var appBorderDefault:                   Color { borderDefault }
    static var appBorderMuted:                     Color { borderMuted }
    static var appBorderActive:                    Color { borderActive }
    static var appBorderBrand:                     Color { borderBrand }
    static var appBorderSuccess:                   Color { borderSuccess }
    static var appBorderWarning:                   Color { borderWarning }
    static var appBorderError:                     Color { borderError }
    // Other legacy
    static var appBackground:                      Color { surfacesBasePrimary }
    static var appForeground:                      Color { typographyPrimary }
}

// MARK: - Spacing Tokens  (Figma Primitives/Dimensions 4px grid)

extension CGFloat {
    // Numeric scale — use in new code
    static let space1:  CGFloat = 4
    static let space2:  CGFloat = 8
    static let space3:  CGFloat = 12
    static let space4:  CGFloat = 16   // == spaceMD
    static let space5:  CGFloat = 20
    static let space6:  CGFloat = 24   // == spaceLG
    static let space8:  CGFloat = 32   // == spaceXL
    static let space10: CGFloat = 40
    static let space12: CGFloat = 48   // == space2XL
    static let space16: CGFloat = 64
    static let space20: CGFloat = 80
    static let space24: CGFloat = 96
    // Legacy aliases
    static let spaceXS:  CGFloat = 4
    static let spaceSM:  CGFloat = 8
    static let spaceMD:  CGFloat = 16
    static let spaceLG:  CGFloat = 24
    static let spaceXL:  CGFloat = 32
    static let space2XL: CGFloat = 48
}

// MARK: - Radius Tokens  (Figma "Simantic-Dimensions" › Mobile values)
// iOS has no breakpoints — always uses the Mobile tier.
// For pill/capsule shapes use .clipShape(Capsule()) instead of radiusFull.

extension CGFloat {
    static let radiusNone: CGFloat = 0
    static let radiusXS:   CGFloat = 4
    static let radiusSM:   CGFloat = 8
    static let radiusMD:   CGFloat = 12
    static let radiusLG:   CGFloat = 16
    static let radiusXL:   CGFloat = 24
    static let radius2XL:  CGFloat = 32
}

// MARK: - Icon Size Tokens
// Matches Phosphor icon size mapping in CLAUDE.md:
//   xs=12 · sm=16 · md=20 · lg=24 · xl=32

extension CGFloat {
    static let iconSizeXs: CGFloat = 12
    static let iconSizeSm: CGFloat = 16
    static let iconSizeMd: CGFloat = 20
    static let iconSizeLg: CGFloat = 24
    static let iconSizeXl: CGFloat = 32
}

// MARK: - Typography Tokens  (Figma "🎨 Tokens & Styles" page, node 18:577)
// Font family: Inter (Figma) → system default on iOS (closest match).
// Overline tokens require a .tracking() modifier for letter-spacing:
//   .font(.appOverlineSmall).tracking(1)   // 1pt tracking
//   .font(.appOverlineLarge).tracking(2)   // 2pt tracking

extension Font {

    // ── Display ──────────────────────────────────────────────────────────────
    static let appDisplayLarge:  Font = .system(size: 96, weight: .regular)
    static let appDisplayMedium: Font = .system(size: 80, weight: .regular)
    static let appDisplaySmall:  Font = .system(size: 64, weight: .regular)

    // ── Heading ───────────────────────────────────────────────────────────────
    static let appHeadingLarge:  Font = .system(size: 56, weight: .bold)
    static let appHeadingMedium: Font = .system(size: 48, weight: .bold)
    static let appHeadingSmall:  Font = .system(size: 40, weight: .bold)

    // ── Title ─────────────────────────────────────────────────────────────────
    static let appTitleLarge:    Font = .system(size: 28, weight: .bold)
    static let appTitleMedium:   Font = .system(size: 24, weight: .bold)
    static let appTitleSmall:    Font = .system(size: 20, weight: .bold)

    // ── Body ──────────────────────────────────────────────────────────────────
    static let appBodyLarge:     Font = .system(size: 16, weight: .regular)
    static let appBodyMedium:    Font = .system(size: 14, weight: .regular)
    static let appBodySmall:     Font = .system(size: 12, weight: .regular)

    // ── Body Emphasized ───────────────────────────────────────────────────────
    static let appBodyLargeEm:   Font = .system(size: 16, weight: .medium)
    static let appBodyMediumEm:  Font = .system(size: 14, weight: .medium)
    static let appBodySmallEm:   Font = .system(size: 12, weight: .medium)

    // ── CTA (call-to-action / buttons) ────────────────────────────────────────
    static let appCTALarge:      Font = .system(size: 16, weight: .semibold)
    static let appCTAMedium:     Font = .system(size: 14, weight: .semibold)
    static let appCTASmall:      Font = .system(size: 12, weight: .semibold)

    // ── Link ──────────────────────────────────────────────────────────────────
    static let appLinkLarge:     Font = .system(size: 16, weight: .medium)
    static let appLinkMedium:    Font = .system(size: 14, weight: .medium)
    static let appLinkSmall:     Font = .system(size: 12, weight: .medium)

    // ── Caption ───────────────────────────────────────────────────────────────
    static let appCaptionMedium: Font = .system(size: 12, weight: .regular)
    static let appCaptionSmall:  Font = .system(size: 10, weight: .regular)

    // ── Badge ─────────────────────────────────────────────────────────────────
    static let appBadgeMedium:   Font = .system(size: 10, weight: .semibold)
    static let appBadgeSmall:    Font = .system(size:  8, weight: .semibold)

    // ── Overline ──────────────────────────────────────────────────────────────
    // Pair with .tracking(1) or .tracking(2) for Figma letter-spacing.
    static let appOverlineSmall:  Font = .system(size:  8, weight: .bold)
    static let appOverlineMedium: Font = .system(size: 10, weight: .bold)
    static let appOverlineLarge:  Font = .system(size: 12, weight: .bold)

    // ── Legacy aliases — keeps existing call-sites compiling ──────────────────
    /// Alias → appTitleLarge (28pt bold)
    static var appTitle:   Font { appTitleLarge }
    /// Alias → appBodyLarge (16pt regular)
    static var appBody:    Font { appBodyLarge }
    /// Alias → appCaptionMedium (12pt regular)
    static var appCaption: Font { appCaptionMedium }
}
