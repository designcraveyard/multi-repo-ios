// MarkdownInputProcessor.swift
// Detects markdown trigger patterns and transforms the current line.
//
// Called from the UITextView delegate's shouldChangeTextIn method.
// Returns true if the input was consumed (trigger detected and handled).

import UIKit

// MARK: - MarkdownInputProcessor

struct MarkdownInputProcessor {

    // MARK: - Process Input

    /// Checks if the replacement text triggers a markdown transformation.
    /// Returns `true` if the trigger was handled (caller should return `false` from shouldChangeTextIn).
    static func process(
        textView: UITextView,
        range: NSRange,
        replacementText text: String,
        textStorage: MarkdownTextStorage
    ) -> Bool {
        // Check if cursor is inside a table row
        let currentBlock = blockAtPosition(range.location, in: textStorage)

        // Tab key handling — table cell navigation takes priority
        if text == "\t" {
            if case .tableRow = currentBlock {
                return handleTableTab(textView: textView, range: range, textStorage: textStorage, reverse: false)
            }
            return handleTab(textView: textView, range: range, textStorage: textStorage, reverse: false)
        }

        // Enter key handling — table row insertion takes priority
        if text == "\n" {
            if case .tableRow = currentBlock {
                return handleTableEnter(textView: textView, range: range, textStorage: textStorage)
            }
            if case .tableSeparator = currentBlock {
                return handleTableEnter(textView: textView, range: range, textStorage: textStorage)
            }
            return handleEnter(textView: textView, range: range, textStorage: textStorage)
        }

        return false
    }

    // MARK: - Enter Key

    /// On Enter inside a list:
    ///   - If the current list item has content → create a new list item
    ///   - If the current list item is empty → exit the list (remove prefix)
    private static func handleEnter(
        textView: UITextView,
        range: NSRange,
        textStorage: MarkdownTextStorage
    ) -> Bool {
        let nsString = textStorage.string as NSString
        let lineRange = nsString.lineRange(for: NSRange(location: range.location, length: 0))
        let line = nsString.substring(with: lineRange).trimmingCharacters(in: .newlines)

        // Task list: "- [ ] " or "- [x] "
        if let taskMatch = matchTaskList(line) {
            if taskMatch.content.isEmpty {
                // Empty task item → exit list
                replaceLineContent(textView: textView, lineRange: lineRange, with: "\n", textStorage: textStorage)
                return true
            }
            // Continue with unchecked task
            let prefix = String(repeating: " ", count: taskMatch.indent) + "- [ ] "
            insertNewLine(textView: textView, at: range.location, prefix: prefix, textStorage: textStorage)
            return true
        }

        // Bullet list: "- " or "* " or "+ "
        if let bulletMatch = matchBulletList(line) {
            if bulletMatch.content.isEmpty {
                replaceLineContent(textView: textView, lineRange: lineRange, with: "\n", textStorage: textStorage)
                return true
            }
            let prefix = String(repeating: " ", count: bulletMatch.indent) + String(bulletMatch.marker) + " "
            insertNewLine(textView: textView, at: range.location, prefix: prefix, textStorage: textStorage)
            return true
        }

        // Ordered list: "1. "
        if let orderedMatch = matchOrderedList(line) {
            if orderedMatch.content.isEmpty {
                replaceLineContent(textView: textView, lineRange: lineRange, with: "\n", textStorage: textStorage)
                return true
            }
            let prefix = String(repeating: " ", count: orderedMatch.indent) + "\(orderedMatch.number + 1). "
            insertNewLine(textView: textView, at: range.location, prefix: prefix, textStorage: textStorage)
            return true
        }

        // Blockquote continuation
        if line.trimmingCharacters(in: .whitespaces).hasPrefix(">") {
            let depth = countBlockquoteDepth(line)
            let trimmedContent = stripBlockquotePrefix(line, depth: depth)
            if trimmedContent.isEmpty {
                replaceLineContent(textView: textView, lineRange: lineRange, with: "\n", textStorage: textStorage)
                return true
            }
            let prefix = String(repeating: "> ", count: depth)
            insertNewLine(textView: textView, at: range.location, prefix: prefix, textStorage: textStorage)
            return true
        }

        return false
    }

    // MARK: - Tab Key (Indent / Outdent)

