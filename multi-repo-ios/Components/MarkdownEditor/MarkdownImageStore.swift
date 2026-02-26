// MarkdownImageStore.swift
// Stores images referenced by the markdown editor.
// Images keyed by UUID; editor text contains NSTextAttachments referencing these UUIDs.

import UIKit

struct ImageEntry: Identifiable {
    let id: UUID
    var originalImage: UIImage
    var croppedImage: UIImage?
    var altText: String

    var displayImage: UIImage { croppedImage ?? originalImage }
}

class MarkdownImageStore {
    private(set) var images: [UUID: ImageEntry] = [:]

    @discardableResult
    func addImage(_ image: UIImage, altText: String = "") -> UUID {
        let id = UUID()
        images[id] = ImageEntry(id: id, originalImage: image, croppedImage: nil, altText: altText)
        return id
    }

    func image(for id: UUID) -> ImageEntry? {
        images[id]
    }

    func updateCroppedImage(_ cropped: UIImage, for id: UUID) {
        images[id]?.croppedImage = cropped
    }

    func removeImage(for id: UUID) {
        images.removeValue(forKey: id)
    }
}
