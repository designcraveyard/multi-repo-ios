// AppTooltip.swift
// Style source: NativeComponentStyling.swift › NativeTooltipStyling
//
// SwiftUI has no dedicated tooltip API on iOS. This component uses .popover()
// with .presentationCompactAdaptation(.popover) to render a small bubble
// instead of a full sheet on compact size classes (iPhones).
//
// Usage:
//   @State var showTip = false
//
//   AppTooltip(isPresented: $showTip, tipText: "Tap to like this post") {
//       Image(systemName: "heart")
//           .onTapGesture { showTip.toggle() }
//   }
//
//   // Custom arrow edge (default is .top → bubble appears below anchor):
//   AppTooltip(isPresented: $showTip, tipText: "Bold text",
//              arrowEdge: .bottom) {
//       Button("B") { showTip.toggle() }
//   }
//
//   // Rich tip content (pass any View as tipContent):
//   AppTooltip(isPresented: $showTip) {
//       someAnchorView
//   } tipContent: {
//       VStack { Text("Title").bold(); Text("Detail") }
//   }

import SwiftUI

// MARK: - AppTooltip

/// A tooltip component built on `.popover()`.
/// All visual tokens come from `NativeTooltipStyling` in `NativeComponentStyling.swift`.
///
/// On iPhone (compact width), `.presentationCompactAdaptation(.popover)` keeps the
/// tooltip as a small popover instead of expanding to a full sheet.
public struct AppTooltip<Label: View, TipContent: View>: View {

    // MARK: - Properties

    @Binding var isPresented: Bool

    /// The edge from which the popover arrow points toward the anchor view.
    var arrowEdge: Edge = NativeTooltipStyling.Layout.defaultArrowEdge

    /// The anchor view that the tooltip appears near.
    @ViewBuilder let label: () -> Label

    /// The content shown inside the tooltip bubble.
    @ViewBuilder let tipContent: () -> TipContent

    // MARK: - Body

    public var body: some View {
        label()
            .popover(isPresented: $isPresented, arrowEdge: arrowEdge) {
                tipContent()
                    .font(NativeTooltipStyling.Typography.content)
                    .foregroundStyle(NativeTooltipStyling.Colors.text)
                    .padding(.horizontal, NativeTooltipStyling.Layout.paddingH)
                    .padding(.vertical, NativeTooltipStyling.Layout.paddingV)
                    .frame(maxWidth: NativeTooltipStyling.Layout.maxWidth)
                    // Dark inverse background on the popover chrome (arrow + bubble)
                    .presentationBackground(NativeTooltipStyling.Colors.background)
                    // Keeps this as a popover bubble on iPhone, not a full sheet
                    .presentationCompactAdaptation(.popover)
            }
    }
}

// MARK: - Convenience Initialiser (plain text tip)

extension AppTooltip where TipContent == Text {
    /// Convenience init for plain-text tooltips — no need to build a content closure.
    /// Default arrowEdge matches `NativeTooltipStyling.Layout.defaultArrowEdge` (.top).
    public init(isPresented: Binding<Bool>,
                tipText: String,
                arrowEdge: Edge = .top,
                @ViewBuilder label: @escaping () -> Label) {
        self._isPresented = isPresented
        self.arrowEdge = arrowEdge
        self.label = label
        self.tipContent = { Text(tipText) }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var showTop = false
    @Previewable @State var showBottom = false
    @Previewable @State var showLeading = false
    @Previewable @State var showTrailing = false

    VStack(spacing: 48) {
        Text("Tap each button to toggle tooltip")
            .font(.appCaptionMedium)
            .foregroundStyle(Color.typographyMuted)

        // Arrow at top → bubble appears below
        AppTooltip(isPresented: $showTop, tipText: "View details", arrowEdge: .top) {
            Button("Top (below)") { showTop.toggle() }
                .font(.appCTAMedium)
        }

        // Arrow at bottom → bubble appears above
        AppTooltip(isPresented: $showBottom, tipText: "View details", arrowEdge: .bottom) {
            Button("Bottom (above)") { showBottom.toggle() }
                .font(.appCTAMedium)
        }

        HStack(spacing: 64) {
            // Arrow at trailing → bubble appears to the left
            AppTooltip(isPresented: $showTrailing, tipText: "View details", arrowEdge: .trailing) {
                Button("Trailing (left)") { showTrailing.toggle() }
                    .font(.appCTAMedium)
            }

            // Arrow at leading → bubble appears to the right
            AppTooltip(isPresented: $showLeading, tipText: "View details", arrowEdge: .leading) {
                Button("Leading (right)") { showLeading.toggle() }
                    .font(.appCTAMedium)
            }
        }

        // Rich content example
        AppTooltip(isPresented: .constant(true), tipText: "Always visible tooltip", arrowEdge: .top) {
            Image(systemName: "heart")
                .font(.title)
                .foregroundStyle(Color.appIconPrimary)
        }
    }
    .padding()
}
