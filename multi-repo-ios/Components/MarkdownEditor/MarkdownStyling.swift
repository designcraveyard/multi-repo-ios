// MarkdownStyling.swift
// Centralized style tokens for AppMarkdownEditor.
//
// This file defines ALL visual appearance values used by the markdown editor.
// Organized into five sections: Fonts, Colors, Layout, Symbols, and Wrapper Chrome.
//
// ┌─────────────────────────────────────────────────────────────────────┐
// │  RULES                                                              │
// │  1. All colors MUST reference DesignTokens.swift semantic tokens.    │
// │  2. No hardcoded hex colors or arbitrary pixel values.              │
// │  3. Font sizes map 1:1 with web CSS --typography-* tokens.          │
// │  4. Layout constants use CGFloat.space* / .radius* where possible.  │
// │  5. Any change here affects every markdown editor instance.         │
// └─────────────────────────────────────────────────────────────────────┘

import UIKit
import SwiftUI


// ═══════════════════════════════════════════════════════════════════════
// MARK: - Fonts
// ═══════════════════════════════════════════════════════════════════════
//
// UIFont values used inside NSAttributedString for the UITextView backend.
// SwiftUI Font equivalents live in DesignTokens.swift for wrapper chrome.
//
// Body is 16pt to match Apple Notes. Line height is controlled separately
// via paragraph styles (24pt = 1.5× body size).

enum MarkdownFonts {

    // ── Headings ─────────────────────────────────────────────────────
    // Maps to web --typography-title-* CSS custom properties.
    // Each level reduces size; H4–H6 use semibold to stay visually
    // distinct from body text at the same or smaller point size.

    /// H1: Title Large — 28pt bold. Primary document heading.
    static let h1 = UIFont.systemFont(ofSize: 28, weight: .bold)

    /// H2: Title Medium — 24pt bold. Section-level heading.
    static let h2 = UIFont.systemFont(ofSize: 24, weight: .bold)

    /// H3: Title Small — 20pt bold. Subsection heading.
    static let h3 = UIFont.systemFont(ofSize: 20, weight: .bold)

    /// H4: Body Large Emphasis — 18pt semibold. Minor heading.
    static let h4 = UIFont.systemFont(ofSize: 18, weight: .semibold)

    /// H5: Body Medium Emphasis — 16pt semibold. Same size as body but heavier.
    static let h5 = UIFont.systemFont(ofSize: 16, weight: .semibold)

    /// H6: Body Small Emphasis — 14pt semibold. Smallest heading level.
    static let h6 = UIFont.systemFont(ofSize: 14, weight: .semibold)


    // ── Body ─────────────────────────────────────────────────────────
    // Default text fonts. 16pt matches Apple Notes body size.
    // Line height (24pt) is controlled via NSParagraphStyle, not here.

    /// Default body text — 16pt regular. All non-heading, non-code content.
    static let body = UIFont.systemFont(ofSize: 16, weight: .regular)

    /// Bold emphasis — rendered by **text** or __text__ syntax.
    static let bodyBold = UIFont.systemFont(ofSize: 16, weight: .bold)

    /// Italic emphasis — rendered by *text* or _text_ syntax.
    static let bodyItalic: UIFont = {
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            .withSize(16)
            .withSymbolicTraits(.traitItalic)
            ?? UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withSize(16)
        return UIFont(descriptor: desc, size: 16)
    }()

    /// Bold + Italic — rendered by ***text*** syntax.
    static let bodyBoldItalic: UIFont = {
        let traits: UIFontDescriptor.SymbolicTraits = [.traitBold, .traitItalic]
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            .withSize(16)
            .withSymbolicTraits(traits)
            ?? UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withSize(16)
        return UIFont(descriptor: desc, size: 16)
    }()


    // ── Code ─────────────────────────────────────────────────────────
    // Monospace fonts for inline `code` and fenced ```code blocks```.
    // Slightly smaller than body to visually offset code from prose.

