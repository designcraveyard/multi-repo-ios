// MarkdownTextStorage.swift
// Custom NSTextStorage that applies inline markdown formatting as the user types.
//
// Architecture:
//   1. Stores raw text in a backing NSMutableAttributedString
//   2. On each edit, classifies every line into a BlockType
//   3. Applies visual attributes (font, color, paragraph style)
//   4. Hides markdown syntax by making markers invisible (near-zero-width + clear color)
//   5. Custom MarkdownLayoutManager draws bullet dots and SF Symbol checkboxes
//      on top of invisible marker characters

import UIKit

// MARK: - Custom Attributed String Keys

extension NSAttributedString.Key {
    /// Number of columns in a table row (Int).
    static let tableColumnCount = NSAttributedString.Key("md.tableColumnCount")
    /// Whether this table row is the header row (Bool).
    static let tableIsHeader = NSAttributedString.Key("md.tableIsHeader")
    /// Custom highlight background for ==text== spans (UIColor).
    /// NOT using system .backgroundColor — that draws sharp rects.
    /// MarkdownLayoutManager reads this key and draws rounded rects instead.
    static let highlightBackground = NSAttributedString.Key("md.highlightBackground")
}

// MARK: - Block Type

enum MarkdownBlockType: Equatable {
    case paragraph
    case heading(level: Int)
    case bulletList(indent: Int)
    case orderedList(indent: Int, number: Int)
    case taskList(indent: Int, checked: Bool)
    case blockquote(depth: Int)
    case codeFenceOpen
    case codeBlock
    case codeFenceClose
    case horizontalRule
    case tableRow
    case tableSeparator
}

// MARK: - MarkdownTextStorage

class MarkdownTextStorage: NSTextStorage {

    // --- Constants ---

