// AppChip.swift
// Figma source: bubbles-kit › node 76:460 "Chips"
//
// Axes: Type(ChipTabs/Filters/SegmentControl) × Size(Small/Medium/Large) × Active(Off/On)
//
// ChipTabs     OFF: surfacesBaseLowContrast bg; ON: surfacesBaseLowContrastPressed + borderActive ring
// Filters      OFF: surfacesBasePrimary + borderDefault; ON: surfacesBasePrimary + borderActive
// SegmentControl: transparent → surfacesBasePrimary + shadow (managed inside SegmentControlBar)
//
// Usage:
//   AppChip(label: "Design", variant: .chipTabs, isActive: true) { }
//   AppChip(label: "iOS", variant: .filters, size: .md, isActive: false) { }

import SwiftUI

// MARK: - Types

public enum AppChipVariant {
    case chipTabs       // tab-style pill chip
    case filters        // filter toggle chip
    case segmentControl // segment inside a SegmentControlBar
}

public enum AppChipSize {
    case sm  // h=24, px=12, py=4,  gap=4
    case md  // h=36, px=16, py=8,  gap=8
    case lg  // h=48, px=20, py=12, gap=8
}

// MARK: - Size Spec

private struct ChipSizeSpec {
    let paddingH: CGFloat
    let paddingV: CGFloat
    let spacing: CGFloat
    let font: Font
    let iconSize: CGFloat
}

private extension AppChipSize {
    var spec: ChipSizeSpec {
        switch self {
        case .sm: return ChipSizeSpec(paddingH: 12, paddingV: 4,  spacing: 4, font: .appCTASmall,  iconSize: .iconSizeSm)
        case .md: return ChipSizeSpec(paddingH: 16, paddingV: 8,  spacing: 8, font: .appCTASmall,  iconSize: .iconSizeSm)
        case .lg: return ChipSizeSpec(paddingH: 20, paddingV: 12, spacing: 8, font: .appCTAMedium, iconSize: .iconSizeMd)
        }
    }
}

// MARK: - AppChip

/// A tappable pill chip matching the Figma "Chips" component (node 76:460).
///
/// Three visual variants:
/// - `chipTabs` -- borderless pill with low-contrast background; active state adds an active border ring.
/// - `filters` -- bordered pill on base-primary background; active state swaps to active border.
/// - `segmentControl` -- transparent by default, elevated white/grey background when active; intended
///   for use inside `AppSegmentControlBar`.
///
/// Supports three sizes (sm/md/lg), optional leading/trailing icons, and a disabled state (0.5 opacity).
/// Haptic feedback (light impact) fires on every tap. Press state is tracked via a zero-distance `DragGesture`.
///
/// **Key properties:** `label`, `variant`, `size`, `isActive`, `leadingIcon`, `trailingIcon`, `isDisabled`
public struct AppChip: View {

    let label: String
    let variant: AppChipVariant
    let size: AppChipSize
    let isActive: Bool
    let leadingIcon: AnyView?
    let trailingIcon: AnyView?
    let isDisabled: Bool
    let action: () -> Void

    @State private var isPressed = false

    public init(
        label: String,
        variant: AppChipVariant = .chipTabs,
        size: AppChipSize = .md,
        isActive: Bool = false,
        leadingIcon: AnyView? = nil,
        trailingIcon: AnyView? = nil,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.variant = variant
        self.size = size
        self.isActive = isActive
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
        self.isDisabled = isDisabled
        self.action = action
    }

    public var body: some View {
        chipContent
            .opacity(isDisabled ? 0.5 : 1.0)
            .allowsHitTesting(!isDisabled)
            .animation(.easeOut(duration: 0.15), value: isPressed)
            .animation(.easeOut(duration: 0.15), value: isActive)
    }