    /// Inline code — 14pt monospace. Sits inside body text.
    static let code = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)

    /// Code block — 14pt monospace. Full-line code in fenced blocks.
    static let codeBlock = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)


    // ── Helpers ──────────────────────────────────────────────────────
    // Font lookup by heading level (1–6).

    static func heading(level: Int) -> UIFont {
        switch level {
        case 1: return h1
        case 2: return h2
        case 3: return h3
        case 4: return h4
        case 5: return h5
        default: return h6
        }
    }
}


// ═══════════════════════════════════════════════════════════════════════
// MARK: - Colors
// ═══════════════════════════════════════════════════════════════════════
//
// UIColor values for NSAttributedString attributes.
// Every color references a Color.* semantic token from DesignTokens.swift.
// UIColor conversion: UIColor(Color.tokenName).
//
// Naming follows the pattern:
//   <element>       → primary color for that element
//   <element>Muted  → de-emphasized variant

enum MarkdownColors {

    // ── Text ─────────────────────────────────────────────────────────
    // Primary, secondary, and muted text tiers.

    /// Default text color — used for body, headings, list content.
    static let text = UIColor(Color.typographyPrimary)

    /// Secondary text — used for toolbar icons, metadata.
    static let textSecondary = UIColor(Color.typographySecondary)

    /// Muted text — used for disabled content, syntax hints, faded markers.
    static let textMuted = UIColor(Color.typographyMuted)

    /// Accent text — used for interactive elements like links.
    static let textAccent = UIColor(Color.typographyAccent)


    // ── Links ────────────────────────────────────────────────────────

    /// Link text color — accent blue, matches web anchor color.
    static let link = UIColor(Color.typographyAccent)


    // ── Code ─────────────────────────────────────────────────────────
    // Inline `code` and ```code blocks``` use a high-contrast surface
    // background with secondary text to visually separate from prose.

    /// Code background — subtle high-contrast surface fill.
    static let codeBackground = UIColor(Color.surfacesBaseHighContrast)

    /// Code text — secondary for visual separation from body.
    static let codeText = UIColor(Color.typographySecondary)


    // ── Blockquote ───────────────────────────────────────────────────
    // Blockquotes use a softer background with secondary text and
    // a left border rendered by MarkdownLayoutManager.

    /// Blockquote background fill — low-contrast surface.
    static let blockquoteBackground = UIColor(Color.surfacesBaseLowContrast)

    /// Blockquote left border — standard border color.
    static let blockquoteBorder = UIColor(Color.borderDefault)

    /// Blockquote text — secondary to distinguish from body.
    static let blockquoteText = UIColor(Color.typographySecondary)


    // ── Syntax ───────────────────────────────────────────────────────
    // Hidden syntax characters (**, ~~, ```, etc.) are made invisible.

    /// Syntax characters are fully transparent — drawn at near-zero width.
    static let syntaxHidden = UIColor.clear


    // ── Checkboxes ───────────────────────────────────────────────────
    // SF Symbol checkboxes in task lists. Checked = brand, unchecked = muted.

    /// Checked checkbox — brand interactive color (filled circle + check).
    static let checkboxChecked = UIColor(Color.surfacesBrandInteractive)

    /// Unchecked checkbox — muted (empty circle).
    static let checkboxUnchecked = UIColor(Color.typographyMuted)


    // ── Strikethrough ────────────────────────────────────────────────

    /// Strikethrough text — muted to show "done" or "deleted" state.
    static let strikethrough = UIColor(Color.typographyMuted)


    // ── Tables ───────────────────────────────────────────────────────
    // Table borders (pipe chars) and optional header row background.

    /// Table pipe character and separator row color.
    static let tableBorder = UIColor(Color.borderDefault)

    /// Table header row background — subtle fill.
    static let tableHeaderBackground = UIColor(Color.surfacesBaseLowContrast)


    // ── Horizontal Rule ──────────────────────────────────────────────

    /// Horizontal rule (---) rendered as a strikethrough line.
    static let horizontalRule = UIColor(Color.borderDefault)


    // ── On-Brand ─────────────────────────────────────────────────────

    /// Text on brand-colored backgrounds (e.g., checked badge overlays).
    static let onBrandPrimary = UIColor(Color.typographyOnBrandPrimary)
}


