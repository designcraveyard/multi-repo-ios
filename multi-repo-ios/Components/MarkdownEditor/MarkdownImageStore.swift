// MarkdownImageStore.swift
// Stores images referenced by the markdown editor.
// Images keyed by UUID; editor text contains NSTextAttachments referencing these UUIDs.

import UIKit

// MARK: - ImageEntry

/// A single image record in the store. Holds both the original and an optional
/// cropped version; `displayImage` returns whichever is most up-to-date.
struct ImageEntry: Identifiable {
    let id: UUID
    var originalImage: UIImage
    var croppedImage: UIImage?
    var altText: String

    /// Returns the cropped image if available, otherwise the original.
    var displayImage: UIImage { croppedImage ?? originalImage }
}

// MARK: - MarkdownImageStore

/// In-memory store for images embedded in the markdown editor.
/// Each image is keyed by UUID; `MarkdownImageAttachment` references these UUIDs
/// to look up display images at render time.
class MarkdownImageStore {
    private(set) var images: [UUID: ImageEntry] = [:]

    /// Adds a new image and returns its UUID for attachment reference.
    @discardableResult
    func addImage(_ image: UIImage, altText: String = "") -> UUID {
        let id = UUID()
        images[id] = ImageEntry(id: id, originalImage: image, croppedImage: nil, altText: altText)
        return id
    }

    /// Looks up an image entry by UUID. Returns nil if not found.
    func image(for id: UUID) -> ImageEntry? {
        images[id]
    }

    /// Replaces the cropped variant for an existing image entry.
    func updateCroppedImage(_ cropped: UIImage, for id: UUID) {
        images[id]?.croppedImage = cropped
    }

    /// Removes an image entry entirely. The corresponding attachment will render as empty.
    func removeImage(for id: UUID) {
        images.removeValue(forKey: id)
    }
}
