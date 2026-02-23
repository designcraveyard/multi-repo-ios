// AppRadioButton.swift
// Custom radio button + radio group for single-selection scenarios.
// No Figma source — designed from scratch using semantic design tokens.
//
// Usage:
//   AppRadioButton(checked: isSelected, label: "Option A") { isSelected = $0 }
//
//   AppRadioGroup(value: $selected) {
//       AppRadioButton(value: "a", label: "Option A")
//       AppRadioButton(value: "b", label: "Option B")
//   }

import SwiftUI

// MARK: - RadioGroup Environment Key

private struct RadioGroupValueKey: EnvironmentKey {
    static let defaultValue: Binding<String>? = nil
}

private struct RadioGroupDisabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var radioGroupValue: Binding<String>? {
        get { self[RadioGroupValueKey.self] }
        set { self[RadioGroupValueKey.self] = newValue }
    }
    var radioGroupDisabled: Bool {
        get { self[RadioGroupDisabledKey.self] }
        set { self[RadioGroupDisabledKey.self] = newValue }
    }
}

// MARK: - AppRadioButton

/// Standalone radio button with optional label. Use inside AppRadioGroup for managed single-selection.
public struct AppRadioButton: View {

    // MARK: - Properties

    let checked: Bool
    let label: String?
    let value: String?
    let disabled: Bool
    let onChange: ((Bool) -> Void)?

    @Environment(\.radioGroupValue) private var groupValue
    @Environment(\.radioGroupDisabled) private var groupDisabled

    public init(
        checked: Bool = false,
        label: String? = nil,
        value: String? = nil,
        disabled: Bool = false,
        onChange: ((Bool) -> Void)? = nil
    ) {
        self.checked = checked
        self.label = label
        self.value = value
        self.disabled = disabled
        self.onChange = onChange
    }

    // MARK: - Computed

    private var isChecked: Bool {
        if let groupValue, let value {
            return groupValue.wrappedValue == value
        }
        return checked
    }

    private var isDisabled: Bool { disabled || groupDisabled }

    // MARK: - Body

    public var body: some View {
        Button(action: handleTap) {
            HStack(spacing: .space2) {
                radioCircle
                if let label {
                    Text(label)
                        .font(isChecked ? .appBodyMediumEm : .appBodyMedium)
                        .foregroundStyle(Color.typographyPrimary)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isChecked ? "Selected" : "Not selected")
    }

    // MARK: - Subviews

    private var radioCircle: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    isChecked ? Color.surfacesBrandInteractive : Color.borderDefault,
                    lineWidth: 2
                )
                .frame(width: 20, height: 20)
                .background(
                    Circle().fill(isChecked ? Color.surfacesBrandInteractive : Color.clear)
                )

            if isChecked {
                Circle()
                    .fill(Color.typographyOnBrandPrimary)
                    .frame(width: 8, height: 8)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isChecked)
    }

    // MARK: - Helpers

    private func handleTap() {
        if let groupValue, let value {
            groupValue.wrappedValue = value
        } else {
            onChange?(!isChecked)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - AppRadioGroup

/// Manages single-selection state across a group of AppRadioButton children.
public struct AppRadioGroup<Content: View>: View {

    @Binding var value: String
    let disabled: Bool
    let content: Content

    public init(
        value: Binding<String>,
        disabled: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self._value = value
        self.disabled = disabled
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .space3) {
            content
        }
        .environment(\.radioGroupValue, $value)
        .environment(\.radioGroupDisabled, disabled)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Preview

#Preview("RadioButton") {
    struct RadioPreview: View {
        @State private var selected = "a"
        @State private var standalone = false

        var body: some View {
            VStack(alignment: .leading, spacing: .space6) {
                Text("Standalone").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                AppRadioButton(checked: standalone, label: "Standalone radio") { standalone = $0 }

                Text("Radio Group").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                AppRadioGroup(value: $selected) {
                    AppRadioButton(label: "Option A", value: "a")
                    AppRadioButton(label: "Option B", value: "b")
                    AppRadioButton(label: "Option C", value: "c")
                }

                Text("Disabled").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                AppRadioGroup(value: .constant("a"), disabled: true) {
                    AppRadioButton(label: "Disabled selected", value: "a")
                    AppRadioButton(label: "Disabled unselected", value: "b")
                }
            }
            .padding(.space4)
            .background(Color.surfacesBasePrimary)
        }
    }
    return RadioPreview()
}