// ═══════════════════════════════════════════════════════════════════════
// MARK: - Layout
// ═══════════════════════════════════════════════════════════════════════
//
// Spacing, indentation, and sizing constants.
// Controls the spatial rhythm of the rendered markdown content.

enum MarkdownLayout {

    // ── Line Height ──────────────────────────────────────────────────
    // Body text uses a fixed 24pt line height (1.5× the 16pt body font).
    // This creates comfortable reading density matching Apple Notes.

    /// Fixed line height for body text — 24pt.
    /// Applied via NSParagraphStyle.minimumLineHeight / maximumLineHeight.
    static let bodyLineHeight: CGFloat = 24

    /// Baseline offset to vertically center 16pt text in 24pt line box.
    /// Formula: (lineHeight - fontLineHeight) / 4 ≈ (24 - 19.1) / 4
    static let bodyBaselineOffset: CGFloat = 1.2


    // ── Lists ────────────────────────────────────────────────────────
    // Lists use hanging indentation. Each nesting level adds one
    // indentPerLevel unit. The marker (bullet/number/checkbox) sits
    // at the left edge; content starts after markerTextSpacing.

    /// Horizontal indent per nesting level — 24pt.
    /// Level 0 content starts at 24pt, level 1 at 48pt, etc.
    static let listIndentPerLevel: CGFloat = 24

    /// Minimum horizontal space between list marker and text content — 8pt.
    /// Applies to bullet dots, numbers, and checkboxes equally.
    /// Implemented via kern attribute on the last invisible marker character.
    static let listMarkerTextSpacing: CGFloat = 8


    // ── Blockquotes ──────────────────────────────────────────────────

    /// Left indent per blockquote depth level — 16pt.
    static let blockquoteIndent: CGFloat = 16

    /// Left border thickness for blockquote visual indicator.
    static let blockquoteBorderWidth: CGFloat = 3


    // ── Code ─────────────────────────────────────────────────────────

    /// Padding inside fenced code blocks.
    static let codeBlockPadding: CGFloat = CGFloat.space4

    /// Horizontal padding for inline code spans.
    static let codeInlinePaddingH: CGFloat = 4

    /// Vertical padding for inline code spans.
    static let codeInlinePaddingV: CGFloat = 2

    /// Corner radius for code block background.
    static let codeBlockCornerRadius: CGFloat = CGFloat.radiusMD


    // ── Paragraph Spacing ────────────────────────────────────────────
    // Vertical space BETWEEN paragraphs (not within — that's line height).

    /// Space after a body paragraph — 8pt.
    static let paragraphSpacing: CGFloat = 8

    /// Space before a heading — 16pt. Gives headings visual breathing room.
    static let headingSpacingBefore: CGFloat = 16

    /// Space after a heading — 8pt.
    static let headingSpacingAfter: CGFloat = 8

    /// Space between list items — 2pt. Tight to keep lists compact.
    static let listItemSpacing: CGFloat = 2
}


// ═══════════════════════════════════════════════════════════════════════
// MARK: - Symbols
// ═══════════════════════════════════════════════════════════════════════
//
// SF Symbol names and sizes for rendered list markers.
// MarkdownLayoutManager draws these on top of invisible markdown syntax.

enum MarkdownSymbols {

    // ── Bullet List ──────────────────────────────────────────────────
    // Bullet dots are drawn as SF Symbols at each nesting level.
    // Level 0 = filled circle, level 1 = empty circle, level 2 = small square.

    /// SF Symbol names for bullet markers by nesting depth.
    static let bulletSymbols: [String] = [
        "circle.fill",      // Level 0 — solid dot
        "circle",            // Level 1 — hollow circle
        "square.fill",       // Level 2+ — small filled square
    ]

    /// Point size for bullet SF Symbols — 6pt for a compact dot.
    static let bulletSymbolSize: CGFloat = 6

    /// Returns the SF Symbol name for a given nesting level.
    static func bulletSymbol(forLevel level: Int) -> String {
        bulletSymbols[level % bulletSymbols.count]
    }


