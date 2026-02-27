// MarkdownImageAttachment.swift
// Custom NSTextAttachment rendering rounded-corner image thumbnails inline.
// Uses semantic design tokens for border color — no hardcoded values.

import UIKit
import SwiftUI

// MARK: - MarkdownImageAttachment

/// Custom `NSTextAttachment` that renders inline image thumbnails with rounded corners
/// and a semantic-token border. Sized proportionally to `maxWidth` while capping height
/// at 300pt to prevent tall images from dominating the viewport.
class MarkdownImageAttachment: NSTextAttachment {
    // MARK: - Properties

    let imageID: UUID
    private weak var imageStore: MarkdownImageStore?
    var maxWidth: CGFloat

    /// Maximum display height to prevent tall images from filling the viewport.
    private let maxHeight: CGFloat = 300

    // MARK: - Init

    init(imageID: UUID, imageStore: MarkdownImageStore, maxWidth: CGFloat) {
        self.imageID = imageID
        self.imageStore = imageStore
        self.maxWidth = max(maxWidth, 100) // Ensure minimum usable width
        super.init(data: nil, ofType: nil)
        updateBounds()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    // MARK: - Bounds Calculation

    /// Recalculates `bounds` from the current display image, respecting `maxWidth` and `maxHeight`.
    func updateBounds() {
        guard let entry = imageStore?.image(for: imageID) else { return }
        let img = entry.displayImage
        guard img.size.width > 0, img.size.height > 0 else { return }

        let aspectRatio = img.size.width / img.size.height
        var displayWidth = min(maxWidth, img.size.width)
        var displayHeight = displayWidth / aspectRatio

        // Cap height to prevent tall images from dominating the viewport
        if displayHeight > maxHeight {
            displayHeight = maxHeight
            displayWidth = displayHeight * aspectRatio
        }

        bounds = CGRect(x: 0, y: -4, width: displayWidth, height: displayHeight)
    }

    // MARK: - Rendering

    /// Draws the image with rounded corners and a 1px border using semantic design tokens.
    override func image(
        forBounds imageBounds: CGRect,
        textContainer: NSTextContainer?,
        characterIndex charIndex: Int
    ) -> UIImage? {
        guard let entry = imageStore?.image(for: imageID) else { return nil }
        let img = entry.displayImage

        let renderer = UIGraphicsImageRenderer(size: imageBounds.size)
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: imageBounds.size)
            let cornerRadius: CGFloat = 8
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            path.addClip()
            img.draw(in: rect)

            // 1px border using semantic design token
            let borderColor = UIColor(Color.borderMuted)
            borderColor.setStroke()
            let borderPath = UIBezierPath(
                roundedRect: rect.insetBy(dx: 0.5, dy: 0.5),
                cornerRadius: cornerRadius
            )
            borderPath.lineWidth = 1
            borderPath.stroke()
        }
    }
}
