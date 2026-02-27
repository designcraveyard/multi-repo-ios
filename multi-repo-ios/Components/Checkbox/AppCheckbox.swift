// AppCheckbox.swift
// Custom checkbox supporting checked, unchecked, and indeterminate states.
// No Figma source — designed from scratch using semantic design tokens.
//
// Usage:
//   AppCheckbox(checked: isOn, label: "Agree to terms") { isOn = $0 }
//   AppCheckbox(checked: true, indeterminate: true, label: "Partial")

import SwiftUI

// MARK: - AppCheckbox

/// A square checkbox with optional label, supporting three visual states:
/// unchecked (empty bordered square), checked (filled square with checkmark),
/// and indeterminate (filled square with horizontal dash).
///
/// The indicator is a 20pt rounded-rectangle using `radiusXS` corner radius.
/// When filled (checked or indeterminate), the background uses the brand-interactive
/// color and the icon is drawn as a white `Path` stroke. The checkmark and dash
/// are rendered with `lineCap: .round` for a polished appearance.
///
/// Disabled state uses 0.5 opacity. Haptic feedback (light) fires on tap.
///
/// **Key properties:** `checked`, `indeterminate`, `label`, `disabled`, `onChange`
public struct AppCheckbox: View {

    // MARK: - Properties

    let checked: Bool
    let indeterminate: Bool
    let label: String?
    let disabled: Bool
    let onChange: ((Bool) -> Void)?

    public init(
        checked: Bool = false,
        indeterminate: Bool = false,
        label: String? = nil,
        disabled: Bool = false,
        onChange: ((Bool) -> Void)? = nil
    ) {
        self.checked = checked
        self.indeterminate = indeterminate
        self.label = label
        self.disabled = disabled
        self.onChange = onChange
    }

    // MARK: - Computed

    /// True when the box should render with a filled brand-interactive background
    /// (either checked or indeterminate).
    private var isFilled: Bool { checked || indeterminate }

    // MARK: - Body

    public var body: some View {
        Button(action: handleTap) {
            HStack(spacing: .space2) {
                checkboxSquare
                if let label {
                    Text(label)
                        .font(isFilled ? .appBodyMediumEm : .appBodyMedium)
                        .foregroundStyle(Color.typographyPrimary)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1.0)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(
            indeterminate ? "Mixed" : (checked ? "Checked" : "Unchecked")
        )
    }

    // MARK: - Subviews

    private var checkboxSquare: some View {
        ZStack {
            RoundedRectangle(cornerRadius: .radiusXS)
                .strokeBorder(
                    isFilled ? Color.surfacesBrandInteractive : Color.borderDefault,
                    lineWidth: 2
                )
                .frame(width: 20, height: 20)
                .background(
                    RoundedRectangle(cornerRadius: .radiusXS)
                        .fill(isFilled ? Color.surfacesBrandInteractive : Color.clear)
                )

            if checked && !indeterminate {
                checkmarkIcon
            }

            if indeterminate {
                dashIcon
            }
        }
        .animation(.easeInOut(duration: 0.15), value: checked)
        .animation(.easeInOut(duration: 0.15), value: indeterminate)
    }

    /// Hand-drawn checkmark path: starts bottom-left, angles down to the dip, then up to top-right.
    /// Coordinates are relative to the 20x20 frame.
    private var checkmarkIcon: some View {
        Path { path in
            path.move(to: CGPoint(x: 5, y: 10))
            path.addLine(to: CGPoint(x: 8.5, y: 13.5))
            path.addLine(to: CGPoint(x: 15, y: 6))
        }
        .stroke(Color.typographyOnBrandPrimary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        .frame(width: 20, height: 20)
    }

    /// Horizontal dash for indeterminate state: a centered line from x=5 to x=15.
    private var dashIcon: some View {
        Path { path in
            path.move(to: CGPoint(x: 5, y: 10))
            path.addLine(to: CGPoint(x: 15, y: 10))
        }
        .stroke(Color.typographyOnBrandPrimary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        .frame(width: 20, height: 20)
    }

    // MARK: - Helpers

    private func handleTap() {
        onChange?(!checked)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Preview

#Preview("Checkbox") {
    struct CheckboxPreview: View {
        @State private var isChecked = false
        @State private var isIndeterminate = true

        var body: some View {
            VStack(alignment: .leading, spacing: .space6) {
                Text("Default").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                AppCheckbox(checked: isChecked, label: "Accept terms") { isChecked = $0 }

                Text("Indeterminate").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                AppCheckbox(checked: true, indeterminate: isIndeterminate, label: "Select all") {
                    isIndeterminate = false
                    isChecked = $0
                }

                Text("Disabled").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                AppCheckbox(checked: true, label: "Disabled checked", disabled: true)
                AppCheckbox(checked: false, label: "Disabled unchecked", disabled: true)
            }
            .padding(.space4)
            .background(Color.surfacesBasePrimary)
        }
    }
    return CheckboxPreview()
}
