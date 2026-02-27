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

/// UIFont values used inside NSAttributedString for the UITextView backend.
/// Includes iPad scaling (1.25x) and all heading/body/code font variants.
enum MarkdownFonts {

    // ── iPad Scaling ────────────────────────────────────────────────
    // iPad uses 20pt base (1.25× iPhone 16pt) per user feedback.

    /// Scale factor: 1.25 on iPad, 1.0 on iPhone.
    static let scale: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 1.25 : 1.0

    // ── Base Sizes (pre-scale) ─────────────────────────────────────
    private static let h1Size: CGFloat = 28
    private static let h2Size: CGFloat = 24
    private static let h3Size: CGFloat = 20
    private static let h4Size: CGFloat = 18
    private static let h5Size: CGFloat = 16
    private static let h6Size: CGFloat = 14
    private static let bodySize: CGFloat = 16
    private static let codeSize: CGFloat = 14

    // ── Headings ─────────────────────────────────────────────────────

    /// H1: Title Large — 28pt (35pt iPad) bold.
    static let h1 = UIFont.systemFont(ofSize: h1Size * scale, weight: .bold)

    /// H2: Title Medium — 24pt (30pt iPad) bold.
    static let h2 = UIFont.systemFont(ofSize: h2Size * scale, weight: .bold)

    /// H3: Title Small — 20pt (25pt iPad) bold.
    static let h3 = UIFont.systemFont(ofSize: h3Size * scale, weight: .bold)

    /// H4: Body Large Emphasis — 18pt (22.5pt iPad) semibold.
    static let h4 = UIFont.systemFont(ofSize: h4Size * scale, weight: .semibold)

    /// H5: Body Medium Emphasis — 16pt (20pt iPad) semibold.
    static let h5 = UIFont.systemFont(ofSize: h5Size * scale, weight: .semibold)

    /// H6: Body Small Emphasis — 14pt (17.5pt iPad) semibold.
    static let h6 = UIFont.systemFont(ofSize: h6Size * scale, weight: .semibold)


    // ── Body ─────────────────────────────────────────────────────────

    /// Default body text — 16pt (20pt iPad) regular.
    static let body = UIFont.systemFont(ofSize: bodySize * scale, weight: .regular)

    /// Bold emphasis — rendered by **text** or __text__ syntax.
    static let bodyBold = UIFont.systemFont(ofSize: bodySize * scale, weight: .bold)

    /// Italic emphasis — rendered by *text* or _text_ syntax.
    static let bodyItalic: UIFont = {
        let size = bodySize * scale
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            .withSize(size)
            .withSymbolicTraits(.traitItalic)
            ?? UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withSize(size)
        return UIFont(descriptor: desc, size: size)
    }()

    /// Bold + Italic — rendered by ***text*** syntax.
    static let bodyBoldItalic: UIFont = {
        let size = bodySize * scale
        let traits: UIFontDescriptor.SymbolicTraits = [.traitBold, .traitItalic]
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            .withSize(size)
            .withSymbolicTraits(traits)
            ?? UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withSize(size)
        return UIFont(descriptor: desc, size: size)
    }()


    // ── Code ─────────────────────────────────────────────────────────

    /// Inline code — 14pt (17.5pt iPad) monospace.
    static let code = UIFont.monospacedSystemFont(ofSize: codeSize * scale, weight: .regular)

    /// Code block — 14pt (17.5pt iPad) monospace.
    static let codeBlock = UIFont.monospacedSystemFont(ofSize: codeSize * scale, weight: .regular)


    // ── Helpers ──────────────────────────────────────────────────────

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

/// UIColor values for NSAttributedString attributes. Every color references a
/// `Color.*` semantic token from DesignTokens.swift, converted via `UIColor(Color.*)`.
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


    // ── Highlight ─────────────────────────────────────────────────────
    // ==highlighted text== uses a warning-toned background fill
    // drawn as a rounded rect by MarkdownLayoutManager.

    /// Highlight background — warm warning surface for ==text== spans.
    static let highlightBackground = UIColor(Color.surfacesWarningSubtle)


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

/// Spacing, indentation, and sizing constants that control the spatial rhythm
/// of rendered markdown content inside the editor.
enum MarkdownLayout {

    // ── Line Height ──────────────────────────────────────────────────
    // Body text uses a fixed 24pt line height (1.5× the 16pt body font).
    // This creates comfortable reading density matching Apple Notes.

    /// Fixed line height for body text — 24pt (30pt iPad).
    /// Applied via NSParagraphStyle.minimumLineHeight / maximumLineHeight.
    static let bodyLineHeight: CGFloat = 24 * MarkdownFonts.scale

    /// Baseline offset to vertically center text in the line box.
    static let bodyBaselineOffset: CGFloat = 1.2 * MarkdownFonts.scale


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
    static let codeBlockPadding: CGFloat = CGFloat.space2

    /// Horizontal padding for inline code spans.
    static let codeInlinePaddingH: CGFloat = 4

    /// Vertical padding for inline code spans.
    static let codeInlinePaddingV: CGFloat = 2

    /// Corner radius for code block background.
    static let codeBlockCornerRadius: CGFloat = CGFloat.radiusMD

    /// Corner radius for ==highlight== background rounded rects.
    static let highlightCornerRadius: CGFloat = 3


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

/// SF Symbol names and sizes for rendered list markers (bullets, checkboxes).
/// `MarkdownLayoutManager` draws these on top of invisible markdown syntax characters.
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

/// Visual tokens for the floating keyboard accessory toolbar (`MarkdownKeyboardToolbar`).
enum MarkdownToolbarStyling {

    /// Toolbar total height including padding — 52pt for breathing room.
    static let height: CGFloat = 52

    /// Individual button tap target size.
    static let buttonSize: CGFloat = 38

    /// Button corner radius for rounder glass buttons.
    static let buttonCornerRadius: CGFloat = 10

    /// SF Symbol point size for toolbar button icons.
    static let iconPointSize: CGFloat = 16

    /// SF Symbol weight for toolbar button icons.
    static let iconWeight: UIImage.SymbolWeight = .medium

    /// Horizontal spacing between buttons — tight for glass look.
    static let buttonSpacing: CGFloat = 1

    /// Divider height between button groups.
    static let dividerHeight: CGFloat = 24

    /// Horizontal padding on toolbar edges — more breathing room.
    static let edgePadding: CGFloat = 12
}


// ═══════════════════════════════════════════════════════════════════════
// MARK: - NativeMarkdownEditorStyling (Wrapper Chrome)
// ═══════════════════════════════════════════════════════════════════════
//
// Follows the NativeComponentStyling pattern for the SwiftUI wrapper.
// Controls the outer chrome: border, label, hint, placeholder, background.
// Does NOT affect the rendered markdown content inside the UITextView.

/// Wrapper chrome tokens for the `AppMarkdownEditor` SwiftUI view.
/// Controls the outer border, label, hint, placeholder, and background.
/// Does NOT affect the rendered markdown content inside the UITextView.
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
