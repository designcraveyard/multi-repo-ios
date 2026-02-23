// AppBottomSheet.swift
// Style source: NativeComponentStyling.swift › NativeBottomSheetStyling
//
// Usage:
//   // Default detents (.medium, .large):
//   Button("Open Sheet") { showSheet = true }
//       .appBottomSheet(isPresented: $showSheet) {
//           MySheetContent()
//       }
//
//   // Custom detents:
//   someView
//       .appBottomSheet(isPresented: $showSheet, detents: [.fraction(0.4), .large]) {
//           MySheetContent()
//       }

import SwiftUI

// MARK: - AppBottomSheetModifier

/// ViewModifier that presents a bottom sheet with design-token styling.
/// All visual tokens come from `NativeBottomSheetStyling` in `NativeComponentStyling.swift`.
private struct AppBottomSheetModifier<SheetContent: View>: ViewModifier {

    @Binding var isPresented: Bool
    let detents: Set<PresentationDetent>
    @ViewBuilder let sheetContent: () -> SheetContent

    // Tracks the active snap point so we can detect detent changes for haptics.
    @State private var selectedDetent: PresentationDetent = .medium

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                sheetContent()
                    // Controls which heights the sheet can snap to.
                    // .medium ≈ 50% of screen, .large ≈ 90% of screen.
                    // The selection binding lets us observe snap-point changes.
                    .presentationDetents(detents, selection: $selectedDetent)
                    // Shows or hides the drag indicator pill at the top.
                    .presentationDragIndicator(NativeBottomSheetStyling.Layout.dragIndicatorVisibility)
                    // Rounds the top corners of the sheet.
                    .presentationCornerRadius(NativeBottomSheetStyling.Layout.cornerRadius)
                    // Background fill of the sheet surface.
                    .presentationBackground(NativeBottomSheetStyling.Colors.sheetBackground)
                    // Padding around sheet content.
                    .padding(.horizontal, NativeBottomSheetStyling.Layout.contentPaddingH)
                    .padding(.top, NativeBottomSheetStyling.Layout.contentPaddingTop)
                    // Haptic feedback when the sheet snaps to a new detent
                    .onChange(of: selectedDetent) { _, _ in
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }
            }
    }
}

// MARK: - View Extension

extension View {
    /// Presents a styled bottom sheet over the current view.
    ///
    /// - Parameters:
    ///   - isPresented: Binding that controls sheet visibility.
    ///   - detents: The heights the sheet can snap to. Defaults to `[.medium, .large]`.
    ///   - content: The view to render inside the sheet.
    public func appBottomSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent> = [.medium, .large],
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        modifier(AppBottomSheetModifier(
            isPresented: isPresented,
            detents: detents,
            sheetContent: content
        ))
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var show = false

    VStack {
        Button("Open Sheet") { show = true }
            .appBottomSheet(isPresented: $show) {
                VStack(alignment: .leading, spacing: .space4) {
                    Text("Sheet Title").font(.appTitleSmall)
                    Text("Sheet content goes here.")
                        .font(.appBodyMedium)
                        .foregroundStyle(Color.appTextSecondary)
                    Spacer()
                }
            }
    }
}
