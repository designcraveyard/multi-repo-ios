// AppRangeSlider.swift
// Style source: NativeComponentStyling.swift > NativeRangeSliderStyling
//
// Native Slider-based range control. iOS owns the slider rendering, including the
// current Liquid Glass treatment, while this wrapper preserves range constraints,
// labels, and the haptic cadence used by the custom version.
//
// How it works:
//   * Two regular SwiftUI Slider controls are stacked vertically.
//   * The lower Slider is clamped below the upper value.
//   * The upper Slider is clamped above the lower value.
//   * Step snapping is delegated to Slider when step > 0.
//
// Usage:
//   @State var low  = 20.0
//   @State var high = 80.0
//
//   AppRangeSlider(lowerValue: $low, upperValue: $high, range: 0...100)
//
//   // With step and labels:
//   AppRangeSlider(lowerValue: $low, upperValue: $high, range: 0...100,
//                  step: 5, showLabels: true)

import SwiftUI
import UIKit

// MARK: - AppRangeSlider

/// A range slider with lower and upper bound thumb handles.
/// All visual tokens come from `NativeRangeSliderStyling` in `NativeComponentStyling.swift`.
public struct AppRangeSlider: View {

    // MARK: - Properties

    /// The current minimum (left thumb) value. Bind to a `@State` variable.
    @Binding var lowerValue: Double

    /// The current maximum (right thumb) value. Bind to a `@State` variable.
    @Binding var upperValue: Double

    /// The full selectable range (e.g. 0...100).
    let range: ClosedRange<Double>

    /// Discrete step interval. Pass 0 for continuous (no snapping).
    var step: Double = 0

    /// When true, renders formatted min/max values below the slider ends.
    var showLabels: Bool = false

    /// Minimum distance between lowerValue and upperValue.
    /// Step mode: one full step. Continuous: 1% of the range.
    private var minDistance: Double {
        step > 0 ? step : (range.upperBound - range.lowerBound) * 0.01
    }

    private enum ActiveThumb { case lower, upper }

    // MARK: - Continuous Haptic Tracking
    // In step mode, haptics fire on each discrete step — see DragGesture handler below.
    // In continuous mode (step=0), we fire UISelectionFeedbackGenerator every time
    // either thumb crosses a 1%-of-range threshold, matching the "drumroll" feel of
    // iOS drum-roll / time pickers. Reset to current value on each new touch-down.
    @State private var lastHapticLower: Double = 0
    @State private var lastHapticUpper: Double = 0

    // MARK: - Haptics

    /// Light impact fired when a thumb is first grabbed.
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)

    /// Selection tick fired on each discrete step change (step mode only).
    private let selectionFeedback = UISelectionFeedbackGenerator()

    // MARK: - Body

    public var body: some View {
        VStack(spacing: NativeRangeSliderStyling.Layout.labelSpacing) {
            VStack(spacing: NativeRangeSliderStyling.Layout.sliderSpacing) {
                nativeSlider(
                    value: lowerBinding,
                    thumb: .lower,
                    bounds: range.lowerBound...(upperValue - minDistance)
                )

                nativeSlider(
                    value: upperBinding,
                    thumb: .upper,
                    bounds: (lowerValue + minDistance)...range.upperBound
                )
            }
            .frame(minHeight: NativeRangeSliderStyling.Layout.totalHeight)

            // ── Optional min/max labels
            if showLabels {
                HStack {
                    Text(formatted(lowerValue))
                        .font(NativeRangeSliderStyling.Typography.boundLabel)
                        .foregroundStyle(NativeRangeSliderStyling.Colors.label)
                    Spacer()
                    Text(formatted(upperValue))
                        .font(NativeRangeSliderStyling.Typography.boundLabel)
                        .foregroundStyle(NativeRangeSliderStyling.Colors.label)
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func nativeSlider(
        value: Binding<Double>,
        thumb: ActiveThumb,
        bounds: ClosedRange<Double>
    ) -> some View {
        if step > 0 {
            Slider(
                value: value,
                in: normalizedBounds(bounds),
                step: step,
                onEditingChanged: { editingChanged($0, thumb: thumb) }
            )
            .tint(NativeRangeSliderStyling.Colors.trackActive)
        } else {
            Slider(
                value: value,
                in: normalizedBounds(bounds),
                onEditingChanged: { editingChanged($0, thumb: thumb) }
            )
            .tint(NativeRangeSliderStyling.Colors.trackActive)
        }
    }

    // MARK: - Helpers

    private var rangeSpan: Double { range.upperBound - range.lowerBound }

    private var lowerBinding: Binding<Double> {
        Binding(
            get: { lowerValue },
            set: { newValue in
                let clamped = min(max(newValue, range.lowerBound), upperValue - minDistance)
                handleHaptic(for: .lower, oldValue: lowerValue, newValue: clamped)
                lowerValue = clamped
            }
        )
    }

    private var upperBinding: Binding<Double> {
        Binding(
            get: { upperValue },
            set: { newValue in
                let clamped = max(min(newValue, range.upperBound), lowerValue + minDistance)
                handleHaptic(for: .upper, oldValue: upperValue, newValue: clamped)
                upperValue = clamped
            }
        )
    }

    private func normalizedBounds(_ bounds: ClosedRange<Double>) -> ClosedRange<Double> {
        let lower = max(range.lowerBound, min(bounds.lowerBound, range.upperBound))
        let upper = max(lower, min(bounds.upperBound, range.upperBound))
        return lower...upper
    }

    private func editingChanged(_ isEditing: Bool, thumb: ActiveThumb) {
        guard isEditing else { return }
        impactFeedback.prepare()
        selectionFeedback.prepare()
        impactFeedback.impactOccurred()

        switch thumb {
        case .lower:
            lastHapticLower = lowerValue
        case .upper:
            lastHapticUpper = upperValue
        }
    }

    private func handleHaptic(for thumb: ActiveThumb, oldValue: Double, newValue: Double) {
        guard newValue != oldValue else { return }

        if step > 0 {
            selectionFeedback.selectionChanged()
            return
        }

        let threshold = rangeSpan * 0.01
        switch thumb {
        case .lower:
            if abs(newValue - lastHapticLower) >= threshold {
                selectionFeedback.selectionChanged()
                lastHapticLower = newValue
            }
        case .upper:
            if abs(newValue - lastHapticUpper) >= threshold {
                selectionFeedback.selectionChanged()
                lastHapticUpper = newValue
            }
        }
    }

    /// Formats a Double value for the min/max label -- integers show without decimal.
    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var low  = 20.0
    @Previewable @State var high = 80.0
    @Previewable @State var low2 = 10.0
    @Previewable @State var high2 = 60.0

    VStack(spacing: 40) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Continuous").font(.appBodyMediumEm)
            AppRangeSlider(lowerValue: $low, upperValue: $high, range: 0...100,
                           showLabels: true)
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("Step 10").font(.appBodyMediumEm)
            AppRangeSlider(lowerValue: $low2, upperValue: $high2, range: 0...100,
                           step: 10, showLabels: true)
        }
    }
    .padding()
}
