// MarkdownTableView.swift
// UIView-based visual table overlay for the markdown editor.
// Uses UICollectionView with compositional layout for an editable grid.
// Header row has distinct styling. Supports context menu for row/column operations.

import UIKit
import SwiftUI
import Combine

// MARK: - MarkdownTableView

class MarkdownTableView: UIView {

    // MARK: - Properties

    let model: MarkdownTableModel
    private var collectionView: UICollectionView!
    private var cancellables = Set<AnyCancellable>()
    var onModelChanged: (() -> Void)?

    /// Focused cell for blue highlight.
    private var focusedIndexPath: IndexPath?

    // Design tokens
    private let borderColor = UIColor(Color.borderDefault)
    private let headerBackground = UIColor(Color.surfacesBaseLowContrast)
    private let selectionColor = UIColor(Color.surfacesBrandInteractive).withAlphaComponent(0.12)
    private let cellFont = MarkdownFonts.body
    private let headerFont = UIFont.systemFont(ofSize: MarkdownFonts.body.pointSize, weight: .semibold)
    private let cornerRadius: CGFloat = 8

    // MARK: - Init

    init(model: MarkdownTableModel) {
        self.model = model
        super.init(frame: .zero)
        setupCollectionView()
        observeModel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    // MARK: - Setup

    private func setupCollectionView() {
        let layout = createLayout()
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(TableCellView.self, forCellWithReuseIdentifier: TableCellView.reuseID)
        collectionView.isScrollEnabled = false
        addSubview(collectionView)

        layer.cornerRadius = cornerRadius
        layer.borderWidth = 1
        layer.borderColor = borderColor.cgColor
        clipsToBounds = true

        // Context menu
        let interaction = UIContextMenuInteraction(delegate: self)
        addInteraction(interaction)
    }

    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] section, environment in
            guard let self else { return nil }
            let colCount = self.model.columnCount
            guard colCount > 0 else { return nil }
            let itemWidth: NSCollectionLayoutDimension = .fractionalWidth(1.0 / CGFloat(colCount))
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .estimated(44))
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44)),
                repeatingSubitem: item,
                count: colCount
            )
            let section = NSCollectionLayoutSection(group: group)
            return section
        }
    }

    private func observeModel() {
        model.$cells
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.reloadData() }
            .store(in: &cancellables)
    }

    // MARK: - Layout

    override var intrinsicContentSize: CGSize {
        let rowHeight: CGFloat = 44
        let height = CGFloat(model.rowCount) * rowHeight
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }

    func reloadData() {
        collectionView.collectionViewLayout = createLayout()
        collectionView.reloadData()
        invalidateIntrinsicContentSize()
        onModelChanged?()
    }
}

// MARK: - UICollectionViewDataSource

extension MarkdownTableView: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        model.rowCount * model.columnCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TableCellView.reuseID, for: indexPath) as! TableCellView
        let row = indexPath.item / model.columnCount
        let col = indexPath.item % model.columnCount
        let isHeader = row == 0
        let isFocused = indexPath == focusedIndexPath

        cell.configure(
            text: model.cells[row][col],
            isHeader: isHeader,
            isFocused: isFocused,
            font: isHeader ? headerFont : cellFont,
            headerBackground: headerBackground,
            selectionColor: selectionColor,
            borderColor: borderColor,
            alignment: model.alignments[col]
        )

        cell.onTextChanged = { [weak self] newText in
            guard let self, row < self.model.cells.count, col < self.model.cells[row].count else { return }
            self.model.cells[row][col] = newText
            self.onModelChanged?()
        }

        cell.onTab = { [weak self] in
            self?.moveFocus(from: indexPath, forward: true)
        }

        cell.onReturn = { [weak self] in
            self?.moveFocus(from: indexPath, down: true)
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension MarkdownTableView: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        focusedIndexPath = indexPath
        collectionView.reloadData()
        // Focus the text field
        if let cell = collectionView.cellForItem(at: indexPath) as? TableCellView {
            cell.focusTextField()
        }
    }
}

// MARK: - UIContextMenuInteractionDelegate

