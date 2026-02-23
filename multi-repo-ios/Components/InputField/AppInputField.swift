// AppInputField.swift
// Figma source: bubbles-kit › node 90:3753 "Input Field"
//
// Axes: State(Default/Disabled/Focus/Filled/Success/Warning/Error) × Type(Default/TextField) = 11
//
// Figma primitive slots (left→right):
//   [leadingLabel?] [leadingPicker?] [leadingSeparator?] [text field] [trailingSeparator?] [trailingPicker?] [trailingLabel?]
//
// Usage:
//   AppInputField(text: $name, label: "Full Name", placeholder: "Enter your name")
//   AppInputField(text: $email, label: "Email", state: .error, hint: "Invalid email address")
//   AppInputField(text: $amount, label: "Amount", leadingLabel: AnyView(AppLabel(label: "USD")), leadingSeparator: true)
//   AppTextField(text: $bio, label: "Bio", placeholder: "Tell us about yourself…")
//
//   // First-class picker slots (no AnyView wrapping required):
//   AppInputField(text: $amount, label: "Amount",
//       leadingPicker: .picker(label: "Currency", selection: $currency,
//                              options: [("USD", "USD"), ("EUR", "EUR")]),
//       leadingSeparator: true)

import SwiftUI
import PhosphorSwift

// MARK: - Types

public enum AppInputFieldState {
    case `default`
    case success
    case warning
    case error
}

// MARK: - InputPickerConfig

/// Type-erased picker configuration for AppInputField's leading/trailing picker slots.
/// Use the static factory `.picker(label:selection:options:)` — it renders
/// `AppNativePicker(embedded: true)` internally so the caller never touches AnyView.
public struct InputPickerConfig {
    let view: AnyView

    /// Creates a picker config backed by an embedded AppNativePicker chip.
    public static func picker<T: Hashable>(
        label: String,
        selection: Binding<T>,
        options: [(label: String, value: T)]
    ) -> InputPickerConfig {
        InputPickerConfig(view: AnyView(
            AppNativePicker(
                label: label,
                selection: selection,
                options: options,
                embedded: true
            )
        ))
    }
}

// MARK: - State Spec

private struct InputStateSpec {
    let borderColor: Color
    let focusBorderColor: Color
    let hintColor: Color
    let iconColor: Color
    let stateIcon: AnyView?
}

private extension AppInputFieldState {
    var spec: InputStateSpec {
        switch self {
        case .default:
            // No border at rest — only shows on focus (borderActive)
            return InputStateSpec(
                borderColor: .clear,
                focusBorderColor: .borderActive,
                hintColor: .typographyMuted,
                iconColor: .iconsMuted,
                stateIcon: nil
            )
        case .success:
            return InputStateSpec(
                borderColor: .borderSuccess,
                focusBorderColor: .borderSuccess,
                hintColor: .typographySuccess,
                iconColor: .iconsSuccess,
                stateIcon: AnyView(Ph.checkCircle.regular.iconSize(.md).foregroundStyle(Color.iconsSuccess))
            )
        case .warning:
            return InputStateSpec(
                borderColor: .borderWarning,
                focusBorderColor: .borderWarning,
                hintColor: .typographyWarning,
                iconColor: .iconsWarning,
                stateIcon: AnyView(Ph.warning.regular.iconSize(.md).foregroundStyle(Color.iconsWarning))
            )
        case .error:
            return InputStateSpec(
                borderColor: .borderError,
                focusBorderColor: .borderError,
                hintColor: .typographyError,
                iconColor: .iconsError,
                stateIcon: AnyView(Ph.warningCircle.regular.iconSize(.md).foregroundStyle(Color.iconsError))
            )
        }
    }
}

// MARK: - Shared Label Style

private let LABEL_FONT: Font = .appBodySmallEm
private let HINT_FONT: Font = .appCaptionMedium
private let INPUT_FONT: Font = .appBodyMedium
// Figma: radius-lg (16pt mobile). No border at rest for default state — border only on focus.
private let INPUT_CORNER_RADIUS: CGFloat = 16
private let INPUT_H_PADDING: CGFloat = 16
private let INPUT_V_PADDING: CGFloat = 14

// MARK: - AppInputField (single line)

public struct AppInputField: View {

    // MARK: - Properties

    @Binding var text: String
    let label: String?
    let placeholder: String
    let state: AppInputFieldState
    let hint: String?
    let leadingIcon: AnyView?
    let trailingIcon: AnyView?
    let leadingLabel: AnyView?
    let trailingLabel: AnyView?
    let leadingPicker: InputPickerConfig?
    let trailingPicker: InputPickerConfig?
    let leadingSeparator: Bool
    let trailingSeparator: Bool
    let isDisabled: Bool

    @FocusState private var isFocused: Bool

    // MARK: - Init