    // ── Task List Checkboxes ─────────────────────────────────────────
    // Checkboxes use filled/empty circle SF Symbols.

    /// Unchecked checkbox SF Symbol — empty circle.
    static let checkboxUnchecked = "circle"

    /// Checked checkbox SF Symbol — filled circle with checkmark.
    static let checkboxChecked = "checkmark.circle.fill"

    /// Point size for checkbox SF Symbols — 18pt for tap-friendly target.
    static let checkboxSize: CGFloat = 18

    /// SF Symbol configuration weight for checkboxes.
    static let checkboxWeight: UIImage.SymbolWeight = .regular

    /// Point size for SF Symbol configuration — controls symbol rendering.
    static let checkboxSymbolPointSize: CGFloat = 16
}


// ═══════════════════════════════════════════════════════════════════════
// MARK: - Keyboard Toolbar
// ═══════════════════════════════════════════════════════════════════════
//
// Visual tokens for the floating keyboard accessory toolbar.
// Uses system material blur for a liquid glass appearance on iOS 26+.

enum MarkdownToolbarStyling {

    /// Toolbar total height including padding.
    static let height: CGFloat = 48

    /// Individual button tap target size.
    static let buttonSize: CGFloat = 36

    /// Button corner radius for rounded appearance.
    static let buttonCornerRadius: CGFloat = 8

    /// SF Symbol point size for toolbar button icons.
    static let iconPointSize: CGFloat = 15

    /// SF Symbol weight for toolbar button icons.
    static let iconWeight: UIImage.SymbolWeight = .medium

    /// Horizontal spacing between buttons.
    static let buttonSpacing: CGFloat = 2

    /// Divider height between button groups.
    static let dividerHeight: CGFloat = 24

    /// Horizontal padding on toolbar edges.
    static let edgePadding: CGFloat = 8
}


// ═══════════════════════════════════════════════════════════════════════
// MARK: - NativeMarkdownEditorStyling (Wrapper Chrome)
// ═══════════════════════════════════════════════════════════════════════
//
// Follows the NativeComponentStyling pattern for the SwiftUI wrapper.
// Controls the outer chrome: border, label, hint, placeholder, background.
// Does NOT affect the rendered markdown content inside the UITextView.

enum NativeMarkdownEditorStyling {

    struct Colors {
        /// Editor surface background — low-contrast surface.
        static let background = Color.surfacesBaseLowContrast

        /// Default border — transparent (no visible border).
        static let border = Color.clear

        /// Focus border — active/interactive border when editing.
        static let borderFocused = Color.borderActive

        /// Success state border.
        static let borderSuccess = Color.borderSuccess

        /// Warning state border.
        static let borderWarning = Color.borderWarning

        /// Error state border.
        static let borderError = Color.borderError

        /// Label text color above the editor.
        static let label = Color.typographySecondary

        /// Hint text color below the editor (default state).
        static let hint = Color.typographyMuted

        /// Hint text color — success state.
        static let hintSuccess = Color.typographySuccess

        /// Hint text color — warning state.
        static let hintWarning = Color.typographyWarning

        /// Hint text color — error state.
        static let hintError = Color.typographyError

        /// Placeholder text when editor is empty.
        static let placeholder = Color.typographyMuted

        /// Caret (cursor) color — brand interactive.
        static let caret = Color.surfacesBrandInteractive
    }

    struct Layout {
        /// Outer corner radius of the editor container.
        static let cornerRadius: CGFloat = .radiusMD

        /// Horizontal padding inside the editor container.
        static let paddingH: CGFloat = .space4

        /// Vertical padding inside the editor container.
        static let paddingV: CGFloat = 14 // 3.5 × 4pt base unit

        /// Border stroke width.
        static let borderWidth: CGFloat = 1

        /// Spacing between label and editor.
        static let labelSpacing: CGFloat = .space1
    }

    struct Typography {
        /// Label font above the editor.
        static let label = Font.appBodySmallEm

        /// Hint font below the editor.
        static let hint = Font.appCaptionMedium
    }
}