    /// Attributes that collapse syntax characters to near-zero width and make them invisible.
    private static let hiddenAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 0.01),
        .foregroundColor: UIColor.clear,
    ]

    /// Attributes that make characters invisible but KEEP their width
    /// so MarkdownLayoutManager can draw replacements (bullets, checkboxes) on top.
    private static let invisibleAttrs: [NSAttributedString.Key: Any] = [
        .foregroundColor: UIColor.clear,
    ]

    // --- Backing store ---
    private let backing = NSMutableAttributedString()

    // --- State ---
    private(set) var lineBlocks: [(range: NSRange, block: MarkdownBlockType)] = []

    // MARK: - NSTextStorage required overrides

    override var string: String { backing.string }

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        backing.attributes(at: location, effectiveRange: range)
    }

    override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        backing.replaceCharacters(in: range, with: str)
        edited(.editedCharacters, range: range, changeInLength: str.count - range.length)
        endEditing()
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        beginEditing()
        backing.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    // MARK: - Process Editing

    override func processEditing() {
        applyMarkdownFormatting()
        super.processEditing()
    }

    // MARK: - Full Formatting Pass

    func applyMarkdownFormatting() {
        let fullRange = NSRange(location: 0, length: length)
        guard fullRange.length > 0 else { return }

        // Reset to default body style with 24pt line height
        let defaultAttrs: [NSAttributedString.Key: Any] = [
            .font: MarkdownFonts.body,
            .foregroundColor: MarkdownColors.text,
            .paragraphStyle: defaultParagraphStyle(),
            .baselineOffset: MarkdownLayout.bodyBaselineOffset,
        ]
        backing.setAttributes(defaultAttrs, range: fullRange)

        // Classify lines
        lineBlocks = classifyLines()

        // Apply block-level formatting
        for (i, entry) in lineBlocks.enumerated() {
            applyBlockStyle(range: entry.range, block: entry.block, index: i)
        }

        // Apply inline formatting (outside code blocks)
        applyInlineFormatting()
    }

    // MARK: - Typing Attributes

    /// Returns appropriate typing attributes for the cursor at the given position.
    /// Used to fix cursor height and ensure typed characters are visible.
    /// Heading lines get heading font; table rows get body font with visible text color
    /// (critical: without this, typed text inside table cells inherits hidden/border styling).
    func typingAttributes(at position: Int) -> [NSAttributedString.Key: Any] {
        var font: UIFont = MarkdownFonts.body
        var color: UIColor = MarkdownColors.text
        var para = defaultParagraphStyle()

        for (lineRange, block) in lineBlocks {
            if position >= lineRange.location && position <= NSMaxRange(lineRange) {
                switch block {
                case .heading(let level):
                    font = MarkdownFonts.heading(level: level)
                case .tableRow:
                    // Determine if this is a header row
                    if let idx = lineBlocks.firstIndex(where: { $0.range == lineRange }),
                       idx + 1 < lineBlocks.count,
                       lineBlocks[idx + 1].block == .tableSeparator {
                        font = MarkdownFonts.bodyBold
                    } else {
                        font = MarkdownFonts.body
                    }
                    color = MarkdownColors.text
                    let tablePara = NSMutableParagraphStyle()
                    tablePara.minimumLineHeight = MarkdownLayout.bodyLineHeight
                    tablePara.maximumLineHeight = MarkdownLayout.bodyLineHeight
                    tablePara.paragraphSpacing = 0
                    para = tablePara
                case .tableSeparator:
                    font = MarkdownFonts.body
                    color = MarkdownColors.tableBorder
                default:
                    break
                }
                break
            }
        }
        return [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: para,
            .baselineOffset: MarkdownLayout.bodyBaselineOffset,
        ]
    }

    // MARK: - Line Classification

    private func classifyLines() -> [(range: NSRange, block: MarkdownBlockType)] {
        var results: [(range: NSRange, block: MarkdownBlockType)] = []
        let nsString = backing.string as NSString
        var inCode = false

        nsString.enumerateSubstrings(in: NSRange(location: 0, length: nsString.length), options: [.byLines, .substringNotRequired]) { _, lineRange, _, _ in
            let line = nsString.substring(with: lineRange)
            let stripped = String(line.drop(while: { $0 == " " || $0 == "\t" }))

            // Code fence toggle
            if stripped.hasPrefix("```") {
                if inCode {
                    results.append((lineRange, .codeFenceClose))
                    inCode = false
                } else {
                    results.append((lineRange, .codeFenceOpen))
                    inCode = true
                }
                return
            }

            if inCode {
                results.append((lineRange, .codeBlock))
                return
            }

            // Horizontal rule
            if Self.isHorizontalRule(stripped) {
                results.append((lineRange, .horizontalRule))
                return
            }

            // Heading
            if let level = Self.headingLevel(stripped) {
                results.append((lineRange, .heading(level: level)))
                return
            }

            // Indent level from the original line
            let indent = Self.indentLevel(line)

            // Task list (before bullet, since task starts with "- [")
            if let checked = Self.taskListMatch(stripped) {
                results.append((lineRange, .taskList(indent: indent, checked: checked)))
                return
            }

            // Bullet list
            if Self.isBulletList(stripped) {
                results.append((lineRange, .bulletList(indent: indent)))
                return
            }

            // Ordered list
            if let number = Self.orderedListNumber(stripped) {
                results.append((lineRange, .orderedList(indent: indent, number: number)))
                return
            }

            // Blockquote
            if let depth = Self.blockquoteDepth(stripped) {
                results.append((lineRange, .blockquote(depth: depth)))
                return
            }

            // Table row or separator
            if stripped.hasPrefix("|") && stripped.hasSuffix("|") {
                let inner = stripped.dropFirst().dropLast()
                let isSep = inner.allSatisfy { "- |:".contains($0) } && inner.contains("-")
                results.append((lineRange, isSep ? .tableSeparator : .tableRow))
                return
            }

            results.append((lineRange, .paragraph))
        }

        return results
    }

    // MARK: - Pattern Matching Helpers

    private static func headingLevel(_ stripped: String) -> Int? {
        var count = 0
        for ch in stripped {
            if ch == "#" { count += 1 } else { break }
        }
        guard count >= 1, count <= 6 else { return nil }
        if stripped.count == count { return count }
        guard stripped[stripped.index(stripped.startIndex, offsetBy: count)] == " " else { return nil }
        return count
    }

    private static func indentLevel(_ line: String) -> Int {
        var spaces = 0
        for ch in line {
            if ch == " " { spaces += 1 }
            else if ch == "\t" { spaces += 4 }
            else { break }
        }
        return spaces / 2
    }

    private static func isBulletList(_ stripped: String) -> Bool {
        stripped.hasPrefix("- ") || stripped.hasPrefix("* ") || stripped.hasPrefix("+ ")
    }

    private static func orderedListNumber(_ stripped: String) -> Int? {
        guard let dotIndex = stripped.firstIndex(of: ".") else { return nil }
        let prefix = stripped[stripped.startIndex..<dotIndex]
        guard let num = Int(prefix), num > 0 else { return nil }
        let afterDot = stripped.index(after: dotIndex)
        guard afterDot < stripped.endIndex, stripped[afterDot] == " " else { return nil }
        return num
    }

    private static func taskListMatch(_ stripped: String) -> Bool? {
        if stripped.hasPrefix("- [ ] ") || stripped.hasPrefix("* [ ] ") ||
           stripped == "- [ ]" || stripped == "* [ ]" { return false }
        if stripped.hasPrefix("- [x] ") || stripped.hasPrefix("- [X] ") ||
           stripped.hasPrefix("* [x] ") || stripped.hasPrefix("* [X] ") ||
           stripped == "- [x]" || stripped == "- [X]" ||
           stripped == "* [x]" || stripped == "* [X]" { return true }
        return nil
    }

    private static func blockquoteDepth(_ stripped: String) -> Int? {
        var depth = 0
        var s = stripped[...]
        while s.hasPrefix("> ") || s.hasPrefix(">") {
            depth += 1
            s = s.dropFirst(s.hasPrefix("> ") ? 2 : 1)
        }
        return depth > 0 ? depth : nil
    }

    private static func isHorizontalRule(_ stripped: String) -> Bool {
        let clean = stripped.replacingOccurrences(of: " ", with: "")
        return (clean == "---" || clean == "***" || clean == "___") && stripped.count >= 3
    }

    /// Parse a markdown table row into cell strings.
    /// "| A | B | C |" → ["A", "B", "C"]
    static func parseTableCells(_ line: String) -> [String] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("|") && trimmed.hasSuffix("|") else { return [] }
        let inner = String(trimmed.dropFirst().dropLast())
        return inner.split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    // MARK: - Block Style Application

    private func applyBlockStyle(range: NSRange, block: MarkdownBlockType, index: Int) {
        guard range.length > 0 else { return }
        let line = (backing.string as NSString).substring(with: range)
        let leadingSpaces = line.prefix(while: { $0 == " " || $0 == "\t" }).count

        switch block {
        case .heading(let level):
            let font = MarkdownFonts.heading(level: level)
            let para = NSMutableParagraphStyle()
            para.paragraphSpacingBefore = MarkdownLayout.headingSpacingBefore
            para.paragraphSpacing = MarkdownLayout.headingSpacingAfter

            backing.addAttributes([
                .font: font,
                .foregroundColor: MarkdownColors.text,
                .paragraphStyle: para,
                .baselineOffset: 0,
            ], range: range)

            let prefixLen = Self.headingPrefixLength(line)
            if prefixLen > 0 && prefixLen < range.length {
                backing.addAttributes(Self.hiddenAttrs, range: NSRange(location: range.location, length: prefixLen))
            } else if prefixLen > 0 {
                backing.addAttribute(.foregroundColor, value: MarkdownColors.textMuted, range: NSRange(location: range.location, length: prefixLen))
            }

        case .bulletList(let indent):
            let para = listParagraphStyle(indent: indent)
            backing.addAttribute(.paragraphStyle, value: para, range: range)

            // Collapse the dash/marker to zero-width — MarkdownLayoutManager draws SF Symbol bullet
            // at a calculated position. Using hiddenAttrs ensures first-line text starts at the
            // paragraph indent, matching wrapped lines exactly.
            let prefixLen = leadingSpaces + 2 // "- " or "* " or "+ "
            if prefixLen <= range.length {
                backing.addAttributes(Self.hiddenAttrs, range: NSRange(location: range.location, length: prefixLen))
            }

        case .orderedList(let indent, let num):
            let para = listParagraphStyle(indent: indent)
            backing.addAttribute(.paragraphStyle, value: para, range: range)

            // Hide leading spaces, keep number visible at the margin
            if leadingSpaces > 0 {
                backing.addAttributes(Self.hiddenAttrs, range: NSRange(location: range.location, length: leadingSpaces))
            }
            // The number + ". " is visible and drawn by MarkdownLayoutManager at calculated position
            let prefixLen = leadingSpaces + String(num).count + 2 // "1. "
            if prefixLen <= range.length {
                // Collapse the entire prefix — MarkdownLayoutManager draws the number
                backing.addAttributes(Self.hiddenAttrs, range: NSRange(location: range.location, length: prefixLen))
            }

        case .taskList(let indent, let checked):
            let para = listParagraphStyle(indent: indent)
            backing.addAttribute(.paragraphStyle, value: para, range: range)

            // Collapse entire prefix "- [ ] " or "- [x] " to zero-width.
            // MarkdownLayoutManager draws the checkbox at a calculated position.
            let dashLen = leadingSpaces + 2
            let cbLen = 3
            let totalPrefixLen = dashLen + cbLen + 1 // "- [ ] " or "- [x] "
            if totalPrefixLen <= range.length {
                backing.addAttributes(Self.hiddenAttrs, range: NSRange(location: range.location, length: totalPrefixLen))
            } else if dashLen + cbLen <= range.length {
                // No space after checkbox (end of line)
                backing.addAttributes(Self.hiddenAttrs, range: NSRange(location: range.location, length: dashLen + cbLen))
            }

            // Strikethrough + muted for checked task content
            if checked {
                let contentStart = min(totalPrefixLen, range.length)
                if contentStart < range.length {
                    let contentRange = NSRange(location: range.location + contentStart, length: range.length - contentStart)
                    backing.addAttributes([
                        .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                        .foregroundColor: MarkdownColors.textMuted,
                    ], range: contentRange)
                }
            }

        case .blockquote(let depth):
            let para = NSMutableParagraphStyle()
            let indent = CGFloat(depth) * MarkdownLayout.blockquoteIndent + MarkdownLayout.blockquoteIndent
            para.firstLineHeadIndent = indent
            para.headIndent = indent
            para.paragraphSpacing = MarkdownLayout.paragraphSpacing
            para.minimumLineHeight = MarkdownLayout.bodyLineHeight
            para.maximumLineHeight = MarkdownLayout.bodyLineHeight

            // Apple Notes style: normal weight text, secondary color, no background.
            // The left bar is drawn by MarkdownLayoutManager.
            backing.addAttributes([
                .foregroundColor: MarkdownColors.blockquoteText,
                .font: MarkdownFonts.body,
                .paragraphStyle: para,
                .baselineOffset: MarkdownLayout.bodyBaselineOffset,
            ], range: range)

            // Hide the "> " prefix
            var prefixLen = 0
            for ch in line {
                if ch == ">" || ch == " " { prefixLen += 1 } else { break }
            }
            if prefixLen > 0 && prefixLen < range.length {
                backing.addAttributes(Self.hiddenAttrs, range: NSRange(location: range.location, length: prefixLen))
            } else if prefixLen > 0 {
                backing.addAttribute(.foregroundColor, value: MarkdownColors.textMuted, range: NSRange(location: range.location, length: prefixLen))
            }

        case .codeFenceOpen, .codeFenceClose:
            backing.addAttributes([
                .font: MarkdownFonts.codeBlock,
                .foregroundColor: MarkdownColors.textMuted,
                .backgroundColor: MarkdownColors.codeBackground,
            ], range: range)

        case .codeBlock:
            backing.addAttributes([
                .font: MarkdownFonts.codeBlock,
                .foregroundColor: MarkdownColors.codeText,
                .backgroundColor: MarkdownColors.codeBackground,
            ], range: range)

        case .horizontalRule:
            // Hide the "---" text — MarkdownLayoutManager draws a full-width line
            backing.addAttributes(Self.hiddenAttrs, range: range)
            let para = NSMutableParagraphStyle()
            para.minimumLineHeight = MarkdownLayout.bodyLineHeight
            para.maximumLineHeight = MarkdownLayout.bodyLineHeight
            para.paragraphSpacing = MarkdownLayout.paragraphSpacing
            backing.addAttribute(.paragraphStyle, value: para, range: range)

        case .tableRow:
            let isHeader = index + 1 < lineBlocks.count && lineBlocks[index + 1].block == .tableSeparator
            let font = isHeader ? MarkdownFonts.bodyBold : MarkdownFonts.body

            // Parse cells and set up tab-stop-based column layout
            let cells = Self.parseTableCells(line)
            let columnCount = max(cells.count, 1)

            let para = NSMutableParagraphStyle()
            para.minimumLineHeight = MarkdownLayout.bodyLineHeight
            para.maximumLineHeight = MarkdownLayout.bodyLineHeight
            para.paragraphSpacing = 0

            // Apply uniform style to the ENTIRE row first — this ensures every
            // character (including newly typed ones) gets visible text color and
            // the correct font. This is critical: processEditing() re-runs on
            // every keystroke, and per-character styling can interfere with the
            // text system's attribute resolution for the insertion point.
            backing.addAttributes([
                .font: font,
                .foregroundColor: MarkdownColors.text,
                .paragraphStyle: para,
                .baselineOffset: MarkdownLayout.bodyBaselineOffset,
            ], range: range)

            // Now color ONLY the pipe characters using NSString character-at-index
            // (not Swift String enumeration) to avoid Unicode offset mismatches.
            // We set foregroundColor only — font stays uniform from above.
            let nsLine = backing.string as NSString
            for offset in 0..<range.length {
                let charIndex = range.location + offset
                if nsLine.character(at: charIndex) == 0x7C /* "|" */ {
                    backing.addAttribute(
                        .foregroundColor,
                        value: MarkdownColors.tableBorder,
                        range: NSRange(location: charIndex, length: 1)
                    )
                }
            }

            // Store column count for LayoutManager (via a custom attribute)
            backing.addAttribute(.tableColumnCount, value: columnCount, range: range)
            backing.addAttribute(.tableIsHeader, value: isHeader, range: range)

        case .tableSeparator:
            // Style separator row as muted border-colored text (visible but de-emphasized).
            // Hiding it entirely breaks editing: processEditing() re-parses on each keystroke
            // and a fully-hidden separator can cause table row misclassification.
            let para = NSMutableParagraphStyle()
            para.minimumLineHeight = MarkdownLayout.bodyLineHeight
            para.maximumLineHeight = MarkdownLayout.bodyLineHeight
            para.paragraphSpacing = 0
            backing.addAttributes([
                .font: MarkdownFonts.body,
                .foregroundColor: MarkdownColors.tableBorder,
                .paragraphStyle: para,
                .baselineOffset: MarkdownLayout.bodyBaselineOffset,
            ], range: range)

        case .paragraph:
            break
        }
    }

    private static func headingPrefixLength(_ line: String) -> Int {
        let leadingSpaces = line.prefix(while: { $0 == " " || $0 == "\t" }).count
        let afterSpaces = line.dropFirst(leadingSpaces)
        var hashCount = 0
        for ch in afterSpaces {
            if ch == "#" { hashCount += 1 } else { break }
        }
        guard hashCount >= 1, hashCount <= 6 else { return 0 }
        let total = leadingSpaces + hashCount
        if afterSpaces.count > hashCount {
            let charAfterHash = afterSpaces[afterSpaces.index(afterSpaces.startIndex, offsetBy: hashCount)]
            if charAfterHash == " " { return total + 1 }
        }
        return total
    }

    // MARK: - Inline Formatting

    private func applyInlineFormatting() {
        let text = backing.string
        let nsText = text as NSString

        // Determine code block and table ranges to skip inline formatting.
        // Table rows contain pipe characters that can interfere with inline
        // regex patterns (e.g. bold ** or strikethrough ~~), so we exclude them.
        var skipRanges: [NSRange] = []
        var inCode = false
        var codeStart = 0
        for (range, block) in lineBlocks {
            switch block {
            case .codeFenceOpen:
                inCode = true
                codeStart = range.location
            case .codeFenceClose:
                inCode = false
                skipRanges.append(NSRange(location: codeStart, length: NSMaxRange(range) - codeStart))
            case .tableRow, .tableSeparator:
                skipRanges.append(range)
            default:
                break
            }
        }

        func isInCodeBlock(_ range: NSRange) -> Bool {
            skipRanges.contains { NSIntersectionRange($0, range).length > 0 }
        }

        // Bold+Italic: ***text*** — MUST come before bold and italic
        applyInlineHidden(nsText: nsText, pattern: "\\*\\*\\*(.+?)\\*\\*\\*", markerLen: 3, isInCodeBlock: isInCodeBlock) { contentRange in
            self.backing.addAttribute(.font, value: MarkdownFonts.bodyBoldItalic, range: contentRange)
        }

        // Bold: **text** or __text__ (not preceded/followed by extra *)
        applyInlineHidden(nsText: nsText, pattern: "(?<!\\*)\\*\\*(?!\\*)(.+?)(?<!\\*)\\*\\*(?!\\*)", markerLen: 2, isInCodeBlock: isInCodeBlock) { contentRange in
            self.backing.addAttribute(.font, value: MarkdownFonts.bodyBold, range: contentRange)
        }
        applyInlineHidden(nsText: nsText, pattern: "(?<!_)__(?!_)(.+?)(?<!_)__(?!_)", markerLen: 2, isInCodeBlock: isInCodeBlock) { contentRange in
            self.backing.addAttribute(.font, value: MarkdownFonts.bodyBold, range: contentRange)
        }

        // Italic: *text* or _text_ (not preceded/followed by extra *)
        applyInlineHidden(nsText: nsText, pattern: "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)", markerLen: 1, isInCodeBlock: isInCodeBlock) { contentRange in
            self.backing.addAttribute(.font, value: MarkdownFonts.bodyItalic, range: contentRange)
        }
        applyInlineHidden(nsText: nsText, pattern: "(?<!_)_(?!_)(.+?)(?<!_)_(?!_)", markerLen: 1, isInCodeBlock: isInCodeBlock) { contentRange in
            self.backing.addAttribute(.font, value: MarkdownFonts.bodyItalic, range: contentRange)
        }

        // Underline: ++text++ — extended markdown syntax
        applyInlineHidden(nsText: nsText, pattern: "\\+\\+(.+?)\\+\\+", markerLen: 2, isInCodeBlock: isInCodeBlock) { contentRange in
            self.backing.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: contentRange)
        }

        // Highlight: ==text== — custom background drawn by MarkdownLayoutManager
        applyInlineHidden(nsText: nsText, pattern: "==(.+?)==", markerLen: 2, isInCodeBlock: isInCodeBlock) { contentRange in
            self.backing.addAttribute(.highlightBackground, value: MarkdownColors.highlightBackground, range: contentRange)
        }

        // Strikethrough: ~~text~~
        applyInlineHidden(nsText: nsText, pattern: "~~(.+?)~~", markerLen: 2, isInCodeBlock: isInCodeBlock) { contentRange in
            self.backing.addAttributes([
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: MarkdownColors.strikethrough,
            ], range: contentRange)
        }

        // Inline code: `code`
        applyInlineHidden(nsText: nsText, pattern: "`([^`]+)`", markerLen: 1, isInCodeBlock: isInCodeBlock) { contentRange in
            self.backing.addAttributes([
                .font: MarkdownFonts.code,
                .foregroundColor: MarkdownColors.codeText,
                .backgroundColor: MarkdownColors.codeBackground,
            ], range: contentRange)
        }

        // Links: [text](url)
        if let regex = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)") {
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
            for match in matches {
                let fullRange = match.range
                guard !isInCodeBlock(fullRange) else { continue }

                let textRange = match.range(at: 1)
                backing.addAttributes(Self.hiddenAttrs, range: NSRange(location: fullRange.location, length: 1))
                backing.addAttributes([
                    .foregroundColor: MarkdownColors.link,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                ], range: textRange)

                let closingStart = NSMaxRange(textRange)
                let closingLen = NSMaxRange(fullRange) - closingStart
                if closingLen > 0 {
                    backing.addAttributes(Self.hiddenAttrs, range: NSRange(location: closingStart, length: closingLen))
                }
            }
        }
    }

    private func applyInlineHidden(nsText: NSString, pattern: String, markerLen: Int, isInCodeBlock: (NSRange) -> Bool, apply: (NSRange) -> Void) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let matches = regex.matches(in: nsText as String, range: NSRange(location: 0, length: nsText.length))
        for match in matches {
            let fullRange = match.range
            guard !isInCodeBlock(fullRange) else { continue }

            let contentRange = match.range(at: 1)
            guard contentRange.location != NSNotFound, contentRange.length > 0 else { continue }

            let openRange = NSRange(location: fullRange.location, length: markerLen)
            backing.addAttributes(Self.hiddenAttrs, range: openRange)

            apply(contentRange)

            let closeStart = NSMaxRange(contentRange)
            let closeLen = NSMaxRange(fullRange) - closeStart
            if closeLen > 0 {
                backing.addAttributes(Self.hiddenAttrs, range: NSRange(location: closeStart, length: closeLen))
            }
        }
    }

    // MARK: - Paragraph Style Helpers

    func defaultParagraphStyle() -> NSMutableParagraphStyle {
        let para = NSMutableParagraphStyle()
        para.paragraphSpacing = MarkdownLayout.paragraphSpacing
        // Fixed 24pt line height for body text
        para.minimumLineHeight = MarkdownLayout.bodyLineHeight
        para.maximumLineHeight = MarkdownLayout.bodyLineHeight
        return para
    }

    private func listParagraphStyle(indent: Int) -> NSMutableParagraphStyle {
        let para = NSMutableParagraphStyle()
        let indentPt = CGFloat(indent + 1) * MarkdownLayout.listIndentPerLevel
        // Both first-line and wrapped lines start at the same indent.
        // Prefix chars are collapsed to zero-width so they don't push text right.
        // Bullets/checkboxes/numbers are drawn by MarkdownLayoutManager in the margin.
        para.firstLineHeadIndent = indentPt
        para.headIndent = indentPt
        para.paragraphSpacing = MarkdownLayout.listItemSpacing
        para.minimumLineHeight = MarkdownLayout.bodyLineHeight
        para.maximumLineHeight = MarkdownLayout.bodyLineHeight
        para.tabStops = [NSTextTab(textAlignment: .left, location: indentPt)]
        return para
    }
}
