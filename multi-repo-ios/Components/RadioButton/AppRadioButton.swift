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

/// A circular radio button with optional label for single-selection scenarios.
///
/// Can be used standalone (with `checked` + `onChange`) or inside an `AppRadioGroup`
/// (with `value` matching the group's bound `String`). When inside a group, the
/// `checked` and `onChange` props are ignored in favor of the environment-injected
/// group binding.
///
/// The radio indicator is a 20pt circle: unchecked shows a default border; checked
/// fills with the brand interactive color and renders an 8pt white inner dot.
/// Disabled state uses 0.5 opacity. Haptic feedback (light) fires on tap.
///
/// **Key properties:** `checked`, `label`, `value`, `disabled`, `onChange`
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

    /// Resolves checked state: prefers group-managed value when inside AppRadioGroup,
    /// falls back to the standalone `checked` prop otherwise.
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

    /// The 20pt radio indicator circle. When checked, the outer circle fills with
    /// brand-interactive color and an 8pt white dot appears in the center.
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
                // Inner dot rendered on top of the filled circle
                Circle()
                    .fill(Color.typographyOnBrandPrimary)
                    .frame(width: 8, height: 8)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isChecked)
    }

    // MARK: - Helpers

    /// Handles tap: updates group binding if inside a group, otherwise calls onChange.
    /// Always fires light haptic feedback.
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

/// Manages single-selection state across a group of `AppRadioButton` children.
///
/// Injects the shared `value` binding and `disabled` flag into the environment so that
/// child radio buttons automatically derive their checked state and update the group
/// selection on tap. Renders children in a vertical `VStack` with `space3` spacing.
///
/// **Key properties:** `value` (binding), `disabled`
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
