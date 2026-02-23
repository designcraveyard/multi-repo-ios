// AppRangeSlider.swift
// Style source: NativeComponentStyling.swift > NativeRangeSliderStyling
//
// Custom DragGesture-based range slider. The previous dual-Slider approach caused
// both thumbs to move simultaneously because overlapping Slider gesture recognizers
// conflicted. This version uses a single DragGesture with proximity-based thumb
// selection — only the nearest thumb moves on each drag.
//
// How it works:
//   * GeometryReader measures the available width
//   * Two Circle thumbs are drawn at normalized lower/upper positions
//   * A single DragGesture covers the entire track area
//   * On touch-down, the closest thumb is selected (ActiveThumb enum)
//   * On drag, only the active thumb's value updates
//   * Step snapping rounds to the nearest step increment
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

    /// Tracks which thumb the current gesture is dragging.
    @State private var activeThumb: ActiveThumb? = nil

    private enum ActiveThumb { case lower, upper }

    // MARK: - Haptics

    /// Light impact fired when a thumb is first grabbed.
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)

    /// Selection tick fired on each discrete step change (step mode only).
    private let selectionFeedback = UISelectionFeedbackGenerator()

    // MARK: - Body

    public var body: some View {
        VStack(spacing: NativeRangeSliderStyling.Layout.labelSpacing) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let thumbR = NativeRangeSliderStyling.Layout.thumbDiameter / 2
                // Usable horizontal range for thumb center positions
                let trackW = max(width - NativeRangeSliderStyling.Layout.thumbDiameter, 1)

                ZStack(alignment: .leading) {
                    // ── Background (inactive) track
                    Capsule()
                        .fill(NativeRangeSliderStyling.Colors.trackBackground)
                        .frame(height: NativeRangeSliderStyling.Layout.trackHeight)
                        .padding(.horizontal, thumbR)

                    // ── Active track segment between lower and upper thumbs
                    Capsule()
                        .fill(NativeRangeSliderStyling.Colors.trackActive)
                        .frame(
                            width: CGFloat(normalizedUpper - normalizedLower) * trackW,
                            height: NativeRangeSliderStyling.Layout.trackHeight
                        )
                        .offset(x: thumbR + CGFloat(normalizedLower) * trackW)

                    // ── Lower thumb
                    thumbCircle
                        .offset(x: CGFloat(normalizedLower) * trackW)

                    // ── Upper thumb
                    thumbCircle
                        .offset(x: CGFloat(normalizedUpper) * trackW)
                }
                .frame(height: NativeRangeSliderStyling.Layout.totalHeight)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let ratio = Double(max(0, min((gesture.location.x - thumbR) / trackW, 1)))
                            let rawValue = range.lowerBound + ratio * rangeSpan
                            let snapped = step > 0
                                ? (rawValue / step).rounded() * step
                                : rawValue
                            let clamped = min(max(snapped, range.lowerBound), range.upperBound)

                            // On first touch, select the nearest thumb + impact haptic
                            if activeThumb == nil {
                                let dLower = abs(clamped - lowerValue)
                                let dUpper = abs(clamped - upperValue)
                                activeThumb = dLower <= dUpper ? .lower : .upper
                                impactFeedback.impactOccurred()
                            }

                            // Update only the active thumb, respecting minDistance.
                            // Fire a selection haptic on each discrete step change.
                            switch activeThumb {
                            case .lower:
                                let newValue = min(clamped, upperValue - minDistance)
                                if step > 0 && newValue != lowerValue { selectionFeedback.selectionChanged() }
                                lowerValue = newValue
                            case .upper:
                                let newValue = max(clamped, lowerValue + minDistance)
                                if step > 0 && newValue != upperValue { selectionFeedback.selectionChanged() }
                                upperValue = newValue
                            case .none:
                                break
                            }
                        }
                        .onEnded { _ in
                            activeThumb = nil
                        }
                )
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

    // MARK: - Subviews

    /// Reusable thumb circle view with shadow and border.
    private var thumbCircle: some View {
        Circle()
            .fill(NativeRangeSliderStyling.Colors.thumb)
            .overlay(Circle().stroke(NativeRangeSliderStyling.Colors.thumbShadow, lineWidth: 0.5))
            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
            .frame(
                width: NativeRangeSliderStyling.Layout.thumbDiameter,
                height: NativeRangeSliderStyling.Layout.thumbDiameter
            )
    }

    // MARK: - Helpers

    private var rangeSpan: Double { range.upperBound - range.lowerBound }

    /// Lower value normalized to 0…1
    private var normalizedLower: Double {
        guard rangeSpan > 0 else { return 0 }
        return (lowerValue - range.lowerBound) / rangeSpan
    }

    /// Upper value normalized to 0…1
    private var normalizedUpper: Double {
        guard rangeSpan > 0 else { return 1 }
        return (upperValue - range.lowerBound) / rangeSpan
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
