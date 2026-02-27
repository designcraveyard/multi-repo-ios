// AppSegmentControlBar.swift
// Figma source: bubbles-kit › node 81:637 "SegmentControlBar"
//
// Axes: Size(Small/Medium/Large) × Type(SegmentControl/Chips/Filters) = 9
//
// SegmentControl — full-width pill container, equal segments, animated sliding thumb
// Chips          — borderless pill chips, single-select
// Filters        — bordered pill chips, multi-select
//
// Usage (SegmentControl):
//   @State private var selected = "week"
//   AppSegmentControlBar(items: [
//       AppSegmentItem(id: "week",  label: "Week"),
//       AppSegmentItem(id: "month", label: "Month"),
//       AppSegmentItem(id: "year",  label: "Year"),
//   ], selected: $selected)
//
// Usage (Filters / multi-select):
//   @State private var filters: Set<String> = []
//   AppSegmentControlBarMulti(items: [...], selected: $filters)

import SwiftUI

// MARK: - Types

public struct AppSegmentItem: Identifiable {
    public let id: String
    public let label: String

    public init(id: String, label: String) {
        self.id = id
        self.label = label
    }
}

public enum AppSegmentBarType {
    case segmentControl  // full-width pill container, sliding thumb, single-select
    case chips           // borderless pill chips, single-select
    case filters         // bordered pill chips, multi-select
}

public enum AppSegmentBarSize {
    case sm
    case md
    case lg
}

// MARK: - Size Spec

private struct SegmentSizeSpec {
    let paddingH: CGFloat
    let paddingV: CGFloat
    let font: Font
}

private extension AppSegmentBarSize {
    var spec: SegmentSizeSpec {
        switch self {
        case .sm: return SegmentSizeSpec(paddingH: .space2, paddingV: .space1, font: .appCTASmall)
        case .md: return SegmentSizeSpec(paddingH: .space3, paddingV: CGFloat.space1 + 2, font: .appCTAMedium)
        case .lg: return SegmentSizeSpec(paddingH: .space4, paddingV: .space2, font: .appCTALarge)
        }
    }
}

// MARK: - AppSegmentControlBar (single-select)

public struct AppSegmentControlBar: View {

    let items: [AppSegmentItem]
    @Binding var selected: String
    let type: AppSegmentBarType
    let size: AppSegmentBarSize

    @Namespace private var thumbNamespace
    @Environment(\.colorScheme) private var colorScheme

    /// Light mode: white thumb (BasePrimary) for max contrast on grey track.
    /// Dark mode: subtle grey thumb (BaseHighContrast) for elevated appearance.
    private var segmentThumbColor: Color {
        colorScheme == .dark ? Color.surfacesBaseHighContrast : Color.surfacesBasePrimary
    }

    public init(
        items: [AppSegmentItem],
        selected: Binding<String>,
        type: AppSegmentBarType = .segmentControl,
        size: AppSegmentBarSize = .md
    ) {
        self.items = items
        self._selected = selected
        self.type = type
        self.size = size
    }

