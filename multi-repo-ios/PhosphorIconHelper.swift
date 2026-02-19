/**
 * PhosphorIconHelper.swift
 *
 * SwiftUI convenience layer for Phosphor Icons.
 *
 * Package: https://github.com/phosphor-icons/swift (PhosphorSwift, v2+)
 * Web counterpart: app/components/icons/Icon.tsx  (<Icon name="House" />)
 *
 * ── Usage ──────────────────────────────────────────────────────────────────
 *
 *   // Basic icon (regular weight, 20pt = md)
 *   PhosphorIcon(.house)
 *
 *   // With weight
 *   PhosphorIcon(.heart, weight: .fill)
 *
 *   // With design-token size
 *   PhosphorIcon(.arrowRight, size: .lg)
 *
 *   // With explicit color token
 *   PhosphorIcon(.warning, weight: .bold, size: .sm, color: .appError)
 *
 *   // Accessible icon (adds accessibilityLabel)
 *   PhosphorIcon(.bell, label: "Notifications")
 *
 *   // Using raw Phosphor API (for custom/advanced cases)
 *   Ph.house.regular.color(.appPrimary).frame(width: 24, height: 24)
 *
 * ── Size tokens (mirrors web IconSize) ─────────────────────────────────────
 *   .xs  = 12pt    .sm = 16pt    .md = 20pt (default)
 *   .lg  = 24pt    .xl = 32pt
 *
 * ── Weight tokens ──────────────────────────────────────────────────────────
 *   .thin | .light | .regular (default) | .bold | .fill | .duotone
 *
 * ── Letter-spacing note ────────────────────────────────────────────────────
 *   SwiftUI doesn't bake tracking into a View. When using Overline typography
 *   alongside icons, apply `.tracking(1)` or `.tracking(2)` on the Text node.
 */

import SwiftUI
import PhosphorSwift

// MARK: - Icon Size Token

/// Named size aliases that mirror the web IconSize tokens.
/// xs=12  sm=16  md=20 (default)  lg=24  xl=32
public enum PhosphorIconSize: CGFloat {
    case xs  = 12
    case sm  = 16
    case md  = 20
    case lg  = 24
    case xl  = 32
}

// MARK: - PhosphorIcon View

/// Token-aligned SwiftUI wrapper for Phosphor Icons.
///
/// Mirrors the web `<Icon />` component API so both platforms
/// use the same conceptual interface.
public struct PhosphorIcon: View {

    // ── Stored properties ──────────────────────────────────────────────────

    private let iconName: Ph.IconName
    private let weight:   Ph.IconWeight
    private let size:     CGFloat
    private let color:    Color
    private let label:    String?

    // ── Initialisers ───────────────────────────────────────────────────────

    /// - Parameters:
    ///   - iconName: Phosphor icon name enum value (e.g. `.house`, `.arrowRight`)
    ///   - weight:   Icon weight. Default: `.regular`
    ///   - size:     Token-based size alias. Default: `.md` (20pt)
    ///   - color:    SwiftUI Color. Default: `.primary` (inherits tint)
    ///   - label:    Accessibility label. If `nil`, icon is decorative (hidden from VoiceOver).
    public init(
        _ iconName: Ph.IconName,
        weight: Ph.IconWeight = .regular,
        size:   PhosphorIconSize = .md,
        color:  Color = .primary,
        label:  String? = nil
    ) {
        self.iconName = iconName
        self.weight   = weight
        self.size     = size.rawValue
        self.color    = color
        self.label    = label
    }

    /// Raw-pixel initialiser — use sparingly; prefer token sizes.
    public init(
        _ iconName: Ph.IconName,
        weight:    Ph.IconWeight = .regular,
        rawSize:   CGFloat,
        color:     Color = .primary,
        label:     String? = nil
    ) {
        self.iconName = iconName
        self.weight   = weight
        self.size     = rawSize
        self.color    = color
        self.label    = label
    }

    // ── Body ───────────────────────────────────────────────────────────────

    public var body: some View {
        Ph.icon(iconName, weight: weight)
            .color(color)
            .frame(width: size, height: size)
            .accessibilityLabel(label ?? "")
            .accessibilityHidden(label == nil)
    }
}

// MARK: - Convenience Modifiers

public extension PhosphorIcon {

    /// Change weight while keeping other properties.
    func weight(_ weight: Ph.IconWeight) -> PhosphorIcon {
        PhosphorIcon(iconName, weight: weight, rawSize: size, color: color, label: label)
    }

    /// Change color while keeping other properties.
    func iconColor(_ color: Color) -> PhosphorIcon {
        PhosphorIcon(iconName, weight: weight, rawSize: size, color: color, label: label)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("PhosphorIcon sizes & weights") {
    VStack(spacing: CGFloat.space4) {

        Text("Size tokens").font(.appTitleSmall)

        HStack(spacing: CGFloat.space4) {
            PhosphorIcon(.house, size: .xs)
            PhosphorIcon(.house, size: .sm)
            PhosphorIcon(.house, size: .md)
            PhosphorIcon(.house, size: .lg)
            PhosphorIcon(.house, size: .xl)
        }

        Divider()

        Text("Weight variants").font(.appTitleSmall)

        HStack(spacing: CGFloat.space4) {
            PhosphorIcon(.heart, weight: .thin,     size: .lg)
            PhosphorIcon(.heart, weight: .light,    size: .lg)
            PhosphorIcon(.heart, weight: .regular,  size: .lg)
            PhosphorIcon(.heart, weight: .bold,     size: .lg)
            PhosphorIcon(.heart, weight: .fill,     size: .lg)
            PhosphorIcon(.heart, weight: .duotone,  size: .lg)
        }

        Divider()

        Text("Color tokens").font(.appTitleSmall)

        HStack(spacing: CGFloat.space4) {
            PhosphorIcon(.warning, weight: .fill, size: .lg, color: .appError)
            PhosphorIcon(.checkCircle, weight: .fill, size: .lg, color: .appSuccess)
            PhosphorIcon(.info, weight: .fill, size: .lg, color: .appPrimary)
        }

        Divider()

        Text("Accessible icon").font(.appTitleSmall)
        PhosphorIcon(.bell, size: .lg, label: "Notifications")
    }
    .padding(CGFloat.space6)
}
#endif
