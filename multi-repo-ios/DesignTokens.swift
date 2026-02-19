// DesignTokens.swift
// Auto-synced from Figma "bubbles-kit" › Semantic collection (NeutralLight / NeutralDark)
// DO NOT edit manually — update tokens in Figma, then run /design-token-sync to regenerate.
//
// Usage:
//   .background(Color.appSurfaceBasePrimary)
//   .foregroundStyle(Color.appTextPrimary)
//   .padding(CGFloat.spaceMD)
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

// MARK: - Color Tokens  (Figma Semantic › bubbles-kit)

extension Color {

    // -------------------------------------------------------------------------
    // Surfaces
    // -------------------------------------------------------------------------

    /// Base surface – primary background (white / black)
    static let appSurfaceBasePrimary         = adaptive(light: "#FFFFFF", dark: "#000000")
    /// Base surface – low-contrast (near-white / near-black)
    static let appSurfaceBaseLowContrast     = adaptive(light: "#F5F5F5", dark: "#171717")
    /// Base surface – high-contrast
    static let appSurfaceBaseHighContrast    = adaptive(light: "#E5E5E5", dark: "#262626")

    /// Inverse surface – primary (black / white)
    static let appSurfaceInversePrimary      = adaptive(light: "#000000", dark: "#FFFFFF")
    /// Inverse surface – low-contrast
    static let appSurfaceInverseLowContrast  = adaptive(light: "#171717", dark: "#F5F5F5")
    /// Inverse surface – high-contrast
    static let appSurfaceInverseHighContrast = adaptive(light: "#262626", dark: "#E5E5E5")

    /// Brand surface (zinc-950 / zinc-50)
    static let appSurfaceBrand               = adaptive(light: "#09090B", dark: "#FAFAFA")
    /// Brand surface – low-contrast
    static let appSurfaceBrandLowContrast    = adaptive(light: "#E4E4E7", dark: "#27272A")
    /// Brand surface – high-contrast
    static let appSurfaceBrandHighContrast   = adaptive(light: "#D4D4D8", dark: "#3F3F46")
    /// Brand surface – hover state
    static let appSurfaceBrandHover          = adaptive(light: "#27272A", dark: "#E4E4E7")
    /// Brand surface – pressed state
    static let appSurfaceBrandPressed        = adaptive(light: "#09090B", dark: "#A1A1AA")

    /// Accent surface – primary (indigo-600 / indigo-400)
    static let appSurfaceAccentPrimary       = adaptive(light: "#4F46E5", dark: "#818CF8")
    /// Accent surface – low-contrast
    static let appSurfaceAccentLowContrast   = adaptive(light: "#C7D2FE", dark: "#3730A3")
    /// Accent surface – high-contrast
    static let appSurfaceAccentHighContrast  = adaptive(light: "#A5B4FC", dark: "#4338CA")

    /// Success surface – solid
    static let appSurfaceSuccessSolid        = adaptive(light: "#16A34A", dark: "#86EFAC")
    /// Success surface – subtle
    static let appSurfaceSuccessSubtle       = adaptive(light: "#DCFCE7", dark: "#052E16")
    /// Warning surface – solid
    static let appSurfaceWarningSolid        = adaptive(light: "#D97706", dark: "#FCD34D")
    /// Warning surface – subtle
    static let appSurfaceWarningSubtle       = adaptive(light: "#FEF3C7", dark: "#431407")
    /// Error surface – solid
    static let appSurfaceErrorSolid          = adaptive(light: "#DC2626", dark: "#FCA5A5")
    /// Error surface – subtle
    static let appSurfaceErrorSubtle         = adaptive(light: "#FEE2E2", dark: "#450A0A")

    // -------------------------------------------------------------------------
    // Typography
    // -------------------------------------------------------------------------

    /// Primary text (slate-900 / slate-50)
    static let appTextPrimary                = adaptive(light: "#0F172A", dark: "#F8FAFC")
    /// Secondary text (slate-700 / slate-300)
    static let appTextSecondary              = adaptive(light: "#334155", dark: "#CBD5E1")
    /// Muted text (slate-500 / slate-400)
    static let appTextMuted                  = adaptive(light: "#64748B", dark: "#94A3B8")

    /// Inverse primary text (slate-50 / slate-950)
    static let appTextInversePrimary         = adaptive(light: "#F8FAFC", dark: "#020617")
    /// Inverse secondary text
    static let appTextInverseSecondary       = adaptive(light: "#CBD5E1", dark: "#334155")
    /// Inverse muted text
    static let appTextInverseMuted           = adaptive(light: "#64748B", dark: "#64748B")

