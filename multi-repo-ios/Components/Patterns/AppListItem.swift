// AppListItem.swift
// Figma source: bubbles-kit › "ListItem" (composed pattern)
//
// Horizontal row: optional leading Thumbnail + TextBlock content (title required)
// + optional trailing action (button | iconButton | badge) + optional divider below.
// Display-only with optional tap actions on trailing slot.
//
// Usage:
//   AppListItem(title: "Ayurveda Books", subtitle: "bought for Anjali at airport")
//   AppListItem(
//     title: "Pack luggage",
//     thumbnail: AppThumbnailConfig(url: someURL),
//     trailing: .badge(label: "New", type: .brand)
//   )
//   AppListItem(title: "Depart", subtitle: "Flight at 08:00", trailing: .button(label: "Edit") { })

import PhosphorSwift
import SwiftUI

// MARK: - Types

/// Configuration for the leading thumbnail slot.
public struct AppThumbnailConfig {
    /// Remote image URL (nil = placeholder silhouette)
    public let url: URL?
    /// Accessibility description for the image
    public let accessibilityLabel: String?
    public let size: AppThumbnailSize
    public let rounded: Bool

    public init(
        url: URL? = nil,
        accessibilityLabel: String? = nil,
        size: AppThumbnailSize = .sm,
        rounded: Bool = false
    ) {
        self.url = url
        self.accessibilityLabel = accessibilityLabel
        self.size = size
        self.rounded = rounded
    }
}

/// Trailing slot — one of: a button, an icon button, a badge, radio, checkbox, switch, or nothing.
public enum AppListItemTrailing {
    case button(
        label: String,
        variant: AppButtonVariant = .secondary,
        size: AppButtonSize = .sm,
        action: () -> Void
    )
    case iconButton(
        icon: AnyView,
        accessibilityLabel: String,
        variant: AppIconButtonVariant = .quarternary,
        action: () -> Void
    )
    case badge(
        label: String,
        type: AppBadgeType = .brand,
        subtle: Bool = false
    )
    case radio(
        checked: Bool,
        onChange: (Bool) -> Void
    )
    case checkbox(
        checked: Bool,
        indeterminate: Bool = false,
        onChange: (Bool) -> Void
    )
    case toggle(
        checked: Bool,
        onChange: (Bool) -> Void
    )
}

// MARK: - AppListItem

public struct AppListItem: View {

    // MARK: - Properties

    let title: String
    let subtitle: String?
    /// Main body copy — maps to TextBlock body slot.
    let bodyText: String?
    let metadata: String?
    let thumbnail: AppThumbnailConfig?
    let trailing: AppListItemTrailing?
    let divider: Bool

    public init(
        title: String,
        subtitle: String? = nil,
        body: String? = nil,
        metadata: String? = nil,
        thumbnail: AppThumbnailConfig? = nil,
        trailing: AppListItemTrailing? = nil,
        divider: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.bodyText = body
        self.metadata = metadata
        self.thumbnail = thumbnail
        self.trailing = trailing
        self.divider = divider
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: .space3) {
                leadingThumbnail
                textContent
                trailingSlot
            }
            .padding(.vertical, .space3)

            if divider {
                AppDivider()
            }
        }
    }

    // MARK: - Helpers

    /// Returns true when the trailing selection control is in a selected/on state,
    /// or when the trailing is a non-selection type (button, badge, icon) — those
    /// always render the title with emphasis.
    private var isTrailingSelected: Bool {
        guard let trailing else { return true }
        switch trailing {
        case .radio(let checked, _):             return checked
        case .checkbox(let checked, _, _):       return checked
        case .toggle(let checked, _):            return checked
        default:                                 return true
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var leadingThumbnail: some View {
        if let thumbnail {
            AppThumbnail(
                url: thumbnail.url,
                size: thumbnail.size,
                rounded: thumbnail.rounded
            ) {
                EmptyView()
            }
            .accessibilityLabel(thumbnail.accessibilityLabel ?? "")
        }
    }

    private var textContent: some View {
        // Title font steps up to appBodyLargeEm (medium weight) when the trailing
        // selection control is active; falls back to appBodyLarge (regular) when off.
        VStack(alignment: .leading, spacing: .space1) {
            Text(title)
                .font(isTrailingSelected ? .appBodyLargeEm : .appBodyLarge)
                .foregroundStyle(Color.typographyPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.appBodySmall)
                    .foregroundStyle(Color.typographyMuted)
            }
            if let bodyText {
                Text(bodyText)
                    .font(.appBodyMedium)
                    .foregroundStyle(Color.typographySecondary)
            }
            if let metadata {
                Text(metadata)
                    .font(.appCaptionSmall)
                    .foregroundStyle(Color.typographyMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var trailingSlot: some View {
        if let trailing {
            switch trailing {
            case let .button(label, variant, size, action):
                AppButton(label: label, variant: variant, size: size, action: action)

            case let .iconButton(icon, accessibilityLabel, variant, action):
                AppIconButton(icon: icon, label: accessibilityLabel, variant: variant) {
                    action()
                }

            case let .badge(label, type, subtle):
                AppBadge(label: label, type: type, subtle: subtle)

            case let .radio(checked, onChange):
                AppRadioButton(checked: checked, onChange: onChange)

            case let .checkbox(checked, indeterminate, onChange):
                AppCheckbox(checked: checked, indeterminate: indeterminate, onChange: onChange)

            case let .toggle(checked, onChange):
                AppSwitch(checked: checked, onChange: onChange)
            }
        }
    }
}

// MARK: - Preview

#Preview("ListItem") {
    ScrollView {
        VStack(alignment: .leading, spacing: 0) {

            Text("Title only").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                .padding(.horizontal, .space4).padding(.top, .space4)
            AppListItem(title: "Plain row", divider: true)
                .padding(.horizontal, .space4)

            Text("With subtitle").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                .padding(.horizontal, .space4).padding(.top, .space4)
            AppListItem(
                title: "Ayurveda Books",
                subtitle: "bought for Anjali at airport",
                divider: true
            )
            .padding(.horizontal, .space4)

            Text("Thumbnail + badge trailing").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                .padding(.horizontal, .space4).padding(.top, .space4)
            AppListItem(
                title: "Pack luggage",
                subtitle: "Ready for the trip",
                thumbnail: AppThumbnailConfig(size: .sm),
                trailing: .badge(label: "New", type: .brand),
                divider: true
            )
            .padding(.horizontal, .space4)

            Text("Button trailing").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                .padding(.horizontal, .space4).padding(.top, .space4)
            AppListItem(
                title: "Depart",
                subtitle: "Flight at 08:00",
                trailing: .button(label: "Edit", action: {})
            )
            .padding(.horizontal, .space4)

            Text("IconButton trailing").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                .padding(.horizontal, .space4).padding(.top, .space4)
            AppListItem(
                title: "Trip to Bali",
                subtitle: "Summer vacation",
                body: "Remember to pack sunscreen and the camera.",
                trailing: .iconButton(
                    icon: AnyView(Ph.dotsThree.regular.iconSize(.md)),
                    accessibilityLabel: "More options",
                    action: {}
                )
            )
            .padding(.horizontal, .space4)
        }
    }
    .background(Color.surfacesBasePrimary)
}
