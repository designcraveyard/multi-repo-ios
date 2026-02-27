// MarkdownImageCropView.swift
// Custom image crop view with drag handles, aspect ratio presets, and rule-of-thirds grid.

import SwiftUI

// MARK: - MarkdownImageCropView

/// Full-screen image crop view presented modally from the image viewer.
/// Provides a draggable crop rectangle with corner/edge handles, a rule-of-thirds
/// grid overlay, and aspect ratio presets (Free, 1:1, 4:3, 16:9).
///
/// Composed of several private helper views:
/// - `CropDimmingOverlay` -- dims areas outside the crop rect
/// - `GridOverlay` -- draws rule-of-thirds guidelines
/// - `CropHandleVisuals` -- renders L-shaped corner brackets and edge bars
/// - `CropGestureOverlay` -- single DragGesture that routes to the nearest handle or center
struct MarkdownImageCropView: View {

    // MARK: - Properties

    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var cropRect: CGRect = .zero
    @State private var imageRect: CGRect = .zero
    @State private var selectedAspectRatio: AspectRatio = .free
    @State private var isInitialized = false

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar

                // Image + crop overlay
                GeometryReader { geometry in
                    let containerSize = geometry.size
                    ZStack {
                        // Original image
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: containerSize.width, maxHeight: containerSize.height)
                            .background(GeometryReader { _ in
                                Color.clear.onAppear {
                                    let imgSize = imageFitSize(
                                        imageSize: image.size,
                                        containerSize: containerSize
                                    )
                                    let origin = CGPoint(
                                        x: (containerSize.width - imgSize.width) / 2,
                                        y: (containerSize.height - imgSize.height) / 2
                                    )
                                    imageRect = CGRect(origin: origin, size: imgSize)
                                    if !isInitialized {
                                        cropRect = imageRect.insetBy(dx: 20, dy: 20)
                                        isInitialized = true
                                    }
                                }
                            })

                        // Dimmed overlay outside crop rect
                        CropDimmingOverlay(cropRect: cropRect, containerSize: containerSize)

                        // Grid lines (rule of thirds)
                        GridOverlay(cropRect: cropRect)

                        // Handle visuals (no hit testing — gesture is on the overlay below)
                        CropHandleVisuals(cropRect: cropRect)

                        // Single gesture overlay handles all drag interactions
                        CropGestureOverlay(
                            cropRect: $cropRect,
                            imageRect: imageRect,
                            aspectRatio: selectedAspectRatio
                        )
                    }
                }

                // Bottom bar with aspect ratios
                aspectRatioBar
            }
        }
        .statusBarHidden()
    }

    // MARK: - Subviews

    private var topBar: some View {
        HStack {
            Button { onCancel() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(Circle())
            }
            Spacer()
            Text("Crop")
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
            Button { performCrop() } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.surfacesBrandInteractive)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var aspectRatioBar: some View {
        HStack(spacing: 20) {
            ForEach(AspectRatio.allCases) { ratio in
                Button {
                    selectedAspectRatio = ratio
                    applyAspectRatio(ratio)
                } label: {
                    Text(ratio.label)
                        .font(.caption)
                        .fontWeight(selectedAspectRatio == ratio ? .bold : .regular)
                        .foregroundStyle(selectedAspectRatio == ratio ? Color.surfacesBrandInteractive : .white.opacity(0.7))
                }
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Helpers

    private func imageFitSize(imageSize: CGSize, containerSize: CGSize) -> CGSize {
        let widthRatio = containerSize.width / imageSize.width
        let heightRatio = containerSize.height / imageSize.height
        let scale = min(widthRatio, heightRatio)
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }

    private func applyAspectRatio(_ ratio: AspectRatio) {
        guard ratio != .free else { return }
        let center = CGPoint(x: cropRect.midX, y: cropRect.midY)
        let targetRatio = ratio.value

        var newWidth = cropRect.width
        var newHeight = newWidth / targetRatio

        if newHeight > imageRect.height {
            newHeight = imageRect.height - 40
            newWidth = newHeight * targetRatio
        }
        if newWidth > imageRect.width {
            newWidth = imageRect.width - 40
            newHeight = newWidth / targetRatio
        }

        var newRect = CGRect(
            x: center.x - newWidth / 2,
            y: center.y - newHeight / 2,
            width: newWidth,
            height: newHeight
        )
        newRect = constrainToImage(newRect)
        withAnimation(.easeInOut(duration: 0.2)) {
            cropRect = newRect
        }
    }

    private func constrainToImage(_ rect: CGRect) -> CGRect {
        var r = rect
        r.origin.x = max(imageRect.minX, min(r.origin.x, imageRect.maxX - r.width))
        r.origin.y = max(imageRect.minY, min(r.origin.y, imageRect.maxY - r.height))
        r.size.width = min(r.width, imageRect.width)
        r.size.height = min(r.height, imageRect.height)
        return r
    }

    /// Maps the on-screen crop rect back to pixel coordinates and produces the cropped UIImage.
    private func performCrop() {
        guard let cgImage = image.cgImage else { return }

        // Convert screen-space crop rect to pixel-space using the display-to-actual scale factors
        let scaleX = CGFloat(cgImage.width) / imageRect.width
        let scaleY = CGFloat(cgImage.height) / imageRect.height

        let cropInImage = CGRect(
            x: (cropRect.minX - imageRect.minX) * scaleX,
            y: (cropRect.minY - imageRect.minY) * scaleY,
            width: cropRect.width * scaleX,
            height: cropRect.height * scaleY
        )

        guard let croppedCGImage = cgImage.cropping(to: cropInImage) else { return }
        let croppedImage = UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
        onCrop(croppedImage)
    }
}

// MARK: - AspectRatio

enum AspectRatio: String, CaseIterable, Identifiable {
    case free, square, fourThree, sixteenNine

    var id: String { rawValue }

    var label: String {
        switch self {
        case .free: return "Free"
        case .square: return "1:1"
        case .fourThree: return "4:3"
        case .sixteenNine: return "16:9"
        }
    }

    var value: CGFloat {
        switch self {
        case .free: return 0
        case .square: return 1.0
        case .fourThree: return 4.0 / 3.0
        case .sixteenNine: return 16.0 / 9.0
        }
    }
}

// MARK: - CropDimmingOverlay

/// Draws a semi-transparent black overlay over the entire container, with the crop
/// rectangle punched out using even-odd fill to reveal the image underneath.
private struct CropDimmingOverlay: View {
    let cropRect: CGRect
    let containerSize: CGSize

    var body: some View {
        Canvas { context, size in
            var fullPath = Path()
            fullPath.addRect(CGRect(origin: .zero, size: size))
            fullPath.addRect(cropRect)
            context.fill(fullPath, with: .color(.black.opacity(0.5)), style: FillStyle(eoFill: true))
        }
        .allowsHitTesting(false)
    }
}

// MARK: - GridOverlay

/// Draws rule-of-thirds guide lines (2 vertical + 2 horizontal) and a 1px white border
/// around the crop rectangle. Hit-testing is disabled so gestures pass through.
private struct GridOverlay: View {
    let cropRect: CGRect

    var body: some View {
        Canvas { context, _ in
            let lineColor = Color.white.opacity(0.3)
            let thirdW = cropRect.width / 3
            let thirdH = cropRect.height / 3

            for i in 1...2 {
                var vPath = Path()
                let x = cropRect.minX + thirdW * CGFloat(i)
                vPath.move(to: CGPoint(x: x, y: cropRect.minY))
                vPath.addLine(to: CGPoint(x: x, y: cropRect.maxY))
                context.stroke(vPath, with: .color(lineColor), lineWidth: 0.5)

                var hPath = Path()
                let y = cropRect.minY + thirdH * CGFloat(i)
                hPath.move(to: CGPoint(x: cropRect.minX, y: y))
                hPath.addLine(to: CGPoint(x: cropRect.maxX, y: y))
                context.stroke(hPath, with: .color(lineColor), lineWidth: 0.5)
            }

            var border = Path()
            border.addRect(cropRect)
            context.stroke(border, with: .color(.white), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - CropHandleVisuals (display only, no gestures)

/// Renders branded L-shaped corner handles and short edge-center bars on the crop rectangle.
/// This is a display-only layer; all gesture handling is in `CropGestureOverlay`.
private struct CropHandleVisuals: View {
    let cropRect: CGRect

    private let length: CGFloat = 20
    private let thickness: CGFloat = 4
    private var color: Color { Color.surfacesBrandInteractive }

    var body: some View {
        Canvas { context, _ in
            let c = color
            // Corner handles — L-shaped brackets
            drawCorner(context: context, x: cropRect.minX, y: cropRect.minY, dx: 1, dy: 1)
            drawCorner(context: context, x: cropRect.maxX, y: cropRect.minY, dx: -1, dy: 1)
            drawCorner(context: context, x: cropRect.minX, y: cropRect.maxY, dx: 1, dy: -1)
            drawCorner(context: context, x: cropRect.maxX, y: cropRect.maxY, dx: -1, dy: -1)

            // Edge handles — short bars
            drawEdge(context: context, x: cropRect.midX - length / 2, y: cropRect.minY - thickness / 2, w: length, h: thickness)
            drawEdge(context: context, x: cropRect.midX - length / 2, y: cropRect.maxY - thickness / 2, w: length, h: thickness)
            drawEdge(context: context, x: cropRect.minX - thickness / 2, y: cropRect.midY - length / 2, w: thickness, h: length)
            drawEdge(context: context, x: cropRect.maxX - thickness / 2, y: cropRect.midY - length / 2, w: thickness, h: length)
        }
        .allowsHitTesting(false)
    }

    private func drawCorner(context: GraphicsContext, x: CGFloat, y: CGFloat, dx: CGFloat, dy: CGFloat) {
        var hBar = Path()
        hBar.addRect(CGRect(
            x: dx > 0 ? x : x - length,
            y: dy > 0 ? y - thickness / 2 : y - thickness / 2,
            width: length,
            height: thickness
        ))
        context.fill(hBar, with: .color(color))

        var vBar = Path()
        vBar.addRect(CGRect(
            x: dx > 0 ? x - thickness / 2 : x - thickness / 2,
            y: dy > 0 ? y : y - length,
            width: thickness,
            height: length
        ))
        context.fill(vBar, with: .color(color))
    }

    private func drawEdge(context: GraphicsContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        var path = Path()
        path.addRect(CGRect(x: x, y: y, width: w, height: h))
        context.fill(path, with: .color(color))
    }
}

// MARK: - CropGestureOverlay

/// Single gesture overlay that determines which handle (or center) is being dragged
/// based on the drag start location. Avoids SwiftUI's .position() hit-test issue
/// where all positioned views share the parent's full frame.
private struct CropGestureOverlay: View {
    @Binding var cropRect: CGRect
    let imageRect: CGRect
    let aspectRatio: AspectRatio

    @State private var dragStartRect: CGRect = .zero
    @State private var activeTarget: DragTarget = .none

    private let handleHitRadius: CGFloat = 30

    private enum DragTarget {
        case none, center
        case topLeft, topRight, bottomLeft, bottomRight
        case top, bottom, left, right
    }

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if activeTarget == .none {
                            activeTarget = target(for: value.startLocation)
                            dragStartRect = cropRect
                        }
                        guard activeTarget != .none else { return }
                        applyDrag(target: activeTarget, translation: value.translation)
                    }
                    .onEnded { _ in
                        activeTarget = .none
                        dragStartRect = .zero
                    }
            )
    }

    // MARK: - Target Detection

    private func target(for point: CGPoint) -> DragTarget {
        let r = cropRect
        let h = handleHitRadius

        // Check corners first (highest priority)
        if dist(point, CGPoint(x: r.minX, y: r.minY)) < h { return .topLeft }
        if dist(point, CGPoint(x: r.maxX, y: r.minY)) < h { return .topRight }
        if dist(point, CGPoint(x: r.minX, y: r.maxY)) < h { return .bottomLeft }
        if dist(point, CGPoint(x: r.maxX, y: r.maxY)) < h { return .bottomRight }

        // Check edges
        if abs(point.y - r.minY) < h && point.x > r.minX && point.x < r.maxX { return .top }
        if abs(point.y - r.maxY) < h && point.x > r.minX && point.x < r.maxX { return .bottom }
        if abs(point.x - r.minX) < h && point.y > r.minY && point.y < r.maxY { return .left }
        if abs(point.x - r.maxX) < h && point.y > r.minY && point.y < r.maxY { return .right }

        // Check center (inside crop rect)
        if r.contains(point) { return .center }

        return .none
    }

    private func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    // MARK: - Drag Application

    private func applyDrag(target: DragTarget, translation: CGSize) {
        let base = dragStartRect
        let minDim: CGFloat = 50

        if target == .center {
            var r = base
            r.origin.x += translation.width
            r.origin.y += translation.height
            r = constrain(r)
            cropRect = r
            return
        }

        var r = base

        switch target {
        case .topLeft:
            r.origin.x += translation.width
            r.origin.y += translation.height
            r.size.width -= translation.width
            r.size.height -= translation.height
        case .topRight:
            r.size.width += translation.width
            r.origin.y += translation.height
            r.size.height -= translation.height
        case .bottomLeft:
            r.origin.x += translation.width
            r.size.width -= translation.width
            r.size.height += translation.height
        case .bottomRight:
            r.size.width += translation.width
            r.size.height += translation.height
        case .top:
            r.origin.y += translation.height
            r.size.height -= translation.height
        case .bottom:
            r.size.height += translation.height
        case .left:
            r.origin.x += translation.width
            r.size.width -= translation.width
        case .right:
            r.size.width += translation.width
        default:
            break
        }

        // Enforce minimum size
        if r.width < minDim {
            if target == .topLeft || target == .bottomLeft || target == .left {
                r.origin.x = base.maxX - minDim
            }
            r.size.width = minDim
        }
        if r.height < minDim {
            if target == .topLeft || target == .topRight || target == .top {
                r.origin.y = base.maxY - minDim
            }
            r.size.height = minDim
        }

        // Enforce aspect ratio lock
        if aspectRatio != .free {
            let ratio = aspectRatio.value
            switch target {
            case .left, .right:
                r.size.height = r.width / ratio
            default:
                r.size.width = r.height * ratio
            }
        }

        // Constrain within image bounds
        r.origin.x = max(imageRect.minX, r.origin.x)
        r.origin.y = max(imageRect.minY, r.origin.y)
        if r.maxX > imageRect.maxX { r.size.width = imageRect.maxX - r.origin.x }
        if r.maxY > imageRect.maxY { r.size.height = imageRect.maxY - r.origin.y }

        cropRect = r
    }

    private func constrain(_ rect: CGRect) -> CGRect {
        var r = rect
        r.origin.x = max(imageRect.minX, min(r.origin.x, imageRect.maxX - r.width))
        r.origin.y = max(imageRect.minY, min(r.origin.y, imageRect.maxY - r.height))
        return r
    }
}