    /// Brand text (zinc-950 / zinc-50)
    static let appTextBrand                  = adaptive(light: "#09090B", dark: "#FAFAFA")
    /// Text on brand surface (always white / always black)
    static let appTextOnBrandPrimary         = adaptive(light: "#FFFFFF", dark: "#000000")

    /// Accent text (indigo-600 / indigo-400)
    static let appTextAccent                 = adaptive(light: "#4F46E5", dark: "#818CF8")
    /// Success text
    static let appTextSuccess                = adaptive(light: "#15803D", dark: "#4ADE80")
    /// Warning text
    static let appTextWarning                = adaptive(light: "#B45309", dark: "#FBBF24")
    /// Error text
    static let appTextError                  = adaptive(light: "#B91C1C", dark: "#F87171")

    // -------------------------------------------------------------------------
    // Icons
    // -------------------------------------------------------------------------

    /// Primary icon (slate-950 / slate-50)
    static let appIconPrimary                = adaptive(light: "#020617", dark: "#F8FAFC")
    /// Secondary icon (slate-600 / slate-400)
    static let appIconSecondary              = adaptive(light: "#475569", dark: "#94A3B8")
    /// Muted icon (slate-400 / slate-700)
    static let appIconMuted                  = adaptive(light: "#94A3B8", dark: "#334155")

    /// Inverse primary icon
    static let appIconInversePrimary         = adaptive(light: "#F8FAFC", dark: "#020617")
    /// Inverse secondary icon
    static let appIconInverseSecondary       = adaptive(light: "#94A3B8", dark: "#475569")
    /// Inverse muted icon
    static let appIconInverseMuted           = adaptive(light: "#1E293B", dark: "#94A3B8")

    /// Brand icon (zinc-950 / zinc-50)
    static let appIconBrand                  = adaptive(light: "#09090B", dark: "#FAFAFA")
    /// Icon on brand surface
    static let appIconOnBrandPrimary         = adaptive(light: "#F8FAFC", dark: "#020617")

    /// Success icon
    static let appIconSuccess                = adaptive(light: "#16A34A", dark: "#4ADE80")
    /// Warning icon (amber)
    static let appIconWarning                = adaptive(light: "#F59E0B", dark: "#FBBF24")
    /// Error icon
    static let appIconError                  = adaptive(light: "#EF4444", dark: "#F87171")

    // -------------------------------------------------------------------------
    // Borders
    // -------------------------------------------------------------------------

    /// Default border
    static let appBorderDefault              = adaptive(light: "#E5E5E5", dark: "#1E293B")
    /// Muted border
    static let appBorderMuted                = adaptive(light: "#F5F5F5", dark: "#0F172A")
    /// Active / focused border
    static let appBorderActive               = adaptive(light: "#020617", dark: "#F8FAFC")
    /// Brand border
    static let appBorderBrand                = adaptive(light: "#09090B", dark: "#FAFAFA")
    /// Success border
    static let appBorderSuccess              = adaptive(light: "#16A34A", dark: "#86EFAC")
    /// Warning border
    static let appBorderWarning              = adaptive(light: "#D97706", dark: "#FCD34D")
    /// Error border
    static let appBorderError                = adaptive(light: "#DC2626", dark: "#FCA5A5")

    // -------------------------------------------------------------------------
    // Legacy aliases (keep existing call-sites compiling)
    // -------------------------------------------------------------------------

    /// Alias → appSurfaceBasePrimary
    static var appBackground: Color { appSurfaceBasePrimary }
    /// Alias → appTextPrimary
    static var appForeground: Color { appTextPrimary }
}

// MARK: - Spacing Tokens

extension CGFloat {
    static let spaceXS:  CGFloat = 4
    static let spaceSM:  CGFloat = 8
    static let spaceMD:  CGFloat = 16
    static let spaceLG:  CGFloat = 24
    static let spaceXL:  CGFloat = 32
    static let space2XL: CGFloat = 48
}

// MARK: - Typography Tokens

extension Font {
    /// Large display / page heading — 28pt semibold
    static let appTitle:   Font = .system(size: 28, weight: .semibold)
    /// Standard body copy — 16pt regular
    static let appBody:    Font = .system(size: 16, weight: .regular)
    /// Small caption / label — 12pt regular
    static let appCaption: Font = .system(size: 12, weight: .regular)
}