    public var body: some View {
        let spec = size.spec
        let isSegment = type == .segmentControl

        if isSegment {
            // SegmentControl: full-width, equal segments
            HStack(spacing: 0) {
                ForEach(items) { item in
                    segmentControlButton(item: item, spec: spec)
                }
            }
            // Figma: paddingLeft/Right=4, paddingTop/Bottom=2
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.surfacesBaseLowContrast)
            .clipShape(Capsule())
        } else {
            // Chips/Filters: content-sized pills
            HStack(spacing: CGFloat.space2) {
                ForEach(items) { item in
                    chipFilterButton(item: item, spec: spec)
                }
            }
        }
    }

    // MARK: - SegmentControl button (equal-width, full-stretch)

    @ViewBuilder
    private func segmentControlButton(item: AppSegmentItem, spec: SegmentSizeSpec) -> some View {
        let isActive = item.id == selected

        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selected = item.id
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            ZStack {
                // Sliding thumb — white in light, subtle grey in dark
                if isActive {
                    Capsule()
                        .fill(segmentThumbColor)
                        .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                        .matchedGeometryEffect(id: "segmentThumb", in: thumbNamespace)
                }

                Text(item.label)
                    .font(spec.font)
                    .foregroundStyle(isActive ? Color.typographyPrimary : Color.typographySecondary)
                    .padding(.horizontal, spec.paddingH)
                    .padding(.vertical, spec.paddingV)
                    .frame(maxWidth: .infinity)  // equal segments
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }

    // MARK: - Chips / Filters button (content-sized)

    @ViewBuilder
    private func chipFilterButton(item: AppSegmentItem, spec: SegmentSizeSpec) -> some View {
        let isActive = item.id == selected

        Button {
            withAnimation(.easeOut(duration: 0.15)) {
                selected = item.id
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(item.label)
                .font(spec.font)
                .foregroundStyle(isActive ? Color.typographyPrimary : Color.typographySecondary)
                .padding(.horizontal, spec.paddingH)
                .padding(.vertical, spec.paddingV)
        }
        .buttonStyle(.plain)
        .background(chipBackground(isActive: isActive))
        .overlay(chipBorder(isActive: isActive))
        .clipShape(Capsule())
        .animation(.easeOut(duration: 0.15), value: isActive)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }

    @ViewBuilder
    private func chipBackground(isActive: Bool) -> some View {
        switch type {
        case .segmentControl:
            Color.clear
        case .chips:
            Capsule().fill(isActive ? Color.surfacesBaseLowContrast : Color.surfacesBaseLowContrast)
        case .filters:
            Capsule().fill(Color.surfacesBasePrimary)
        }
    }

    @ViewBuilder
    private func chipBorder(isActive: Bool) -> some View {
        if type == .filters {
            Capsule().strokeBorder(isActive ? Color.borderActive : Color.borderDefault, lineWidth: 1)
        }
    }
}

// MARK: - AppSegmentControlBarMulti (multi-select, Filters)

public struct AppSegmentControlBarMulti: View {

    let items: [AppSegmentItem]
    @Binding var selected: Set<String>
    let size: AppSegmentBarSize

    public init(items: [AppSegmentItem], selected: Binding<Set<String>>, size: AppSegmentBarSize = .md) {
        self.items = items
        self._selected = selected
        self.size = size
    }

    public var body: some View {
        let spec = size.spec

        HStack(spacing: CGFloat.space2) {
            ForEach(items) { item in
                let isActive = selected.contains(item.id)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if isActive { selected.remove(item.id) } else { selected.insert(item.id) }
                } label: {
                    Text(item.label)
                        .font(spec.font)
                        .foregroundStyle(isActive ? Color.typographyPrimary : Color.typographySecondary)
                        .padding(.horizontal, spec.paddingH)
                        .padding(.vertical, spec.paddingV)
                }
                .buttonStyle(.plain)
                .background(
                    Capsule().fill(Color.surfacesBasePrimary)
                )
                .overlay(
                    Capsule().strokeBorder(isActive ? Color.borderActive : Color.borderDefault, lineWidth: 1)
                )
                .animation(.easeOut(duration: 0.15), value: isActive)
                .accessibilityAddTraits(isActive ? [.isSelected] : [])
            }
        }
    }
}

// MARK: - Preview

#Preview("SegmentControlBar") {
    @Previewable @State var segSelected = "week"
    @Previewable @State var chipSelected = "all"
    @Previewable @State var filterSelected: Set<String> = ["ios"]

    ScrollView {
        VStack(alignment: .leading, spacing: CGFloat.space6) {

            Text("SegmentControl (sm)").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
            AppSegmentControlBar(items: [
                AppSegmentItem(id: "week",  label: "Week"),
                AppSegmentItem(id: "month", label: "Month"),
                AppSegmentItem(id: "year",  label: "Year"),
            ], selected: $segSelected, type: .segmentControl, size: .sm)

            Text("SegmentControl (md)").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
            AppSegmentControlBar(items: [
                AppSegmentItem(id: "week",  label: "Week"),
                AppSegmentItem(id: "month", label: "Month"),
                AppSegmentItem(id: "year",  label: "Year"),
            ], selected: $segSelected, type: .segmentControl, size: .md)

            Text("Chips (single-select)").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
            AppSegmentControlBar(items: [
                AppSegmentItem(id: "all",    label: "All"),
                AppSegmentItem(id: "design", label: "Design"),
                AppSegmentItem(id: "code",   label: "Code"),
            ], selected: $chipSelected, type: .chips)

            Text("Filters (multi-select)").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
            AppSegmentControlBarMulti(items: [
                AppSegmentItem(id: "ios",     label: "iOS"),
                AppSegmentItem(id: "android", label: "Android"),
                AppSegmentItem(id: "web",     label: "Web"),
            ], selected: $filterSelected)
        }
        .padding(CGFloat.space4)
    }
    .background(Color.surfacesBasePrimary)
}
