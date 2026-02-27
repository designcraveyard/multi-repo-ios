// MarkdownExporter.swift
// Exports the editor content as a temporary .md file for sharing.
// Since MarkdownTextStorage stores the original markdown syntax (hidden visually
// but present in the string), export is simply writing the backing string to a file.

import UIKit

struct MarkdownExporter {

    /// Export editor content as a temporary .md file URL.
    /// Returns nil if the file could not be written.
    static func exportToFile(storage: MarkdownTextStorage, filename: String = "document") -> URL? {
        let markdown = storage.string
        let sanitized = filename
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: " ", with: "-")
        let name = sanitized.isEmpty ? "document" : sanitized
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name).md")

        do {
            try markdown.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            return nil
        }
    }
}
