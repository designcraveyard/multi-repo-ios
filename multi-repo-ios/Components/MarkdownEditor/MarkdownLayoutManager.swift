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
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)

        guard let storage = markdownStorage,
              let container = textContainers.first else { return }

        let visibleCharRange = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)

        for (lineRange, block) in storage.lineBlocks {
            guard NSIntersectionRange(visibleCharRange, lineRange).length > 0 else { continue }

            let line = (storage.string as NSString).substring(with: lineRange)
            let leadingSpaces = line.prefix(while: { $0 == " " || $0 == "\t" }).count

            switch block {
            case .bulletList(let indent):
                // Draw SF Symbol bullet over the invisible dash character
                let dashIndex = lineRange.location + leadingSpaces
                guard dashIndex < NSMaxRange(lineRange) else { continue }
                drawBulletSymbol(at: dashIndex, indent: indent, origin: origin, container: container)

            case .taskList(_, let checked):
                // Draw SF Symbol checkbox over the invisible "[ ]" characters
                let cbStart = lineRange.location + leadingSpaces + 2 // after "- "
                guard cbStart + 3 <= NSMaxRange(lineRange) else { continue }
                drawCheckbox(at: cbStart, length: 3, checked: checked, origin: origin, container: container)

            default:
                break
            }
        }
    }

    // MARK: - SF Symbol Bullet

    private func drawBulletSymbol(at charIndex: Int, indent: Int, origin: CGPoint, container: NSTextContainer) {
        let glyphIndex = glyphIndexForCharacter(at: charIndex)
        var glyphRect = boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: container)
        glyphRect = glyphRect.offsetBy(dx: origin.x, dy: origin.y)

        // Pick the SF Symbol based on nesting depth
        let symbolName = MarkdownSymbols.bulletSymbol(forLevel: indent)
        let pointSize = MarkdownSymbols.bulletSymbolSize
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .bold)
        guard let image = UIImage(systemName: symbolName, withConfiguration: config)?
            .withTintColor(MarkdownColors.text, renderingMode: .alwaysOriginal) else { return }

        // Size the bullet image — slightly larger than the point size for visual weight
        let imageSize: CGFloat = pointSize + 2
        let imageRect = CGRect(
            x: glyphRect.midX - imageSize / 2,
            y: glyphRect.midY - imageSize / 2,
            width: imageSize,
            height: imageSize
        )
        image.draw(in: imageRect)
    }

    // MARK: - SF Symbol Checkbox

    private func drawCheckbox(at charIndex: Int, length: Int, checked: Bool, origin: CGPoint, container: NSTextContainer) {
        let glyphIndex = glyphIndexForCharacter(at: charIndex)
        var cbRect = boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: length), in: container)
        cbRect = cbRect.offsetBy(dx: origin.x, dy: origin.y)

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
            x: cbRect.minX,
            y: cbRect.midY - imageSize / 2,
            width: imageSize,
            height: imageSize
        )
        image.draw(in: imageRect)
    }
}
