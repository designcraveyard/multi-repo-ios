/**
 * PhosphorIconHelper.swift
 *
 * SwiftUI size-token layer for Phosphor Icons.
 *
 * Package: https://github.com/phosphor-icons/swift (PhosphorSwift, v2+)
 * Web counterpart: app/components/icons/Icon.tsx  (<Icon name="House" />)
 *
 * ── How Phosphor Swift works ───────────────────────────────────────────────
 *
 * Icons are accessed as  Ph.<name>.<weight>  — each returns a SwiftUI View
 * (an Image that is already .resizable()).  You then chain .color() and
 * .frame() modifiers to style them.
 *
 * There is no generic "pass a name string" API in the Swift package — the
 * icon name and weight are selected at the call site via static members.
 * This is a deliberate design choice for type-safety and tree-shaking.
 *
 * ── Usage ──────────────────────────────────────────────────────────────────
 *
 *   // Preferred: use PhosphorIconSize tokens for consistent sizing
 *   Ph.house.regular.iconSize(.md)
 *   Ph.heart.fill.iconSize(.lg).iconColor(.appError)
 *   Ph.arrowRight.bold.iconSize(.sm)
 *
 *   // With default color (inherits from environment)
 *   Ph.bell.regular.iconSize(.md)
 *
 *   // Accessible icon: chain .iconAccessibility(label:)
 *   Ph.bell.regular.iconSize(.md).iconAccessibility(label: "Notifications")
 *
 *   // Raw Phosphor API (when you need a custom non-token size)
 *   Ph.house.regular.color(.appIconPrimary).frame(width: 18, height: 18)
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

// MARK: - View extension — sizing and color helpers

public extension View {

    /// Apply a token-based Phosphor icon size.
    /// Use on any  Ph.<name>.<weight>  icon view.
    ///
    ///   Ph.house.regular.iconSize(.md)
    ///   Ph.heart.fill.iconSize(.lg).iconColor(.appError)
    func iconSize(_ size: PhosphorIconSize) -> some View {
        self.frame(width: size.rawValue, height: size.rawValue)
    }

    /// Apply a token-based Phosphor icon size using raw pt value.
    /// Prefer the  `iconSize(_:PhosphorIconSize)`  overload when possible.
    func iconSize(_ pt: CGFloat) -> some View {
        self.frame(width: pt, height: pt)
    }

    /// Apply a color to a Phosphor icon.
    /// Equivalent to `.color()` but discoverable alongside `.iconSize()`.
    ///
    ///   Ph.warning.fill.iconSize(.sm).iconColor(.appError)
    func iconColor(_ color: Color) -> some View {
        self.color(color)
    }

    /// Make a Phosphor icon accessible.
    /// - Parameter label: VoiceOver label. Passing `nil` marks the icon as decorative.
    func iconAccessibility(label: String?) -> some View {
        self
            .accessibilityLabel(label ?? "")
            .accessibilityHidden(label == nil)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Phosphor icon tokens") {
    ScrollView {
        VStack(alignment: .leading, spacing: CGFloat.space6) {

            // ── Size tokens ───────────────────────────────────────────────
            Text("Size tokens").font(.appTitleSmall)

            HStack(spacing: CGFloat.space4) {
                VStack(spacing: CGFloat.space2) {
                    Ph.house.regular.iconSize(.xs)
                    Text("xs").font(.appCaptionSmall)
                }
                VStack(spacing: CGFloat.space2) {
                    Ph.house.regular.iconSize(.sm)
                    Text("sm").font(.appCaptionSmall)
                }
                VStack(spacing: CGFloat.space2) {
                    Ph.house.regular.iconSize(.md)
                    Text("md").font(.appCaptionSmall)
                }
                VStack(spacing: CGFloat.space2) {
                    Ph.house.regular.iconSize(.lg)
                    Text("lg").font(.appCaptionSmall)
                }
                VStack(spacing: CGFloat.space2) {
                    Ph.house.regular.iconSize(.xl)
                    Text("xl").font(.appCaptionSmall)
                }
            }

            Divider()

            // ── Weight variants ───────────────────────────────────────────
            Text("Weight variants").font(.appTitleSmall)

            HStack(spacing: CGFloat.space4) {
                VStack(spacing: CGFloat.space2) {
                    Ph.heart.thin.iconSize(.lg)
                    Text("thin").font(.appCaptionSmall)
                }
                VStack(spacing: CGFloat.space2) {
                    Ph.heart.light.iconSize(.lg)
                    Text("light").font(.appCaptionSmall)
                }
                VStack(spacing: CGFloat.space2) {
                    Ph.heart.regular.iconSize(.lg)
                    Text("regular").font(.appCaptionSmall)
                }
                VStack(spacing: CGFloat.space2) {
                    Ph.heart.bold.iconSize(.lg)
                    Text("bold").font(.appCaptionSmall)
                }
                VStack(spacing: CGFloat.space2) {
                    Ph.heart.fill.iconSize(.lg)
                    Text("fill").font(.appCaptionSmall)
                }
                VStack(spacing: CGFloat.space2) {
                    Ph.heart.duotone.iconSize(.lg)
                    Text("duotone").font(.appCaptionSmall)
                }
            }

            Divider()

            // ── Color tokens ──────────────────────────────────────────────
            Text("Color tokens").font(.appTitleSmall)

            HStack(spacing: CGFloat.space4) {
                Ph.warning.fill.iconSize(.lg).iconColor(.appTextError)
                Ph.checkCircle.fill.iconSize(.lg).iconColor(.appTextSuccess)
                Ph.info.fill.iconSize(.lg).iconColor(.appTextAccent)
            }

            Divider()

            // ── Accessibility ─────────────────────────────────────────────
            Text("Accessible icon").font(.appTitleSmall)
            Ph.bell.regular.iconSize(.lg).iconAccessibility(label: "Notifications")
        }
        .padding(CGFloat.space6)
    }
}
#endif
