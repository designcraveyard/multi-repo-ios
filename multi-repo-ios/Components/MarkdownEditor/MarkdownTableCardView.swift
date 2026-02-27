// MarkdownTableCardView.swift
// Read-only visual grid card rendered inline in the markdown text view.
// Positioned over invisible table pipe-syntax text. Tap opens the editor sheet.

import UIKit
import SwiftUI

// MARK: - MarkdownTableCardView

/// Read-only UIKit table card rendered as an overlay on top of invisible pipe-syntax
/// text in the editor. Displays a compact grid with optional header row/column styling,
/// horizontal scrolling when columns exceed the available width, and a delete button.
/// Tapping anywhere on the card opens the full `MarkdownTableEditorView` sheet.
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
    private let rowHeight: CGFloat = 44
    private let cellHPad: CGFloat = 8

    // Design tokens
    private let borderColor   = UIColor(Color.borderDefault)
    private let headerBG      = UIColor(Color.surfacesBaseLowContrast)
    private let bodyBG        = UIColor(Color.surfacesBasePrimary)
    private let textColor     = MarkdownColors.text
    private let cornerRadius: CGFloat = 8
    private let minColWidth: CGFloat  = 100

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

    /// Configures the scroll view and vertical row stack for the card's grid layout.
    private func setupShell() {
        backgroundColor = bodyBG
        layer.cornerRadius = cornerRadius
        layer.borderWidth = 1
        layer.borderColor = borderColor.cgColor
        clipsToBounds = true

        scrollView.isScrollEnabled = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = false
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
            // Allow rowStack to grow wider than frame when columns overflow → enables horizontal scroll.
            rowStack.widthAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.widthAnchor),
        ])
    }

    /// Rebuilds row subviews from the model's cell data. Called on init and refresh.
    private func buildRows() {
        rowStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (rowIdx, row) in model.cells.enumerated() {
            let isHeader = rowIdx == 0 && model.hasHeader
            rowStack.addArrangedSubview(makeRowView(cells: row, isHeaderRow: isHeader, hasHeaderColumn: model.hasHeaderColumn))
        }
    }

    /// Creates a single row view with a horizontal stack of cells, each with a text label.
    /// Header cells get semibold font; header columns get a tinted background.
    private func makeRowView(cells: [String], isHeaderRow: Bool, hasHeaderColumn: Bool) -> UIView {
        let container = UIView()
        container.backgroundColor = isHeaderRow ? headerBG : .clear
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: rowHeight).isActive = true

        // Bottom border (1pt, matches editor cell border)
        let bottomBorder = UIView()
        bottomBorder.backgroundColor = borderColor
        bottomBorder.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bottomBorder)
        NSLayoutConstraint.activate([
            bottomBorder.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bottomBorder.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomBorder.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bottomBorder.heightAnchor.constraint(equalToConstant: 1),
        ])

        guard !cells.isEmpty else { return container }

        // Horizontal stack: fillEqually with min column width — enables horizontal scroll.
        let colStack = UIStackView()
        colStack.axis = .horizontal
        colStack.distribution = .fillEqually
        colStack.spacing = 0
        colStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(colStack)
        NSLayoutConstraint.activate([
            colStack.topAnchor.constraint(equalTo: container.topAnchor),
            colStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            colStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            colStack.bottomAnchor.constraint(equalTo: bottomBorder.topAnchor),
        ])

        for (colIdx, text) in cells.enumerated() {
            let isHeaderCell = isHeaderRow || (hasHeaderColumn && colIdx == 0)

            let cell = UIView()
            cell.backgroundColor = (hasHeaderColumn && colIdx == 0 && !isHeaderRow) ? headerBG : .clear
            cell.translatesAutoresizingMaskIntoConstraints = false
            // Min column width — when exceeded, horizontal scroll activates on the card.
            cell.widthAnchor.constraint(greaterThanOrEqualToConstant: minColWidth).isActive = true

            let label = UILabel()
            label.text = text
            label.font = isHeaderCell
                ? UIFont.systemFont(ofSize: MarkdownFonts.body.pointSize, weight: .semibold)
                : MarkdownFonts.body
            label.textColor = textColor
            label.lineBreakMode = .byTruncatingTail
            label.numberOfLines = 1
            label.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: cell.topAnchor),
                label.bottomAnchor.constraint(equalTo: cell.bottomAnchor),
                label.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: cellHPad),
                label.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -cellHPad),
            ])

            // Right border between columns (1pt, matches editor)
            if colIdx < cells.count - 1 {
                let divider = UIView()
                divider.backgroundColor = borderColor
                divider.translatesAutoresizingMaskIntoConstraints = false
                cell.addSubview(divider)
                NSLayoutConstraint.activate([
                    divider.widthAnchor.constraint(equalToConstant: 1),
                    divider.topAnchor.constraint(equalTo: cell.topAnchor),
                    divider.bottomAnchor.constraint(equalTo: cell.bottomAnchor),
                    divider.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
                ])
            }

            colStack.addArrangedSubview(cell)
        }
        return container
    }

    private func setupDeleteButton() {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "trash",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .medium))
        config.baseForegroundColor = UIColor(Color.iconsError)
        config.baseBackgroundColor = UIColor(Color.surfacesBaseLowContrast).withAlphaComponent(0.9)
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
