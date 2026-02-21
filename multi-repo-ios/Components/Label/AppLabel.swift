// AppLabel.swift
// Figma source: bubbles-kit › node 82:1401 "Label"
//
// Axes: Size (sm | md | lg) × Type (secondaryAction | primaryAction | brandInteractive | information)
//
// Usage:
//   AppLabel(label: "Tag")
//   AppLabel(label: "Verified", size: .lg, type: .primaryAction, leadingIcon: AnyView(Ph.checkCircle.regular.iconSize(.md)))
//   AppLabel(label: "Draft", size: .sm, type: .information, showTrailingIcon: false)

import SwiftUI
import PhosphorSwift

// MARK: - Types

public enum AppLabelSize {
    case sm   // 12px / 16px, gap=2pt
    case md   // 14px / 20px, gap=8pt
    case lg   // 16px / 24px, gap=12pt
}

public enum AppLabelType {
    case secondaryAction   // --typography-secondary
    case primaryAction     // --typography-primary
    case brandInteractive  // --typography-brand
    case information       // --typography-muted
}

// MARK: - AppLabel

public struct AppLabel: View {

    let label: String
    let size: AppLabelSize
    let type: AppLabelType
    let leadingIcon: AnyView?
    let trailingIcon: AnyView?
    let showLeadingIcon: Bool
    let showTrailingIcon: Bool

    public init(
        label: String = "Label",
        size: AppLabelSize = .md,
        type: AppLabelType = .secondaryAction,
        leadingIcon: AnyView? = nil,
        trailingIcon: AnyView? = nil,
        showLeadingIcon: Bool = true,
        showTrailingIcon: Bool = true
    ) {
        self.label = label
        self.size = size
        self.type = type
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
        self.showLeadingIcon = showLeadingIcon
        self.showTrailingIcon = showTrailingIcon
    }

    // ── Computed style properties ──────────────────────────────────────────────

    private var textColor: Color {
        switch type {
        case .secondaryAction:  return Color.typographySecondary
        case .primaryAction:    return Color.typographyPrimary
        case .brandInteractive: return Color.typographyBrand
        case .information:      return Color.typographyMuted
        }
    }

    private var textFont: Font {
        switch size {
        case .sm: return .appBodySmallEm
        case .md: return .appBodyMediumEm
        case .lg: return .appBodyLargeEm
        }
    }

    private var spacing: CGFloat {
        switch size {
        case .sm: return CGFloat.space1 / 2   // 2pt (micro)
        case .md: return CGFloat.space2        // 8pt
        case .lg: return CGFloat.space3        // 12pt
        }
    }

    private var iconToken: PhosphorIconSize {
        switch size {
        case .sm: return .sm    // 16pt
        case .md, .lg: return .lg // 24pt
        }
    }

    // ── Body ──────────────────────────────────────────────────────────────────

    public var body: some View {
        HStack(spacing: spacing) {
            if showLeadingIcon, let leadingIcon {
                leadingIcon
                    .foregroundStyle(textColor)
            }

            Text(label)
                .font(textFont)
                .foregroundStyle(textColor)
                .fixedSize()

            if showTrailingIcon, let trailingIcon {
                trailingIcon
                    .foregroundStyle(textColor)
            }
        }
    }
}

// MARK: - Preview

#Preview("Label") {
    ScrollView {
        VStack(alignment: .leading, spacing: CGFloat.space4) {

            // ── Size × Type grid ──────────────────────────────────────────────
            Group {
                Text("Small").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                HStack(spacing: CGFloat.space3) {
                    AppLabel(label: "Secondary", size: .sm, type: .secondaryAction)
                    AppLabel(label: "Primary", size: .sm, type: .primaryAction)
                    AppLabel(label: "Brand", size: .sm, type: .brandInteractive)
                    AppLabel(label: "Info", size: .sm, type: .information)
                }
            }

            Group {
                Text("Medium").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                HStack(spacing: CGFloat.space3) {
                    AppLabel(label: "Secondary", size: .md, type: .secondaryAction)
                    AppLabel(label: "Primary", size: .md, type: .primaryAction)
                    AppLabel(label: "Brand", size: .md, type: .brandInteractive)
                    AppLabel(label: "Info", size: .md, type: .information)
                }
            }

            Group {
                Text("Large").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                HStack(spacing: CGFloat.space3) {
                    AppLabel(label: "Secondary", size: .lg, type: .secondaryAction)
                    AppLabel(label: "Primary", size: .lg, type: .primaryAction)
                    AppLabel(label: "Brand", size: .lg, type: .brandInteractive)
                    AppLabel(label: "Info", size: .lg, type: .information)
                }
            }

            Divider()

            // ── With icons ────────────────────────────────────────────────────
            Group {
                Text("With icons").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                AppLabel(
                    label: "Verified",
                    size: .lg,
                    type: .primaryAction,
                    leadingIcon: AnyView(Ph.checkCircle.regular.iconSize(.lg))
                )
                AppLabel(
                    label: "USD",
                    size: .md,
                    type: .secondaryAction,
                    trailingIcon: AnyView(Ph.caretDown.regular.iconSize(.md))
                )
                AppLabel(
                    label: "Info",
                    size: .sm,
                    type: .information,
                    leadingIcon: AnyView(Ph.info.regular.iconSize(.sm)),
                    trailingIcon: AnyView(Ph.caretRight.regular.iconSize(.sm))
                )
            }
        }
        .padding(CGFloat.space4)
    }
    .background(Color.surfacesBasePrimary)
}
