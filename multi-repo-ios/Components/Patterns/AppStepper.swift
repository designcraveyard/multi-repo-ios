// AppStepper.swift
// Figma source: bubbles-kit › node 108:4357 "TimelineStepper"
//
// Vertical timeline of steps, each composed of an AppStepIndicator dot +
// connecting line + AppTextBlock content. Display-only — no interaction.
//
// Usage:
//   AppStepper(steps: [
//     AppStepperStep(title: "Ordered", subtitle: "Mar 1", completed: true),
//     AppStepperStep(title: "Shipped", completed: true),
//     AppStepperStep(title: "Arriving", subtitle: "Expected Mar 5"),
//   ])

import SwiftUI

// MARK: - Types

public struct AppStepperStep {
    /// Primary step label (required)
    public let title: String
    /// Secondary line below title
    public let subtitle: String?
    /// Optional body copy for the step
    public let body: String?
    /// Whether this step has been completed
    public let completed: Bool

    public init(title: String, subtitle: String? = nil, body: String? = nil, completed: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.completed = completed
    }
}

// MARK: - AppStepper

public struct AppStepper: View {

    // MARK: - Properties

    let steps: [AppStepperStep]

    public init(steps: [AppStepperStep]) {
        self.steps = steps
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                stepRow(step: step, isLast: index == steps.count - 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Subviews

    private func stepRow(step: AppStepperStep, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: .space6) {
            // Left column: indicator + connector line
            trackColumn(completed: step.completed, isLast: isLast)

            // Right column: text content
            AppTextBlock(
                title: step.title,
                subtext: step.subtitle,
                body: step.body
            )
            .padding(.bottom, isLast ? 0 : .space6)
        }
    }

    private func trackColumn(completed: Bool, isLast: Bool) -> some View {
        VStack(spacing: .space2) {
            AppStepIndicator(completed: completed)
                .padding(.top, .space2)

            if !isLast {
                Rectangle()
                    .fill(Color.appBorderDefault)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 12)
    }
}

// MARK: - Preview

#Preview("Stepper") {
    ScrollView {
        VStack(alignment: .leading, spacing: .space8) {

            Text("All completed").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
            AppStepper(steps: [
                AppStepperStep(title: "Ordered", subtitle: "Mar 1", completed: true),
                AppStepperStep(title: "Shipped", subtitle: "Mar 2", completed: true),
                AppStepperStep(title: "Delivered", subtitle: "Mar 4", completed: true),
            ])

            Divider()

            Text("Mixed state").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
            AppStepper(steps: [
                AppStepperStep(title: "Ayurveda Books", subtitle: "bought for Anjali at airport", completed: true),
                AppStepperStep(title: "Pack luggage", completed: false),
                AppStepperStep(title: "Depart", subtitle: "Flight at 08:00", completed: false),
            ])

            Divider()

            Text("Single step").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
            AppStepper(steps: [
                AppStepperStep(title: "Submit application", body: "Fill in all required fields before submitting."),
            ])
        }
        .padding(.space4)
    }
    .background(Color.surfacesBasePrimary)
}
