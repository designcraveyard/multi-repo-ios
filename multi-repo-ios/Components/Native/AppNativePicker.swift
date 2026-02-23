// AppNativePicker.swift
// Style source: NativeComponentStyling.swift › NativePickerStyling
//
// Usage:
//   // Standalone (label above, error text below):
//   AppNativePicker(label: "Country", selection: $country, options: [
//       (label: "Australia", value: "AU"),
//       (label: "India",     value: "IN"),
//   ])
//
//   // Standalone with size / variant:
//   AppNativePicker(label: "Size", selection: $size, options: [...], chipSize: .md, chipVariant: .filters)
//
//   // Embedded inside InputField's leading/trailing picker slot (via InputPickerConfig):
//   AppInputField(text: $amount, label: "Amount",
//       leadingPicker: .picker(label: "Currency", selection: $currency,
//                              options: [("USD", "USD"), ("EUR", "EUR")]),
//       leadingSeparator: true)
//
//   // Embedded manually (AnyView):
//   AppInputField(
//       text: $amount,
//       label: "Amount",
//       leadingLabel: AnyView(AppNativePicker(
//           label: "Currency",
//           selection: $currency,
//           options: [(\"USD\", \"USD\"), (\"EUR\", \"EUR\")],
//           embedded: true
//       )),
//       leadingSeparator: true
//   )

import SwiftUI

// MARK: - AppNativePicker

/// A styled wrapper around `Menu` that presents a chip-shaped trigger opening a native popover menu.
/// All visual tokens come from `NativePickerStyling` in `NativeComponentStyling.swift`.
///
/// - Set `embedded: true` to render only the chip trigger with no label above or error text below
///   — use this when placing inside `AppInputField`'s `leadingLabel` / `trailingLabel` slot or via `InputPickerConfig`.
/// - `chipSize` and `chipVariant` control the standalone chip appearance (ignored when `embedded: true`,
///   which always uses `sm`/`chipTabs` to match the InputField slot height).
public struct AppNativePicker<T: Hashable>: View {

    // MARK: - Properties

    /// Form label displayed above the chip trigger (non-embedded mode only).
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

    /// When true, renders only the chip trigger — no label above, no error text below.
    /// Use when embedding inside `AppInputField`'s `leadingLabel` / `trailingLabel` slot.
    /// Embedded mode always uses `sm` size and `chipTabs` variant.
    var embedded: Bool = false

    /// Chip size for standalone mode (sm/md/lg). Ignored when `embedded: true`.
    var chipSize: AppChipSize = .sm

    /// Chip variant for standalone mode (chipTabs/filters). Ignored when `embedded: true`.
    /// `segmentControl` is not supported — use `AppSegmentControlBar` instead.
    var chipVariant: AppChipVariant = .chipTabs

    // MARK: - Body

