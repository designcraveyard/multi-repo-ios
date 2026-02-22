// AppProgressLoader.swift
// Style source: NativeComponentStyling.swift › NativeProgressLoaderStyling
//
// Usage:
//   // Indefinite spinner:
//   AppProgressLoader()
//
//   // Indefinite with label:
//   AppProgressLoader(label: "Loading…")
//
//   // Definite linear bar (0.0 – 1.0):
//   AppProgressLoader(variant: .definite(value: 0.65, total: 1.0))
//
//   // Definite with raw values (e.g. 3 of 10 steps):
//   AppProgressLoader(variant: .definite(value: 3, total: 10), label: "Step 3 of 10")

import SwiftUI

// MARK: - Variant

/// Controls whether the loader is indefinite (spinning) or definite (filled bar).
public enum AppProgressLoaderVariant {
    /// Spinning circular indicator — use when progress is unknown.
    case indefinite

    /// Linear filled bar — use when progress is measurable.
    /// - Parameters:
    ///   - value: Current progress value (must be ≥ 0 and ≤ total).
    ///   - total: The value at which progress is 100%.
    case definite(value: Double, total: Double)
}

// MARK: - AppProgressLoader

/// A styled wrapper around SwiftUI's `ProgressView`.
/// All visual tokens come from `NativeProgressLoaderStyling` in `NativeComponentStyling.swift`.
public struct AppProgressLoader: View {

    // MARK: - Properties

    /// The loader variant — indefinite spinner or definite linear bar.
    var variant: AppProgressLoaderVariant = .indefinite

    /// Optional descriptive label rendered below the spinner or bar.
    var label: String? = nil

    // MARK: - Body

    public var body: some View {
        VStack(spacing: NativeProgressLoaderStyling.Layout.labelSpacing) {
            switch variant {
            case .indefinite:
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(NativeProgressLoaderStyling.Colors.tint)
                    .scaleEffect(NativeProgressLoaderStyling.Layout.scale)

            case let .definite(value, total):
                ZStack(alignment: .leading) {
                    // Background (inactive) track
                    Capsule()
                        .fill(NativeProgressLoaderStyling.Colors.track)
                        .frame(height: NativeProgressLoaderStyling.Layout.linearTrackHeight)

                    // Active filled track — width proportional to progress
                    GeometryReader { geo in
                        Capsule()
                            .fill(NativeProgressLoaderStyling.Colors.tint)
                            .frame(
                                width: geo.size.width * CGFloat(min(value / total, 1.0)),
                                height: NativeProgressLoaderStyling.Layout.linearTrackHeight
                            )
                    }
                    .frame(height: NativeProgressLoaderStyling.Layout.linearTrackHeight)
                }
            }

            if let label {
                Text(label)
                    .font(NativeProgressLoaderStyling.Typography.label)
                    .foregroundStyle(NativeProgressLoaderStyling.Colors.label)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        AppProgressLoader()
        AppProgressLoader(label: "Uploading…")
        AppProgressLoader(variant: .definite(value: 0.4, total: 1.0), label: "40%")
        AppProgressLoader(variant: .definite(value: 7, total: 10), label: "Step 7 of 10")
    }
    .padding()
}
