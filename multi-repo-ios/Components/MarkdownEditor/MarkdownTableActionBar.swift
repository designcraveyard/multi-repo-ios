// MarkdownTableActionBar.swift
// Floating pill action bar for the dedicated table editor sheet.
// Structural operations: add/delete row+column, column alignment, header row toggle.

import SwiftUI

// MARK: - MarkdownTableActionBar

/// Floating capsule-shaped action bar shown at the bottom of the table editor sheet.
/// Provides structural operations: add/delete rows and columns, column text alignment
/// (left/center/right), header row/column toggles, and a keyboard dismiss button.
struct MarkdownTableActionBar: View {

    // MARK: - Properties

    @ObservedObject var model: MarkdownTableModel
    /// The column index that currently has keyboard focus (used for alignment targeting).
    var focusedColumn: Int?
    var onDismissKeyboard: (() -> Void)?

    // MARK: - Body

    var body: some View {
        HStack(spacing: 2) {
            barButton(icon: "arrow.down.to.line", label: "Add Row") {
                model.addRow()
            }
            barButton(icon: "arrow.right.to.line", label: "Add Col") {
                model.addColumn()
            }
            barButton(icon: "minus", label: "Del Row",
                      disabled: model.rowCount <= 1) {
                model.deleteRow(at: model.rowCount - 1)
            }
            barButton(icon: "minus.square", label: "Del Col",
                      disabled: model.columnCount <= 1) {
                model.deleteColumn(at: model.columnCount - 1)
            }

            Divider()
                .frame(height: 20)
                .padding(.horizontal, 4)

            Menu {
                Button {
                    applyAlignment(.left)
                } label: { Label("Align Left", systemImage: "text.alignleft") }
                Button {
                    applyAlignment(.center)
                } label: { Label("Align Center", systemImage: "text.aligncenter") }
                Button {
                    applyAlignment(.right)
                } label: { Label("Align Right", systemImage: "text.alignright") }
            } label: {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 32, height: 32)
                    .foregroundStyle(Color(uiColor: MarkdownColors.text))
            }

            Divider()
                .frame(height: 20)
                .padding(.horizontal, 4)

            // Header row toggle
            Toggle(isOn: Binding(
                get: { model.hasHeader },
                set: { model.hasHeader = $0 }
            )) {
                Image(systemName: model.hasHeader ? "tablecells.fill" : "tablecells")
                    .font(.system(size: 14, weight: .medium))
            }
            .toggleStyle(.button)
            .tint(Color(uiColor: MarkdownColors.link))
            .frame(width: 32, height: 32)

            // Header column toggle
            Toggle(isOn: Binding(
                get: { model.hasHeaderColumn },
                set: { model.hasHeaderColumn = $0 }
            )) {
                Image(systemName: model.hasHeaderColumn ? "sidebar.left" : "sidebar.squares.left")
                    .font(.system(size: 14, weight: .medium))
            }
            .toggleStyle(.button)
            .tint(Color(uiColor: MarkdownColors.link))
            .frame(width: 32, height: 32)

            Divider()
                .frame(height: 20)
                .padding(.horizontal, 4)

            // Keyboard dismiss
            barButton(icon: "keyboard.chevron.compact.down", label: "Hide Keyboard") {
                onDismissKeyboard?()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    // MARK: - Helpers

    private func applyAlignment(_ alignment: ColumnAlignment) {
        let col = focusedColumn ?? 0
        guard col < model.columnCount else { return }
        model.setAlignment(alignment, forColumn: col)
    }

    @ViewBuilder
    private func barButton(
        icon: String,
        label: String,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 32, height: 32)
                .foregroundStyle(disabled
                    ? Color(uiColor: MarkdownColors.text).opacity(0.3)
                    : Color(uiColor: MarkdownColors.text))
        }
        .disabled(disabled)
    }
}