    private static func handleTab(
        textView: UITextView,
        range: NSRange,
        textStorage: MarkdownTextStorage,
        reverse: Bool
    ) -> Bool {
        let nsString = textStorage.string as NSString
        let lineRange = nsString.lineRange(for: NSRange(location: range.location, length: 0))
        let line = nsString.substring(with: lineRange)
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

        if reverse {
            // Remove 2 spaces from beginning if present
            if line.hasPrefix("  ") {
                let newLine = String(line.dropFirst(2))
                let replaceRange = lineRange
                textStorage.replaceCharacters(in: replaceRange, with: newLine)
                textView.selectedRange = NSRange(location: max(range.location - 2, lineRange.location), length: 0)
            }
        } else {
            // Add 2 spaces to beginning
            let newLine = "  " + line
            textStorage.replaceCharacters(in: lineRange, with: newLine)
            textView.selectedRange = NSRange(location: range.location + 2, length: 0)
        }
        return true
    }

    // MARK: - Pattern Matching

    private struct BulletMatch {
        let indent: Int
        let marker: Character
        let content: String
    }

    private struct OrderedMatch {
        let indent: Int
        let number: Int
        let content: String
    }

    private struct TaskMatch {
        let indent: Int
        let checked: Bool
        let content: String
    }

    private static func matchBulletList(_ line: String) -> BulletMatch? {
        let indent = countLeadingSpaces(line)
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        for marker: Character in ["-", "*", "+"] {
            if trimmed.hasPrefix("\(marker) ") {
                let content = String(trimmed.dropFirst(2))
                return BulletMatch(indent: indent, marker: marker, content: content)
            }
        }
        return nil
    }

    private static func matchOrderedList(_ line: String) -> OrderedMatch? {
        let indent = countLeadingSpaces(line)
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let dotIdx = trimmed.firstIndex(of: ".") else { return nil }
        let numStr = trimmed[trimmed.startIndex..<dotIdx]
        guard let num = Int(numStr), num > 0 else { return nil }
        let afterDot = trimmed.index(after: dotIdx)
        guard afterDot < trimmed.endIndex, trimmed[afterDot] == " " else { return nil }
        let content = String(trimmed[trimmed.index(after: afterDot)...])
        return OrderedMatch(indent: indent, number: num, content: content)
    }

    private static func matchTaskList(_ line: String) -> TaskMatch? {
        let indent = countLeadingSpaces(line)
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("- [ ] ") || trimmed.hasPrefix("* [ ] ") {
            return TaskMatch(indent: indent, checked: false, content: String(trimmed.dropFirst(6)))
        }
        if trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") ||
           trimmed.hasPrefix("* [x] ") || trimmed.hasPrefix("* [X] ") {
            return TaskMatch(indent: indent, checked: true, content: String(trimmed.dropFirst(6)))
        }
        return nil
    }

    private static func countLeadingSpaces(_ line: String) -> Int {
        var count = 0
        for ch in line {
            if ch == " " { count += 1 }
            else if ch == "\t" { count += 4 }
            else { break }
        }
        return count
    }

    private static func countBlockquoteDepth(_ line: String) -> Int {
        var depth = 0
        var s = line.trimmingCharacters(in: .whitespaces)[...]
        while s.hasPrefix("> ") || s.hasPrefix(">") {
            depth += 1
            s = s.dropFirst(s.hasPrefix("> ") ? 2 : 1)
        }
        return depth
    }