extension MarkdownTableView: UIContextMenuInteractionDelegate {

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            self?.makeContextMenu()
        }
    }

    private func makeContextMenu() -> UIMenu {
        let addRow = UIAction(title: "Add Row", image: UIImage(systemName: "plus")) { [weak self] _ in
            self?.model.addRow()
        }
        let addColumn = UIAction(title: "Add Column", image: UIImage(systemName: "plus")) { [weak self] _ in
            self?.model.addColumn()
        }
        let deleteRow = UIAction(title: "Delete Last Row", image: UIImage(systemName: "minus"), attributes: model.rowCount > 1 ? [] : .disabled) { [weak self] _ in
            guard let self else { return }
            self.model.deleteRow(at: self.model.rowCount - 1)
        }
        let deleteColumn = UIAction(title: "Delete Last Column", image: UIImage(systemName: "minus"), attributes: model.columnCount > 1 ? [] : .disabled) { [weak self] _ in
            guard let self else { return }
            self.model.deleteColumn(at: self.model.columnCount - 1)
        }

        let alignLeft = UIAction(title: "Align Left", image: UIImage(systemName: "text.alignleft")) { [weak self] _ in
            guard let self, let col = self.focusedColumn else { return }
            self.model.setAlignment(.left, forColumn: col)
            self.reloadData()
        }
        let alignCenter = UIAction(title: "Align Center", image: UIImage(systemName: "text.aligncenter")) { [weak self] _ in
            guard let self, let col = self.focusedColumn else { return }
            self.model.setAlignment(.center, forColumn: col)
            self.reloadData()
        }
        let alignRight = UIAction(title: "Align Right", image: UIImage(systemName: "text.alignright")) { [weak self] _ in
            guard let self, let col = self.focusedColumn else { return }
            self.model.setAlignment(.right, forColumn: col)
            self.reloadData()
        }
        let alignMenu = UIMenu(title: "Align Column", image: UIImage(systemName: "text.alignleft"), children: [alignLeft, alignCenter, alignRight])

        let copyMarkdown = UIAction(title: "Copy as Markdown", image: UIImage(systemName: "doc.on.doc")) { [weak self] _ in
            UIPasteboard.general.string = self?.model.toMarkdown()
        }

        return UIMenu(children: [addRow, addColumn, deleteRow, deleteColumn, alignMenu, copyMarkdown])
    }

    private var focusedColumn: Int? {
        guard let ip = focusedIndexPath else { return nil }
        return ip.item % model.columnCount
    }

    // MARK: - Focus Navigation

    private func moveFocus(from indexPath: IndexPath, forward: Bool = false, down: Bool = false) {
        let row = indexPath.item / model.columnCount
        let col = indexPath.item % model.columnCount
        var newRow = row
        var newCol = col

        if forward {
            newCol += 1
            if newCol >= model.columnCount {
                newCol = 0
                newRow += 1
            }
        }
        if down {
            newRow += 1
            if newRow >= model.rowCount {
                model.addRow()
            }
        }

        guard newRow < model.rowCount, newCol < model.columnCount else { return }
        let newIndex = IndexPath(item: newRow * model.columnCount + newCol, section: 0)
        focusedIndexPath = newIndex
        collectionView.reloadData()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            if let cell = self?.collectionView.cellForItem(at: newIndex) as? TableCellView {
                cell.focusTextField()
            }
        }
    }
}

// MARK: - TableCellView

private class TableCellView: UICollectionViewCell {

    static let reuseID = "TableCellView"

    private let textField = UITextField()
    var onTextChanged: ((String) -> Void)?
    var onTab: (() -> Void)?
    var onReturn: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        textField.borderStyle = .none
        textField.textColor = MarkdownColors.text
        textField.backgroundColor = .clear
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        contentView.addSubview(textField)

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            textField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            textField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),
        ])

        // Border on the right and bottom of each cell
        let rightBorder = UIView()
        rightBorder.backgroundColor = UIColor(Color.borderDefault)
        rightBorder.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rightBorder)
        NSLayoutConstraint.activate([
            rightBorder.widthAnchor.constraint(equalToConstant: 0.5),
            rightBorder.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rightBorder.topAnchor.constraint(equalTo: contentView.topAnchor),
            rightBorder.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        let bottomBorder = UIView()
        bottomBorder.backgroundColor = UIColor(Color.borderDefault)
        bottomBorder.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bottomBorder)
        NSLayoutConstraint.activate([
            bottomBorder.heightAnchor.constraint(equalToConstant: 0.5),
            bottomBorder.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomBorder.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomBorder.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    func configure(
        text: String,
        isHeader: Bool,
        isFocused: Bool,
        font: UIFont,
        headerBackground: UIColor,
        selectionColor: UIColor,
        borderColor: UIColor,
        alignment: ColumnAlignment
    ) {
        textField.text = text
        textField.font = font

        contentView.backgroundColor = isFocused ? selectionColor : (isHeader ? headerBackground : .clear)

        switch alignment {
        case .left: textField.textAlignment = .left
        case .center: textField.textAlignment = .center
        case .right: textField.textAlignment = .right
        }
    }

    func focusTextField() {
        textField.becomeFirstResponder()
    }

    @objc private func textChanged() {
        onTextChanged?(textField.text ?? "")
    }
}
