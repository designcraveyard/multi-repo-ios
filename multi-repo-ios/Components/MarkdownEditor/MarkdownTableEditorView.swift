// MarkdownTableEditorView.swift
// Full-screen sheet for editing a markdown table.
// Contains an editable UICollectionView grid + floating MarkdownTableActionBar.
// Writes back to the markdown storage ONLY when the user taps Done.

import SwiftUI
import UIKit
import Combine

// MARK: - TableEditorSession

/// Identifiable wrapper passed to .fullScreenCover(item:).
struct TableEditorSession: Identifiable {
    let id = UUID()
    /// Working copy — edits here don't touch the storage until Done.
    let model: MarkdownTableModel
    /// Location in storage to replace on Done. nil = new table, insert at cursorPosition.
    let groupRange: NSRange?
    /// Cursor character offset — used when groupRange is nil (new insert).
    let cursorPosition: Int
}

// MARK: - MarkdownTableEditorView

struct MarkdownTableEditorView: View {

    // MARK: - Inputs

    let session: TableEditorSession
    let onCancel: () -> Void
    let onDone: (MarkdownTableModel) -> Void

    // MARK: - State

    @State private var focusedColumn: Int? = nil

    // MARK: - Body

    var body: some View {
        NavigationStack {
            MarkdownTableEditorGrid(
                model: session.model,
                onFocusedColumnChanged: { col in focusedColumn = col }
            )
            .ignoresSafeArea(.keyboard)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    HStack {
                        Spacer()
                        MarkdownTableActionBar(
                            model: session.model,
                            focusedColumn: focusedColumn
                        )
                        Spacer()
                    }
                    .padding(.bottom, 16)
                }
                .background(Color.clear)
            }
            .navigationTitle("Table")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onCancel) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { onDone(session.model) }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(uiColor: MarkdownColors.link))
                }
            }
        }
    }
}

// MARK: - MarkdownTableEditorGrid (UIViewRepresentable)

struct MarkdownTableEditorGrid: UIViewRepresentable {