    @ViewBuilder
    private var chipContent: some View {
        let spec = size.spec

        HStack(spacing: spec.spacing) {
            if let icon = leadingIcon {
                icon
                    .frame(width: spec.iconSize, height: spec.iconSize)
                    .foregroundStyle(labelColor)
            }

            Text(label)
                .font(spec.font)
                .foregroundStyle(labelColor)
                .lineLimit(1)

            if let icon = trailingIcon {
                icon
                    .frame(width: spec.iconSize, height: spec.iconSize)
                    .foregroundStyle(labelColor)
            }
        }
        .padding(.horizontal, spec.paddingH)
        .padding(.vertical, spec.paddingV)
        .background(backgroundShape)
        .overlay(borderOverlay)
        .contentShape(hitTestShape)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isPressed { isPressed = true } }
                .onEnded { _ in
                    isPressed = false
                    handleTap()
                }
        )
    }

    // MARK: - Colors

    /// Label and icon color: primary when active, secondary when inactive.
    private var labelColor: Color {
        isActive ? .typographyPrimary : .typographySecondary
    }

    /// Background color resolves based on variant, active state, and press state.
    /// Press state always takes priority, providing immediate visual feedback.
    private var backgroundColor: Color {
        if isPressed {
            switch variant {
            case .chipTabs:
                return .surfacesBaseLowContrastPressed
            case .filters:
                return .surfacesBasePrimaryPressed
            case .segmentControl:
                return isActive ? .surfacesBasePrimaryPressed : .surfacesBaseLowContrast
            }
        }

        switch variant {
        case .chipTabs:
            // Active chipTabs use the pressed surface to appear visually "depressed"
            return isActive ? .surfacesBaseLowContrastPressed : .surfacesBaseLowContrast
        case .filters:
            return .surfacesBasePrimary
        case .segmentControl:
            // SegmentControl: active gets an elevated card surface; inactive is transparent
            return isActive ? .surfacesBasePrimary : .clear
        }
    }

    // MARK: - Shapes

    /// Background shape varies by variant: Capsule for chipTabs/filters, RoundedRectangle
    /// for segmentControl. The active segment gets a subtle drop shadow for elevation.
    @ViewBuilder
    private var backgroundShape: some View {
        switch variant {
        case .chipTabs, .filters:
            Capsule().fill(backgroundColor)
        case .segmentControl:
            RoundedRectangle(cornerRadius: .radiusSM).fill(backgroundColor)
                .shadow(color: isActive ? Color.black.opacity(0.08) : .clear, radius: 2, x: 0, y: 1)
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch variant {
        case .chipTabs:
            if isActive {
                Capsule().strokeBorder(Color.borderActive, lineWidth: 1)
            }
        case .filters:
            Capsule().strokeBorder(isActive ? Color.borderActive : Color.borderDefault, lineWidth: 1)
        case .segmentControl:
            EmptyView()
        }
    }

    private var hitTestShape: some Shape {
        switch variant {
        case .chipTabs, .filters:
            return AnyShape(Capsule())
        case .segmentControl:
            return AnyShape(RoundedRectangle(cornerRadius: .radiusSM))
        }
    }

    private func handleTap() {
        guard !isDisabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        action()
    }
}

// MARK: - AnyShape helper (iOS 16 backport)

/// Type-erased Shape wrapper to allow runtime switching between Capsule and RoundedRectangle
/// in `hitTestShape`. This is the pre-iOS 17 equivalent of the built-in `AnyShape`.
private struct AnyShape: Shape, @unchecked Sendable {
    private let _path: (CGRect) -> Path
    init<S: Shape>(_ shape: S) { _path = { rect in shape.path(in: rect) } }
    func path(in rect: CGRect) -> Path { _path(rect) }
}

// MARK: - Preview

#Preview("Chip Variants") {
    ScrollView {
        VStack(alignment: .leading, spacing: CGFloat.space4) {

            Text("ChipTabs").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
            HStack(spacing: CGFloat.space2) {
                AppChip(label: "Design", variant: .chipTabs, isActive: true) {}
                AppChip(label: "Code", variant: .chipTabs, isActive: false) {}
                AppChip(label: "Preview", variant: .chipTabs, isActive: false) {}
            }

            Text("Filters").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
            HStack(spacing: CGFloat.space2) {
                AppChip(label: "All", variant: .filters, isActive: true) {}
                AppChip(label: "iOS", variant: .filters, isActive: false) {}
                AppChip(label: "Disabled", variant: .filters, isActive: false, isDisabled: true) {}
            }

            Text("SegmentControl").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
            HStack(spacing: 0) {
                AppChip(label: "Week", variant: .segmentControl, isActive: true) {}
                AppChip(label: "Month", variant: .segmentControl, isActive: false) {}
                AppChip(label: "Year", variant: .segmentControl, isActive: false) {}
            }
            .padding(.horizontal, CGFloat.space1)
            .padding(.vertical, 2)
            .background(Color.surfacesBaseLowContrastPressed)
            .clipShape(Capsule())

            Text("Sizes").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
            VStack(alignment: .leading, spacing: CGFloat.space2) {
                AppChip(label: "Small", variant: .chipTabs, size: .sm, isActive: true) {}
                AppChip(label: "Medium", variant: .chipTabs, size: .md, isActive: true) {}
                AppChip(label: "Large", variant: .chipTabs, size: .lg, isActive: true) {}
            }
        }
        .padding(CGFloat.space4)
    }
    .background(Color.surfacesBasePrimary)
}