    public init(
        text: Binding<String>,
        label: String? = nil,
        placeholder: String = "",
        state: AppInputFieldState = .default,
        hint: String? = nil,
        leadingIcon: AnyView? = nil,
        trailingIcon: AnyView? = nil,
        leadingLabel: AnyView? = nil,
        trailingLabel: AnyView? = nil,
        leadingPicker: InputPickerConfig? = nil,
        trailingPicker: InputPickerConfig? = nil,
        leadingSeparator: Bool = false,
        trailingSeparator: Bool = false,
        isDisabled: Bool = false
    ) {
        self._text = text
        self.label = label
        self.placeholder = placeholder
        self.state = state
        self.hint = hint
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
        self.leadingLabel = leadingLabel
        self.trailingLabel = trailingLabel
        self.leadingPicker = leadingPicker
        self.trailingPicker = trailingPicker
        self.leadingSeparator = leadingSeparator
        self.trailingSeparator = trailingSeparator
        self.isDisabled = isDisabled
    }

    // MARK: - Helpers

    private var spec: InputStateSpec { state.spec }

    private var currentBorderColor: Color {
        isFocused ? spec.focusBorderColor : spec.borderColor
    }

    /// Icon color for leading/trailing icons:
    /// - Default state: muted when empty+unfocused, primary when focused OR non-empty.
    /// - Semantic states (success/warning/error): always use the state color unchanged.
    private var activeIconColor: Color {
        guard state == .default else { return spec.iconColor }
        return (isFocused || !text.isEmpty) ? .iconsPrimary : .iconsMuted
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: CGFloat.space1) {
            // ── Floating label ───────────────────────────────────────────────
            if let label {
                Text(label)
                    .font(LABEL_FONT)
                    .foregroundStyle(Color.typographySecondary)
            }

            // ── Input row ────────────────────────────────────────────────────
            HStack(spacing: CGFloat.space2) {

                // Leading label slot (AnyView)
                if let leadingLabel {
                    leadingLabel
                }

                // Leading picker slot (first-class, chip trigger only)
                if let leadingPicker {
                    leadingPicker.view
                }

                // Leading separator — shown when either leading slot is present
                if leadingSeparator && (leadingLabel != nil || leadingPicker != nil) {
                    Divider()
                        .frame(width: 1)
                        .background(Color.appBorderDefault)
                }

                // Leading simple icon
                if let leadingIcon {
                    leadingIcon
                        .frame(width: CGFloat.iconSizeMd, height: CGFloat.iconSizeMd)
                        .foregroundStyle(activeIconColor)
                }

                // TextField — tint controls cursor + selection colour
                TextField(placeholder, text: $text)
                    .font(INPUT_FONT)
                    .foregroundStyle(Color.typographyPrimary)
                    .tint(Color.surfacesBrandInteractive)
                    .focused($isFocused)
                    .disabled(isDisabled)
                    .accessibilityHint(hint ?? "")

                // Trailing simple icon (user-provided overrides state icon)
                if let trailingIcon {
                    trailingIcon
                        .frame(width: CGFloat.iconSizeMd, height: CGFloat.iconSizeMd)
                        .foregroundStyle(activeIconColor)
                } else if trailingLabel == nil, trailingPicker == nil, let stateIcon = spec.stateIcon {
                    // Auto state icon only when no trailing icon/label/picker
                    stateIcon
                }

                // Trailing separator — shown when either trailing slot is present
                if trailingSeparator && (trailingLabel != nil || trailingPicker != nil) {
                    Divider()
                        .frame(width: 1)
                        .background(Color.appBorderDefault)
                }

                // Trailing picker slot (first-class, chip trigger only)
                if let trailingPicker {
                    trailingPicker.view
                }

                // Trailing label slot (AnyView)
                if let trailingLabel {
                    trailingLabel
                }
            }
            .padding(.horizontal, INPUT_H_PADDING)
            .padding(.vertical, INPUT_V_PADDING)
            .background(Color.surfacesBaseLowContrast)
            .clipShape(RoundedRectangle(cornerRadius: INPUT_CORNER_RADIUS))
            .overlay(
                RoundedRectangle(cornerRadius: INPUT_CORNER_RADIUS)
                    .strokeBorder(currentBorderColor, lineWidth: 1)
            )
            .opacity(isDisabled ? 0.5 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isFocused)
            // Haptic feedback when the field gains focus
            .onChange(of: isFocused) { _, focused in
                guard focused else { return }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }

            // ── Hint ─────────────────────────────────────────────────────────
            if let hint {
                Text(hint)
                    .font(HINT_FONT)
                    .foregroundStyle(spec.hintColor)
            }
        }
    }
}

// MARK: - AppTextField (multiline)

public struct AppTextField: View {

    @Binding var text: String
    let label: String?
    let placeholder: String
    let state: AppInputFieldState
    let hint: String?
    let minLines: Int
    let isDisabled: Bool

    @FocusState private var isFocused: Bool

    public init(
        text: Binding<String>,
        label: String? = nil,
        placeholder: String = "",
        state: AppInputFieldState = .default,
        hint: String? = nil,
        minLines: Int = 4,
        isDisabled: Bool = false
    ) {
        self._text = text
        self.label = label
        self.placeholder = placeholder
        self.state = state
        self.hint = hint
        self.minLines = minLines
        self.isDisabled = isDisabled
    }

