// MarkdownKeyboardToolbar.swift
// inputAccessoryView for the markdown editor's UITextView.
// Horizontal scrollable row of formatting buttons above the keyboard.
//
// Uses system material blur for a liquid glass appearance on iOS 26+.
// Buttons are grouped by function with thin dividers between groups.

import UIKit
import SwiftUI

// MARK: - Toolbar Action

enum MarkdownToolbarAction {
    case bold
    case italic
    case underline
    case strikethrough
    case highlight
    case inlineCode
    case heading1
    case heading2
    case heading3
    case headingPicker
    case bulletList
    case orderedList
    case taskList
    case blockquote
    case codeBlock
    case horizontalRule
    case link
    case table
    case indent
    case outdent
    case codePicker
    case aiTranscribe
    case aiTransform
}

// MARK: - MarkdownKeyboardToolbar

class MarkdownKeyboardToolbar: UIView {

    // MARK: - Properties

    var onAction: ((MarkdownToolbarAction) -> Void)?
    var onDismissKeyboard: (() -> Void)?

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let dismissButton = UIButton(type: .system)

    /// Stored buttons by action for runtime updates (e.g. transcribe icon state).
    private var buttonMap: [MarkdownToolbarAction: UIButton] = [:]

    private struct ButtonSpec {
        let icon: String
        let label: String
        let action: MarkdownToolbarAction
        let dividerAfter: Bool
    }

