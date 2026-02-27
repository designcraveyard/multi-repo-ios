// AppStepIndicator.swift
// Figma source: bubbles-kit › node 108:9891 "StepIndicator"
//
// 12×12 circular dot representing a single timeline step.
//   completed=false — hollow circle, borderDefault stroke
//   completed=true  — filled surfacesSuccessSolid circle with white checkmark
//
// Usage:
//   AppStepIndicator()            // incomplete
//   AppStepIndicator(completed: true)

import PhosphorSwift
import SwiftUI

// MARK: - AppStepIndicator

/// A 12pt circular dot representing a single timeline step, matching the Figma
/// "StepIndicator" component (node 108:9891).
///
/// Two visual states:
/// - Incomplete (`completed: false`) -- hollow circle with a `borderDefault` stroke.
/// - Completed (`completed: true`) -- solid `surfacesSuccessSolid` circle with a
///   white Phosphor checkmark icon (xs/bold).
///
/// Accessibility labels are set automatically ("Step completed" / "Step incomplete").
///
/// **Key properties:** `completed`
public struct AppStepIndicator: View {

    // MARK: - Properties

    let completed: Bool

    public init(completed: Bool = false) {
        self.completed = completed
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            Circle()
                .fill(completed ? Color.surfacesSuccessSolid : Color.clear)
                .overlay(
                    Circle()
                        .stroke(
                            completed ? Color.surfacesSuccessSolid : Color.borderDefault,
                            lineWidth: 1.5
                        )
                )

            if completed {
                Ph.check.bold
                    .iconSize(.xs)
                    .foregroundStyle(Color.iconsOnBrandPrimary)
            }
        }
        .frame(width: 12, height: 12)
        .accessibilityLabel(completed ? "Step completed" : "Step incomplete")
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Preview

#Preview("StepIndicator") {
    HStack(spacing: .space6) {
        VStack(spacing: .space2) {
            AppStepIndicator(completed: false)
            Text("Incomplete").font(.appCaptionSmall).foregroundStyle(Color.typographyMuted)
        }
        VStack(spacing: .space2) {
            AppStepIndicator(completed: true)
            Text("Completed").font(.appCaptionSmall).foregroundStyle(Color.typographyMuted)
        }
    }
    .padding(.space6)
    .background(Color.surfacesBasePrimary)
}
