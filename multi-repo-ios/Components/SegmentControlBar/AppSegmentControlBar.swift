// AppSegmentControlBar.swift
// Figma source: bubbles-kit › node 81:637 "SegmentControlBar"
//
// Axes: Size(Small/Medium/Large) × Type(SegmentControl/Chips/Filters) = 9
//
// SegmentControl — pill container, animated sliding bg, single-select
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
//   AppSegmentControlBar(items: [...], selectedSet: $filters, type: .filters)

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
    case segmentControl  // pill container, sliding thumb, single-select
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

        HStack(spacing: isSegment ? 0 : CGFloat.space2) {
            ForEach(items) { item in
                segmentButton(item: item, spec: spec)
            }
        }
        .padding(isSegment ? CGFloat.space1 : 0)
        .background(isSegment ? Color.surfacesBaseLowContrastPressed : Color.clear)
        .clipShape(isSegment ? AnyShape(RoundedRectangle(cornerRadius: .radiusMD)) : AnyShape(Rectangle()))
    }

    @ViewBuilder
    private func segmentButton(item: AppSegmentItem, spec: SegmentSizeSpec) -> some View {
        let isActive = item.id == selected
        let isSegment = type == .segmentControl

        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                selected = item.id
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            ZStack {
                // Sliding thumb (SegmentControl only)
                if isSegment && isActive {
                    RoundedRectangle(cornerRadius: .radiusSM)
                        .fill(Color.surfacesBasePrimary)
                        .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                        .matchedGeometryEffect(id: "segmentThumb", in: thumbNamespace)
                }

                Text(item.label)
                    .font(spec.font)
                    .foregroundStyle(labelColor(isActive: isActive))
                    .padding(.horizontal, spec.paddingH)
                    .padding(.vertical, spec.paddingV)
            }
        }
        .buttonStyle(.plain)
        // For chips/filters — apply pill background directly
        .background(chipBackground(isActive: isActive))
        .overlay(chipBorder(isActive: isActive))
        .clipShape(type == .segmentControl ? AnyShape(Rectangle()) : AnyShape(Capsule()))
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }

    private func labelColor(isActive: Bool) -> Color {
        switch type {
        case .segmentControl:
            return isActive ? .typographyPrimary : .typographySecondary
        case .chips:
            return isActive ? .typographyPrimary : .typographySecondary
        case .filters:
            return isActive ? .typographyPrimary : .typographySecondary
        }
    }

    @ViewBuilder
    private func chipBackground(isActive: Bool) -> some View {
        switch type {
        case .segmentControl:
            Color.clear // handled by matchedGeometryEffect thumb above
        case .chips:
            Capsule().fill(isActive ? Color.surfacesBaseLowContrastPressed : Color.surfacesBaseLowContrast)
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

// MARK: - AnyShape helper

private struct AnyShape: Shape {
    private let _path: (CGRect) -> Path
    init<S: Shape>(_ shape: S) { _path = { rect in shape.path(in: rect) } }
    func path(in rect: CGRect) -> Path { _path(rect) }
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