    public var body: some View {
        if embedded {
            chipMenu(size: .sm, variant: .chipTabs)
                .disabled(isDisabled)
                .opacity(isDisabled ? 0.5 : 1.0)
        } else {
            VStack(alignment: .leading, spacing: CGFloat.space1) {
                // Form label above — mirrors web AppNativePicker label behaviour
                Text(label)
                    .font(.appBodySmallEm)
                    .foregroundStyle(Color.typographySecondary)

                chipMenu(size: chipSize, variant: chipVariant)
                    .disabled(isDisabled)
                    .opacity(isDisabled ? 0.5 : 1.0)

                if showError && !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.appCaptionMedium)
                        .foregroundStyle(Color.typographyError)
                }
            }
        }
    }

    // MARK: - Chip Menu

    /// `Menu` with a chip-styled trigger. Tapping opens the native popover list.
    private func chipMenu(size: AppChipSize, variant: AppChipVariant) -> some View {
        Menu {
            ForEach(options, id: \.label) { opt in
                Button {
                    selection = opt.value
                    // Haptic feedback on option selection
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                } label: {
                    // Show a checkmark next to the currently selected item
                    if opt.value == selection {
                        Label(opt.label, systemImage: "checkmark")
                    } else {
                        Text(opt.label)
                    }
                }
            }
        } label: {
            chipTrigger(size: size, variant: variant)
        }
    }

    // MARK: - Chip Trigger

    /// Pill-shaped label styled to match AppChip for the given size and variant.
    private func chipTrigger(size: AppChipSize, variant: AppChipVariant) -> some View {
        let spec = size.triggerSpec

        return HStack(spacing: spec.spacing) {
            Text(selectedLabel)
                .font(spec.font)
                .foregroundStyle(Color.typographyPrimary)
                .lineLimit(1)

            Image(systemName: "chevron.down")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.typographyMuted)
        }
        .padding(.horizontal, spec.paddingH)
        .padding(.vertical, spec.paddingV)
        .background(chipBackground(variant: variant))
        .overlay(chipBorder(variant: variant))
    }

    // MARK: - Variant Appearance

    @ViewBuilder
    private func chipBackground(variant: AppChipVariant) -> some View {
        switch variant {
        case .chipTabs, .segmentControl:
            Capsule().fill(Color.surfacesBaseLowContrast)
        case .filters:
            Capsule().fill(Color.surfacesBasePrimary)
        }
    }

    @ViewBuilder
    private func chipBorder(variant: AppChipVariant) -> some View {
        if showError {
            Capsule().strokeBorder(Color.borderError, lineWidth: NativePickerStyling.Layout.errorBorderWidth)
        } else {
            switch variant {
            case .chipTabs, .segmentControl:
                Capsule().strokeBorder(Color.clear, lineWidth: 0)
            case .filters:
                Capsule().strokeBorder(Color.borderDefault, lineWidth: 1)
            }
        }
    }

    // MARK: - Helpers

    /// Returns the display label for the currently selected value.
    /// Falls back to `label` if no matching option is found (e.g. before first selection).
    private var selectedLabel: String {
        options.first(where: { $0.value == selection })?.label ?? label
    }
}

// MARK: - Chip Trigger Size Spec

/// Mirrors AppChipSize specs for the picker's chip trigger.
private struct PickerTriggerSpec {
    let paddingH: CGFloat
    let paddingV: CGFloat
    let spacing: CGFloat
    let font: Font
}

private extension AppChipSize {
    var triggerSpec: PickerTriggerSpec {
        switch self {
        case .sm: return PickerTriggerSpec(paddingH: 12, paddingV: 4,  spacing: 4, font: .appCTASmall)
        case .md: return PickerTriggerSpec(paddingH: 16, paddingV: 8,  spacing: 8, font: .appCTASmall)
        case .lg: return PickerTriggerSpec(paddingH: 20, paddingV: 12, spacing: 8, font: .appCTAMedium)
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selected = "AU"
    @Previewable @State var errSelected = "AU"
    @Previewable @State var currency = "USD"
    @Previewable @State var amount = ""
    @Previewable @State var filterSel = "All"

    ScrollView {
        VStack(alignment: .leading, spacing: 24) {

            Text("Standalone — sm / chipTabs (default)").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)

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

            Divider()

            Text("Standalone — md / chipTabs").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
            AppNativePicker(
                label: "Category",
                selection: $selected,
                options: [("Australia", "AU"), ("India", "IN")],
                chipSize: .md
            )

            Text("Standalone — lg / filters").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
            AppNativePicker(
                label: "Filter",
                selection: $filterSel,
                options: [("All", "All"), ("Active", "Active"), ("Done", "Done")],
                chipSize: .lg,
                chipVariant: .filters
            )

            Divider()

            Text("Embedded inside InputField").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)

            AppInputField(
                text: $amount,
                label: "Amount",
                placeholder: "0.00",
                leadingPicker: .picker(
                    label: "Currency",
                    selection: $currency,
                    options: [("USD", "USD"), ("EUR", "EUR"), ("GBP", "GBP")]
                ),
                leadingSeparator: true
            )
        }
        .padding()
    }
    .background(Color.surfacesBasePrimary)
}
