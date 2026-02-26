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

        // Tables are rendered by MarkdownTableView overlays — no drawing needed here.

        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)

        guard let storage = markdownStorage,
              let container = textContainers.first else { return }

        let visibleCharRange = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)

        for (lineRange, block) in storage.lineBlocks {
            let isVisible = NSIntersectionRange(visibleCharRange, lineRange).length > 0
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

    // Table rendering is handled by MarkdownTableView overlays — no drawing needed here.
}
