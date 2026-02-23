// MarkdownKeyboardToolbar.swift
// inputAccessoryView for the markdown editor's UITextView.
// Horizontal scrollable row of formatting buttons above the keyboard.

import UIKit
import SwiftUI

// MARK: - Toolbar Action

enum MarkdownToolbarAction {
    case bold
    case italic
    case strikethrough
    case inlineCode
    case heading1
    case heading2
    case heading3
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
}

// MARK: - MarkdownKeyboardToolbar

class MarkdownKeyboardToolbar: UIView {

    // MARK: - Properties

    var onAction: ((MarkdownToolbarAction) -> Void)?

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    private struct ButtonSpec {
        let icon: String
        let label: String
        let action: MarkdownToolbarAction
        let dividerAfter: Bool
    }

    private let buttons: [ButtonSpec] = [
        ButtonSpec(icon: "bold", label: "Bold", action: .bold, dividerAfter: false),
        ButtonSpec(icon: "italic", label: "Italic", action: .italic, dividerAfter: false),
        ButtonSpec(icon: "strikethrough", label: "Strikethrough", action: .strikethrough, dividerAfter: false),
        ButtonSpec(icon: "chevron.left.forwardslash.chevron.right", label: "Code", action: .inlineCode, dividerAfter: true),
        ButtonSpec(icon: "textformat.size.larger", label: "H1", action: .heading1, dividerAfter: false),
        ButtonSpec(icon: "textformat.size", label: "H2", action: .heading2, dividerAfter: false),
        ButtonSpec(icon: "textformat.size.smaller", label: "H3", action: .heading3, dividerAfter: true),
        ButtonSpec(icon: "list.bullet", label: "Bullet", action: .bulletList, dividerAfter: false),
        ButtonSpec(icon: "list.number", label: "Numbered", action: .orderedList, dividerAfter: false),
        ButtonSpec(icon: "checklist", label: "Task", action: .taskList, dividerAfter: true),
        ButtonSpec(icon: "text.quote", label: "Quote", action: .blockquote, dividerAfter: false),
        ButtonSpec(icon: "curlybraces", label: "Code Block", action: .codeBlock, dividerAfter: false),
        ButtonSpec(icon: "minus", label: "Divider", action: .horizontalRule, dividerAfter: true),
        ButtonSpec(icon: "tablecells", label: "Table", action: .table, dividerAfter: false),
        ButtonSpec(icon: "link", label: "Link", action: .link, dividerAfter: true),
        ButtonSpec(icon: "increase.indent", label: "Indent", action: .indent, dividerAfter: false),
        ButtonSpec(icon: "decrease.indent", label: "Outdent", action: .outdent, dividerAfter: false),
    ]

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: frame.width, height: 44))
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = UIColor(NativeMarkdownEditorStyling.Colors.background)
        autoresizingMask = .flexibleWidth

        // Top border
        let border = UIView()
        border.backgroundColor = UIColor(NativeMarkdownEditorStyling.Colors.borderFocused).withAlphaComponent(0.1)
        border.translatesAutoresizingMaskIntoConstraints = false
        addSubview(border)
        NSLayoutConstraint.activate([
            border.topAnchor.constraint(equalTo: topAnchor),
            border.leadingAnchor.constraint(equalTo: leadingAnchor),
            border.trailingAnchor.constraint(equalTo: trailingAnchor),
            border.heightAnchor.constraint(equalToConstant: 0.5),
        ])

        // Scroll view
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        // Stack view
        stackView.axis = .horizontal
        stackView.spacing = 2
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -8),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
        ])

        // Create buttons
        for spec in buttons {
            let btn = createButton(spec: spec)
            stackView.addArrangedSubview(btn)

            if spec.dividerAfter {
                let divider = createDivider()
                stackView.addArrangedSubview(divider)
            }
        }
    }

    private func createButton(spec: ButtonSpec) -> UIButton {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        btn.setImage(UIImage(systemName: spec.icon, withConfiguration: config), for: .normal)
        btn.tintColor = MarkdownColors.textSecondary
        btn.accessibilityLabel = spec.label
        btn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            btn.widthAnchor.constraint(equalToConstant: 36),
            btn.heightAnchor.constraint(equalToConstant: 36),
        ])
        btn.layer.cornerRadius = 6
        btn.addAction(UIAction { [weak self] _ in
            self?.onAction?(spec.action)
        }, for: .touchUpInside)
        return btn
    }

    private func createDivider() -> UIView {
        let div = UIView()
        div.backgroundColor = MarkdownColors.tableBorder
        div.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            div.widthAnchor.constraint(equalToConstant: 1),
            div.heightAnchor.constraint(equalToConstant: 24),
        ])
        return div
    }
}
