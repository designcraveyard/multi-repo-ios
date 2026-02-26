// MarkdownLayoutManager.swift
// Custom NSLayoutManager that draws bullet dots and SF Symbol checkboxes
// on top of invisible marker characters in the text storage.
//
// Works in tandem with MarkdownTextStorage which sets bullet/checkbox characters
// to invisible (clear foreground, normal width). This layout manager then draws
// the visual replacements at those character positions.

import UIKit

// MARK: - MarkdownLayoutManager

class MarkdownLayoutManager: NSLayoutManager {

    weak var markdownStorage: MarkdownTextStorage?

    // MARK: - Glyph Drawing

    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        // Draw highlight backgrounds BEFORE text so text renders on top
        drawHighlightBackgrounds(forGlyphRange: glyphsToShow, at: origin)

        // Draw code block container backgrounds BEFORE text so text renders on top
        drawCodeBlockContainers(forGlyphRange: glyphsToShow, at: origin)

        // Draw table backgrounds BEFORE text so text renders on top (not covered by fills)
        drawTableBackgrounds(forGlyphRange: glyphsToShow, at: origin)

        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)

        guard let storage = markdownStorage,
              let container = textContainers.first else { return }

        let visibleCharRange = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)

        // Collect table row groups for border drawing (backgrounds already drawn above)
        var tableGroup: [(range: NSRange, block: MarkdownBlockType)] = []

        for (lineRange, block) in storage.lineBlocks {
            let isVisible = NSIntersectionRange(visibleCharRange, lineRange).length > 0

            // Accumulate table rows into groups
            switch block {
            case .tableRow, .tableSeparator:
                tableGroup.append((lineRange, block))
                continue
            default:
                // Flush any accumulated table group
                if !tableGroup.isEmpty {
                    drawTableBorders(rows: tableGroup, origin: origin, container: container)
                    tableGroup.removeAll()
                }
            }

            guard isVisible else { continue }

            switch block {
            case .bulletList(let indent):
                drawBulletSymbol(lineRange: lineRange, indent: indent, origin: origin, container: container)

            case .orderedList(let indent, let number):
                drawOrderedNumber(lineRange: lineRange, indent: indent, number: number, origin: origin, container: container)

            case .taskList(let indent, let checked):
                drawCheckbox(lineRange: lineRange, indent: indent, checked: checked, origin: origin, container: container)

            case .horizontalRule:
                drawHorizontalRule(lineRange: lineRange, origin: origin, container: container)

            case .blockquote(let depth):
                drawBlockquoteBar(lineRange: lineRange, depth: depth, origin: origin, container: container)

            default:
                break
            }
        }

        // Flush final table group
        if !tableGroup.isEmpty {
            drawTableBorders(rows: tableGroup, origin: origin, container: container)
        }
    }

    // MARK: - Highlight Backgrounds

    /// Scans for the custom `.highlightBackground` attribute and draws rounded rects
    /// behind the text. Called before `super.drawGlyphs` so text renders on top.
    private func drawHighlightBackgrounds(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard let storage = textStorage,
              let container = textContainers.first else { return }

        let charRange = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)

        storage.enumerateAttribute(.highlightBackground, in: charRange, options: []) { value, attrRange, _ in
            guard let color = value as? UIColor else { return }

            let glyphRange = self.glyphRange(forCharacterRange: attrRange, actualCharacterRange: nil)

            // Enumerate line fragments to handle highlights that wrap across lines
            self.enumerateLineFragments(forGlyphRange: glyphRange) { _, usedRect, _, effectiveGlyphRange, _ in
                let intersection = NSIntersectionRange(glyphRange, effectiveGlyphRange)
                guard intersection.length > 0 else { return }

                var boundingRect = self.boundingRect(forGlyphRange: intersection, in: container)
                boundingRect.origin.x += origin.x
                boundingRect.origin.y += origin.y

                let path = UIBezierPath(
                    roundedRect: boundingRect,
                    cornerRadius: MarkdownLayout.highlightCornerRadius
                )
                color.setFill()
                path.fill()
            }
        }
    }

    // MARK: - Code Block Containers

    /// Groups consecutive code block lines (fence open → code lines → fence close)
    /// and draws a single full-width rounded container rect behind each group.
    /// Called before `super.drawGlyphs` so text renders on top.
    private func drawCodeBlockContainers(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard let storage = markdownStorage,
              let container = textContainers.first else { return }

        let visibleCharRange = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)

        // Collect consecutive code block groups from lineBlocks
        var groups: [[NSRange]] = []
        var currentGroup: [NSRange] = []

        for (lineRange, block) in storage.lineBlocks {
            switch block {
            case .codeFenceOpen, .codeBlock, .codeFenceClose:
                currentGroup.append(lineRange)
            default:
                if !currentGroup.isEmpty {
                    groups.append(currentGroup)
                    currentGroup = []
                }
            }
        }
        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }

        // Draw a rounded rect for each code block group
        let padding = MarkdownLayout.codeBlockPadding
        let cornerRadius = MarkdownLayout.codeBlockCornerRadius

        for group in groups {
            guard let firstRange = group.first, let lastRange = group.last else { continue }

            // Check if any line in the group intersects the visible range
            let groupRange = NSRange(location: firstRange.location, length: NSMaxRange(lastRange) - firstRange.location)
            guard NSIntersectionRange(visibleCharRange, groupRange).length > 0 else { continue }

            // Compute bounding rect from first to last line
            let firstGlyphIndex = glyphIndexForCharacter(at: firstRange.location)
            let lastGlyphIndex = glyphIndexForCharacter(at: lastRange.location)
            let firstLineRect = lineFragmentRect(forGlyphAt: firstGlyphIndex, effectiveRange: nil)
            let lastLineRect = lineFragmentRect(forGlyphAt: lastGlyphIndex, effectiveRange: nil)

            let containerRect = CGRect(
                x: origin.x - padding,
                y: origin.y + firstLineRect.minY - padding,
                width: container.size.width + padding * 2,
                height: (lastLineRect.maxY - firstLineRect.minY) + padding * 2
            )

            let path = UIBezierPath(roundedRect: containerRect, cornerRadius: cornerRadius)
            MarkdownColors.codeBackground.setFill()
            path.fill()
        }
    }

    // MARK: - SF Symbol Bullet

    private func drawBulletSymbol(lineRange: NSRange, indent: Int, origin: CGPoint, container: NSTextContainer) {
        let glyphIndex = glyphIndexForCharacter(at: lineRange.location)
        let lineRect = lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)

        let contentIndent = CGFloat(indent + 1) * MarkdownLayout.listIndentPerLevel
        let markerCenterX = contentIndent - MarkdownLayout.listIndentPerLevel / 2

        let symbolName = MarkdownSymbols.bulletSymbol(forLevel: indent)
        let pointSize = MarkdownSymbols.bulletSymbolSize
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .bold)
        guard let image = UIImage(systemName: symbolName, withConfiguration: config)?
            .withTintColor(MarkdownColors.text, renderingMode: .alwaysOriginal) else { return }

        let imageSize: CGFloat = pointSize + 2
        let imageRect = CGRect(
            x: origin.x + markerCenterX - imageSize / 2,
            y: origin.y + lineRect.midY - imageSize / 2,
            width: imageSize,
            height: imageSize
        )
        image.draw(in: imageRect)
    }

    // MARK: - Ordered List Number

    private func drawOrderedNumber(lineRange: NSRange, indent: Int, number: Int, origin: CGPoint, container: NSTextContainer) {
        let glyphIndex = glyphIndexForCharacter(at: lineRange.location)
        let lineRect = lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)

        let contentIndent = CGFloat(indent + 1) * MarkdownLayout.listIndentPerLevel
        let markerAreaStart = contentIndent - MarkdownLayout.listIndentPerLevel

        let numStr = "\(number)."
        let attrs: [NSAttributedString.Key: Any] = [
            .font: MarkdownFonts.body,
            .foregroundColor: MarkdownColors.text,
        ]
        let numSize = (numStr as NSString).size(withAttributes: attrs)

        // Right-align the number within the margin area, with small gap before content
        let numX = contentIndent - numSize.width - 6
        let numY = lineRect.midY - numSize.height / 2

        (numStr as NSString).draw(
            at: CGPoint(x: origin.x + max(markerAreaStart, numX), y: origin.y + numY),
            withAttributes: attrs
        )
    }

    // MARK: - SF Symbol Checkbox

    private func drawCheckbox(lineRange: NSRange, indent: Int, checked: Bool, origin: CGPoint, container: NSTextContainer) {
        let glyphIndex = glyphIndexForCharacter(at: lineRange.location)
        let lineRect = lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)

        let contentIndent = CGFloat(indent + 1) * MarkdownLayout.listIndentPerLevel
        let markerCenterX = contentIndent - MarkdownLayout.listIndentPerLevel / 2

        let symbolName = checked ? MarkdownSymbols.checkboxChecked : MarkdownSymbols.checkboxUnchecked
        let symbolColor = checked ? MarkdownColors.checkboxChecked : MarkdownColors.checkboxUnchecked
        let config = UIImage.SymbolConfiguration(
            pointSize: MarkdownSymbols.checkboxSymbolPointSize,
            weight: MarkdownSymbols.checkboxWeight
        )
        guard let image = UIImage(systemName: symbolName, withConfiguration: config)?
            .withTintColor(symbolColor, renderingMode: .alwaysOriginal) else { return }

        let imageSize = MarkdownSymbols.checkboxSize
        let imageRect = CGRect(
            x: origin.x + markerCenterX - imageSize / 2,
            y: origin.y + lineRect.midY - imageSize / 2,
            width: imageSize,
            height: imageSize
        )
        image.draw(in: imageRect)
    }

    // MARK: - Horizontal Rule (full-width line)

    private func drawHorizontalRule(lineRange: NSRange, origin: CGPoint, container: NSTextContainer) {
        let glyphIndex = glyphIndexForCharacter(at: lineRange.location)
        let lineRect = lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)

        let y = origin.y + lineRect.midY
        let path = UIBezierPath()
        path.move(to: CGPoint(x: origin.x, y: y))
        path.addLine(to: CGPoint(x: origin.x + container.size.width, y: y))
        path.lineWidth = 1
        MarkdownColors.horizontalRule.setStroke()
        path.stroke()
    }

    // MARK: - Blockquote Left Bar

    private func drawBlockquoteBar(lineRange: NSRange, depth: Int, origin: CGPoint, container: NSTextContainer) {
        let glyphIndex = glyphIndexForCharacter(at: lineRange.location)
        let lineRect = lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)

        for d in 0..<depth {
            let barX = origin.x + CGFloat(d) * MarkdownLayout.blockquoteIndent + 4
            let barRect = CGRect(
                x: barX,
                y: origin.y + lineRect.minY + 2,
                width: MarkdownLayout.blockquoteBorderWidth,
                height: lineRect.height - 4
            )
            let path = UIBezierPath(roundedRect: barRect, cornerRadius: MarkdownLayout.blockquoteBorderWidth / 2)
            MarkdownColors.blockquoteBorder.setFill()
            path.fill()
        }
    }

    // MARK: - Table Backgrounds (drawn BEFORE text)

    /// Pre-scans lineBlocks for table groups and draws header backgrounds
    /// and outer fills BEFORE super.drawGlyphs so text renders ON TOP.
    private func drawTableBackgrounds(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard let storage = markdownStorage,
              let container = textContainers.first else { return }

        let visibleCharRange = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        let cornerRadius: CGFloat = 8

        for group in storage.tableGroups() {
            guard NSIntersectionRange(visibleCharRange, group).length > 0 else { continue }

            let rowRects = tableRowRects(in: group, origin: origin, container: container, storage: storage)
            guard !rowRects.isEmpty else { continue }

            let tableTop = rowRects.first!.rect.minY
            let tableBottom = rowRects.last!.rect.maxY
            let tableWidth = container.size.width
            let tableRect = CGRect(x: origin.x, y: tableTop, width: tableWidth, height: tableBottom - tableTop)

            // Full table background (subtle, so grid lines show through)
            let bgPath = UIBezierPath(roundedRect: tableRect, cornerRadius: cornerRadius)
            UIColor(white: 0, alpha: 0.02).setFill()
            bgPath.fill()

            // Header background
            for row in rowRects where row.isHeader {
                let headerPath = UIBezierPath(
                    roundedRect: CGRect(x: row.rect.minX, y: row.rect.minY, width: row.rect.width, height: row.rect.height),
                    byRoundingCorners: [.topLeft, .topRight],
                    cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
                )
                MarkdownColors.tableHeaderBackground.setFill()
                headerPath.fill()
            }
        }
    }

    // MARK: - Table Borders (drawn AFTER text)

    /// Draws outer border, row dividers, and column dividers for a table group.
    /// Column dividers are positioned at actual pipe character locations in the text.
    private func drawTableBorders(rows: [(range: NSRange, block: MarkdownBlockType)], origin: CGPoint, container: NSTextContainer) {
        guard let storage = markdownStorage else { return }

        let rowRects = tableRowRects(rows: rows, origin: origin, container: container, storage: storage)
        guard !rowRects.isEmpty else { return }

        let tableWidth = container.size.width
        let borderWidth: CGFloat = 0.5
        let cornerRadius: CGFloat = 8

        let tableTop = rowRects.first!.rect.minY
        let tableBottom = rowRects.last!.rect.maxY
        let tableRect = CGRect(x: origin.x, y: tableTop, width: tableWidth, height: tableBottom - tableTop)

        // Outer border
        let outerPath = UIBezierPath(roundedRect: tableRect, cornerRadius: cornerRadius)
        outerPath.lineWidth = borderWidth
        MarkdownColors.tableBorder.setStroke()
        outerPath.stroke()

        // Horizontal row dividers
        for i in 1..<rowRects.count {
            let y = rowRects[i].rect.minY
            let isAfterHeader = i == 1 && rowRects[0].isHeader
            let hLine = UIBezierPath()
            hLine.move(to: CGPoint(x: origin.x, y: y))
            hLine.addLine(to: CGPoint(x: origin.x + tableWidth, y: y))
            hLine.lineWidth = isAfterHeader ? 1.5 : borderWidth
            MarkdownColors.tableBorder.setStroke()
            hLine.stroke()
        }

        // Column dividers at pipe character positions
        // Use the first data row to find pipe X positions
        let dataRows = rows.filter { if case .tableRow = $0.block { return true }; return false }
        guard let firstRow = dataRows.first else { return }
        let pipePositions = pipeXPositions(in: firstRow.range, origin: origin)

        for x in pipePositions {
            let vLine = UIBezierPath()
            vLine.move(to: CGPoint(x: x, y: tableTop))
            vLine.addLine(to: CGPoint(x: x, y: tableBottom))
            vLine.lineWidth = borderWidth
            MarkdownColors.tableBorder.setStroke()
            vLine.stroke()
        }
    }

    // MARK: - Table Helpers

    private struct TableRowInfo {
        let rect: CGRect
        let isHeader: Bool
    }

    /// Compute row rects from a table group NSRange.
    private func tableRowRects(in groupRange: NSRange, origin: CGPoint, container: NSTextContainer, storage: MarkdownTextStorage) -> [TableRowInfo] {
        let dataRows = storage.lineBlocks.filter { entry in
            if case .tableRow = entry.block,
               NSIntersectionRange(groupRange, entry.range).length > 0 { return true }
            return false
        }
        return tableRowRectsFromEntries(dataRows, origin: origin, container: container, storage: storage)
    }

    /// Compute row rects from an array of (range, block) entries.
    private func tableRowRects(rows: [(range: NSRange, block: MarkdownBlockType)], origin: CGPoint, container: NSTextContainer, storage: MarkdownTextStorage) -> [TableRowInfo] {
        let dataRows = rows.filter { if case .tableRow = $0.block { return true }; return false }
        return tableRowRectsFromEntries(dataRows, origin: origin, container: container, storage: storage)
    }

    private func tableRowRectsFromEntries(_ entries: [(range: NSRange, block: MarkdownBlockType)], origin: CGPoint, container: NSTextContainer, storage: MarkdownTextStorage) -> [TableRowInfo] {
        let tableWidth = container.size.width
        var result: [TableRowInfo] = []
        for entry in entries {
            let glyphIndex = glyphIndexForCharacter(at: entry.range.location)
            let lineRect = lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
            var effectiveRange = NSRange()
            let isHeader = (storage.attribute(.tableIsHeader, at: entry.range.location, effectiveRange: &effectiveRange) as? Bool) ?? false
            result.append(TableRowInfo(
                rect: CGRect(x: origin.x, y: origin.y + lineRect.minY, width: tableWidth, height: lineRect.height),
                isHeader: isHeader
            ))
        }
        return result
    }

    /// Find the X positions of interior pipe characters in a table row.
    /// Skips the first and last pipes (outer border handles those edges).
    private func pipeXPositions(in lineRange: NSRange, origin: CGPoint) -> [CGFloat] {
        guard let storage = textStorage else { return [] }
        let nsString = storage.string as NSString
        var positions: [CGFloat] = []

        // Find all pipe indices in the line
        var pipeIndices: [Int] = []
        for offset in 0..<lineRange.length {
            let charIndex = lineRange.location + offset
            if nsString.character(at: charIndex) == 0x7C /* "|" */ {
                pipeIndices.append(charIndex)
            }
        }

        // Skip first and last pipes (those are at the table edges)
        guard pipeIndices.count > 2 else { return [] }
        let interiorPipes = pipeIndices[1..<(pipeIndices.count - 1)]

        for charIndex in interiorPipes {
            let glyphIndex = glyphIndexForCharacter(at: charIndex)
            let location = self.location(forGlyphAt: glyphIndex)
            let lineFragRect = lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
            let x = origin.x + lineFragRect.origin.x + location.x
            positions.append(x)
        }

        return positions
    }
}
