// AppInputField.swift
// Figma source: bubbles-kit › node 90:3753 "Input Field"
//
// Axes: State(Default/Disabled/Focus/Filled/Success/Warning/Error) × Type(Default/TextField) = 11
//
// Usage:
//   AppInputField(text: $name, label: "Full Name", placeholder: "Enter your name")
//   AppInputField(text: $email, label: "Email", state: .error, hint: "Invalid email address")
//   AppTextField(text: $bio, label: "Bio", placeholder: "Tell us about yourself")

import SwiftUI

// MARK: - Types

public enum AppInputFieldState {
    case `default`
    case success
    case warning
    case error
}

// MARK: - State Spec

private struct InputStateSpec {
    let borderColor: Color
    let focusBorderColor: Color
    let hintColor: Color
    let iconColor: Color
}

private extension AppInputFieldState {
    var spec: InputStateSpec {
        switch self {
        case .default:
            return InputStateSpec(
                borderColor: .borderDefault,
                focusBorderColor: .borderActive,
                hintColor: .typographyMuted,
                iconColor: .iconsMuted
            )
        case .success:
            return InputStateSpec(
                borderColor: .borderSuccess,
                focusBorderColor: .borderSuccess,
                hintColor: .typographySuccess,
                iconColor: .iconsSuccess
            )
        case .warning:
            return InputStateSpec(
                borderColor: .borderWarning,
                focusBorderColor: .borderWarning,
                hintColor: .typographyWarning,
                iconColor: .iconsWarning
            )
        case .error:
            return InputStateSpec(
                borderColor: .borderError,
                focusBorderColor: .borderError,
                hintColor: .typographyError,
                iconColor: .iconsError
            )
        }
    }
}

// MARK: - AppInputField (single line)

public struct AppInputField: View {

    @Binding var text: String
    let label: String?
    let placeholder: String
    let state: AppInputFieldState
    let hint: String?
    let leadingIcon: AnyView?
    let trailingIcon: AnyView?
    let isDisabled: Bool

    @FocusState private var isFocused: Bool

    public init(
        text: Binding<String>,
        label: String? = nil,
        placeholder: String = "",
        state: AppInputFieldState = .default,
        hint: String? = nil,
        leadingIcon: AnyView? = nil,
        trailingIcon: AnyView? = nil,
        isDisabled: Bool = false
    ) {
        self._text = text
        self.label = label
        self.placeholder = placeholder
        self.state = state
        self.hint = hint
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
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
                    .font(.appBodySmallEm)
                    .foregroundStyle(Color.typographySecondary)
            }

            HStack(spacing: CGFloat.space2) {
                if let icon = leadingIcon {
                    icon
                        .frame(width: .iconSizeSm, height: .iconSizeSm)
                        .foregroundStyle(spec.iconColor)
                }

                TextField(placeholder, text: $text)
                    .font(.appBodyMedium)
                    .foregroundStyle(Color.typographyPrimary)
                    .focused($isFocused)
                    .disabled(isDisabled)
                    .accessibilityHint(hint ?? "")

                if let icon = trailingIcon {
                    icon
                        .frame(width: .iconSizeSm, height: .iconSizeSm)
                        .foregroundStyle(spec.iconColor)
                }
            }
            .padding(.horizontal, CGFloat.space4)
            .padding(.vertical, 14)
            .background(Color.surfacesBaseLowContrast)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(currentBorderColor, lineWidth: 1)
            )
            .opacity(isDisabled ? 0.5 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isFocused)

            if let hint {
                Text(hint)
                    .font(.appCaptionMedium)
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
                    .font(.appBodySmallEm)
                    .foregroundStyle(Color.typographySecondary)
            }

            TextEditor(text: $text)
                .font(.appBodyMedium)
                .foregroundStyle(Color.typographyPrimary)
                .focused($isFocused)
                .disabled(isDisabled)
                .frame(minHeight: CGFloat(minLines) * 20 + CGFloat.space4)
                .padding(.horizontal, CGFloat.space4 - 4) // TextEditor has built-in inset
                .padding(.vertical, 10) // ~14pt minus TextEditor built-in inset
                .background(Color.surfacesBaseLowContrast)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(currentBorderColor, lineWidth: 1)
                )
                .opacity(isDisabled ? 0.5 : 1.0)
                .animation(.easeOut(duration: 0.15), value: isFocused)

            if let hint {
                Text(hint)
                    .font(.appCaptionMedium)
                    .foregroundStyle(spec.hintColor)
            }
        }
    }
}

// MARK: - Preview

#Preview("Input Field") {
    @Previewable @State var name = ""
    @Previewable @State var email = "user@example"
    @Previewable @State var bio = ""

    ScrollView {
        VStack(spacing: CGFloat.space4) {

            AppInputField(text: $name, label: "Full Name", placeholder: "Enter your name")
            AppInputField(text: .constant("user@example.com"), label: "Email", state: .success, hint: "Looks good!")
            AppInputField(text: $email, label: "Email", state: .error, hint: "Please enter a valid email address")
            AppInputField(text: .constant(""), label: "Password", placeholder: "Enter password", state: .warning, hint: "Weak password")
            AppInputField(text: .constant("Disabled value"), label: "Disabled", isDisabled: true)

            Divider()

            AppTextField(text: $bio, label: "Bio", placeholder: "Tell us about yourself…")
        }
        .padding(CGFloat.space4)
    }
    .background(Color.surfacesBasePrimary)
}
