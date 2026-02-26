// MarkdownTableCardView.swift
// Read-only visual grid card rendered inline in the markdown text view.
// Positioned over invisible table pipe-syntax text. Tap opens the editor sheet.

import UIKit
import SwiftUI

// MARK: - MarkdownTableCardView

class MarkdownTableCardView: UIView {

    // MARK: - Callbacks

    var onTap: (() -> Void)?
    var onDelete: (() -> Void)?

    // MARK: - Properties

    private let model: MarkdownTableModel
    private let scrollView = UIScrollView()
    private let rowStack = UIStackView()
    private let deleteButton = UIButton(type: .system)
    private let maxDisplayHeight: CGFloat = 200
    private let rowHeight: CGFloat = 36
    private let cellHPad: CGFloat = 8

    // Design tokens
    private let borderColor   = UIColor(Color.borderDefault)
    private let headerBG      = UIColor(Color.surfacesBaseLowContrast)
    private let bodyBG        = UIColor(Color.surfacesBasePrimary)
    private let textColor     = MarkdownColors.text
    private let dividerColor  = UIColor(Color.borderMuted)
    private let cornerRadius: CGFloat = 8

    // MARK: - Init

    init(model: MarkdownTableModel) {
        self.model = model
        super.init(frame: .zero)
        setupShell()
        buildRows()
        setupDeleteButton()
        setupTap()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupShell() {
        backgroundColor = bodyBG
        layer.cornerRadius = cornerRadius
        layer.borderWidth = 1
        layer.borderColor = borderColor.cgColor
        clipsToBounds = true

        scrollView.isScrollEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        rowStack.axis = .vertical
        rowStack.spacing = 0
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(rowStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            rowStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            rowStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            rowStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            rowStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            rowStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])
    }

    private func buildRows() {
        rowStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (rowIdx, row) in model.cells.enumerated() {
            let isHeader = rowIdx == 0 && model.hasHeader
            rowStack.addArrangedSubview(makeRowView(cells: row, isHeader: isHeader))
        }
    }

    private func makeRowView(cells: [String], isHeader: Bool) -> UIView {
        let container = UIView()
        container.backgroundColor = isHeader ? headerBG : .clear
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: rowHeight).isActive = true

        // Bottom border
        let border = UIView()
        border.backgroundColor = dividerColor
        border.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(border)
        NSLayoutConstraint.activate([
            border.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            border.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            border.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            border.heightAnchor.constraint(equalToConstant: 0.5),
        ])

        guard !cells.isEmpty else { return container }

        // Build equal-width columns
        var prevAnchor = container.leadingAnchor
        for (colIdx, text) in cells.enumerated() {
            let label = UILabel()
            label.text = text
            label.font = isHeader
                ? UIFont.systemFont(ofSize: MarkdownFonts.body.pointSize, weight: .semibold)
                : MarkdownFonts.body
            label.textColor = textColor
            label.lineBreakMode = .byTruncatingTail
            label.numberOfLines = 1
            label.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)

            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: container.topAnchor),
                label.bottomAnchor.constraint(equalTo: border.topAnchor),
                label.leadingAnchor.constraint(equalTo: prevAnchor, constant: cellHPad),
            ])

            if colIdx == cells.count - 1 {
                // Last column: pin to trailing edge
                label.trailingAnchor.constraint(
                    equalTo: container.trailingAnchor, constant: -cellHPad
                ).isActive = true
            } else {
                // Equal fractional width
                label.widthAnchor.constraint(
                    equalTo: container.widthAnchor,
                    multiplier: 1.0 / CGFloat(cells.count),
                    constant: -(cellHPad * 2)
                ).isActive = true

                // Vertical divider
                let divider = UIView()
                divider.backgroundColor = dividerColor
                divider.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(divider)
                NSLayoutConstraint.activate([
                    divider.widthAnchor.constraint(equalToConstant: 0.5),
                    divider.topAnchor.constraint(equalTo: container.topAnchor),
                    divider.bottomAnchor.constraint(equalTo: border.topAnchor),
                    divider.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: cellHPad),
                ])
                prevAnchor = divider.trailingAnchor
            }
        }
        return container
    }

    private func setupDeleteButton() {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "trash",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .medium))
        config.baseForegroundColor = .systemRed
        config.baseBackgroundColor = UIColor.systemBackground.withAlphaComponent(0.85)
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 7, bottom: 5, trailing: 7)
        deleteButton.configuration = config
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        addSubview(deleteButton)

        NSLayoutConstraint.activate([
            deleteButton.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
        ])
    }

    private func setupTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        addGestureRecognizer(tap)
    }

    // MARK: - Actions

    @objc private func cardTapped() { onTap?() }
    @objc private func deleteTapped() { onDelete?() }

    // MARK: - Refresh

    /// Rebuilds the row display after the underlying model data changes.
    func refresh() {
        buildRows()
    }

    // MARK: - Intrinsic Size

    override var intrinsicContentSize: CGSize {
        let contentHeight = CGFloat(model.rowCount) * rowHeight
        return CGSize(width: UIView.noIntrinsicMetric, height: min(contentHeight, maxDisplayHeight))
    }
}
