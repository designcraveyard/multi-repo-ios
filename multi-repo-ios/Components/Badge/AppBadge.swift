// AppBadge.swift
// Figma source: bubbles-kit › node 87:1071 "Badge"
//
// Axes: Size(Small/Number/Tiny/Medium) × Subtle(Off/On) × Type(Brand/Success/Error/Accent) = 32
//
// Usage:
//   AppBadge(label: "New", type: .brand)
//   AppBadge(label: "12", size: .number, type: .error)
//   AppBadge(size: .tiny, type: .success)         // dot indicator
//   AppBadge(label: "Beta", type: .accent, subtle: true)

import SwiftUI

// MARK: - Types

public enum AppBadgeSize {
    case tiny    // dot only — 6pt
    case sm      // 16pt height, badge-sm font
    case number  // same as sm, numeric label
    case md      // 20pt height, badge-md font
}

public enum AppBadgeType {
    case brand
    case success
    case error
    case accent
}

// MARK: - Color Spec

private struct BadgeColorSpec {
    let background: Color
    let foreground: Color
}

private extension AppBadgeType {
    func spec(subtle: Bool) -> BadgeColorSpec {
        if subtle {
            switch self {
            case .brand:
                return BadgeColorSpec(background: .surfacesBrandInteractiveLowContrast, foreground: .typographyBrand)
            case .success:
                return BadgeColorSpec(background: .surfacesSuccessSubtle, foreground: .typographySuccess)
            case .error:
                return BadgeColorSpec(background: .surfacesErrorSubtle, foreground: .typographyError)
            case .accent:
                return BadgeColorSpec(background: .surfacesAccentLowContrast, foreground: .typographyAccent)
            }
        } else {
            switch self {
            case .brand:
                return BadgeColorSpec(background: .surfacesBrandInteractive, foreground: .typographyOnBrandPrimary)
            case .success:
                return BadgeColorSpec(background: .surfacesSuccessSolid, foreground: .typographyOnBrandPrimary)
            case .error:
                return BadgeColorSpec(background: .surfacesErrorSolid, foreground: .typographyOnBrandPrimary)
            case .accent:
                return BadgeColorSpec(background: .surfacesAccentPrimary, foreground: .typographyOnBrandPrimary)
            }
        }
    }
}

// MARK: - AppBadge

public struct AppBadge: View {

    let size: AppBadgeSize
    let type: AppBadgeType
    let subtle: Bool
    let label: String?

    public init(
        label: String? = nil,
        size: AppBadgeSize = .md,
        type: AppBadgeType = .brand,
        subtle: Bool = false
    ) {
        self.label = label
        self.size = size
        self.type = type
        self.subtle = subtle
    }

    /// Convenience init for numeric badges
    public init(
        count: Int,
        size: AppBadgeSize = .number,
        type: AppBadgeType = .brand,
        subtle: Bool = false
    ) {
        self.label = "\(count)"
        self.size = size
        self.type = type
        self.subtle = subtle
    }

    private var spec: BadgeColorSpec { type.spec(subtle: subtle) }

    public var body: some View {
        if size == .tiny {
            Circle()
                .fill(spec.background)
                .frame(width: 4, height: 4)
                .accessibilityHidden(true)
        } else {
            Text(label ?? "")
                .font(size == .md ? .appBadgeMedium : .appBadgeSmall)
                .foregroundStyle(spec.foreground)
                .lineLimit(1)
                .padding(.horizontal, size == .md ? 6 : 4)
                .frame(minWidth: size == .md ? 16 : 14, minHeight: size == .md ? 16 : 14)
                .background(spec.background)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Preview

#Preview("Badge") {
    VStack(alignment: .leading, spacing: CGFloat.space4) {
        Text("Solid").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
        HStack(spacing: CGFloat.space2) {
            AppBadge(label: "Brand",   type: .brand)
            AppBadge(label: "Success", type: .success)
            AppBadge(label: "Error",   type: .error)
            AppBadge(label: "Accent",  type: .accent)
        }

        Text("Subtle").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
        HStack(spacing: CGFloat.space2) {
            AppBadge(label: "Brand",   type: .brand,   subtle: true)
            AppBadge(label: "Success", type: .success, subtle: true)
            AppBadge(label: "Error",   type: .error,   subtle: true)
            AppBadge(label: "Accent",  type: .accent,  subtle: true)
        }

        Text("Number / Tiny").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
        HStack(spacing: CGFloat.space2) {
            AppBadge(count: 3,  type: .brand)
            AppBadge(count: 12, type: .error)
            AppBadge(count: 99, type: .success)
            AppBadge(size: .tiny, type: .brand)
            AppBadge(size: .tiny, type: .error)
            AppBadge(size: .tiny, type: .success)
        }

        Text("Small").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
        HStack(spacing: CGFloat.space2) {
            AppBadge(label: "New", size: .sm, type: .brand)
            AppBadge(label: "Beta", size: .sm, type: .accent, subtle: true)
        }
    }
    .padding(CGFloat.space4)
    .background(Color.surfacesBasePrimary)
}
