// AppColorPicker.swift
// Style source: NativeComponentStyling.swift › NativeColorPickerStyling
//
// Usage:
//   AppColorPicker(label: "Accent Color", selection: $accentColor)
//
//   // With opacity slider:
//   AppColorPicker(label: "Background", selection: $bgColor, supportsOpacity: true)

import SwiftUI

// MARK: - AppColorPicker

/// A styled wrapper around SwiftUI's `ColorPicker`.
/// All visual tokens come from `NativeColorPickerStyling` in `NativeComponentStyling.swift`.
///
/// Note: The color swatch and system color wheel sheet are fully managed by iOS.
/// Only the label font/color and surrounding tint are configurable via public API.
public struct AppColorPicker: View {

    // MARK: - Properties

    /// Label text displayed next to the color swatch trigger button.
    let label: String

    /// The currently selected color. Bind to a `@State` or `@Published` variable.
    @Binding var selection: Color

    /// When true, the system color wheel includes an opacity/alpha slider.
    var supportsOpacity: Bool = false

    // MARK: - Body

    public var body: some View {
        ColorPicker(label, selection: $selection, supportsOpacity: supportsOpacity)
            .font(NativeColorPickerStyling.Typography.label)
            .foregroundStyle(NativeColorPickerStyling.Colors.label)
            .tint(NativeColorPickerStyling.Colors.tint)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var color1 = Color.appSurfaceAccentPrimary
    @Previewable @State var color2 = Color.appSurfaceSuccessSolid

    VStack(spacing: 24) {
        AppColorPicker(label: "Accent Color", selection: $color1)
        AppColorPicker(label: "Background (with opacity)", selection: $color2,
                       supportsOpacity: true)
    }
    .padding()
}
