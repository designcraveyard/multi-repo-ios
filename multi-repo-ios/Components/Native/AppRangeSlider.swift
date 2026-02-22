// AppRangeSlider.swift
// Style source: NativeComponentStyling.swift › NativeRangeSliderStyling
//
// SwiftUI has no native range slider. This implementation stacks two invisible
// Slider views in a ZStack and draws a custom active track rectangle between
// the lower and upper thumb positions using GeometryReader.
//
// How it works:
//   • Lower Slider: range from [range.lowerBound ... upperValue - minDistance]
//   • Upper Slider: range from [lowerValue + minDistance ... range.upperBound]
//   • Both Sliders have .tint(.clear) to hide their native filled track
//   • A custom Rectangle is positioned between lowerValue and upperValue thumbs
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
    /// Prevents the two thumbs from occupying the same position.
    private var minDistance: Double { step > 0 ? step : 0.001 }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: NativeRangeSliderStyling.Layout.labelSpacing) {
            GeometryReader { geometry in
                let width = geometry.size.width

                ZStack(alignment: .leading) {
                    // ── Background (inactive) track
                    Capsule()
                        .fill(NativeRangeSliderStyling.Colors.trackBackground)
                        .frame(height: NativeRangeSliderStyling.Layout.trackHeight)

                    // ── Active track segment between lower and upper thumbs
                    Capsule()
                        .fill(NativeRangeSliderStyling.Colors.trackActive)
                        .frame(
                            width: activeWidth(in: width),
                            height: NativeRangeSliderStyling.Layout.trackHeight
                        )
                        .offset(x: lowerOffset(in: width))

                    // ── Lower thumb Slider (invisible track, visible thumb)
                    //    Range clamped so lower cannot exceed upper - minDistance
                    Slider(
                        value: $lowerValue,
                        in: range.lowerBound...(upperValue - minDistance),
                        step: step > 0 ? step : 0.001
                    )
                    // Clear tint hides the native filled track; only the white thumb remains
                    .tint(.clear)
                    .onChange(of: lowerValue) { _, new in
                        // Safety clamp — prevents floating point edge cases
                        if new > upperValue - minDistance {
                            lowerValue = upperValue - minDistance
                        }
                    }

                    // ── Upper thumb Slider (invisible track, visible thumb)
                    //    Range clamped so upper cannot go below lower + minDistance
                    Slider(
                        value: $upperValue,
                        in: (lowerValue + minDistance)...range.upperBound,
                        step: step > 0 ? step : 0.001
                    )
                    .tint(.clear)
                    .onChange(of: upperValue) { _, new in
                        if new < lowerValue + minDistance {
                            upperValue = lowerValue + minDistance
                        }
                    }
                }
                // Total height must be ≥ 44pt for accessibility minimum touch target
                .frame(height: NativeRangeSliderStyling.Layout.totalHeight)
            }
            .frame(height: NativeRangeSliderStyling.Layout.totalHeight)

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

    // MARK: - Helpers

    /// X offset of the active track's left edge (where the lower thumb sits).
    private func lowerOffset(in width: CGFloat) -> CGFloat {
        let ratio = (lowerValue - range.lowerBound) / (range.upperBound - range.lowerBound)
        return CGFloat(ratio) * width
    }

    /// Width of the active track segment between lower and upper thumbs.
    private func activeWidth(in width: CGFloat) -> CGFloat {
        let lowerRatio = (lowerValue - range.lowerBound) / (range.upperBound - range.lowerBound)
        let upperRatio = (upperValue - range.lowerBound) / (range.upperBound - range.lowerBound)
        return CGFloat(upperRatio - lowerRatio) * width
    }

    /// Formats a Double value for the min/max label — integers show without decimal.
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
    @Previewable @State var low2 = 0.0
    @Previewable @State var high2 = 50.0

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
