// ComponentsShowcaseView.swift
// Showcase page displaying RadioButton, Checkbox, and Switch components
// both standalone and as ListItem trailing accessories.
// responsive: N/A — showcase/demo view, single-column layout

import SwiftUI

struct ComponentsShowcaseView: View {

    // MARK: - Properties

    @State private var radioValue = "email"
    @State private var checkNotifications = true
    @State private var checkUpdates = false
    @State private var checkMarketing = false
    @State private var switchDarkMode = false
    @State private var switchNotifications = true
    @State private var switchLocation = false

    // MARK: - Computed

    private var allChecked: Bool {
        checkNotifications && checkUpdates && checkMarketing
    }

    private var someChecked: Bool {
        checkNotifications || checkUpdates || checkMarketing
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .space8) {
                radioSection
                AppDivider()
                checkboxSection
                AppDivider()
                switchSection
            }
            .padding(.space6)
        }
        .background(Color.surfacesBasePrimary)
        .navigationTitle("Components Showcase")
    }

    // MARK: - Subviews

    // ── Radio Buttons ───────────────────────────────────────────────

    private var radioSection: some View {
        VStack(alignment: .leading, spacing: .space4) {
            Text("Radio Buttons")
                .font(.appTitleMedium)
                .foregroundStyle(Color.typographyPrimary)

            // Standalone
            sectionLabel("Standalone")
            VStack(alignment: .leading, spacing: .space3) {
                AppRadioButton(checked: true, label: "Selected radio")
                AppRadioButton(checked: false, label: "Unselected radio")
                AppRadioButton(checked: true, label: "Disabled selected", disabled: true)
            }

            // Radio Group
            sectionLabel("Radio Group — Contact preference")
            AppRadioGroup(value: $radioValue) {
                AppRadioButton(label: "Email", value: "email")
                AppRadioButton(label: "SMS", value: "sms")
                AppRadioButton(label: "Push notification", value: "push")
            }

            // As ListItem rows
            sectionLabel("As ListItem rows")
            VStack(spacing: 0) {
                AppListItem(
                    title: "Email",
                    subtitle: "Receive updates via email",
                    trailing: .radio(checked: radioValue == "email") { _ in radioValue = "email" },
                    divider: true
                )
                AppListItem(
                    title: "SMS",
                    subtitle: "Receive updates via text message",
                    trailing: .radio(checked: radioValue == "sms") { _ in radioValue = "sms" },
                    divider: true
                )
                AppListItem(
                    title: "Push notification",
                    subtitle: "Receive updates on your device",
                    trailing: .radio(checked: radioValue == "push") { _ in radioValue = "push" }
                )
            }
        }
    }

    // ── Checkboxes ──────────────────────────────────────────────────

    private var checkboxSection: some View {
        VStack(alignment: .leading, spacing: .space4) {
            Text("Checkboxes")
                .font(.appTitleMedium)
                .foregroundStyle(Color.typographyPrimary)

            // Standalone
            sectionLabel("Standalone")
            VStack(alignment: .leading, spacing: .space3) {
                AppCheckbox(checked: true, label: "Checked")
                AppCheckbox(checked: false, label: "Unchecked")
                AppCheckbox(checked: true, indeterminate: true, label: "Indeterminate")
                AppCheckbox(checked: true, label: "Disabled checked", disabled: true)
            }

            // As ListItem rows
            sectionLabel("As ListItem rows — Email preferences")
            VStack(spacing: 0) {
                AppListItem(
                    title: "Select all",
                    trailing: .checkbox(
                        checked: allChecked,
                        indeterminate: !allChecked && someChecked
                    ) { val in
                        checkNotifications = val
                        checkUpdates = val
                        checkMarketing = val
                    },
                    divider: true
                )
                AppListItem(
                    title: "Notifications",
                    subtitle: "Transaction alerts and reminders",
                    trailing: .checkbox(checked: checkNotifications) { checkNotifications = $0 },
                    divider: true
                )
                AppListItem(
                    title: "Product updates",
                    subtitle: "New features and improvements",
                    trailing: .checkbox(checked: checkUpdates) { checkUpdates = $0 },
                    divider: true
                )
                AppListItem(
                    title: "Marketing",
                    subtitle: "Promotions and special offers",
                    trailing: .checkbox(checked: checkMarketing) { checkMarketing = $0 }
                )
            }
        }
    }

    // ── Switches ────────────────────────────────────────────────────

    private var switchSection: some View {
        VStack(alignment: .leading, spacing: .space4) {
            Text("Switches")
                .font(.appTitleMedium)
                .foregroundStyle(Color.typographyPrimary)

            // Standalone
            sectionLabel("Standalone")
            VStack(alignment: .leading, spacing: .space3) {
                AppSwitch(checked: true, label: "On")
                AppSwitch(checked: false, label: "Off")
                AppSwitch(checked: true, label: "Disabled on", disabled: true)
            }

            // As ListItem rows
            sectionLabel("As ListItem rows — Settings")
            VStack(spacing: 0) {
                AppListItem(
                    title: "Dark mode",
                    subtitle: "Use dark color theme",
                    trailing: .toggle(checked: switchDarkMode) { switchDarkMode = $0 },
                    divider: true
                )
                AppListItem(
                    title: "Notifications",
                    subtitle: "Enable push notifications",
                    trailing: .toggle(checked: switchNotifications) { switchNotifications = $0 },
                    divider: true
                )
                AppListItem(
                    title: "Location services",
                    subtitle: "Allow access to your location",
                    trailing: .toggle(checked: switchLocation) { switchLocation = $0 }
                )
            }
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.appCaptionMedium)
            .foregroundStyle(Color.typographyMuted)
    }
}

// MARK: - Preview

#Preview("Components Showcase") {
    NavigationStack {
        ComponentsShowcaseView()
    }
}
