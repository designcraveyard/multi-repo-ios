// AppTextBlock.swift
// Figma source: bubbles-kit › node 84:789 "TextBlock"
//
// A vertical typography stack with up to 5 optional text slots:
// overline → title → subtext → body → metadata
//
// Usage:
//   AppTextBlock(title: "Ayurveda Books", subtext: "bought for Anjali at airport")
//   AppTextBlock(overline: "RECENT", title: "Trip to Bali", body: "Some notes here", metadata: "Posted 2d ago")

import SwiftUI

// MARK: - AppTextBlock

/// A vertical typography stack matching the Figma "TextBlock" component (node 84:789).
///
/// Renders up to 5 optional text slots in a consistent typographic hierarchy:
/// 1. **overline** -- uppercased, tracked, muted caption (`appOverlineSmall`).
/// 2. **title** -- primary emphasis text (`appBodyLargeEm`).
/// 3. **subtext** -- secondary line below title, muted (`appBodySmall`).
/// 4. **body** -- main body copy, secondary color (`appBodyMedium`).
/// 5. **metadata** -- footnote-level caption, muted (`appCaptionSmall`).
///
/// The header group (overline + title + subtext) uses tighter `space1` vertical spacing,
/// while the overall block uses `space2` between the header, body, and metadata sections.
///
/// **Key properties:** `overline`, `title`, `subtext`, `bodyText` (init param: `body`), `metadata`
public struct AppTextBlock: View {

    // MARK: - Properties

    /// Overline label — appOverlineSmall + tracking(1), typographyMuted
    let overline: String?
    /// Primary title — appBodyLargeEm, typographyPrimary
    let title: String?
    /// Secondary line below title — appBodySmall, typographyMuted
    let subtext: String?
    /// Main body copy — appBodyMedium, typographySecondary
    let bodyText: String?
    /// Trailing metadata footnote — appCaptionSmall, typographyMuted
    let metadata: String?

    public init(
        overline: String? = nil,
        title: String? = nil,
        subtext: String? = nil,
        body: String? = nil,
        metadata: String? = nil
    ) {
        self.overline = overline
        self.title = title
        self.subtext = subtext
        self.bodyText = body
        self.metadata = metadata
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: .space2) {
            headerStack
            bodyView
            metadataText
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var headerStack: some View {
        let hasHeader = overline != nil || title != nil || subtext != nil
        if hasHeader {
            VStack(alignment: .leading, spacing: .space1) {
                if let overline {
                    Text(overline.uppercased())
                        .font(.appOverlineSmall)
                        .tracking(1)
                        .foregroundStyle(Color.typographyMuted)
                }
                if let title {
                    Text(title)
                        .font(.appBodyLargeEm)
                        .foregroundStyle(Color.typographyPrimary)
                }
                if let subtext {
                    Text(subtext)
                        .font(.appBodySmall)
                        .foregroundStyle(Color.typographyMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var bodyView: some View {
        if let bodyText {
            Text(bodyText)
                .font(.appBodyMedium)
                .foregroundStyle(Color.typographySecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var metadataText: some View {
        if let metadata {
            Text(metadata)
                .font(.appCaptionSmall)
                .foregroundStyle(Color.typographyMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Preview

#Preview("TextBlock") {
    ScrollView {
        VStack(alignment: .leading, spacing: .space6) {

            Text("Title + Subtext").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
            AppTextBlock(title: "Ayurveda Books", subtext: "bought for Anjali at airport")

            Divider()

            Text("All slots").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
            AppTextBlock(
                overline: "RECENT",
                title: "Trip to Bali",
                subtext: "Summer vacation",
                body: "Some description can come here regarding the task",
                metadata: "Posted 2d ago"
            )

            Divider()

            Text("Title only").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
            AppTextBlock(title: "Inbox")

            Divider()

            Text("Body + Metadata only").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
            AppTextBlock(body: "Some description text here.", metadata: "3 days ago")
        }
        .padding(.space4)
    }
    .background(Color.surfacesBasePrimary)
}
