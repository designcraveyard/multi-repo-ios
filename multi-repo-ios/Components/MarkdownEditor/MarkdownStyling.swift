// MarkdownStyling.swift
// Centralized style tokens for AppMarkdownEditor.
//
// All values MUST reference DesignTokens.swift — no hardcoded hex or raw point sizes.
// Font sizes map 1:1 with the web CSS variables in markdown-editor.css.

import UIKit
import SwiftUI

// MARK: - Fonts (UIFont for NSAttributedString)

enum MarkdownFonts {
    // Headings — map to web --typography-title-* tokens
    static let h1 = UIFont.systemFont(ofSize: 28, weight: .bold)     // title-lg
    static let h2 = UIFont.systemFont(ofSize: 24, weight: .bold)     // title-md
    static let h3 = UIFont.systemFont(ofSize: 20, weight: .bold)     // title-sm
    static let h4 = UIFont.systemFont(ofSize: 16, weight: .semibold) // body-lg-em
    static let h5 = UIFont.systemFont(ofSize: 14, weight: .semibold) // body-md-em
    static let h6 = UIFont.systemFont(ofSize: 12, weight: .semibold) // body-sm-em

    // Body
    static let body = UIFont.systemFont(ofSize: 14, weight: .regular) // body-md
    static let bodyBold = UIFont.systemFont(ofSize: 14, weight: .bold)
    static let bodyItalic: UIFont = {
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            .withSize(14)
            .withSymbolicTraits(.traitItalic) ?? UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withSize(14)
        return UIFont(descriptor: desc, size: 14)
    }()
    static let bodyBoldItalic: UIFont = {
        let traits: UIFontDescriptor.SymbolicTraits = [.traitBold, .traitItalic]
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            .withSize(14)
            .withSymbolicTraits(traits) ?? UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withSize(14)
        return UIFont(descriptor: desc, size: 14)
    }()

    // Code (monospace)
    static let code = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    static let codeBlock = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
}

// MARK: - Colors (UIColor for NSAttributedString)

enum MarkdownColors {
    static let text = UIColor(Color.typographyPrimary)
    static let textSecondary = UIColor(Color.typographySecondary)
    static let textMuted = UIColor(Color.typographyMuted)
    static let textAccent = UIColor(Color.typographyAccent)
    static let link = UIColor(Color.typographyAccent)
    // Code: SurfaceBaseHighContrast bg, mono font, secondary text
    static let codeBackground = UIColor(Color.surfacesBaseHighContrast)
    static let codeText = UIColor(Color.typographySecondary)
    // Blockquote uses a softer background
    static let blockquoteBackground = UIColor(Color.surfacesBaseLowContrast)
    static let blockquoteBorder = UIColor(Color.borderDefault)
    static let blockquoteText = UIColor(Color.typographySecondary)
    static let syntaxHidden = UIColor.clear
    static let checkboxChecked = UIColor(Color.surfacesBrandInteractive)
    static let checkboxUnchecked = UIColor(Color.typographyMuted)
    static let strikethrough = UIColor(Color.typographyMuted)
    static let tableBorder = UIColor(Color.borderDefault)
    static let tableHeaderBackground = UIColor(Color.surfacesBaseLowContrast)
    static let horizontalRule = UIColor(Color.borderDefault)
    static let onBrandPrimary = UIColor(Color.typographyOnBrandPrimary)
}

// MARK: - Layout

enum MarkdownLayout {
    static let listIndentPerLevel: CGFloat = 24
    static let blockquoteIndent: CGFloat = 16
    static let blockquoteBorderWidth: CGFloat = 3
    static let codeBlockPadding: CGFloat = CGFloat.space4
    static let codeInlinePaddingH: CGFloat = 4
    static let codeInlinePaddingV: CGFloat = 2
    static let codeBlockCornerRadius: CGFloat = CGFloat.radiusMD
    static let paragraphSpacing: CGFloat = 8
    static let headingSpacingBefore: CGFloat = 16
    static let headingSpacingAfter: CGFloat = 8
}

// MARK: - Bullet Characters

enum MarkdownBullets {
    static let levels: [String] = ["•", "◦", "▪"]

    static func bullet(forLevel level: Int) -> String {
        levels[level % levels.count]
    }
}

// MARK: - NativeMarkdownEditorStyling (wrapper chrome)
// Follows the NativeComponentStyling pattern for the SwiftUI wrapper.

enum NativeMarkdownEditorStyling {

    struct Colors {
        static let background = Color.surfacesBaseLowContrast
        static let border = Color.clear
        static let borderFocused = Color.borderActive
        static let borderSuccess = Color.borderSuccess
        static let borderWarning = Color.borderWarning
        static let borderError = Color.borderError
        static let label = Color.typographySecondary
        static let hint = Color.typographyMuted
        static let hintSuccess = Color.typographySuccess
        static let hintWarning = Color.typographyWarning
        static let hintError = Color.typographyError
        static let placeholder = Color.typographyMuted
        static let caret = Color.surfacesBrandInteractive
    }

    struct Layout {
        static let cornerRadius: CGFloat = .radiusMD
        static let paddingH: CGFloat = .space4
        static let paddingV: CGFloat = 14 // 3.5 * 4
        static let borderWidth: CGFloat = 1
        static let labelSpacing: CGFloat = .space1
    }

    struct Typography {
        static let label = Font.appBodySmallEm
        static let hint = Font.appCaptionMedium
    }
}