    private static func stripBlockquotePrefix(_ line: String, depth: Int) -> String {
        var s = line.trimmingCharacters(in: .whitespaces)[...]
        for _ in 0..<depth {
            if s.hasPrefix("> ") { s = s.dropFirst(2) }
            else if s.hasPrefix(">") { s = s.dropFirst(1) }
        }
        return s.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Table Cell Navigation (Tab)

    /// Tab inside a table row: move cursor to the next cell (after the next pipe).
    /// If at the last cell, move to the first cell of the next row.
    private static func handleTableTab(
        textView: UITextView,
        range: NSRange,
        textStorage: MarkdownTextStorage,
        reverse: Bool
    ) -> Bool {
        let nsString = textStorage.string as NSString
        let fullLength = nsString.length

        if reverse {
            // Shift+Tab: move to previous cell
            // Search backward from cursor for a pipe, then backward again to find the start of the previous cell
            var pos = range.location - 1
            // Skip current pipe if cursor is right after one
            if pos >= 0 && nsString.character(at: pos) == pipeChar { pos -= 1 }
            // Find the pipe before the previous cell
            while pos >= 0 && nsString.character(at: pos) != pipeChar { pos -= 1 }
            if pos >= 0 {
                // Position cursor right after this pipe (skip space)
                let target = pos + 1
                let cursorPos = target < fullLength && nsString.character(at: target) == spaceChar ? target + 1 : target
                textView.selectedRange = NSRange(location: cursorPos, length: 0)
                return true
            }
        } else {
            // Forward Tab: find the next pipe after cursor, place cursor after it
            var pos = range.location
            while pos < fullLength && nsString.character(at: pos) != pipeChar { pos += 1 }
            // Skip the pipe we found
            if pos < fullLength { pos += 1 }
            // If we're at end of line (newline or end of text), try next table row
            if pos >= fullLength || nsString.character(at: pos) == newlineChar {
                // Move past the newline
                if pos < fullLength { pos += 1 }
                // Skip separator row if present
                let sepLineRange = nsString.lineRange(for: NSRange(location: min(pos, fullLength - 1), length: 0))
                let sepLine = nsString.substring(with: sepLineRange).trimmingCharacters(in: .whitespacesAndNewlines)
                if isSeparatorRow(sepLine) {
                    pos = NSMaxRange(sepLineRange)
                    if pos < fullLength && nsString.character(at: pos) == newlineChar { pos += 1 }
                }
                // Now pos should be at the start of the next data row — skip leading pipe + space
                if pos < fullLength && nsString.character(at: pos) == pipeChar { pos += 1 }
                if pos < fullLength && nsString.character(at: pos) == spaceChar { pos += 1 }
            } else {
                // Skip space after pipe
                if pos < fullLength && nsString.character(at: pos) == spaceChar { pos += 1 }
            }
            textView.selectedRange = NSRange(location: min(pos, fullLength), length: 0)
            return true
        }

        return false
    }

    // MARK: - Table Row Insertion (Enter)

    /// Enter inside a table row: insert a new row with the same number of columns.
    private static func handleTableEnter(
        textView: UITextView,
        range: NSRange,
        textStorage: MarkdownTextStorage
    ) -> Bool {
        let nsString = textStorage.string as NSString
        let lineRange = nsString.lineRange(for: NSRange(location: range.location, length: 0))
        let line = nsString.substring(with: lineRange).trimmingCharacters(in: .newlines)

        // Count columns from the current line (or find a nearby table row)
        var columnCount = countPipes(in: line) - 1  // pipes - 1 = columns
        if columnCount < 1 {
            // Try to find column count from adjacent table rows
            for (lr, block) in textStorage.lineBlocks {
                if case .tableRow = block {
                    let rowLine = nsString.substring(with: lr)
                    columnCount = max(countPipes(in: rowLine) - 1, 1)
                    break
                }
            }
        }
        columnCount = max(columnCount, 1)

        // Build new row: "| | | |" with correct column count
        let cellContent = " "
        var newRow = "|"
        for _ in 0..<columnCount {
            newRow += " \(cellContent)|"
        }

        // Insert at the end of the current line
        let insertionPoint = NSMaxRange(lineRange)
        let insertion = "\n" + newRow
        textStorage.replaceCharacters(in: NSRange(location: insertionPoint, length: 0), with: insertion)

        // Place cursor in the first cell of the new row (after "| ")
        let cursorPos = insertionPoint + 3 // "\n" + "| " = 3 chars
        textView.selectedRange = NSRange(location: cursorPos, length: 0)
        return true
    }

    // MARK: - Table Helpers

    /// Returns the block type at the given character position.
    private static func blockAtPosition(_ position: Int, in textStorage: MarkdownTextStorage) -> MarkdownBlockType {
        for (lineRange, block) in textStorage.lineBlocks {
            if position >= lineRange.location && position <= NSMaxRange(lineRange) {
                return block
            }
        }
        return .paragraph
    }

    private static let pipeChar: unichar = 0x7C   // "|"
    private static let spaceChar: unichar = 0x20   // " "
    private static let newlineChar: unichar = 0x0A // "\n"

    private static func countPipes(in line: String) -> Int {
        line.filter { $0 == "|" }.count
    }

    private static func isSeparatorRow(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("|") && trimmed.hasSuffix("|") else { return false }
        let inner = trimmed.dropFirst().dropLast()
        return inner.allSatisfy { "- |:".contains($0) } && inner.contains("-")
    }

    // MARK: - Text Manipulation Helpers

    private static func insertNewLine(textView: UITextView, at location: Int, prefix: String, textStorage: MarkdownTextStorage) {
        let insertion = "\n" + prefix
        textStorage.replaceCharacters(in: NSRange(location: location, length: 0), with: insertion)
        textView.selectedRange = NSRange(location: location + insertion.count, length: 0)
    }

    private static func replaceLineContent(textView: UITextView, lineRange: NSRange, with text: String, textStorage: MarkdownTextStorage) {
        textStorage.replaceCharacters(in: lineRange, with: text)
        textView.selectedRange = NSRange(location: lineRange.location + text.count, length: 0)
    }
}
