// AppSwitch.swift
// Toggle switch for binary on/off settings.
// Uses the native SwiftUI Toggle on iOS 26+ to automatically adopt
// the system Liquid Glass design. All interactions (tap, drag) and
// accessibility are handled by the system control.
//
// Usage:
//   AppSwitch(checked: isOn, label: "Dark mode") { isOn = $0 }

import SwiftUI

// MARK: - AppSwitch

/// Toggle switch for binary on/off settings.
/// Wraps SwiftUI's native Toggle to get the iOS 26 Liquid Glass thumb style.
public struct AppSwitch: View {

    // MARK: - Properties

    let checked: Bool
    let label: String?
    let disabled: Bool
    let onChange: ((Bool) -> Void)?

    public init(
        checked: Bool = false,
        label: String? = nil,
        disabled: Bool = false,
        onChange: ((Bool) -> Void)? = nil
    ) {
        self.checked = checked
        self.label = label
        self.disabled = disabled
        self.onChange = onChange
    }

    // MARK: - Body

    public var body: some View {
        Group {
            if let label {
                Toggle(isOn: toggleBinding) {
                    Text(label)
                        .font(.appBodyMedium)
                        .foregroundStyle(Color.typographyPrimary)
                }
            } else {
                Toggle("", isOn: toggleBinding)
                    .labelsHidden()
            }
        }
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1.0)
        .accessibilityValue(checked ? "On" : "Off")
    }

    // MARK: - Helpers

    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { checked },
            set: { newValue in
                guard !disabled else { return }
                onChange?(newValue)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        )
    }
}

// MARK: - Preview

#Preview("Switch") {
    struct SwitchPreview: View {
        @State private var isOn1 = false
        @State private var isOn2 = true

        var body: some View {
            VStack(alignment: .leading, spacing: .space6) {
                Text("Default (off)").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                AppSwitch(checked: isOn1, label: "Notifications") { isOn1 = $0 }

                Text("Default (on)").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                AppSwitch(checked: isOn2, label: "Dark mode") { isOn2 = $0 }

                Text("Disabled").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
                AppSwitch(checked: true, label: "Disabled on", disabled: true)
                AppSwitch(checked: false, label: "Disabled off", disabled: true)
            }
            .padding(.space4)
            .background(Color.surfacesBasePrimary)
        }
    }
    return SwitchPreview()
}
