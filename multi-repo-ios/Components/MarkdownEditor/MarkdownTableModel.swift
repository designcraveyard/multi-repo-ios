// MarkdownTableModel.swift
// Data model for a visual table in the markdown editor.
// Supports row/column mutations, alignment, and markdown serialization.

import Foundation
import Combine

// MARK: - ColumnAlignment

/// Text alignment for a table column. Serialized to GFM alignment markers
/// in the separator row (`:---`, `:---:`, `---:`).
enum ColumnAlignment: Equatable {
    case left, center, right
}

// MARK: - MarkdownTableModel

/// Observable data model for a GFM-style markdown table.
///
/// Supports row/column mutations (add, delete, move, reorder), per-column alignment,
/// optional header row and header column styling, deep copying for non-destructive
/// sheet editing, and round-trip markdown serialization (`toMarkdown()` / `fromMarkdown()`).
class MarkdownTableModel: ObservableObject {

    // MARK: - Properties

    @Published var cells: [[String]]
    @Published var alignments: [ColumnAlignment]

    var rowCount: Int { cells.count }
    var columnCount: Int { cells.first?.count ?? 0 }

    /// Whether the first row is styled as a header. Visual only — does not change
    /// the exported markdown structure (GFM always requires a header + separator).
    @Published var hasHeader: Bool = true
    /// Whether the first column is styled as a header column. Visual only.
    @Published var hasHeaderColumn: Bool = false

    // MARK: - Init

    init(cells: [[String]], alignments: [ColumnAlignment]? = nil, hasHeader: Bool = true, hasHeaderColumn: Bool = false) {
        self.cells = cells
        self.alignments = alignments ?? Array(repeating: .left, count: cells.first?.count ?? 0)
        self.hasHeader = hasHeader
        self.hasHeaderColumn = hasHeaderColumn
    }

    /// Create a default empty table (1 header row + 1 data row, 3 columns).
    static func makeDefault() -> MarkdownTableModel {
        MarkdownTableModel(cells: [
            ["Column 1", "Column 2", "Column 3"],
            ["", "", ""],
        ])
    }

    // MARK: - Mutations

    func addRow(at index: Int? = nil) {
        let newRow = Array(repeating: "", count: columnCount)
        let insertionIndex = index ?? rowCount
        cells.insert(newRow, at: min(insertionIndex, rowCount))
    }

    func addColumn(at index: Int? = nil) {
        let insertionIndex = index ?? columnCount
        for i in 0..<cells.count {
            cells[i].insert("", at: min(insertionIndex, cells[i].count))
        }
        alignments.insert(.left, at: min(insertionIndex, alignments.count))
    }

    func deleteRow(at index: Int) {
        guard rowCount > 1, index < rowCount else { return }
        cells.remove(at: index)
    }

    func deleteColumn(at index: Int) {
        guard columnCount > 1, index < columnCount else { return }
        for i in 0..<cells.count {
            cells[i].remove(at: index)
        }
        alignments.remove(at: index)
    }

    func moveRow(from source: Int, to destination: Int) {
        guard source != destination,
              source < rowCount, destination < rowCount else { return }
        let row = cells.remove(at: source)
        cells.insert(row, at: destination)
    }

    func moveColumn(from source: Int, to destination: Int) {
        guard source != destination,
              source < columnCount, destination < columnCount else { return }
        for i in 0..<cells.count {
            let val = cells[i].remove(at: source)
            cells[i].insert(val, at: destination)
        }
        let align = alignments.remove(at: source)
        alignments.insert(align, at: destination)
    }

    /// Returns a deep copy — used so the sheet editor can be cancelled without
    /// affecting the original model.
    func copy() -> MarkdownTableModel {
        MarkdownTableModel(cells: cells.map { $0 }, alignments: alignments, hasHeader: hasHeader, hasHeaderColumn: hasHeaderColumn)
    }

    func setAlignment(_ alignment: ColumnAlignment, forColumn col: Int) {
        guard col < alignments.count else { return }
        alignments[col] = alignment
    }

    // MARK: - Markdown Serialization

    func toMarkdown() -> String {
        guard !cells.isEmpty, columnCount > 0 else { return "" }
        var lines: [String] = []

        // Header row
        let header = "| " + cells[0].joined(separator: " | ") + " |"
        lines.append(header)

        // Separator row with alignment markers
        let sep = "| " + alignments.map { alignment -> String in
            switch alignment {
            case .left: return "---"
            case .center: return ":---:"
            case .right: return "---:"
            }
        }.joined(separator: " | ") + " |"
        lines.append(sep)

        // Data rows
        for row in cells.dropFirst() {
            lines.append("| " + row.joined(separator: " | ") + " |")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Parse from Markdown

    static func fromMarkdown(_ text: String) -> MarkdownTableModel? {
        let lines = text.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count >= 2 else { return nil }

        func parsePipeLine(_ line: String) -> [String] {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let stripped = trimmed.hasPrefix("|") ? String(trimmed.dropFirst()) : trimmed
            let final = stripped.hasSuffix("|") ? String(stripped.dropLast()) : stripped
            return final.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        }

        // Parse header
        let headerCells = parsePipeLine(lines[0])
        guard !headerCells.isEmpty else { return nil }

        // Parse separator (line 1) for alignments
        let sepCells = parsePipeLine(lines[1])
        let alignments: [ColumnAlignment] = sepCells.map { cell in
            let s = cell.trimmingCharacters(in: CharacterSet(charactersIn: " -"))
            if s.hasPrefix(":") && s.hasSuffix(":") { return .center }
            if s.hasSuffix(":") { return .right }
            return .left
        }

        // Parse data rows
        var allCells: [[String]] = [headerCells]
        for line in lines.dropFirst(2) {
            let rowCells = parsePipeLine(line)
            // Pad or trim to match header column count
            var normalized = rowCells
            while normalized.count < headerCells.count { normalized.append("") }
            if normalized.count > headerCells.count { normalized = Array(normalized.prefix(headerCells.count)) }
            allCells.append(normalized)
        }

        return MarkdownTableModel(cells: allCells, alignments: alignments)
    }
}
