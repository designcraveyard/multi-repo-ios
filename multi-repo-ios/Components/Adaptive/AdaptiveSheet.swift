// AdaptiveSheet.swift
// Adaptive presentation: bottom sheet on compact, centered modal dialog on regular.
//
// Usage:
//
//   someView
//       .adaptiveSheet(isPresented: $showSheet, title: "Edit Profile") {
//           EditProfileContent()
//       }
//
//   // With custom detents (compact only — ignored on regular):
//   someView
//       .adaptiveSheet(
//           isPresented: $showSheet,
//           detents: [.fraction(0.4), .large],
//           title: "Filters"
//       ) {
//           FilterContent()
//       }
//
// On iPhone / portrait iPad (.compact): presents as AppBottomSheet (drag-to-dismiss sheet).
// On iPad landscape / macOS (.regular): presents as a centered modal dialog with overlay.
//
// Modal spec (regular):
//   - Max width: 480pt
//   - Corner radius: radiusXL token
//   - Background: surfacesBasePrimary
//   - Scrim: 40% black overlay
//   - Close button top-right (X icon)

import SwiftUI

// MARK: - AdaptiveSheetModifier

/// ViewModifier that presents content as a sheet on compact or modal on regular.
private struct AdaptiveSheetModifier<SheetContent: View>: ViewModifier {

    // MARK: - Properties

    @Environment(\.horizontalSizeClass) private var sizeClass
    @Binding var isPresented: Bool
    let detents: Set<PresentationDetent>
    let title: String?
    @ViewBuilder let sheetContent: () -> SheetContent

    // MARK: - Layout Constants

    private let modalMaxWidth: CGFloat = 480
    private let modalMaxHeight: CGFloat = 600

    // MARK: - Body

    func body(content: Content) -> some View {
        if sizeClass == .regular {
            content
                .overlay {
                    if isPresented {
                        modalPresentation
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isPresented)
        } else {
            content
                .appBottomSheet(isPresented: $isPresented, detents: detents) {
                    sheetContent()
                }
        }
    }

    // MARK: - Modal Presentation (Regular)

    private var modalPresentation: some View {
        ZStack {
            // Scrim
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("Close")

            // Dialog card
            VStack(alignment: .leading, spacing: 0) {
                // Header with optional title + close button
                HStack {
                    if let title {
                        Text(title)
                            .font(.appTitleSmall)
                            .foregroundStyle(Color.typographyPrimary)
                    }
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.typographySecondary)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel("Close")
                }
                .padding(.horizontal, CGFloat.spaceMD)
                .padding(.top, CGFloat.spaceMD)
                .padding(.bottom, CGFloat.spaceSM)

                // Content
                ScrollView {
                    sheetContent()
                        .padding(.horizontal, CGFloat.spaceMD)
                        .padding(.bottom, CGFloat.spaceMD)
                }
            }
            .frame(maxWidth: modalMaxWidth, maxHeight: modalMaxHeight)
            .background(Color.surfacesBasePrimary, in: RoundedRectangle(cornerRadius: CGFloat.radiusXL))
            .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 8)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Presents content adaptively: bottom sheet on compact, centered modal on regular.
    ///
    /// - Parameters:
    ///   - isPresented: Binding that controls visibility.
    ///   - detents: Sheet snap heights on compact. Ignored on regular. Defaults to `[.medium, .large]`.
    ///   - title: Optional title shown in the header.
    ///   - content: The view to present.
    public func adaptiveSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent> = [.medium, .large],
        title: String? = nil,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        modifier(AdaptiveSheetModifier(
            isPresented: isPresented,
            detents: detents,
            title: title,
            sheetContent: content
        ))
    }
}

// MARK: - Preview

#Preview("Compact (Sheet)") {
    @Previewable @State var show = false

    VStack {
        Button("Open Sheet") { show = true }
    }
    .adaptiveSheet(isPresented: $show, title: "Edit Profile") {
        VStack(alignment: .leading, spacing: CGFloat.spaceMD) {
            Text("Sheet content goes here.")
                .font(.appBodyMedium)
                .foregroundStyle(Color.typographySecondary)
            Spacer()
        }
    }
    .environment(\.horizontalSizeClass, .compact)
}

#Preview("Regular (Modal)") {
    @Previewable @State var show = true

    VStack {
        Button("Open Modal") { show = true }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.surfacesBasePrimary)
    .adaptiveSheet(isPresented: $show, title: "Edit Profile") {
        VStack(alignment: .leading, spacing: CGFloat.spaceMD) {
            Text("Modal content goes here on iPad/macOS.")
                .font(.appBodyMedium)
                .foregroundStyle(Color.typographySecondary)
        }
    }
    .environment(\.horizontalSizeClass, .regular)
}
