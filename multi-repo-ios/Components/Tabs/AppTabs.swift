// AppTabs.swift
// Figma source: bubbles-kit › node 76:660 (_Tabs tab item) + node 78:284 (Tabs bar)
//
// Axes: Size(Small/Medium/Large) × Active(Off/On)
// The animated indicator slides under the active tab using matchedGeometryEffect.
//
// Usage:
//   @State private var activeTab = "design"
//   AppTabs(items: [
//       AppTabItem(id: "design", label: "Design"),
//       AppTabItem(id: "code",   label: "Code"),
//   ], activeTab: $activeTab)

import SwiftUI

// MARK: - Types

public struct AppTabItem: Identifiable {
    public let id: String
    public let label: String
    public let icon: AnyView?

    public init(id: String, label: String, icon: AnyView? = nil) {
        self.id = id
        self.label = label
        self.icon = icon
    }
}

public enum AppTabSize {
    case sm  // cta-sm, py 4pt, px 8pt
    case md  // cta-md, py 8pt, px 12pt
    case lg  // cta-lg, py 8pt, px 16pt
}

// MARK: - Size Spec

private struct TabSizeSpec {
    let paddingH: CGFloat
    let paddingV: CGFloat
    let font: Font
    let iconSize: CGFloat
    let indicatorHeight: CGFloat
}

private extension AppTabSize {
    var spec: TabSizeSpec {
        switch self {
        case .sm:
            return TabSizeSpec(paddingH: .space2, paddingV: .space1, font: .appCTASmall, iconSize: .iconSizeSm, indicatorHeight: 2)
        case .md:
            return TabSizeSpec(paddingH: .space3, paddingV: .space2, font: .appCTAMedium, iconSize: .iconSizeSm, indicatorHeight: 2)
        case .lg:
            return TabSizeSpec(paddingH: .space4, paddingV: .space2, font: .appCTALarge, iconSize: .iconSizeMd, indicatorHeight: 2)
        }
    }
}

// MARK: - AppTabs

public struct AppTabs: View {

    let items: [AppTabItem]
    @Binding var activeTab: String
    let size: AppTabSize

    @Namespace private var indicatorNamespace

    public init(items: [AppTabItem], activeTab: Binding<String>, size: AppTabSize = .md) {
        self.items = items
        self._activeTab = activeTab
        self.size = size
    }

    public var body: some View {
        let spec = size.spec

        VStack(spacing: 0) {
            // ── Tab row ──────────────────────────────────────────────────────
            HStack(spacing: 0) {
                ForEach(items) { item in
                    tabButton(item: item, spec: spec)
                }
            }
            .overlay(alignment: .bottom) {
                // Bottom border (full width, always visible)
                Rectangle()
                    .fill(Color.borderDefault)
                    .frame(height: 1)
            }
        }
    }

    // MARK: - Tab Button

    @ViewBuilder
    private func tabButton(item: AppTabItem, spec: TabSizeSpec) -> some View {
        let isActive = item.id == activeTab

        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                activeTab = item.id
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: CGFloat.space1) {
                    if let icon = item.icon {
                        icon
                            .frame(width: spec.iconSize, height: spec.iconSize)
                            .foregroundStyle(isActive ? Color.typographyPrimary : Color.typographySecondary)
                    }

                    Text(item.label)
                        .font(spec.font)
                        .foregroundStyle(isActive ? Color.typographyPrimary : Color.typographySecondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, spec.paddingH)
                .padding(.vertical, spec.paddingV)
                .animation(.easeOut(duration: 0.15), value: isActive)

                // ── Sliding indicator ────────────────────────────────────────
                // matchedGeometryEffect moves the indicator bar smoothly between tabs
                ZStack {
                    // Transparent spacer always takes up the indicator height
                    Rectangle().fill(Color.clear).frame(height: spec.indicatorHeight)

                    if isActive {
                        Rectangle()
                            .fill(Color.surfacesBrandInteractive)
                            .frame(height: spec.indicatorHeight)
                            .matchedGeometryEffect(id: "tabIndicator", in: indicatorNamespace)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}

// MARK: - Preview

#Preview("Tabs") {
    @Previewable @State var activeTab = "design"

    VStack(alignment: .leading, spacing: CGFloat.space6) {

        Text("Small").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
        AppTabs(items: [
            AppTabItem(id: "design", label: "Design"),
            AppTabItem(id: "code",   label: "Code"),
            AppTabItem(id: "preview",label: "Preview"),
        ], activeTab: $activeTab, size: .sm)

        Text("Medium (default)").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
        AppTabs(items: [
            AppTabItem(id: "design", label: "Design"),
            AppTabItem(id: "code",   label: "Code"),
            AppTabItem(id: "preview",label: "Preview"),
        ], activeTab: $activeTab, size: .md)

        Text("Large").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
        AppTabs(items: [
            AppTabItem(id: "design", label: "Design"),
            AppTabItem(id: "code",   label: "Code"),
            AppTabItem(id: "preview",label: "Preview"),
        ], activeTab: $activeTab, size: .lg)

        Text("Active: \(activeTab)").font(.appBodyMedium).foregroundStyle(Color.typographySecondary)
    }
    .padding(CGFloat.space4)
    .background(Color.surfacesBasePrimary)
}
