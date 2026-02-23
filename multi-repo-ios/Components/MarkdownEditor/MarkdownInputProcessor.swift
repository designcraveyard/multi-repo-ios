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
        // Enter key handling
        if text == "\n" {
            return handleEnter(textView: textView, range: range, textStorage: textStorage)
        }

        // Tab key handling (indent in lists)
        if text == "\t" {
            return handleTab(textView: textView, range: range, textStorage: textStorage, reverse: false)
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

        // Only indent/outdent in lists
        let isList = trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") ||
                     matchOrderedList(trimmed) != nil || matchTaskList(trimmed) != nil

        guard isList else { return false }

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
