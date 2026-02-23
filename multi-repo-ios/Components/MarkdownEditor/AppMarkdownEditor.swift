// AppMarkdownEditor.swift
// Real-time inline WYSIWYG markdown editor for SwiftUI.
//
// Type markdown syntax (## , - , **text**) and it renders as
// formatted content in-place. Powered by UITextView + NSAttributedString.
//
// Usage:
//   @State var markdown = ""
//   AppMarkdownEditor(text: $markdown, label: "Description")
//   AppMarkdownEditor(text: $markdown, placeholder: "Write something...")
//   AppMarkdownEditor(text: $markdown, state: .error, hint: "Required")

import SwiftUI
import UIKit

// MARK: - AppMarkdownEditor

public struct AppMarkdownEditor: View {

    // MARK: - Properties

    @Binding var text: String
    var label: String?
    var placeholder: String
    var state: AppInputFieldState
    var hint: String?
    var minHeight: CGFloat
    var maxHeight: CGFloat?
    var isDisabled: Bool

    @State private var isFocused = false
    @State private var editorHeight: CGFloat = 200

    // MARK: - Init

    public init(
        text: Binding<String>,
        label: String? = nil,
        placeholder: String = "",
        state: AppInputFieldState = .default,
        hint: String? = nil,
        minHeight: CGFloat = 200,
        maxHeight: CGFloat? = nil,
        isDisabled: Bool = false
    ) {
        self._text = text
        self.label = label
        self.placeholder = placeholder
        self.state = state
        self.hint = hint
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.isDisabled = isDisabled
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: NativeMarkdownEditorStyling.Layout.labelSpacing) {
            // Label
            if let label {
                Text(label)
                    .font(NativeMarkdownEditorStyling.Typography.label)
                    .foregroundStyle(NativeMarkdownEditorStyling.Colors.label)
            }

            // Editor
            MarkdownEditorRepresentable(
                text: $text,
                isFocused: $isFocused,
                placeholder: placeholder,
                isDisabled: isDisabled,
                minHeight: minHeight,
                onHeightChange: { newHeight in
                    editorHeight = newHeight
                }
            )
            .frame(minHeight: minHeight, maxHeight: maxHeight)
            .background(NativeMarkdownEditorStyling.Colors.background)
            .clipShape(RoundedRectangle(cornerRadius: NativeMarkdownEditorStyling.Layout.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: NativeMarkdownEditorStyling.Layout.cornerRadius)
                    .stroke(borderColor, lineWidth: NativeMarkdownEditorStyling.Layout.borderWidth)
            )
            .animation(.easeOut(duration: 0.15), value: isFocused)

            // Hint
            if let hint {
                Text(hint)
                    .font(NativeMarkdownEditorStyling.Typography.hint)
                    .foregroundStyle(hintColor)
            }
        }
        .opacity(isDisabled ? 0.5 : 1.0)
        .allowsHitTesting(!isDisabled)
    }

    // MARK: - Helpers

    private var borderColor: Color {
        switch state {
        case .default:
            return isFocused ? NativeMarkdownEditorStyling.Colors.borderFocused : NativeMarkdownEditorStyling.Colors.border
        case .success:
            return NativeMarkdownEditorStyling.Colors.borderSuccess
        case .warning:
            return NativeMarkdownEditorStyling.Colors.borderWarning
        case .error:
            return NativeMarkdownEditorStyling.Colors.borderError
        }
    }

    private var hintColor: Color {
        switch state {
        case .default: return NativeMarkdownEditorStyling.Colors.hint
        case .success: return NativeMarkdownEditorStyling.Colors.hintSuccess
        case .warning: return NativeMarkdownEditorStyling.Colors.hintWarning
        case .error: return NativeMarkdownEditorStyling.Colors.hintError
        }
    }
}

// MARK: - UIViewRepresentable

struct MarkdownEditorRepresentable: UIViewRepresentable {

    @Binding var text: String
    @Binding var isFocused: Bool
    let placeholder: String
    let isDisabled: Bool
    let minHeight: CGFloat
    let onHeightChange: (CGFloat) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textStorage = MarkdownTextStorage()

        // Custom layout manager that draws bullets and checkboxes
        let layoutManager = MarkdownLayoutManager()
        layoutManager.markdownStorage = textStorage