    @ObservedObject var model: MarkdownTableModel
    var onFocusedColumnChanged: ((Int?) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model, onFocusedColumnChanged: onFocusedColumnChanged)
    }

    func makeUIView(context: Context) -> UICollectionView {
        let cv = UICollectionView(frame: .zero,
                                  collectionViewLayout: context.coordinator.createLayout(for: model))
        cv.backgroundColor = UIColor(Color.surfacesBasePrimary)
        cv.dataSource = context.coordinator
        cv.delegate = context.coordinator
        cv.register(EditorCellView.self, forCellWithReuseIdentifier: EditorCellView.reuseID)
        cv.keyboardDismissMode = .interactive
        context.coordinator.collectionView = cv
        return cv
    }

    func updateUIView(_ cv: UICollectionView, context: Context) {
        // Layout changes (column count) require a full layout rebuild.
        let coord = context.coordinator
        if coord.lastColumnCount != model.columnCount {
            coord.lastColumnCount = model.columnCount
            cv.collectionViewLayout = coord.createLayout(for: model)
            cv.reloadData()
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
        let model: MarkdownTableModel
        var onFocusedColumnChanged: ((Int?) -> Void)?
        weak var collectionView: UICollectionView?

        private var focusedIndexPath: IndexPath?
        private var suppressReload = false
        var lastColumnCount: Int = 0
        private var cancellables = Set<AnyCancellable>()

        // Design tokens
        private let headerBG    = UIColor(Color.surfacesBaseLowContrast)
        private let selectColor = UIColor(Color.surfacesBrandInteractive).withAlphaComponent(0.12)
        private let borderColor = UIColor(Color.borderDefault)
        private let headerFont  = UIFont.systemFont(
            ofSize: MarkdownFonts.body.pointSize, weight: .semibold)
        private let bodyFont    = MarkdownFonts.body

        init(model: MarkdownTableModel,
             onFocusedColumnChanged: ((Int?) -> Void)?) {
            self.model = model
            self.lastColumnCount = model.columnCount
            self.onFocusedColumnChanged = onFocusedColumnChanged
            super.init()
            observeModel()
        }

        private func observeModel() {
            model.$cells
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    guard let self, !self.suppressReload else { return }
                    self.collectionView?.collectionViewLayout =
                        self.createLayout(for: self.model)
                    self.collectionView?.reloadData()
                }
                .store(in: &cancellables)
        }

        // MARK: - Layout

        func createLayout(for model: MarkdownTableModel) -> UICollectionViewLayout {
            UICollectionViewCompositionalLayout { [weak self] _, environment in
                guard self != nil else { return nil }
                let colCount = model.columnCount
                guard colCount > 0 else { return nil }

                let availableWidth = environment.container.effectiveContentSize.width
                let minColWidth: CGFloat = 110
                let useFixed = CGFloat(colCount) * minColWidth > availableWidth

                let itemWidth: NSCollectionLayoutDimension = useFixed
                    ? .absolute(minColWidth)
                    : .fractionalWidth(1.0 / CGFloat(colCount))

                let item = NSCollectionLayoutItem(
                    layoutSize: .init(widthDimension: itemWidth,
                                      heightDimension: .absolute(44)))
                let groupWidth: NSCollectionLayoutDimension = useFixed
                    ? .absolute(minColWidth * CGFloat(colCount))
                    : .fractionalWidth(1.0)
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: .init(widthDimension: groupWidth,
                                      heightDimension: .absolute(44)),
                    repeatingSubitem: item,
                    count: colCount)
                return NSCollectionLayoutSection(group: group)
            }
        }

        // MARK: - DataSource

        func collectionView(_ cv: UICollectionView,
                            numberOfItemsInSection section: Int) -> Int {
            model.rowCount * model.columnCount
        }

        func collectionView(_ cv: UICollectionView,
                            cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = cv.dequeueReusableCell(
                withReuseIdentifier: EditorCellView.reuseID,
                for: indexPath) as! EditorCellView
            let row = indexPath.item / model.columnCount
            let col = indexPath.item % model.columnCount
            let isHeader = row == 0 && model.hasHeader
            let isFocused = indexPath == focusedIndexPath

            cell.configure(
                text: model.cells[row][col],
                isHeader: isHeader,
                isFocused: isFocused,
                font: isHeader ? headerFont : bodyFont,
                headerBG: headerBG,
                selectionColor: selectColor,
                borderColor: borderColor,
                alignment: model.alignments[col])

            cell.onTextChanged = { [weak self] newText in
                guard let self,
                      row < self.model.cells.count,
                      col < self.model.cells[row].count else { return }
                self.suppressReload = true
                self.model.cells[row][col] = newText
                self.suppressReload = false
            }

            cell.onReturn = { [weak self] in
                self?.moveFocus(from: indexPath, down: true)
            }

            cell.onTab = { [weak self] in
                self?.moveFocus(from: indexPath, forward: true)
            }

            return cell
        }

        // MARK: - Delegate

        func collectionView(_ cv: UICollectionView,
                            didSelectItemAt indexPath: IndexPath) {
            focusedIndexPath = indexPath
            cv.reloadData()
            let col = indexPath.item % model.columnCount
            onFocusedColumnChanged?(col)
            DispatchQueue.main.async {
                (cv.cellForItem(at: indexPath) as? EditorCellView)?.focusTextField()
            }
        }

        // MARK: - Focus Navigation

        private func moveFocus(from ip: IndexPath, forward: Bool = false, down: Bool = false) {
            let row = ip.item / model.columnCount
            let col = ip.item % model.columnCount
            var newRow = row
            var newCol = col

            if forward {
                newCol += 1
                if newCol >= model.columnCount { newCol = 0; newRow += 1 }
            }
            if down {
                newRow += 1
                if newRow >= model.rowCount { model.addRow() }
            }

            guard newRow < model.rowCount, newCol < model.columnCount else { return }
            let newIP = IndexPath(item: newRow * model.columnCount + newCol, section: 0)
            focusedIndexPath = newIP
            let newCol2 = newIP.item % model.columnCount
            onFocusedColumnChanged?(newCol2)

            collectionView?.reloadData()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                guard let cv = self?.collectionView else { return }
                (cv.cellForItem(at: newIP) as? EditorCellView)?.focusTextField()
            }
        }
    }
}

// MARK: - EditorCellView

private class EditorCellView: UICollectionViewCell, UITextFieldDelegate {

    static let reuseID = "EditorCellView"

    private let textField = UITextField()
    var onTextChanged: ((String) -> Void)?
    var onReturn: (() -> Void)?
    var onTab: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        textField.borderStyle = .none
        textField.textColor = MarkdownColors.text
        textField.backgroundColor = .clear
        textField.returnKeyType = .next
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        contentView.addSubview(textField)

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            textField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])

        // Right and bottom borders
        for isBottom in [true, false] {
            let line = UIView()
            line.backgroundColor = UIColor(Color.borderDefault)
            line.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(line)
            if isBottom {
                NSLayoutConstraint.activate([
                    line.heightAnchor.constraint(equalToConstant: 0.5),
                    line.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    line.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    line.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                ])
            } else {
                NSLayoutConstraint.activate([
                    line.widthAnchor.constraint(equalToConstant: 0.5),
                    line.topAnchor.constraint(equalTo: contentView.topAnchor),
                    line.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                    line.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                ])
            }
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(
        text: String,
        isHeader: Bool,
        isFocused: Bool,
        font: UIFont,
        headerBG: UIColor,
        selectionColor: UIColor,
        borderColor: UIColor,
        alignment: ColumnAlignment
    ) {
        textField.text = text
        textField.font = font
        contentView.backgroundColor = isFocused ? selectionColor : (isHeader ? headerBG : .clear)
        textField.textAlignment = alignment == .center ? .center : alignment == .right ? .right : .left
    }

    func focusTextField() { textField.becomeFirstResponder() }

    @objc private func textChanged() { onTextChanged?(textField.text ?? "") }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onReturn?()
        return false
    }
}
