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
import PhotosUI

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
    var showChrome: Bool

    @State private var isFocused = false
    @State private var editorHeight: CGFloat = 200
    @State private var viewingImageEntry: ImageEntry?
    @State private var viewingImageStore: MarkdownImageStore?

    // MARK: - Init

    public init(
        text: Binding<String>,
        label: String? = nil,
        placeholder: String = "",
        state: AppInputFieldState = .default,
        hint: String? = nil,
        minHeight: CGFloat = 200,
        maxHeight: CGFloat? = nil,
        isDisabled: Bool = false,
        showChrome: Bool = true
    ) {
        self._text = text
        self.label = label
        self.placeholder = placeholder
        self.state = state
        self.hint = hint
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.isDisabled = isDisabled
        self.showChrome = showChrome
    }

    // MARK: - Body

    public var body: some View {
        if showChrome {
            chromeWrapped
        } else {
            bareEditor
        }
    }

    // MARK: - Chrome-Wrapped Editor (with label, border, hint)

    private var chromeWrapped: some View {
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
                },
                onImageTap: { entry, store in
                    viewingImageStore = store
                    viewingImageEntry = entry
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
        .fullScreenCover(item: $viewingImageEntry) { entry in
            MarkdownImageViewer(
                imageEntry: entry,
                imageStore: viewingImageStore,
                onCropComplete: { _ in }
            )
        }
    }

    // MARK: - Bare Editor (no chrome — for full-page Notes-like usage)

    private var bareEditor: some View {
        MarkdownEditorRepresentable(
            text: $text,
            isFocused: $isFocused,
            placeholder: placeholder,
            isDisabled: isDisabled,
            minHeight: minHeight,
            onHeightChange: { newHeight in
                editorHeight = newHeight
            },
            onImageTap: { entry, store in
                viewingImageStore = store
                viewingImageEntry = entry
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(isDisabled ? 0.5 : 1.0)
        .allowsHitTesting(!isDisabled)
        .fullScreenCover(item: $viewingImageEntry) { entry in
            MarkdownImageViewer(
                imageEntry: entry,
                imageStore: viewingImageStore,
                onCropComplete: { _ in }
            )
        }
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

// MARK: - MarkdownTextView (UITextView subclass with keyboard shortcuts)

class MarkdownTextView: UITextView {

    /// Callback for toolbar actions triggered by keyboard shortcuts.
    var onKeyboardAction: ((MarkdownToolbarAction) -> Void)?

    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: "b", modifierFlags: .command, action: #selector(cmdBold)),
            UIKeyCommand(input: "i", modifierFlags: .command, action: #selector(cmdItalic)),
            UIKeyCommand(input: "u", modifierFlags: .command, action: #selector(cmdUnderline)),
            UIKeyCommand(input: "k", modifierFlags: .command, action: #selector(cmdLink)),
            UIKeyCommand(input: "\t", modifierFlags: .shift, action: #selector(cmdOutdent)),
        ]
    }

    @objc private func cmdBold() { onKeyboardAction?(.bold) }
    @objc private func cmdItalic() { onKeyboardAction?(.italic) }
    @objc private func cmdUnderline() { onKeyboardAction?(.underline) }
    @objc private func cmdLink() { onKeyboardAction?(.link) }
    @objc private func cmdOutdent() { onKeyboardAction?(.outdent) }
}

// MARK: - UIViewRepresentable

struct MarkdownEditorRepresentable: UIViewRepresentable {

    @Binding var text: String
    @Binding var isFocused: Bool
    let placeholder: String
    let isDisabled: Bool
    let minHeight: CGFloat
    let onHeightChange: (CGFloat) -> Void
    var onImageTap: ((ImageEntry, MarkdownImageStore) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textStorage = MarkdownTextStorage()

        // Custom layout manager that draws bullets, checkboxes, tables, blockquote bars
        let layoutManager = MarkdownLayoutManager()
        layoutManager.markdownStorage = textStorage

        let container = NSTextContainer(size: CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        container.widthTracksTextView = true
        layoutManager.addTextContainer(container)
        textStorage.addLayoutManager(layoutManager)

        let textView = MarkdownTextView(frame: .zero, textContainer: container)
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

        // Keyboard shortcuts (Cmd+B, Cmd+I, etc.)
        let coordinator = context.coordinator
        textView.onKeyboardAction = { [weak coordinator] action in
            guard let coordinator else { return }
            coordinator.handleToolbarAction(action, in: textView)
        }

        let isIPad = UIDevice.current.userInterfaceIdiom == .pad

        if isIPad {
            // iPad: floating pill toolbar (not inputAccessoryView)
            // Set up in coordinator after textView is in the view hierarchy
            context.coordinator.setupFloatingToolbar(for: textView)
        } else {
            // iPhone: standard keyboard toolbar
            let toolbar = MarkdownKeyboardToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: MarkdownToolbarStyling.height))
            toolbar.onAction = { action in
                context.coordinator.handleToolbarAction(action, in: textView)
            }
            toolbar.onDismissKeyboard = { [weak textView] in
                textView?.resignFirstResponder()
            }
            textView.inputAccessoryView = toolbar
        }

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

    class Coordinator: NSObject, UITextViewDelegate, UIGestureRecognizerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate, UIDocumentPickerDelegate {
        let parent: MarkdownEditorRepresentable
        weak var textView: UITextView?
        weak var textStorage: MarkdownTextStorage?
        weak var checkboxTapGesture: UITapGestureRecognizer?
        var isUpdating = false
        private var placeholderLabel: UILabel?

        // iPad floating toolbar
        private var floatingToolbar: MarkdownKeyboardToolbar?
        private var floatingToolbarBottomConstraint: NSLayoutConstraint?

        // Image store
        let imageStore = MarkdownImageStore()

        // AI features
        private var audioRecorder: AppAudioRecorder?
        private var isRecording = false
        private var isTranscribing = false

        init(_ parent: MarkdownEditorRepresentable) {
            self.parent = parent
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        // MARK: - Floating Toolbar (iPad)

        func setupFloatingToolbar(for textView: UITextView) {
            let toolbar = MarkdownKeyboardToolbar(frame: .zero)
            toolbar.onAction = { [weak self] action in
                guard let self, let tv = self.textView else { return }
                self.handleToolbarAction(action, in: tv)
            }
            toolbar.translatesAutoresizingMaskIntoConstraints = false
            toolbar.alpha = 0
            toolbar.layer.cornerRadius = 26
            toolbar.clipsToBounds = true
            toolbar.layer.shadowColor = UIColor.black.cgColor
            toolbar.layer.shadowOpacity = 0.08
            toolbar.layer.shadowOffset = CGSize(width: 0, height: 4)
            toolbar.layer.shadowRadius = 12
            toolbar.layer.masksToBounds = false

            textView.addSubview(toolbar)

            let bottomConstraint = toolbar.bottomAnchor.constraint(equalTo: textView.bottomAnchor, constant: -16)
            NSLayoutConstraint.activate([
                toolbar.centerXAnchor.constraint(equalTo: textView.centerXAnchor),
                toolbar.heightAnchor.constraint(equalToConstant: MarkdownToolbarStyling.height),
                toolbar.widthAnchor.constraint(lessThanOrEqualTo: textView.widthAnchor, constant: -32),
                bottomConstraint,
            ])

            self.floatingToolbar = toolbar
            self.floatingToolbarBottomConstraint = bottomConstraint

            // Listen for keyboard events
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        }

        @objc private func keyboardWillShow(_ notification: Notification) {
            guard let toolbar = floatingToolbar,
                  let textView = textView,
                  let userInfo = notification.userInfo,
                  let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                  let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }

            let keyboardTop = textView.bounds.height - textView.convert(keyboardFrame, from: nil).origin.y
            let offset = max(keyboardTop + 12, 16)
            floatingToolbarBottomConstraint?.constant = -offset

            UIView.animate(withDuration: duration) {
                toolbar.alpha = 1
                textView.layoutIfNeeded()
            }
        }

        @objc private func keyboardWillHide(_ notification: Notification) {
            guard let toolbar = floatingToolbar,
                  let userInfo = notification.userInfo,
                  let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }

            UIView.animate(withDuration: duration) {
                toolbar.alpha = 0
            }
        }

        // MARK: - UITextViewDelegate

        func textViewDidChange(_ textView: UITextView) {
            guard !isUpdating else { return }
            isUpdating = true
            parent.text = textView.textStorage.string
            isUpdating = false
            updatePlaceholder(textView)
            updateContentHeight(textView)

            // Fix cursor height: set typing attributes to match current line block type
            if let storage = textStorage {
                textView.typingAttributes = storage.typingAttributes(at: textView.selectedRange.location)
            }
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            guard let storage = textStorage else { return true }
            if MarkdownInputProcessor.process(textView: textView, range: range, replacementText: text, textStorage: storage) {
                DispatchQueue.main.async { [weak self] in
                    self?.parent.text = textView.textStorage.string
                    self?.updatePlaceholder(textView)
                    // Reset typing attributes after Enter/Tab for correct cursor height
                    if let storage = self?.textStorage {
                        textView.typingAttributes = storage.typingAttributes(at: textView.selectedRange.location)
                    }
                }
                return false
            }

            // Pre-set typing attributes BEFORE the text system inserts the character.
            // This is critical for table cells: without this, a character typed next
            // to a pipe inherits the pipe's tableBorder color because processEditing()
            // (which fixes colors) runs AFTER insertion. By setting typingAttributes
            // here, the inserted character gets visible text color immediately.
            textView.typingAttributes = storage.typingAttributes(at: range.location)

            return true
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFocused = true
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isFocused = false
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            // Update typing attributes when cursor moves to match current line type
            if let storage = textStorage {
                textView.typingAttributes = storage.typingAttributes(at: textView.selectedRange.location)
            }
        }

        // MARK: - Native Edit Menu (iOS 16+)
        // Formatting options appear FIRST, then standard actions.
        // Select All is always available.

        func textView(_ textView: UITextView, editMenuForTextIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
            // Select All action — always available
            let selectAllAction = UIAction(title: "Select All", image: UIImage(systemName: "selection.pin.in.out")) { _ in
                textView.selectAll(nil)
            }
            let selectAllMenu = UIMenu(title: "", options: .displayInline, children: [selectAllAction])

            // If no text is selected, show Select All + standard actions
            guard range.length > 0 else {
                return UIMenu(children: [selectAllMenu] + suggestedActions)
            }

            // Inline formatting actions — shown FIRST (icon-only, titles kept for accessibility)
            let formatActions = UIMenu(title: "", options: .displayInline, children: [
                UIAction(title: "", image: UIImage(systemName: "bold"), handler: { [weak self] _ in
                    self?.handleToolbarAction(.bold, in: textView)
                }),
                UIAction(title: "", image: UIImage(systemName: "italic"), handler: { [weak self] _ in
                    self?.handleToolbarAction(.italic, in: textView)
                }),
                UIAction(title: "", image: UIImage(systemName: "underline"), handler: { [weak self] _ in
                    self?.handleToolbarAction(.underline, in: textView)
                }),
                UIAction(title: "", image: UIImage(systemName: "strikethrough"), handler: { [weak self] _ in
                    self?.handleToolbarAction(.strikethrough, in: textView)
                }),
                UIAction(title: "", image: UIImage(systemName: "chevron.left.forwardslash.chevron.right"), handler: { [weak self] _ in
                    self?.handleToolbarAction(.inlineCode, in: textView)
                }),
                UIAction(title: "", image: UIImage(systemName: "link"), handler: { [weak self] _ in
                    self?.handleToolbarAction(.link, in: textView)
                }),
            ])

            // Heading submenu (icon on parent, short labels + icons in children)
            let headingMenu = UIMenu(title: "", image: UIImage(systemName: "textformat.size"), children: [
                UIAction(title: "H1", image: UIImage(systemName: "textformat.size.larger"), handler: { [weak self] _ in
                    self?.handleToolbarAction(.heading1, in: textView)
                }),
                UIAction(title: "H2", image: UIImage(systemName: "textformat.size"), handler: { [weak self] _ in
                    self?.handleToolbarAction(.heading2, in: textView)
                }),
                UIAction(title: "H3", image: UIImage(systemName: "textformat.size.smaller"), handler: { [weak self] _ in
                    self?.handleToolbarAction(.heading3, in: textView)
                }),
            ])

            // Formatting first, then headings, then Select All, then system actions
            return UIMenu(children: [formatActions, headingMenu, selectAllMenu] + suggestedActions)
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

            // Check for image attachment tap — open fullscreen viewer.
            // Scan the entire line at the tapped position for an attachment,
            // since characterIndex may not land exactly on the \uFFFC character.
            if charIndex < storage.length {
                let nsString = storage.string as NSString
                let lineRange = nsString.lineRange(for: NSRange(location: min(charIndex, nsString.length - 1), length: 0))
                var tappedEntry: ImageEntry?
                storage.enumerateAttribute(.attachment, in: lineRange, options: []) { value, _, stop in
                    if let attachment = value as? MarkdownImageAttachment,
                       let entry = self.imageStore.image(for: attachment.imageID) {
                        tappedEntry = entry
                        stop.pointee = true
                    }
                }
                if let entry = tappedEntry {
                    parent.onImageTap?(entry, imageStore)
                    return
                }
            }

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
                toggleWrap(textView: textView, prefix: "**", suffix: "**")
            case .italic:
                toggleWrap(textView: textView, prefix: "*", suffix: "*")
            case .underline:
                toggleWrap(textView: textView, prefix: "++", suffix: "++")
            case .strikethrough:
                toggleWrap(textView: textView, prefix: "~~", suffix: "~~")
            case .highlight:
                toggleWrap(textView: textView, prefix: "==", suffix: "==")
            case .inlineCode:
                toggleWrap(textView: textView, prefix: "`", suffix: "`")
            case .heading1:
                insertLinePrefix(textView: textView, prefix: "# ", storage: storage)
            case .heading2:
                insertLinePrefix(textView: textView, prefix: "## ", storage: storage)
            case .heading3:
                insertLinePrefix(textView: textView, prefix: "### ", storage: storage)
            case .headingPicker:
                showHeadingPicker(in: textView, storage: storage)
                return
            case .codePicker:
                showCodePicker(in: textView, storage: storage)
                return
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
                showLinkPopover(textView: textView, storage: storage, range: range)
                return // Don't sync text immediately — alert handles it
            case .table:
                let table = "| Column 1 | Column 2 | Column 3 |\n| --- | --- | --- |\n|  |  |  |"
                storage.replaceCharacters(in: range, with: table)
                // Place cursor in the first data cell (after the third row's "| ")
                let dataRowStart = range.location + "| Column 1 | Column 2 | Column 3 |\n| --- | --- | --- |\n| ".count
                textView.selectedRange = NSRange(location: dataRowStart, length: 0)
            case .indent:
                _ = MarkdownInputProcessor.process(textView: textView, range: range, replacementText: "\t", textStorage: storage)
            case .outdent:
                // In a table row, Shift+Tab moves to the previous cell
                let currentBlock = blockAtCursor(range.location, storage: storage)
                if case .tableRow = currentBlock {
                    let nsString = storage.string as NSString
                    var pos = range.location - 1
                    if pos >= 0 && nsString.substring(with: NSRange(location: pos, length: 1)) == "|" { pos -= 1 }
                    while pos >= 0 && nsString.substring(with: NSRange(location: pos, length: 1)) != "|" { pos -= 1 }
                    if pos >= 0 {
                        let target = pos + 1
                        let cursorPos = target < nsString.length && nsString.substring(with: NSRange(location: target, length: 1)) == " " ? target + 1 : target
                        textView.selectedRange = NSRange(location: cursorPos, length: 0)
                    }
                } else {
                    let nsString = storage.string as NSString
                    let lineRange = nsString.lineRange(for: range)
                    let line = nsString.substring(with: lineRange)
                    if line.hasPrefix("  ") {
                        storage.replaceCharacters(in: NSRange(location: lineRange.location, length: 2), with: "")
                    }
                }
            case .imagePicker:
                showImageSourcePicker(in: textView)
                return
            case .share:
                guard let fileURL = MarkdownExporter.exportToFile(storage: storage) else { return }
                let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = textView
                    popover.sourceRect = CGRect(x: textView.bounds.midX, y: textView.bounds.midY, width: 0, height: 0)
                }
                if let scene = textView.window?.windowScene,
                   let rootVC = scene.keyWindow?.rootViewController {
                    var topVC = rootVC
                    while let presented = topVC.presentedViewController { topVC = presented }
                    topVC.present(activityVC, animated: true)
                }
                return
            case .aiTranscribe:
                handleTranscribe(in: textView)
                return // Don't sync text immediately — async handlers manage it
            case .aiTransform:
                handleAITransform(in: textView)
                return // Don't sync text immediately — async handlers manage it
            }

            DispatchQueue.main.async { [weak self] in
                self?.parent.text = textView.textStorage.string
                self?.updatePlaceholder(textView)
            }
        }

        // MARK: - Toggle Wrap (Bold/Italic/Underline/Strikethrough/Code)
        // If already wrapped, unwrap. Otherwise, wrap.

        private func toggleWrap(textView: UITextView, prefix: String, suffix: String) {
            guard let storage = textStorage else { return }
            let range = textView.selectedRange

            if range.length > 0 {
                let nsString = storage.string as NSString
                let selectedText = nsString.substring(with: range)

                // Check if the surrounding text already has the markers → unwrap
                let beforeStart = range.location - prefix.count
                let afterEnd = NSMaxRange(range)

                if beforeStart >= 0 && afterEnd + suffix.count <= nsString.length {
                    let before = nsString.substring(with: NSRange(location: beforeStart, length: prefix.count))
                    let after = nsString.substring(with: NSRange(location: afterEnd, length: suffix.count))

                    if before == prefix && after == suffix {
                        // Unwrap: remove suffix first (so offsets stay valid), then prefix
                        storage.replaceCharacters(in: NSRange(location: afterEnd, length: suffix.count), with: "")
                        storage.replaceCharacters(in: NSRange(location: beforeStart, length: prefix.count), with: "")
                        textView.selectedRange = NSRange(location: beforeStart, length: range.length)
                        return
                    }
                }

                // Check if selection includes the markers → unwrap
                if selectedText.hasPrefix(prefix) && selectedText.hasSuffix(suffix) &&
                   selectedText.count > prefix.count + suffix.count {
                    let inner = String(selectedText.dropFirst(prefix.count).dropLast(suffix.count))
                    storage.replaceCharacters(in: range, with: inner)
                    textView.selectedRange = NSRange(location: range.location, length: inner.count)
                    return
                }

                // Wrap the selection
                let replacement = prefix + selectedText + suffix
                storage.replaceCharacters(in: range, with: replacement)
                textView.selectedRange = NSRange(location: range.location + prefix.count, length: selectedText.count)
            } else {
                // No selection: insert markers and place cursor between
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

        // MARK: - Heading Picker

        private func showHeadingPicker(in textView: UITextView, storage: MarkdownTextStorage) {
            guard let viewController = textView.window?.rootViewController?.presentedViewController
                    ?? textView.window?.rootViewController else { return }

            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            let headings: [(String, String)] = [
                ("Heading 1", "# "),
                ("Heading 2", "## "),
                ("Heading 3", "### "),
                ("Body", ""),
            ]

            for (title, prefix) in headings {
                alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                    guard let self else { return }
                    if prefix.isEmpty {
                        // Remove any existing heading prefix
                        let nsString = storage.string as NSString
                        let lineRange = nsString.lineRange(for: textView.selectedRange)
                        let line = nsString.substring(with: lineRange)
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        var hashCount = 0
                        for ch in trimmed { if ch == "#" { hashCount += 1 } else { break } }
                        if hashCount > 0 {
                            let removeLen = min(hashCount + 1, lineRange.length) // "### "
                            storage.replaceCharacters(in: NSRange(location: lineRange.location, length: removeLen), with: "")
                        }
                    } else {
                        self.insertLinePrefix(textView: textView, prefix: prefix, storage: storage)
                    }
                    DispatchQueue.main.async { [weak self] in
                        self?.parent.text = textView.textStorage.string
                        self?.updatePlaceholder(textView)
                    }
                })
            }

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            if let popover = alert.popoverPresentationController {
                popover.sourceView = textView
                let caretRect = textView.caretRect(for: textView.selectedTextRange?.start ?? textView.beginningOfDocument)
                popover.sourceRect = caretRect
            }

            viewController.present(alert, animated: true)
        }

        // MARK: - Code Picker

        private func showCodePicker(in textView: UITextView, storage: MarkdownTextStorage) {
            guard let viewController = textView.window?.rootViewController?.presentedViewController
                    ?? textView.window?.rootViewController else { return }

            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: "Inline Code", style: .default) { [weak self] _ in
                self?.toggleWrap(textView: textView, prefix: "`", suffix: "`")
                DispatchQueue.main.async {
                    self?.parent.text = textView.textStorage.string
                    self?.updatePlaceholder(textView)
                }
            })

            alert.addAction(UIAlertAction(title: "Code Block", style: .default) { [weak self] _ in
                let range = textView.selectedRange
                let insertion = "```\n\n```"
                storage.replaceCharacters(in: range, with: insertion)
                textView.selectedRange = NSRange(location: range.location + 4, length: 0)
                DispatchQueue.main.async {
                    self?.parent.text = textView.textStorage.string
                    self?.updatePlaceholder(textView)
                }
            })

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            if let popover = alert.popoverPresentationController {
                popover.sourceView = textView
                let caretRect = textView.caretRect(for: textView.selectedTextRange?.start ?? textView.beginningOfDocument)
                popover.sourceRect = caretRect
            }

            viewController.present(alert, animated: true)
        }

        // MARK: - Link Popover

        private func showLinkPopover(textView: UITextView, storage: MarkdownTextStorage, range: NSRange) {
            guard let viewController = textView.window?.rootViewController?.presentedViewController
                    ?? textView.window?.rootViewController else { return }

            let selectedText = range.length > 0
                ? (storage.string as NSString).substring(with: range)
                : ""

            let alert = UIAlertController(title: "Add Link", message: nil, preferredStyle: .alert)
            alert.addTextField { tf in
                tf.placeholder = "Display text"
                tf.text = selectedText
                tf.autocapitalizationType = .sentences
            }
            alert.addTextField { tf in
                tf.placeholder = "https://..."
                tf.keyboardType = .URL
                tf.autocapitalizationType = .none
                tf.autocorrectionType = .no
            }

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
                let displayText = alert.textFields?[0].text ?? "link"
                let url = alert.textFields?[1].text ?? ""
                guard !url.isEmpty else { return }

                let markdown = "[\(displayText)](\(url))"
                storage.replaceCharacters(in: range, with: markdown)
                textView.selectedRange = NSRange(location: range.location + markdown.count, length: 0)

                DispatchQueue.main.async {
                    self?.parent.text = textView.textStorage.string
                    self?.updatePlaceholder(textView)
                }
            })

            // On iPad, present as popover anchored to the text view
            if let popover = alert.popoverPresentationController {
                popover.sourceView = textView
                let caretRect = textView.caretRect(for: textView.selectedTextRange?.start ?? textView.beginningOfDocument)
                popover.sourceRect = caretRect
            }

            viewController.present(alert, animated: true)
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

        // MARK: - Block Type Helper

        /// Returns the block type at the given cursor position.
        private func blockAtCursor(_ position: Int, storage: MarkdownTextStorage) -> MarkdownBlockType {
            for (lineRange, block) in storage.lineBlocks {
                if position >= lineRange.location && position <= NSMaxRange(lineRange) {
                    return block
                }
            }
            return .paragraph
        }

        // MARK: - Image Picker

        private func showImageSourcePicker(in textView: UITextView) {
            guard let viewController = textView.window?.rootViewController?.presentedViewController
                    ?? textView.window?.rootViewController else { return }

            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                alert.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
                    self?.openCamera(from: viewController, textView: textView)
                })
            }

            alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
                self?.openPhotoLibrary(from: viewController)
            })

            alert.addAction(UIAlertAction(title: "Files", style: .default) { [weak self] _ in
                self?.openFilePicker(from: viewController)
            })

            alert.addAction(UIAlertAction(title: "URL", style: .default) { [weak self] _ in
                self?.showURLImagePrompt(from: viewController, textView: textView)
            })

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            if let popover = alert.popoverPresentationController {
                popover.sourceView = textView
                let caretRect = textView.caretRect(for: textView.selectedTextRange?.start ?? textView.beginningOfDocument)
                popover.sourceRect = caretRect
            }

            viewController.present(alert, animated: true)
        }

        private func openCamera(from viewController: UIViewController, textView: UITextView) {
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            viewController.present(picker, animated: true)
        }

        private func openPhotoLibrary(from viewController: UIViewController) {
            var config = PHPickerConfiguration(photoLibrary: .shared())
            config.selectionLimit = 1
            config.filter = .images
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            viewController.present(picker, animated: true)
        }

        private func openFilePicker(from viewController: UIViewController) {
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.image])
            picker.delegate = self
            viewController.present(picker, animated: true)
        }

        private func showURLImagePrompt(from viewController: UIViewController, textView: UITextView) {
            let alert = UIAlertController(title: "Image URL", message: nil, preferredStyle: .alert)
            alert.addTextField { tf in
                tf.placeholder = "https://example.com/image.png"
                tf.keyboardType = .URL
                tf.autocapitalizationType = .none
                tf.autocorrectionType = .no
            }

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Download", style: .default) { [weak self] _ in
                guard let urlString = alert.textFields?.first?.text,
                      let url = URL(string: urlString) else { return }

                Task {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        guard let image = UIImage(data: data) else { return }
                        await MainActor.run {
                            self?.insertImage(image, in: textView)
                        }
                    } catch {
                        print("Failed to download image: \(error)")
                    }
                }
            })

            viewController.present(alert, animated: true)
        }

        private func insertImage(_ image: UIImage, in textView: UITextView) {
            guard let storage = textStorage else { return }

            // Calculate max width from text container, with fallback
            let containerWidth = textView.textContainer.size.width
            let maxWidth: CGFloat
            if containerWidth > 0 && containerWidth < 10000 {
                maxWidth = containerWidth - 10
            } else {
                maxWidth = textView.bounds.width - textView.textContainerInset.left - textView.textContainerInset.right - 10
            }

            let id = imageStore.addImage(image)
            let attachment = MarkdownImageAttachment(imageID: id, imageStore: imageStore, maxWidth: maxWidth)
            let attrString = NSMutableAttributedString(attachment: attachment)
            // Use a paragraph style without line height cap so the image
            // determines the line fragment height (not the default 24pt cap).
            let imgPara = NSMutableParagraphStyle()
            imgPara.paragraphSpacing = 4
            imgPara.minimumLineHeight = 0
            imgPara.maximumLineHeight = 0
            attrString.addAttributes([
                .font: MarkdownFonts.body,
                .paragraphStyle: imgPara
            ], range: NSRange(location: 0, length: attrString.length))

            // Always insert on its own line with newlines around it
            let insertionPoint = textView.selectedRange.location
            let nsString = storage.string as NSString
            var prefix = ""
            var suffix = "\n"

            // Add leading newline if not at start of line
            if insertionPoint > 0 && nsString.character(at: insertionPoint - 1) != 0x0A {
                prefix = "\n"
            }

            // Insert: [prefix]\n{attachment}\n
            if !prefix.isEmpty {
                storage.replaceCharacters(in: NSRange(location: insertionPoint, length: 0), with: prefix)
            }
            let attachPoint = insertionPoint + prefix.count
            storage.insert(attrString, at: attachPoint)
            storage.replaceCharacters(in: NSRange(location: attachPoint + 1, length: 0), with: suffix)
            textView.selectedRange = NSRange(location: attachPoint + 1 + suffix.count, length: 0)

            parent.text = textView.textStorage.string
            updatePlaceholder(textView)
        }

        // MARK: - UIImagePickerControllerDelegate

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            guard let image = info[.originalImage] as? UIImage,
                  let textView = textView else { return }
            insertImage(image, in: textView)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }

        // MARK: - PHPickerViewControllerDelegate

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                guard let image = object as? UIImage else { return }
                DispatchQueue.main.async {
                    guard let self, let textView = self.textView else { return }
                    self.insertImage(image, in: textView)
                }
            }
        }

        // MARK: - UIDocumentPickerDelegate

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first,
                  url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            guard let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data),
                  let textView = textView else { return }
            insertImage(image, in: textView)
        }

        // MARK: - AI Transcribe

        private func handleTranscribe(in textView: UITextView) {
            if isRecording {
                stopRecordingAndTranscribe(in: textView)
            } else {
                startRecording(in: textView)
            }
        }

        private func startRecording(in textView: UITextView) {
            let recorder = AppAudioRecorder()
            self.audioRecorder = recorder
            Task {
                do {
                    try await recorder.startRecording()
                    isRecording = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    updateTranscribeButton(recording: true)
                } catch {
                    print("Recording failed: \(error)")
                }
            }
        }

        private func stopRecordingAndTranscribe(in textView: UITextView) {
            guard let recorder = audioRecorder else { return }
            isRecording = false
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            updateTranscribeButton(recording: false)

            Task {
                do {
                    let audioData = try recorder.stopRecording()
                    isTranscribing = true
                    updateTranscribeButton(transcribing: true)

                    let result = try await TranscribeService.shared.transcribe(audioData: audioData)

                    isTranscribing = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    updateTranscribeButton(transcribing: false)

                    // Insert transcribed text at cursor position
                    guard let storage = textStorage else { return }
                    let insertionPoint = textView.selectedRange.location
                    storage.replaceCharacters(in: NSRange(location: insertionPoint, length: 0), with: result.text)
                    textView.selectedRange = NSRange(location: insertionPoint + result.text.count, length: 0)

                    parent.text = textView.textStorage.string
                    updatePlaceholder(textView)
                } catch {
                    isTranscribing = false
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    updateTranscribeButton(transcribing: false)
                    print("Transcription failed: \(error)")
                }
            }
        }

        private func updateTranscribeButton(recording: Bool = false, transcribing: Bool = false) {
            guard let textView = textView else { return }

            func applyToToolbar(_ toolbar: MarkdownKeyboardToolbar) {
                if transcribing {
                    toolbar.setSpinner(action: .aiTranscribe, visible: true)
                } else {
                    toolbar.setSpinner(action: .aiTranscribe, visible: false)
                    let icon = recording ? "stop.circle.fill" : "mic.fill"
                    let tintColor: UIColor = recording ? .systemRed : UIColor.label.withAlphaComponent(0.7)
                    toolbar.updateButton(action: .aiTranscribe, icon: icon, tintColor: tintColor)
                }
            }

            if let toolbar = textView.inputAccessoryView as? MarkdownKeyboardToolbar {
                applyToToolbar(toolbar)
            }
            if let toolbar = floatingToolbar {
                applyToToolbar(toolbar)
            }
        }

        private func updateTransformButton(transforming: Bool) {
            guard let textView = textView else { return }

            func applyToToolbar(_ toolbar: MarkdownKeyboardToolbar) {
                if transforming {
                    toolbar.setSpinner(action: .aiTransform, visible: true)
                } else {
                    toolbar.setSpinner(action: .aiTransform, visible: false)
                    toolbar.updateButton(action: .aiTransform, icon: "sparkles", tintColor: UIColor.label.withAlphaComponent(0.7))
                }
            }

            if let toolbar = textView.inputAccessoryView as? MarkdownKeyboardToolbar {
                applyToToolbar(toolbar)
            }
            if let toolbar = floatingToolbar {
                applyToToolbar(toolbar)
            }
        }

        // MARK: - AI Transform

        private func handleAITransform(in textView: UITextView) {
            guard let viewController = textView.window?.rootViewController?.presentedViewController
                    ?? textView.window?.rootViewController else { return }

            let hasSelection = textView.selectedRange.length > 0
            let selectedText = hasSelection
                ? (textView.textStorage.string as NSString).substring(with: textView.selectedRange)
                : ""
            let fullText = textView.textStorage.string
            let contextText = hasSelection ? selectedText : fullText

            guard !contextText.isEmpty else { return }

            let alert = UIAlertController(title: "AI Transform", message: nil, preferredStyle: .actionSheet)

            let options: [(String, TransformConfig)] = [
                ("Summarise", MarkdownTransformConfig.summarise),
                ("Key Pointers", MarkdownTransformConfig.keyPointers),
                ("List Actions", MarkdownTransformConfig.listActions),
            ]

            for (title, config) in options {
                alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                    self?.runTransform(config: config, text: contextText, hasSelection: hasSelection, in: textView)
                })
            }

            alert.addAction(UIAlertAction(title: "Custom\u{2026}", style: .default) { [weak self] _ in
                self?.showCustomTransformPrompt(contextText: contextText, hasSelection: hasSelection, in: textView)
            })

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            // iPad popover anchor
            if let popover = alert.popoverPresentationController {
                popover.sourceView = textView
                let caretRect = textView.caretRect(for: textView.selectedTextRange?.start ?? textView.beginningOfDocument)
                popover.sourceRect = caretRect
            }

            viewController.present(alert, animated: true)
        }

        private func showCustomTransformPrompt(contextText: String, hasSelection: Bool, in textView: UITextView) {
            guard let viewController = textView.window?.rootViewController?.presentedViewController
                    ?? textView.window?.rootViewController else { return }

            let alert = UIAlertController(title: "Custom Transform", message: "Enter your transformation instruction:", preferredStyle: .alert)
            alert.addTextField { tf in
                tf.placeholder = "e.g., Make it more concise"
                tf.autocapitalizationType = .sentences
            }

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Transform", style: .default) { [weak self] _ in
                guard let prompt = alert.textFields?.first?.text, !prompt.isEmpty else { return }
                let config = MarkdownTransformConfig.custom(prompt: prompt)
                self?.runTransform(config: config, text: contextText, hasSelection: hasSelection, in: textView)
            })

            viewController.present(alert, animated: true)
        }

        private func runTransform(config: TransformConfig, text: String, hasSelection: Bool, in textView: UITextView) {
            guard let storage = textStorage else { return }

            // Show spinner + haptic on start
            updateTransformButton(transforming: true)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            Task {
                var result = ""
                let stream = TransformService.shared.stream(config: config, input: TransformInput(text: text))

                do {
                    for try await event in stream {
                        switch event {
                        case .textDelta(let delta):
                            result += delta
                        case .done:
                            break
                        default:
                            break
                        }
                    }
                } catch {
                    print("Transform failed: \(error)")
                    await MainActor.run {
                        updateTransformButton(transforming: false)
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                    }
                    return
                }

                await MainActor.run {
                    updateTransformButton(transforming: false)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }

                guard !result.isEmpty else { return }

                if hasSelection {
                    showReplaceOrInsertPopup(result: result, selectionRange: textView.selectedRange, in: textView)
                } else {
                    // No selection — insert result below cursor
                    let insertionPoint = textView.selectedRange.location
                    let insertion = "\n\n" + result
                    storage.replaceCharacters(in: NSRange(location: insertionPoint, length: 0), with: insertion)
                    textView.selectedRange = NSRange(location: insertionPoint + insertion.count, length: 0)
                    parent.text = textView.textStorage.string
                    updatePlaceholder(textView)
                }
            }
        }

        private func showReplaceOrInsertPopup(result: String, selectionRange: NSRange, in textView: UITextView) {
            guard let storage = textStorage,
                  let viewController = textView.window?.rootViewController?.presentedViewController
                    ?? textView.window?.rootViewController else { return }

            let alert = UIAlertController(title: "AI Result", message: nil, preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Replace selected text", style: .default) { [weak self] _ in
                storage.replaceCharacters(in: selectionRange, with: result)
                textView.selectedRange = NSRange(location: selectionRange.location + result.count, length: 0)
                self?.parent.text = textView.textStorage.string
                self?.updatePlaceholder(textView)
            })

            alert.addAction(UIAlertAction(title: "Add below", style: .default) { [weak self] _ in
                let insertPoint = NSMaxRange(selectionRange)
                let insertion = "\n\n" + result
                storage.replaceCharacters(in: NSRange(location: insertPoint, length: 0), with: insertion)
                textView.selectedRange = NSRange(location: insertPoint + insertion.count, length: 0)
                self?.parent.text = textView.textStorage.string
                self?.updatePlaceholder(textView)
            })

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            viewController.present(alert, animated: true)
        }
    }
}
