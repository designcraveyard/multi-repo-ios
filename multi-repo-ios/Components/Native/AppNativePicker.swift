// AppNativePicker.swift
// Style source: NativeComponentStyling.swift › NativePickerStyling
//
// Usage:
//   AppNativePicker(label: "Country", selection: $country, options: [
//       (label: "Australia", value: "AU"),
//       (label: "India",     value: "IN"),
//   ])
//
//   // With validation error:
//   AppNativePicker(label: "Size", selection: $size, options: sizes,
//                  showError: true, errorMessage: "Please select a size")
//
//   // Disabled:
//   AppNativePicker(label: "Region", selection: $region, options: regions,
//                  isDisabled: true)

import SwiftUI

// MARK: - AppNativePicker

/// A styled wrapper around SwiftUI's `Picker` using `.menu` style.
/// All visual tokens come from `NativePickerStyling` in `NativeComponentStyling.swift`.
public struct AppNativePicker<T: Hashable>: View {

    // MARK: - Properties

    /// Text label displayed on the picker trigger button.
    let label: String

    /// The currently selected value. Bind to a `@State` or `@Published` variable.
    @Binding var selection: T

    /// The list of options to display. Each option is a `(label: String, value: T)` tuple.
    let options: [(label: String, value: T)]

    /// When true, the picker is rendered at 0.5 opacity and interaction is blocked.
    var isDisabled: Bool = false

    /// When true, a red error border is drawn and `errorMessage` is displayed below.
    var showError: Bool = false

    /// The validation message shown below the picker when `showError` is true.
    var errorMessage: String = ""

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: NativePickerStyling.Layout.paddingV) {
            Picker(label, selection: $selection) {
                ForEach(options, id: \.value) { option in
                    Text(option.label)
                        .foregroundStyle(
                            option.value == selection
                                ? NativePickerStyling.Colors.selectedText
                                : NativePickerStyling.Colors.optionText
                        )
                        .tag(option.value)
                }
            }
            .pickerStyle(.menu)
            .tint(NativePickerStyling.Colors.tint)
            .font(NativePickerStyling.Typography.label)
            .foregroundStyle(NativePickerStyling.Colors.label)
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.5 : 1.0)
            .padding(.vertical, NativePickerStyling.Layout.paddingV)
            .padding(.horizontal, NativePickerStyling.Layout.paddingH)
            .background(
                RoundedRectangle(cornerRadius: NativePickerStyling.Layout.cornerRadius)
                    .stroke(
                        showError
                            ? NativePickerStyling.Colors.errorBorder
                            : Color.appBorderDefault,
                        lineWidth: showError
                            ? NativePickerStyling.Layout.errorBorderWidth
                            : NativePickerStyling.Layout.defaultBorderWidth
                    )
            )

            if showError && !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(NativePickerStyling.Typography.helper)
                    .foregroundStyle(NativePickerStyling.Colors.errorText)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selected = "AU"
    @Previewable @State var errSelected = "AU"

    VStack(spacing: 24) {
        AppNativePicker(
            label: "Country",
            selection: $selected,
            options: [("Australia", "AU"), ("India", "IN"), ("USA", "US")]
        )

        AppNativePicker(
            label: "Size",
            selection: $errSelected,
            options: [("Small", "S"), ("Medium", "M"), ("Large", "L")],
            showError: true,
            errorMessage: "Please select a size"
        )

        AppNativePicker(
            label: "Region (disabled)",
            selection: $selected,
            options: [("North", "N"), ("South", "S")],
            isDisabled: true
        )
    }
    .padding()
}