        let container = NSTextContainer(size: CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        container.widthTracksTextView = true
        layoutManager.addTextContainer(container)
        textStorage.addLayoutManager(layoutManager)

        let textView = UITextView(frame: .zero, textContainer: container)
        textView.delegate = context.coordinator
        textView.isScrollEnabled = true
        textView.isEditable = !isDisabled
        textView.isSelectable = true
        textView.backgroundColor = UIColor.clear
        textView.textContainerInset = UIEdgeInsets(
            top: NativeMarkdownEditorStyling.Layout.paddingV,
            left: NativeMarkdownEditorStyling.Layout.paddingH,
            bottom: NativeMarkdownEditorStyling.Layout.paddingV,
            right: NativeMarkdownEditorStyling.Layout.paddingH
        )
        textView.tintColor = UIColor(NativeMarkdownEditorStyling.Colors.caret)
        textView.font = MarkdownFonts.body
        textView.textColor = MarkdownColors.text
        textView.autocorrectionType = UITextAutocorrectionType.default
        textView.autocapitalizationType = UITextAutocapitalizationType.sentences
        textView.keyboardDismissMode = UIScrollView.KeyboardDismissMode.interactive

        // Keyboard toolbar
        let toolbar = MarkdownKeyboardToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        toolbar.onAction = { action in
            context.coordinator.handleToolbarAction(action, in: textView)
        }
        textView.inputAccessoryView = toolbar

        // Tap gesture for checkbox toggling
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleCheckboxTap(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = context.coordinator
        textView.addGestureRecognizer(tapGesture)

        // Store references
        context.coordinator.textView = textView
        context.coordinator.textStorage = textStorage
        context.coordinator.checkboxTapGesture = tapGesture

        // Set initial content
        if !text.isEmpty {
            textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: text)
        }

        // Placeholder
        context.coordinator.updatePlaceholder(textView)

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        let coordinator = context.coordinator
        guard !coordinator.isUpdating else { return }
        coordinator.isUpdating = true
        defer { coordinator.isUpdating = false }

        textView.isEditable = !isDisabled

        // Sync external text changes
        if let storage = coordinator.textStorage {
            let currentText = storage.string
            if text != currentText {
                let selectedRange = textView.selectedRange
                storage.replaceCharacters(in: NSRange(location: 0, length: storage.length), with: text)
                let safeRange = NSRange(location: min(selectedRange.location, storage.length), length: 0)
                textView.selectedRange = safeRange
            }
        }

        coordinator.updatePlaceholder(textView)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UITextViewDelegate, UIGestureRecognizerDelegate {
        let parent: MarkdownEditorRepresentable
        weak var textView: UITextView?
        weak var textStorage: MarkdownTextStorage?
        weak var checkboxTapGesture: UITapGestureRecognizer?
        var isUpdating = false
        private var placeholderLabel: UILabel?

        init(_ parent: MarkdownEditorRepresentable) {
            self.parent = parent
        }

        // MARK: - UITextViewDelegate

        func textViewDidChange(_ textView: UITextView) {
            guard !isUpdating else { return }
            isUpdating = true
            parent.text = textView.textStorage.string
            isUpdating = false
            updatePlaceholder(textView)
            updateContentHeight(textView)
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            guard let storage = textStorage else { return true }
            if MarkdownInputProcessor.process(textView: textView, range: range, replacementText: text, textStorage: storage) {
                DispatchQueue.main.async { [weak self] in
                    self?.parent.text = textView.textStorage.string
                    self?.updatePlaceholder(textView)
                }
                return false
            }
            return true
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFocused = true
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isFocused = false
        }

        // MARK: - Native Edit Menu (iOS 16+)

        func textView(_ textView: UITextView, editMenuForTextIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
            guard range.length > 0 else { return UIMenu(children: suggestedActions) }

            // Inline formatting actions
            let formatActions = UIMenu(title: "", options: .displayInline, children: [
                UIAction(title: "Bold", image: UIImage(systemName: "bold")) { [weak self] _ in
                    self?.handleToolbarAction(.bold, in: textView)
                },
                UIAction(title: "Italic", image: UIImage(systemName: "italic")) { [weak self] _ in
                    self?.handleToolbarAction(.italic, in: textView)
                },
                UIAction(title: "Strikethrough", image: UIImage(systemName: "strikethrough")) { [weak self] _ in
                    self?.handleToolbarAction(.strikethrough, in: textView)
                },
                UIAction(title: "Code", image: UIImage(systemName: "chevron.left.forwardslash.chevron.right")) { [weak self] _ in
                    self?.handleToolbarAction(.inlineCode, in: textView)
                },
                UIAction(title: "Link", image: UIImage(systemName: "link")) { [weak self] _ in
                    self?.handleToolbarAction(.link, in: textView)
                },
            ])

            // Heading submenu
            let headingMenu = UIMenu(title: "Heading", image: UIImage(systemName: "textformat.size"), children: [
                UIAction(title: "Heading 1") { [weak self] _ in
                    self?.handleToolbarAction(.heading1, in: textView)
                },
                UIAction(title: "Heading 2") { [weak self] _ in
                    self?.handleToolbarAction(.heading2, in: textView)
                },
                UIAction(title: "Heading 3") { [weak self] _ in
                    self?.handleToolbarAction(.heading3, in: textView)
                },
            ])

            return UIMenu(children: suggestedActions + [formatActions, headingMenu])
        }

        // MARK: - Checkbox Tap Gesture

        @objc func handleCheckboxTap(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended,
                  let textView = textView,
                  let storage = textStorage else { return }

            let point = gesture.location(in: textView)
            let adjustedPoint = CGPoint(
                x: point.x - textView.textContainerInset.left,
                y: point.y - textView.textContainerInset.top
            )

            var fraction: CGFloat = 0
            let charIndex = textView.layoutManager.characterIndex(
                for: adjustedPoint,
                in: textView.textContainer,
                fractionOfDistanceBetweenInsertionPoints: &fraction
            )

            for (lineRange, block) in storage.lineBlocks {
                guard case .taskList(_, let checked) = block else { continue }
                let line = (storage.string as NSString).substring(with: lineRange)
                let leadingSpaces = line.prefix(while: { $0 == " " || $0 == "\t" }).count
                let cbStart = lineRange.location + leadingSpaces + 2
                let cbEnd = cbStart + 3

                // Expanded hit area for easier tapping
                if charIndex >= lineRange.location && charIndex < cbEnd + 2 {
                    let replacement = checked ? "[ ]" : "[x]"
                    storage.replaceCharacters(in: NSRange(location: cbStart, length: 3), with: replacement)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()

                    DispatchQueue.main.async { [weak self] in
                        self?.parent.text = textView.textStorage.string
                    }
                    return
                }
            }
        }

        // MARK: - UIGestureRecognizerDelegate

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }

        // MARK: - Toolbar Action Handler

        func handleToolbarAction(_ action: MarkdownToolbarAction, in textView: UITextView) {
            guard let storage = textStorage else { return }
            let range = textView.selectedRange

            switch action {
            case .bold:
                wrapSelection(textView: textView, prefix: "**", suffix: "**")
            case .italic:
                wrapSelection(textView: textView, prefix: "*", suffix: "*")
            case .strikethrough:
                wrapSelection(textView: textView, prefix: "~~", suffix: "~~")
            case .inlineCode:
                wrapSelection(textView: textView, prefix: "`", suffix: "`")
            case .heading1:
                insertLinePrefix(textView: textView, prefix: "# ", storage: storage)
            case .heading2:
                insertLinePrefix(textView: textView, prefix: "## ", storage: storage)
            case .heading3:
                insertLinePrefix(textView: textView, prefix: "### ", storage: storage)
            case .bulletList:
                insertLinePrefix(textView: textView, prefix: "- ", storage: storage)
            case .orderedList:
                insertLinePrefix(textView: textView, prefix: "1. ", storage: storage)
            case .taskList:
                insertLinePrefix(textView: textView, prefix: "- [ ] ", storage: storage)
            case .blockquote:
                insertLinePrefix(textView: textView, prefix: "> ", storage: storage)
            case .codeBlock:
                let insertion = "```\n\n```"
                storage.replaceCharacters(in: range, with: insertion)
                textView.selectedRange = NSRange(location: range.location + 4, length: 0)
            case .horizontalRule:
                let nsString = storage.string as NSString
                let lineRange = nsString.lineRange(for: range)
                let lineEnd = NSMaxRange(lineRange)
                let insertion = lineEnd == storage.length ? "\n---\n" : "---\n"
                storage.replaceCharacters(in: NSRange(location: lineEnd, length: 0), with: insertion)
            case .link:
                if range.length > 0 {
                    let selectedText = (storage.string as NSString).substring(with: range)
                    let replacement = "[\(selectedText)](url)"
                    storage.replaceCharacters(in: range, with: replacement)
                    let urlStart = range.location + selectedText.count + 2
                    textView.selectedRange = NSRange(location: urlStart, length: 3)
                } else {
                    let insertion = "[text](url)"
                    storage.replaceCharacters(in: range, with: insertion)
                    textView.selectedRange = NSRange(location: range.location + 1, length: 4)
                }
            case .table:
                let table = "| Column 1 | Column 2 | Column 3 |\n| --- | --- | --- |\n| | | |\n"
                storage.replaceCharacters(in: range, with: table)
                textView.selectedRange = NSRange(location: range.location + table.count, length: 0)
            case .indent:
                _ = MarkdownInputProcessor.process(textView: textView, range: range, replacementText: "\t", textStorage: storage)
            case .outdent:
                let nsString = storage.string as NSString
                let lineRange = nsString.lineRange(for: range)
                let line = nsString.substring(with: lineRange)
                if line.hasPrefix("  ") {
                    storage.replaceCharacters(in: NSRange(location: lineRange.location, length: 2), with: "")
                }
            }

            DispatchQueue.main.async { [weak self] in
                self?.parent.text = textView.textStorage.string
                self?.updatePlaceholder(textView)
            }
        }

        // MARK: - Text Manipulation Helpers

        private func wrapSelection(textView: UITextView, prefix: String, suffix: String) {
            guard let storage = textStorage else { return }
            let range = textView.selectedRange

            if range.length > 0 {
                let selectedText = (storage.string as NSString).substring(with: range)
                let replacement = prefix + selectedText + suffix
                storage.replaceCharacters(in: range, with: replacement)
                textView.selectedRange = NSRange(location: range.location + prefix.count, length: selectedText.count)
            } else {
                let insertion = prefix + suffix
                storage.replaceCharacters(in: range, with: insertion)
                textView.selectedRange = NSRange(location: range.location + prefix.count, length: 0)
            }
        }

        private func insertLinePrefix(textView: UITextView, prefix: String, storage: MarkdownTextStorage) {
            let nsString = storage.string as NSString
            let lineRange = nsString.lineRange(for: textView.selectedRange)
            let line = nsString.substring(with: lineRange)

            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix(prefix) {
                let prefixRange = (line as NSString).range(of: prefix)
                if prefixRange.location != NSNotFound {
                    let absoluteRange = NSRange(location: lineRange.location + prefixRange.location, length: prefixRange.length)
                    storage.replaceCharacters(in: absoluteRange, with: "")
                    return
                }
            }

            storage.replaceCharacters(in: NSRange(location: lineRange.location, length: 0), with: prefix)
            textView.selectedRange = NSRange(location: textView.selectedRange.location + prefix.count, length: 0)
        }

        // MARK: - Placeholder

        func updatePlaceholder(_ textView: UITextView) {
            let isEmpty = textView.textStorage.string.isEmpty

            if isEmpty && placeholderLabel == nil {
                let label = UILabel()
                label.text = parent.placeholder
                label.font = MarkdownFonts.body
                label.textColor = UIColor(NativeMarkdownEditorStyling.Colors.placeholder)
                label.translatesAutoresizingMaskIntoConstraints = false
                label.isUserInteractionEnabled = false
                textView.addSubview(label)
                NSLayoutConstraint.activate([
                    label.topAnchor.constraint(equalTo: textView.topAnchor, constant: textView.textContainerInset.top),
                    label.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: textView.textContainerInset.left + 5),
                ])
                placeholderLabel = label
            }

            placeholderLabel?.isHidden = !isEmpty
        }

        // MARK: - Content Height

        private func updateContentHeight(_ textView: UITextView) {
            let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude))
            let newHeight = max(parent.minHeight, size.height)
            parent.onHeightChange(newHeight)
        }
    }
}
