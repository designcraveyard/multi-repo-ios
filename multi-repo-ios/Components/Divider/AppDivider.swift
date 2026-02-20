// AppDivider.swift
// Figma source: bubbles-kit › node 95:2092 "Divider"
//
// Axes: Type(SectionDivider/RowDivider) = 2
//
// SectionDivider — visible separator between page sections (border-default)
// RowDivider     — subtle separator between list rows (border-muted)
//
// Usage:
//   AppDivider()                            // row divider (default)
//   AppDivider(type: .section)              // section divider
//   AppDivider(type: .section, label: "or") // labeled section divider
//   AppDivider(orientation: .vertical)      // vertical divider

import SwiftUI

// MARK: - Types

public enum AppDividerType {
    case section  // border-default
    case row      // border-muted
}

public enum AppDividerOrientation {
    case horizontal
    case vertical
}

// MARK: - AppDivider

public struct AppDivider: View {

    let type: AppDividerType
    let orientation: AppDividerOrientation
    let label: String?

    public init(
        type: AppDividerType = .row,
        orientation: AppDividerOrientation = .horizontal,
        label: String? = nil
    ) {
        self.type = type
        self.orientation = orientation
        self.label = label
    }

    private var lineColor: Color {
        type == .section ? .surfacesBaseLowContrast : .surfacesBaseLowContrastPressed
    }

    private var lineHeight: CGFloat {
        type == .section ? 8 : 1
    }

    public var body: some View {
        switch orientation {
        case .vertical:
            Rectangle()
                .fill(lineColor)
                .frame(width: 1)
                .accessibilityHidden(true)

        case .horizontal:
            if let label {
                labeledDivider(label: label)
            } else {
                Rectangle()
                    .fill(lineColor)
                    .frame(height: lineHeight)
                    .accessibilityHidden(true)
            }
        }
    }

    @ViewBuilder
    private func labeledDivider(label: String) -> some View {
        HStack(spacing: CGFloat.space3) {
            Rectangle().fill(lineColor).frame(height: 1)
            Text(label)
                .font(.appCaptionSmall)
                .foregroundStyle(Color.typographyMuted)
                .lineLimit(1)
                .fixedSize()
            Rectangle().fill(lineColor).frame(height: 1)
        }
    }
}

// MARK: - Preview

#Preview("Dividers") {
    VStack(spacing: CGFloat.space6) {

        VStack(alignment: .leading, spacing: CGFloat.space2) {
            Text("Row Divider (default)").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
            Text("Item A").font(.appBodyMedium)
            AppDivider(type: .row)
            Text("Item B").font(.appBodyMedium)
            AppDivider(type: .row)
            Text("Item C").font(.appBodyMedium)
        }

        VStack(alignment: .leading, spacing: CGFloat.space2) {
            Text("Section Divider").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
            AppDivider(type: .section)
        }

        VStack(alignment: .leading, spacing: CGFloat.space2) {
            Text("Labeled Divider").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
            AppDivider(type: .section, label: "or")
        }

        VStack(alignment: .leading, spacing: CGFloat.space2) {
            Text("Vertical Divider").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
            HStack(spacing: CGFloat.space3) {
                Text("Left").font(.appBodyMedium)
                AppDivider(orientation: .vertical).frame(height: 20)
                Text("Right").font(.appBodyMedium)
            }
        }
    }
    .padding(CGFloat.space4)
    .background(Color.surfacesBasePrimary)
}