    private let buttons: [ButtonSpec] = [
        // Group 1: Inline formatting
        ButtonSpec(icon: "bold", label: "Bold", action: .bold, dividerAfter: false),
        ButtonSpec(icon: "italic", label: "Italic", action: .italic, dividerAfter: false),
        ButtonSpec(icon: "underline", label: "Underline", action: .underline, dividerAfter: false),
        ButtonSpec(icon: "strikethrough", label: "Strikethrough", action: .strikethrough, dividerAfter: false),
        ButtonSpec(icon: "highlighter", label: "Highlight", action: .highlight, dividerAfter: false),
        ButtonSpec(icon: "chevron.left.forwardslash.chevron.right", label: "Code", action: .codePicker, dividerAfter: true),

        // Group 2: Heading picker (single Aa button opens heading menu)
        ButtonSpec(icon: "textformat.size", label: "Heading", action: .headingPicker, dividerAfter: true),

        // Group 3: Lists
        ButtonSpec(icon: "list.bullet", label: "Bullet", action: .bulletList, dividerAfter: false),
        ButtonSpec(icon: "list.number", label: "Numbered", action: .orderedList, dividerAfter: false),
        ButtonSpec(icon: "checklist", label: "Task", action: .taskList, dividerAfter: true),

        // Group 4: Block elements
        ButtonSpec(icon: "text.quote", label: "Quote", action: .blockquote, dividerAfter: false),
        ButtonSpec(icon: "minus", label: "Divider", action: .horizontalRule, dividerAfter: true),

        // Group 5: Rich elements
        ButtonSpec(icon: "tablecells", label: "Table", action: .table, dividerAfter: false),
        ButtonSpec(icon: "link", label: "Link", action: .link, dividerAfter: true),

        // Group 6: Indentation
        ButtonSpec(icon: "increase.indent", label: "Indent", action: .indent, dividerAfter: false),
        ButtonSpec(icon: "decrease.indent", label: "Outdent", action: .outdent, dividerAfter: true),

        // Group 7: AI tools
        ButtonSpec(icon: "mic.fill", label: "Transcribe", action: .aiTranscribe, dividerAfter: false),
        ButtonSpec(icon: "sparkles", label: "AI Transform", action: .aiTransform, dividerAfter: false),
    ]

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: frame.width, height: MarkdownToolbarStyling.height))
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .clear
        autoresizingMask = .flexibleWidth

        // Liquid glass blur background
        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        // Subtle top separator
        let topSeparator = UIView()
        topSeparator.backgroundColor = UIColor.separator.withAlphaComponent(0.15)
        topSeparator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topSeparator)
        NSLayoutConstraint.activate([
            topSeparator.topAnchor.constraint(equalTo: topAnchor),
            topSeparator.leadingAnchor.constraint(equalTo: leadingAnchor),
            topSeparator.trailingAnchor.constraint(equalTo: trailingAnchor),
            topSeparator.heightAnchor.constraint(equalToConstant: 0.33),
        ])

        // Sticky keyboard dismiss button (right side)
        let dismissConfig = UIImage.SymbolConfiguration(pointSize: MarkdownToolbarStyling.iconPointSize, weight: .medium)
        dismissButton.setImage(UIImage(systemName: "keyboard.chevron.compact.down", withConfiguration: dismissConfig), for: .normal)
        dismissButton.tintColor = UIColor.label.withAlphaComponent(0.7)
        dismissButton.accessibilityLabel = "Dismiss Keyboard"
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.addAction(UIAction { [weak self] _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self?.onDismissKeyboard?()
        }, for: .touchUpInside)
        addSubview(dismissButton)
        NSLayoutConstraint.activate([
            dismissButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -MarkdownToolbarStyling.edgePadding),
            dismissButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            dismissButton.widthAnchor.constraint(equalToConstant: MarkdownToolbarStyling.buttonSize),
            dismissButton.heightAnchor.constraint(equalToConstant: MarkdownToolbarStyling.buttonSize),
        ])

        // Divider before dismiss button
        let dismissDivider = UIView()
        dismissDivider.backgroundColor = UIColor.separator.withAlphaComponent(0.3)
        dismissDivider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dismissDivider)
        NSLayoutConstraint.activate([
            dismissDivider.trailingAnchor.constraint(equalTo: dismissButton.leadingAnchor, constant: -2),
            dismissDivider.centerYAnchor.constraint(equalTo: centerYAnchor),
            dismissDivider.widthAnchor.constraint(equalToConstant: 0.5),
            dismissDivider.heightAnchor.constraint(equalToConstant: MarkdownToolbarStyling.dividerHeight),
        ])

        // Scroll view — leaves room for the sticky dismiss button on the right
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: dismissDivider.leadingAnchor, constant: -2),
        ])

        // Stack view
        stackView.axis = .horizontal
        stackView.spacing = MarkdownToolbarStyling.buttonSpacing
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: MarkdownToolbarStyling.edgePadding),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -MarkdownToolbarStyling.edgePadding),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
        ])

        // Create buttons
        for spec in buttons {
            let btn = createButton(spec: spec)
            stackView.addArrangedSubview(btn)
            buttonMap[spec.action] = btn

            if spec.dividerAfter {
                let divider = createDivider()
                stackView.addArrangedSubview(divider)
            }
        }
    }

    // MARK: - Public API

    /// Updates the icon and tint color of a toolbar button by action.
    /// Used by the coordinator to reflect recording/transcribing state on the transcribe button.
    func updateButton(action: MarkdownToolbarAction, icon: String, tintColor: UIColor) {
        guard let btn = buttonMap[action] else { return }
        let config = UIImage.SymbolConfiguration(
            pointSize: MarkdownToolbarStyling.iconPointSize,
            weight: MarkdownToolbarStyling.iconWeight
        )
        btn.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
        btn.tintColor = tintColor
    }

    /// Shows or hides a native iOS spinning activity indicator over the button.
    func setSpinner(action: MarkdownToolbarAction, visible: Bool) {
        guard let btn = buttonMap[action] else { return }
        let spinnerTag = 9999
        if visible {
            btn.setImage(nil, for: .normal)
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.tag = spinnerTag
            spinner.translatesAutoresizingMaskIntoConstraints = false
            spinner.startAnimating()
            btn.addSubview(spinner)
            NSLayoutConstraint.activate([
                spinner.centerXAnchor.constraint(equalTo: btn.centerXAnchor),
                spinner.centerYAnchor.constraint(equalTo: btn.centerYAnchor),
            ])
        } else {
            if let spinner = btn.viewWithTag(spinnerTag) as? UIActivityIndicatorView {
                spinner.stopAnimating()
                spinner.removeFromSuperview()
            }
        }
    }

    private func createButton(spec: ButtonSpec) -> UIButton {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(
            pointSize: MarkdownToolbarStyling.iconPointSize,
            weight: MarkdownToolbarStyling.iconWeight
        )
        btn.setImage(UIImage(systemName: spec.icon, withConfiguration: config), for: .normal)
        btn.tintColor = UIColor.label.withAlphaComponent(0.7)
        btn.accessibilityLabel = spec.label
        btn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            btn.widthAnchor.constraint(equalToConstant: MarkdownToolbarStyling.buttonSize),
            btn.heightAnchor.constraint(equalToConstant: MarkdownToolbarStyling.buttonSize),
        ])
        btn.layer.cornerRadius = MarkdownToolbarStyling.buttonCornerRadius

        // Highlight on touch + haptic
        btn.addAction(UIAction { [weak self] _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self?.onAction?(spec.action)
        }, for: .touchUpInside)

        btn.addAction(UIAction { _ in
            UIView.animate(withDuration: 0.1) {
                btn.backgroundColor = UIColor.label.withAlphaComponent(0.06)
            }
        }, for: .touchDown)

        btn.addAction(UIAction { _ in
            UIView.animate(withDuration: 0.15) {
                btn.backgroundColor = .clear
            }
        }, for: [.touchUpInside, .touchUpOutside, .touchCancel])

        return btn
    }

    private func createDivider() -> UIView {
        let div = UIView()
        div.backgroundColor = UIColor.separator.withAlphaComponent(0.3)
        div.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            div.widthAnchor.constraint(equalToConstant: 0.5),
            div.heightAnchor.constraint(equalToConstant: MarkdownToolbarStyling.dividerHeight),
        ])
        return div
    }
}
