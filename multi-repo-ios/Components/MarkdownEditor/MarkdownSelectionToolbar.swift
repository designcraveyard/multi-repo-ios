// MarkdownSelectionToolbar.swift
// Floating toolbar that appears above text selection.
// Shows formatting options (bold, italic, strike, code, link, headings).

import UIKit
import SwiftUI

// MARK: - MarkdownSelectionToolbar

class MarkdownSelectionToolbar: UIView {

    // MARK: - Properties

    var onAction: ((MarkdownToolbarAction) -> Void)?

    private let stackView = UIStackView()
    private let arrowLayer = CAShapeLayer()

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
        ButtonSpec(icon: "link", label: "Link", action: .link, dividerAfter: true),
        ButtonSpec(icon: "textformat.size.larger", label: "H1", action: .heading1, dividerAfter: false),
        ButtonSpec(icon: "textformat.size", label: "H2", action: .heading2, dividerAfter: false),
        ButtonSpec(icon: "textformat.size.smaller", label: "H3", action: .heading3, dividerAfter: false),
    ]

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = MarkdownColors.text
        layer.cornerRadius = CGFloat.radiusMD
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8

        stackView.axis = .horizontal
        stackView.spacing = 2
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
        ])

        for spec in buttons {
            let btn = createButton(spec: spec)
            stackView.addArrangedSubview(btn)

            if spec.dividerAfter {
                let divider = createDivider()
                stackView.addArrangedSubview(divider)
            }
        }

        // Size to fit content
        setNeedsLayout()
        layoutIfNeeded()
    }

    private func createButton(spec: ButtonSpec) -> UIButton {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        btn.setImage(UIImage(systemName: spec.icon, withConfiguration: config), for: .normal)
        btn.tintColor = UIColor(NativeMarkdownEditorStyling.Colors.background)
        btn.accessibilityLabel = spec.label
        btn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            btn.widthAnchor.constraint(equalToConstant: 32),
            btn.heightAnchor.constraint(equalToConstant: 32),
        ])
        btn.layer.cornerRadius = 4
        btn.addAction(UIAction { [weak self] _ in
            self?.onAction?(spec.action)
        }, for: .touchUpInside)
        return btn
    }

    private func createDivider() -> UIView {
        let div = UIView()
        div.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        div.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            div.widthAnchor.constraint(equalToConstant: 1),
            div.heightAnchor.constraint(equalToConstant: 20),
        ])
        return div
    }

    // MARK: - Positioning

    /// Position the toolbar centered above the given rect in the text view.
    func show(above rect: CGRect, in parentView: UIView) {
        let toolbarSize = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        let x = max(8, min(rect.midX - toolbarSize.width / 2, parentView.bounds.width - toolbarSize.width - 8))
        let y = rect.minY - toolbarSize.height - 8

        frame = CGRect(x: x, y: max(4, y), width: toolbarSize.width, height: toolbarSize.height)

        if superview == nil {
            alpha = 0
            parentView.addSubview(self)
            UIView.animate(withDuration: 0.15) { self.alpha = 1 }
        }
    }

    func dismiss() {
        UIView.animate(withDuration: 0.1, animations: { self.alpha = 0 }) { _ in
            self.removeFromSuperview()
        }
    }

    override var intrinsicContentSize: CGSize {
        let size = stackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return CGSize(width: size.width + 8, height: size.height + 8)
    }
}
