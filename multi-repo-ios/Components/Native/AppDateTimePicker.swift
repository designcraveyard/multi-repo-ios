// AppDateTimePicker.swift
// Style source: NativeComponentStyling.swift › NativeDatePickerStyling
//
// Usage:
//   AppDateTimePicker(label: "Birthday", selection: $date)
//
//   AppDateTimePicker(label: "Appointment", selection: $appt, mode: .dateAndTime,
//                    displayStyle: .graphical)
//
//   AppDateTimePicker(label: "Time", selection: $time, mode: .time,
//                    displayStyle: .wheel)
//
//   // With date range:
//   AppDateTimePicker(label: "Check-in", selection: $date,
//                    minimumDate: Date(), maximumDate: nextYear)

import SwiftUI

// MARK: - Supporting Enums

/// The date components the picker selects.
public enum AppDatePickerMode {
    case date           // calendar date only (month / day / year)
    case time           // hour and minute only
    case dateAndTime    // both date and time
}

/// The visual rendering style of the date picker control.
public enum AppDatePickerDisplayStyle {
    case compact        // Compact inline button that expands a popover
    case graphical      // Full month-calendar grid with navigation arrows
    case wheel          // Spinning drum columns (classic iOS drum picker)
}

// MARK: - AppDateTimePicker

/// A styled wrapper around SwiftUI's `DatePicker`.
/// All visual tokens come from `NativeDatePickerStyling` in `NativeComponentStyling.swift`.
public struct AppDateTimePicker: View {

    // MARK: - Properties

    /// Descriptive label shown next to or above the picker control.
    let label: String

    /// The currently selected `Date`. Bind to a `@State` or `@Published` variable.
    @Binding var selection: Date

    /// Controls whether date, time, or both components are selectable.
    var mode: AppDatePickerMode = .date

    /// Controls the visual rendering style (.compact / .graphical / .wheel).
    var displayStyle: AppDatePickerDisplayStyle = .compact

    /// Optional earliest selectable date. Dates before this are greyed out.
    var minimumDate: Date? = nil

    /// Optional latest selectable date. Dates after this are greyed out.
    var maximumDate: Date? = nil

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: NativeDatePickerStyling.Layout.labelSpacing) {
            switch displayStyle {
            case .compact:
                DatePicker(
                    label,
                    selection: $selection,
                    in: dateRange,
                    displayedComponents: displayedComponents
                )
                .datePickerStyle(.compact)
                .tint(NativeDatePickerStyling.Colors.tint)
                .foregroundStyle(NativeDatePickerStyling.Colors.label)
                .font(NativeDatePickerStyling.Typography.label)

            case .graphical:
                DatePicker(
                    label,
                    selection: $selection,
                    in: dateRange,
                    displayedComponents: displayedComponents
                )
                .datePickerStyle(.graphical)
                .tint(NativeDatePickerStyling.Colors.tint)
                .foregroundStyle(NativeDatePickerStyling.Colors.label)
                .background(
                    NativeDatePickerStyling.Colors.background,
                    in: RoundedRectangle(cornerRadius: NativeDatePickerStyling.Layout.graphicalCornerRadius)
                )

            case .wheel:
                // Show the label above the wheel so it doesn't compete for horizontal width
                // with the drum columns, preventing it from wrapping to two lines.
                VStack(alignment: .leading, spacing: NativeDatePickerStyling.Layout.labelSpacing) {
                    Text(label)
                        .font(NativeDatePickerStyling.Typography.label)
                        .foregroundStyle(NativeDatePickerStyling.Colors.label)
                    DatePicker(
                        label,
                        selection: $selection,
                        in: dateRange,
                        displayedComponents: displayedComponents
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .tint(NativeDatePickerStyling.Colors.tint)
                }
            }
        }
    }

    // MARK: - Helpers

    private var displayedComponents: DatePickerComponents {
        switch mode {
        case .date:        return .date
        case .time:        return .hourAndMinute
        case .dateAndTime: return [.date, .hourAndMinute]
        }
    }

    private var dateRange: ClosedRange<Date> {
        let min = minimumDate ?? .distantPast
        let max = maximumDate ?? .distantFuture
        return min...max
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var date = Date()
    @Previewable @State var time = Date()
    @Previewable @State var dateTime = Date()

    ScrollView {
        VStack(alignment: .leading, spacing: 32) {
            Text("Compact (date)").font(.appBodyMediumEm)
            AppDateTimePicker(label: "Birthday", selection: $date)

            Text("Graphical (date)").font(.appBodyMediumEm)
            AppDateTimePicker(label: "Appointment", selection: $dateTime,
                              displayStyle: .graphical)

            Text("Wheel (time)").font(.appBodyMediumEm)
            AppDateTimePicker(label: "Alarm", selection: $time,
                              mode: .time, displayStyle: .wheel)
        }
        .padding()
    }
}
