// MarkdownImageViewer.swift
// Fullscreen image viewer with pinch-to-zoom, double-tap zoom,
// swipe-to-dismiss, and crop access.

import SwiftUI
import UIKit

// MARK: - MarkdownImageViewer

/// Full-screen image viewer presented when tapping an inline image in the editor.
///
/// Supports:
/// - Pinch-to-zoom (1x to 5x) via `MagnifyGesture`
/// - Double-tap to toggle between 1x and 3x zoom
/// - Vertical swipe-to-dismiss (when at 1x zoom)
/// - Crop button that opens `MarkdownImageCropView` as a sheet
struct MarkdownImageViewer: View {

    // MARK: - Properties

    let imageEntry: ImageEntry
    var imageStore: MarkdownImageStore?
    var onCropComplete: ((UIImage) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var showCrop = false
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
                .opacity(backgroundOpacity)

            Image(uiImage: imageEntry.displayImage)
                .resizable()
                .scaledToFit()
                .scaleEffect(zoomScale)
                .offset(y: dragOffset.height)
                .gesture(zoomGesture)
                .gesture(dragToDissmissGesture)
                .onTapGesture(count: 2) {
                    withAnimation(.spring(response: 0.3)) {
                        if zoomScale > 1 {
                            zoomScale = 1
                            lastZoomScale = 1
                        } else {
                            zoomScale = 3
                            lastZoomScale = 3
                        }
                    }
                }

            // Top overlay bar
            VStack {
                HStack {
                    overlayButton(icon: "xmark") { dismiss() }
                    Spacer()
                    overlayButton(icon: "crop") { showCrop = true }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                Spacer()
            }
        }
        .statusBarHidden()
        .sheet(isPresented: $showCrop) {
            MarkdownImageCropView(
                image: imageEntry.originalImage,
                onCrop: { cropped in
                    imageStore?.updateCroppedImage(cropped, for: imageEntry.id)
                    onCropComplete?(cropped)
                    showCrop = false
                },
                onCancel: { showCrop = false }
            )
            .interactiveDismissDisabled()
        }
    }

    // MARK: - Subviews

    private func overlayButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial.opacity(0.5))
                .clipShape(Circle())
        }
    }

    // MARK: - Gestures

    /// Pinch-to-zoom gesture clamped between 1x and 5x. Snaps back to 1x if close.
    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let newScale = lastZoomScale * value.magnification
                zoomScale = min(max(newScale, 1.0), 5.0)
            }
            .onEnded { value in
                let newScale = lastZoomScale * value.magnification
                zoomScale = min(max(newScale, 1.0), 5.0)
                lastZoomScale = zoomScale
                if zoomScale < 1.05 {
                    withAnimation(.spring(response: 0.3)) {
                        zoomScale = 1.0
                        lastZoomScale = 1.0
                    }
                }
            }
    }

    // MARK: - Helpers

    /// Background dims as the user drags further from center (up to 50% fade at 300pt).
    private var backgroundOpacity: Double {
        let progress = min(abs(dragOffset.height) / 300, 1.0)
        return 1.0 - progress * 0.5
    }

    /// Vertical drag gesture that dismisses the viewer when displacement exceeds 150pt.
    /// Disabled when zoomed in (zoomScale > 1.05) to avoid conflicting with pan-to-scroll.
    private var dragToDissmissGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard zoomScale <= 1.05 else { return }
                isDragging = true
                dragOffset = value.translation
            }
            .onEnded { value in
                isDragging = false
                guard zoomScale <= 1.05 else { return }
                if abs(value.translation.height) > 150 {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.3)) {
                        dragOffset = .zero
                    }
                }
            }
    }
}