    private var spec: InputStateSpec { state.spec }

    private var currentBorderColor: Color {
        isFocused ? spec.focusBorderColor : spec.borderColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: CGFloat.space1) {
            if let label {
                Text(label)
                    .font(LABEL_FONT)
                    .foregroundStyle(Color.typographySecondary)
            }

            TextEditor(text: $text)
                .font(INPUT_FONT)
                .foregroundStyle(Color.typographyPrimary)
                .tint(Color.surfacesBrandInteractive)
                .scrollContentBackground(.hidden)  // Remove TextEditor's default background
                .focused($isFocused)
                .disabled(isDisabled)
                .frame(minHeight: CGFloat(minLines) * 20 + CGFloat.space4)
                .padding(.horizontal, INPUT_H_PADDING - 4) // TextEditor has built-in inset
                .padding(.vertical, 10)
                .background(Color.surfacesBaseLowContrast)
                .clipShape(RoundedRectangle(cornerRadius: INPUT_CORNER_RADIUS))
                .overlay(
                    RoundedRectangle(cornerRadius: INPUT_CORNER_RADIUS)
                        .strokeBorder(currentBorderColor, lineWidth: 1)
                )
                .opacity(isDisabled ? 0.5 : 1.0)
                .animation(.easeOut(duration: 0.15), value: isFocused)

            if let hint {
                Text(hint)
                    .font(HINT_FONT)
                    .foregroundStyle(spec.hintColor)
            }
        }
    }
}

// MARK: - Preview

#Preview("Input Field — All States") {
    @Previewable @State var text1 = ""
    @Previewable @State var text2 = "user@example.com"
    @Previewable @State var text3 = ""
    @Previewable @State var bio = ""
    @Previewable @State var currency = "USD"
    @Previewable @State var amount = ""
    @Previewable @State var unit = "kg"

    ScrollView {
        VStack(spacing: CGFloat.space4) {

            // ── Basic states ──────────────────────────────────────────────────
            AppInputField(text: $text1, label: "Default", placeholder: "Enter text")
            AppInputField(text: $text2, label: "Success", state: .success, hint: "Looks good!")
            AppInputField(text: .constant("weak"), label: "Warning", state: .warning, hint: "Weak password")
            AppInputField(text: .constant("user@bad"), label: "Error", state: .error, hint: "Invalid email address")
            AppInputField(text: .constant("Disabled"), label: "Disabled", isDisabled: true)

            Divider()

            // ── With icon slots ───────────────────────────────────────────────
            AppInputField(
                text: $text3,
                label: "With leading icon",
                placeholder: "Search…",
                leadingIcon: AnyView(Ph.magnifyingGlass.regular.iconSize(.md))
            )

            AppInputField(
                text: $text3,
                label: "With trailing icon",
                placeholder: "Password",
                trailingIcon: AnyView(Ph.eye.regular.iconSize(.md))
            )

            Divider()

            // ── First-class picker slots ───────────────────────────────────────
            AppInputField(
                text: $amount,
                label: "Leading picker (currency)",
                placeholder: "0.00",
                leadingPicker: .picker(
                    label: "Currency",
                    selection: $currency,
                    options: [("USD", "USD"), ("EUR", "EUR"), ("GBP", "GBP")]
                ),
                leadingSeparator: true
            )

            AppInputField(
                text: $amount,
                label: "Trailing picker (unit)",
                placeholder: "Enter weight",
                trailingPicker: .picker(
                    label: "Unit",
                    selection: $unit,
                    options: [("kg", "kg"), ("lb", "lb")]
                ),
                trailingSeparator: true
            )

            Divider()

            // ── With Label slots ──────────────────────────────────────────────
            AppInputField(
                text: $text3,
                label: "Leading label",
                placeholder: "0.00",
                leadingLabel: AnyView(AppLabel(label: "USD", size: .md, type: .secondaryAction)),
                leadingSeparator: true
            )

            AppInputField(
                text: $text3,
                label: "Trailing label",
                placeholder: "Enter amount",
                trailingLabel: AnyView(AppLabel(label: "kg", size: .md, type: .information)),
                trailingSeparator: true
            )

            AppInputField(
                text: $text3,
                label: "Leading + Trailing labels",
                placeholder: "0.00",
                leadingLabel: AnyView(AppLabel(label: "From", size: .md, type: .secondaryAction)),
                trailingLabel: AnyView(AppLabel(label: "USD", size: .md, type: .brandInteractive)),
                leadingSeparator: true,
                trailingSeparator: true
            )

            Divider()

            // ── Multiline ─────────────────────────────────────────────────────
            AppTextField(text: $bio, label: "Bio", placeholder: "Tell us about yourself…")
            AppTextField(text: .constant("Great content here."), label: "Bio (filled)", state: .success)
        }
        .padding(CGFloat.space4)
    }
    .background(Color.surfacesBasePrimary)
}
