import SwiftUI
import UIKit
import PhosphorSwift

// MARK: - ShareSheet

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Section Header

private struct ShowcaseSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.appCaptionMedium)
                .foregroundStyle(Color.typographyMuted)
                .tracking(1.5)
            content()
        }
    }
}

// MARK: - Horizontal Scroll Row
// Wraps any HStack content in a horizontal scroll view so it never clips.

private struct HScrollRow<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                content()
            }
        }
    }
}

// MARK: - Carousel Card (for demo)

private struct CarouselCard: Identifiable {
    let id: Int
    let color: Color
    let label: String
}

// MARK: - Component Showcase

struct ContentView: View {
    // DateGrid
    @State private var selectedGridDate = Date()

    // Button
    @State private var isLoading = false

    // Tabs
    @State private var activeTab = "design"

    // SegmentControlBar
    @State private var segSelected = "week"
    @State private var chipSelected = "all"
    @State private var filterSelected: Set<String> = ["ios"]

    // Chip
    @State private var activeChip = "design"
    @State private var activeFilters: Set<String> = ["bold"]

    // Toast
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastVariant: AppToastVariant = .default

    // InputField
    @State private var name = ""
    @State private var email = "user@example"
    @State private var bio = ""
    @State private var textOnlyValue = ""

    // --- Native Components ---
    @State private var pickerSelected = "AU"
    @State private var selectedDate = Date()
    @State private var selectedColor = Color.blue
    @State private var showSheet = false
    @State private var showSheetSmall = false
    @State private var showSheetForm = false
    @State private var showSheetList = false
    @State private var showActionSheet = false
    @State private var showAlert = false
    @State private var showPopoverMenu = false
    @State private var showTooltip = false
    @State private var sliderLow = 20.0
    @State private var sliderHigh = 80.0
    @State private var sliderStepLow = 10.0
    @State private var sliderStepHigh = 60.0
    @State private var sheetFormName = ""
    @State private var sheetFormEmail = ""

    // Input Field — Picker Slots
    @State private var inputLeadingCurrency = "USD"
    @State private var inputTrailingUnit = "kg"

    // Form — Pickers + Input Fields
    @State private var formName = ""
    @State private var formEmail = ""
    @State private var formCountry = "IN"
    @State private var formDOB = Date()
    @State private var formLanguage = "EN"
    @State private var formPhone = ""
    @State private var formBio = ""

    // Form Controls
    @State private var radioValue = "email"
    @State private var checkNotifications = true
    @State private var checkUpdates = false
    @State private var checkMarketing = false
    @State private var switchDarkMode = false
    @State private var switchNotifications = true
    @State private var switchLocation = false

    // BottomNavBar
    @State private var selectedTab = 0

    // Markdown Editor
    @State private var editorMarkdown = """
    ## Welcome to the Markdown Editor

    This is a **real-time inline** WYSIWYG editor. Everything you type renders *in-place*.

    ### Features

    - **Bold**, *italic*, and ~~strikethrough~~ text
    - ++Underline++ and ***bold italic*** formatting
    - Inline `code` snippets

    ### Lists

    - Bullet lists with nesting
      - Second level
        - Third level

    1. Numbered lists
    2. With automatic numbering

    - [ ] Task lists
    - [x] With checkboxes

    > This is a blockquote.

    ---
    """

    var body: some View {
        AdaptiveNavShell(
            selectedTab: $selectedTab,
            tabs: [
                AppNavTab(id: 0, label: "Components", icon: "square.grid.2x2"),
                AppNavTab(id: 1, label: "Editor",     icon: "doc.richtext"),
                AppNavTab(id: 2, label: "AI Demo",    icon: "sparkles", iconFill: "sparkles"),
                AppNavTab(id: 3, label: "Settings",   icon: "gearshape"),
                AppNavTab(id: 4, label: "Assistant",  icon: "bubble.left.and.text.bubble.right"),
            ]
        ) {
            showcaseTab
            editorTab
            AIDemoView()
            settingsTab
            AssistantView()
        }
    }

    // MARK: - Toast Helper

    /// Dismisses the current toast (if any) before showing a new one,
    /// preventing color interpolation artifacts when the spring animation is mid-flight.
    private func showToastWith(message: String, variant: AppToastVariant) {
        if showToast {
            withAnimation { showToast = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                toastMessage = message
                toastVariant = variant
                withAnimation { showToast = true }
            }
        } else {
            toastMessage = message
            toastVariant = variant
            withAnimation { showToast = true }
        }
    }

    // MARK: - Showcase Tab

    private var showcaseTab: some View {
        ScrollView {
                VStack(alignment: .leading, spacing: 40) {

                    // ── Button: Variants ──────────────────────────────────
                    ShowcaseSection(title: "Button — Variants") {
                        VStack(alignment: .leading, spacing: 10) {
                            AppButton(label: "Primary",   variant: .primary)   {}
                            AppButton(label: "Secondary", variant: .secondary) {}
                            AppButton(label: "Tertiary",  variant: .tertiary)  {}
                            AppButton(label: "Success",   variant: .success)   {}
                            AppButton(label: "Danger",    variant: .danger)    {}
                        }
                    }

                    // ── Button: Sizes ─────────────────────────────────────
                    ShowcaseSection(title: "Button — Sizes") {
                        HScrollRow {
                            HStack(spacing: 10) {
                                AppButton(label: "Large",  variant: .primary, size: .lg) {}
                                AppButton(label: "Medium", variant: .primary, size: .md) {}
                                AppButton(label: "Small",  variant: .primary, size: .sm) {}
                            }
                            .padding(.trailing, .space4)
                        }
                    }

                    // ── Button: Icons ─────────────────────────────────────
                    ShowcaseSection(title: "Button — Icons") {
                        VStack(alignment: .leading, spacing: 10) {
                            AppButton(
                                label: "Leading",
                                variant: .primary,
                                leadingIcon: AnyView(Ph.house.regular.iconSize(.md))
                            ) {}
                            AppButton(
                                label: "Trailing",
                                variant: .secondary,
                                trailingIcon: AnyView(Ph.arrowRight.regular.iconSize(.md))
                            ) {}
                            AppButton(
                                label: "Both",
                                variant: .tertiary,
                                leadingIcon: AnyView(Ph.star.regular.iconSize(.md)),
                                trailingIcon: AnyView(Ph.arrowRight.regular.iconSize(.md))
                            ) {}
                            AppButton(
                                label: "Delete",
                                variant: .danger,
                                leadingIcon: AnyView(Ph.trash.regular.iconSize(.md))
                            ) {}
                        }
                    }

                    // ── Button: States ────────────────────────────────────
                    ShowcaseSection(title: "Button — States") {
                        VStack(alignment: .leading, spacing: 10) {
                            AppButton(
                                label: "Tap to Load",
                                variant: .primary,
                                isLoading: isLoading
                            ) {
                                isLoading = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    isLoading = false
                                }
                            }
                            AppButton(label: "Disabled", variant: .primary, isDisabled: true) {}
                            AppButton(label: "Disabled", variant: .danger,  isDisabled: true) {}
                            AppButton(label: "Disabled", variant: .tertiary, isDisabled: true) {}
                        }
                    }

                    // ── IconButton: Variants ──────────────────────────────
                    ShowcaseSection(title: "IconButton — Variants") {
                        HScrollRow {
                            HStack(spacing: .space3) {
                                AppIconButton(icon: AnyView(Ph.heart.regular),     label: "Like",    variant: .primary)     {}
                                AppIconButton(icon: AnyView(Ph.bookmark.regular),  label: "Save",    variant: .secondary)   {}
                                AppIconButton(icon: AnyView(Ph.share.regular),     label: "Share",   variant: .tertiary)    {}
                                AppIconButton(icon: AnyView(Ph.dotsThree.regular), label: "More",    variant: .quarternary) {}
                                AppIconButton(icon: AnyView(Ph.check.regular),     label: "Confirm", variant: .success)     {}
                                AppIconButton(icon: AnyView(Ph.trash.regular),     label: "Delete",  variant: .danger)      {}
                            }
                            .padding(.trailing, .space4)
                        }
                    }

                    // ── IconButton: Sizes ──────────────────────────────────
                    ShowcaseSection(title: "IconButton — Sizes") {
                        HScrollRow {
                            HStack(spacing: .space3) {
                                AppIconButton(icon: AnyView(Ph.star.regular), label: "Favourite", variant: .primary, size: .lg) {}
                                AppIconButton(icon: AnyView(Ph.star.regular), label: "Favourite", variant: .primary, size: .md) {}
                                AppIconButton(icon: AnyView(Ph.star.regular), label: "Favourite", variant: .primary, size: .sm) {}
                            }
                            .padding(.trailing, .space4)
                        }
                    }

                    // ── IconButton: States ─────────────────────────────────
                    ShowcaseSection(title: "IconButton — States") {
                        HScrollRow {
                            HStack(spacing: .space3) {
                                AppIconButton(icon: AnyView(Ph.heart.regular), label: "Loading",  variant: .primary,  isLoading: true)  {}
                                AppIconButton(icon: AnyView(Ph.heart.regular), label: "Disabled", variant: .primary,  isDisabled: true) {}
                                AppIconButton(icon: AnyView(Ph.trash.regular), label: "Disabled", variant: .danger,   isDisabled: true) {}
                                AppIconButton(icon: AnyView(Ph.share.regular), label: "Disabled", variant: .tertiary, isDisabled: true) {}
                            }
                            .padding(.trailing, .space4)
                        }
                    }

                    // ── Icons: Sizes ──────────────────────────────────────
                    ShowcaseSection(title: "Icons — Sizes") {
                        HScrollRow {
                            HStack(spacing: 20) {
                                ForEach([
                                    ("xs", PhosphorIconSize.xs),
                                    ("sm", PhosphorIconSize.sm),
                                    ("md", PhosphorIconSize.md),
                                    ("lg", PhosphorIconSize.lg),
                                    ("xl", PhosphorIconSize.xl),
                                ], id: \.0) { label, token in
                                    VStack(spacing: 4) {
                                        Ph.house.regular
                                            .iconSize(token)
                                            .iconColor(.appIconPrimary)
                                        Text(label)
                                            .font(.system(size: 10))
                                            .foregroundStyle(Color.typographyMuted)
                                    }
                                }
                            }
                            .padding(.trailing, .space4)
                        }
                    }

                    // ── Icons: Weights ────────────────────────────────────
                    ShowcaseSection(title: "Icons — Weights") {
                        HScrollRow {
                            HStack(spacing: 16) {
                                ForEach([
                                    ("thin",    AnyView(Ph.heart.thin.iconSize(.lg))),
                                    ("light",   AnyView(Ph.heart.light.iconSize(.lg))),
                                    ("regular", AnyView(Ph.heart.regular.iconSize(.lg))),
                                    ("bold",    AnyView(Ph.heart.bold.iconSize(.lg))),
                                    ("fill",    AnyView(Ph.heart.fill.iconSize(.lg))),
                                    ("duotone", AnyView(Ph.heart.duotone.iconSize(.lg))),
                                ], id: \.0) { label, icon in
                                    VStack(spacing: 4) {
                                        icon.iconColor(.appIconPrimary)
                                        Text(label)
                                            .font(.system(size: 9))
                                            .foregroundStyle(Color.typographyMuted)
                                    }
                                }
                            }
                            .padding(.trailing, .space4)
                        }
                    }

                    // ── Badge ─────────────────────────────────────────────
                    ShowcaseSection(title: "Badge — Solid") {
                        HScrollRow {
                            HStack(spacing: .space2) {
                                AppBadge(label: "Brand",   type: .brand)
                                AppBadge(label: "Success", type: .success)
                                AppBadge(label: "Error",   type: .error)
                                AppBadge(label: "Accent",  type: .accent)
                            }
                            .padding(.trailing, .space4)
                        }
                    }

                    ShowcaseSection(title: "Badge — Subtle") {
                        HScrollRow {
                            HStack(spacing: .space2) {
                                AppBadge(label: "Brand",   type: .brand,   subtle: true)
                                AppBadge(label: "Success", type: .success, subtle: true)
                                AppBadge(label: "Error",   type: .error,   subtle: true)
                                AppBadge(label: "Accent",  type: .accent,  subtle: true)
                            }
                            .padding(.trailing, .space4)
                        }
                    }

                    ShowcaseSection(title: "Badge — Number / Tiny") {
                        HScrollRow {
                            HStack(spacing: .space2) {
                                AppBadge(count: 3,  type: .brand)
                                AppBadge(count: 12, type: .error)
                                AppBadge(count: 99, type: .success)
                                AppBadge(size: .tiny, type: .brand)
                                AppBadge(size: .tiny, type: .error)
                                AppBadge(size: .tiny, type: .success)
                            }
                            .padding(.trailing, .space4)
                        }
                    }

                    // ── Chip ──────────────────────────────────────────────
                    ShowcaseSection(title: "Chip — ChipTabs (single-select)") {
                        HScrollRow {
                            HStack(spacing: .space2) {
                                ForEach(["Design", "Code", "Product"], id: \.self) { label in
                                    AppChip(
                                        label: label,
                                        variant: .chipTabs,size: .lg,
                                        isActive: activeChip == label.lowercased()
                                    ) {
                                        withAnimation(.easeOut(duration: 0.15)) {
                                            activeChip = label.lowercased()
                                        }
                                    }
                                }
                            }
                            .padding(.trailing, .space4)
                        }
                    }

                    ShowcaseSection(title: "Chip — Filters (multi-select)") {
                        HScrollRow {
                            HStack(spacing: .space2) {
                                ForEach(["Bold", "Italic", "Underline"], id: \.self) { label in
                                    AppChip(
                                        label: label,
                                        variant: .filters,
                                        isActive: activeFilters.contains(label.lowercased())
                                    ) {
                                        withAnimation(.easeOut(duration: 0.15)) {
                                            let key = label.lowercased()
                                            if activeFilters.contains(key) {
                                                activeFilters.remove(key)
                                            } else {
                                                activeFilters.insert(key)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.trailing, .space4)
                        }
                    }

                    ShowcaseSection(title: "Chip — Disabled") {
                        HScrollRow {
                            HStack(spacing: .space2) {
                                AppChip(label: "Active + disabled", variant: .chipTabs, isActive: true, isDisabled: true) {}
                                AppChip(label: "Inactive + disabled", variant: .filters, isDisabled: true) {}
                            }
                            .padding(.trailing, .space4)
                        }
                    }

                    // ── Tabs ──────────────────────────────────────────────
                    ShowcaseSection(title: "Tabs — Animated indicator") {
                        AppTabs(
                            items: [
                                AppTabItem(id: "design",  label: "Design"),
                                AppTabItem(id: "code",    label: "Code"),
                                AppTabItem(id: "preview", label: "Preview"),
                            ],
                            activeTab: $activeTab
                        )

                        Group {
                            if activeTab == "design" {
                                Text("Design tab content")
                            } else if activeTab == "code" {
                                Text("Code tab content")
                            } else {
                                Text("Preview tab content")
                            }
                        }
                        .font(.appBodySmall)
                        .foregroundStyle(Color.typographySecondary)
                        .padding(.top, .space1)
                    }

                    ShowcaseSection(title: "Tabs — Sizes") {
                        VStack(alignment: .leading, spacing: .space3) {
                            AppTabs(
                                items: [
                                    AppTabItem(id: "a", label: "Week"),
                                    AppTabItem(id: "b", label: "Month"),
                                    AppTabItem(id: "c", label: "Year"),
                                ],
                                activeTab: .constant("a"),
                                size: .sm
                            )
                            AppTabs(
                                items: [
                                    AppTabItem(id: "a", label: "Week"),
                                    AppTabItem(id: "b", label: "Month"),
                                    AppTabItem(id: "c", label: "Year"),
                                ],
                                activeTab: .constant("a"),
                                size: .md
                            )
                            AppTabs(
                                items: [
                                    AppTabItem(id: "a", label: "Week"),
                                    AppTabItem(id: "b", label: "Month"),
                                    AppTabItem(id: "c", label: "Year"),
                                ],
                                activeTab: .constant("a"),
                                size: .lg
                            )
                        }
                    }

                    // ── SegmentControlBar ──────────────────────────────────
                    ShowcaseSection(title: "SegmentControlBar — Segment") {
                        AppSegmentControlBar(
                            items: [
                                AppSegmentItem(id: "week",  label: "Week"),
                                AppSegmentItem(id: "month", label: "Month"),
                                AppSegmentItem(id: "year",  label: "Year"),
                            ],
                            selected: $segSelected,
                            type: .segmentControl
                        )
                    }

                    ShowcaseSection(title: "SegmentControlBar — Chips") {
                        HScrollRow {
                            AppSegmentControlBar(
                                items: [
                                    AppSegmentItem(id: "all",    label: "All"),
                                    AppSegmentItem(id: "design", label: "Design"),
                                    AppSegmentItem(id: "code",   label: "Code"),
                                ],
                                selected: $chipSelected,
                                type: .chips
                            )
                            Spacer(minLength: .space4)
                        }
                    }

                    ShowcaseSection(title: "SegmentControlBar — Filters (multi)") {
                        HScrollRow {
                            AppSegmentControlBarMulti(
                                items: [
                                    AppSegmentItem(id: "ios",     label: "iOS"),
                                    AppSegmentItem(id: "android", label: "Android"),
                                    AppSegmentItem(id: "web",     label: "Web"),
                                ],
                                selected: $filterSelected
                            )
                            Spacer(minLength: .space4)
                        }
                    }

                    // ── Divider ───────────────────────────────────────────
                    ShowcaseSection(title: "Divider") {
                        VStack(alignment: .leading, spacing: .space3) {
                            Text("Row divider (default)").font(.appCaptionSmall).foregroundStyle(Color.typographyMuted)
                            Text("Item A").font(.appBodyMedium)
                            AppDivider(type: .row)
                            Text("Item B").font(.appBodyMedium)
                            AppDivider(type: .row)
                            Text("Item C").font(.appBodyMedium)

                            Text("Section divider").font(.appCaptionSmall).foregroundStyle(Color.typographyMuted).padding(.top, .space2)
                            AppDivider(type: .section)

                            Text("Labeled divider").font(.appCaptionSmall).foregroundStyle(Color.typographyMuted).padding(.top, .space2)
                            AppDivider(type: .section, label: "or")

                            Text("Vertical divider").font(.appCaptionSmall).foregroundStyle(Color.typographyMuted).padding(.top, .space2)
                            HStack(spacing: .space3) {
                                Text("Left").font(.appBodyMedium)
                                AppDivider(orientation: .vertical).frame(height: 20)
                                Text("Right").font(.appBodyMedium)
                            }
                        }
                    }

                    // ── Toast ─────────────────────────────────────────────
                    ShowcaseSection(title: "Toast — Variants") {
                        VStack(spacing: .space3) {
                            AppToast(message: "Settings saved", variant: .default, description: "Your preferences have been updated.", dismissible: true)
                            AppToast(message: "Upload complete!", variant: .success, description: "Your file is ready to share.")
                            AppToast(message: "Connection unstable", variant: .warning, actionLabel: "Retry") {}
                            AppToast(message: "Failed to save", variant: .error, description: "Check your connection.", dismissible: true)
                        }
                    }

                    ShowcaseSection(title: "Toast — With buttons") {
                        VStack(spacing: .space3) {
                            AppToast(message: "New update available", variant: .default, actionLabel: "Update now") {}
                            AppToast(
                                message: "Item archived",
                                variant: .default,
                                description: "Moved to trash.",
                                trailingIconButton: ToastTrailingIconButton(
                                    icon: AnyView(Image(systemName: "arrow.uturn.backward").resizable().scaledToFit()),
                                    action: {}
                                )
                            )
                            AppToast(
                                message: "Message sent",
                                variant: .success,
                                trailingIconButton: ToastTrailingIconButton(
                                    icon: AnyView(Image(systemName: "eye").resizable().scaledToFit()),
                                    action: {}
                                ),
                                dismissible: true
                            )
                        }
                    }

                    ShowcaseSection(title: "Toast — Live trigger") {
                        HScrollRow {
                            HStack(spacing: .space2) {
                                AppButton(label: "Settings saved", variant: .secondary, size: .sm) {
                                    showToastWith(message: "Settings saved", variant: .default)
                                }
                                AppButton(label: "Upload complete", variant: .success, size: .sm) {
                                    showToastWith(message: "Upload complete", variant: .success)
                                }
                                AppButton(label: "Connection error", variant: .danger, size: .sm) {
                                    showToastWith(message: "Connection error", variant: .error)
                                }
                            }
                            .padding(.trailing, .space4)
                        }
                    }

                    // ── Input Field ───────────────────────────────────────
                    ShowcaseSection(title: "Input Field") {
                        VStack(spacing: .space3) {
                            AppInputField(text: $name, label: "Full Name", placeholder: "Enter your name")
                            AppInputField(text: .constant("user@example.com"), label: "Email", state: .success, hint: "Looks good!")
                            AppInputField(text: $email, label: "Email", state: .error, hint: "Please enter a valid email address")
                            AppInputField(text: .constant(""), label: "Password", placeholder: "Enter password", state: .warning, hint: "Weak password")
                            AppInputField(text: .constant("Disabled value"), label: "Disabled", isDisabled: true)
                        }
                    }

                    ShowcaseSection(title: "Text Field (multiline)") {
                        AppTextField(text: $bio, label: "Bio", placeholder: "Tell us about yourself…")
                    }

                    ShowcaseSection(title: "TextOnly Field (bare input)") {
                        VStack(alignment: .leading, spacing: .space3) {
                            AppTextOnlyField(text: $textOnlyValue, placeholder: "Type here — no chrome…")
                            AppDivider(type: .row)
                            Text("Used inside complex components like chat inputs or inline editors. No background, no border.")
                                .font(.appCaptionSmall)
                                .foregroundStyle(Color.typographyMuted)
                        }
                    }

                    // ── Thumbnail ─────────────────────────────────────────
                    ShowcaseSection(title: "Thumbnail — Square") {
                        HScrollRow {
                            HStack(spacing: .space3) {
                                ForEach([
                                    ("xs",  AppThumbnailSize.xs),
                                    ("sm",  AppThumbnailSize.sm),
                                    ("md",  AppThumbnailSize.md),
                                    ("lg",  AppThumbnailSize.lg),
                                    ("xl",  AppThumbnailSize.xl),
                                    ("xxl", AppThumbnailSize.xxl),
                                ], id: \.0) { label, size in
                                    VStack(spacing: 4) {
                                        AppThumbnail(size: size)
                                        Text(label).font(.system(size: 9)).foregroundStyle(Color.typographyMuted)
                                    }
                                }
                            }
                            .padding(.trailing, .space4)
                        }
                    }

                    ShowcaseSection(title: "Thumbnail — Circular") {
                        HScrollRow {
                            HStack(spacing: .space3) {
                                ForEach([
                                    ("xs",  AppThumbnailSize.xs),
                                    ("sm",  AppThumbnailSize.sm),
                                    ("md",  AppThumbnailSize.md),
                                    ("lg",  AppThumbnailSize.lg),
                                    ("xl",  AppThumbnailSize.xl),
                                    ("xxl", AppThumbnailSize.xxl),
                                ], id: \.0) { label, size in
                                    VStack(spacing: 4) {
                                        AppThumbnail(size: size, rounded: true)
                                        Text(label).font(.system(size: 9)).foregroundStyle(Color.typographyMuted)
                                    }
                                }
                            }
                            .padding(.trailing, .space4)
                        }
                    }

                    ShowcaseSection(title: "Thumbnail — Initials fallback") {
                        HScrollRow {
                            HStack(spacing: .space3) {
                                AppThumbnail(size: .lg,  rounded: true,  accessibilityLabel: "Alice Brown") { Text("AB") }
                                AppThumbnail(size: .xl,  rounded: true,  accessibilityLabel: "John Doe")    { Text("JD") }
                                AppThumbnail(size: .xxl, rounded: false, accessibilityLabel: "Maria Kim")   { Text("MK") }
                            }
                            .padding(.trailing, .space4)
                        }
                    }

                    // ── Label ──────────────────────────────────────────────
                    ShowcaseSection(title: "Label — Sizes × Types") {
                        VStack(alignment: .leading, spacing: .space3) {
                            ForEach([
                                ("Small", AppLabelSize.sm),
                                ("Medium", AppLabelSize.md),
                                ("Large", AppLabelSize.lg),
                            ], id: \.0) { sizeName, size in
                                VStack(alignment: .leading, spacing: .space1) {
                                    Text(sizeName)
                                        .font(.appCaptionSmall)
                                        .foregroundStyle(Color.typographyMuted)
                                    HScrollRow {
                                        HStack(spacing: .space4) {
                                            AppLabel(label: "Secondary", size: size, type: .secondaryAction)
                                            AppLabel(label: "Primary",   size: size, type: .primaryAction)
                                            AppLabel(label: "Brand",     size: size, type: .brandInteractive)
                                            AppLabel(label: "Info",      size: size, type: .information)
                                        }
                                        .padding(.trailing, .space4)
                                    }
                                }
                            }
                        }
                    }

                    ShowcaseSection(title: "Label — With Icons") {
                        HScrollRow {
                            HStack(spacing: .space4) {
                                AppLabel(
                                    label: "Verified",
                                    size: .lg,
                                    type: .primaryAction,
                                    leadingIcon: AnyView(Ph.checkCircle.regular.iconSize(.lg))
                                )
                                AppLabel(
                                    label: "USD",
                                    size: .md,
                                    type: .secondaryAction,
                                    trailingIcon: AnyView(Ph.caretDown.regular.iconSize(.md))
                                )
                                AppLabel(
                                    label: "Info",
                                    size: .sm,
                                    type: .information,
                                    leadingIcon: AnyView(Ph.info.regular.iconSize(.sm)),
                                    trailingIcon: AnyView(Ph.caretRight.regular.iconSize(.sm))
                                )
                            }
                            .padding(.trailing, .space4)
                        }
                    }

                    // ── Input Field — Icon Slots ───────────────────────────
                    ShowcaseSection(title: "Input Field — Icon Slots") {
                        VStack(spacing: .space3) {
                            AppInputField(
                                text: $name,
                                label: "Leading icon",
                                placeholder: "Search…",
                                leadingIcon: AnyView(Ph.magnifyingGlass.regular.iconSize(.md))
                            )
                            AppInputField(
                                text: $name,
                                label: "Trailing icon",
                                placeholder: "Password",
                                trailingIcon: AnyView(Ph.eye.regular.iconSize(.md))
                            )
                            AppInputField(
                                text: .constant("query"),
                                label: "Both icons",
                                leadingIcon: AnyView(Ph.magnifyingGlass.regular.iconSize(.md)),
                                trailingIcon: AnyView(Ph.x.regular.iconSize(.md))
                            )
                        }
                    }

                    // ── Input Field — Picker Slots ────────────────────────
                    ShowcaseSection(title: "Input Field — Picker Slots") {
                        VStack(spacing: .space3) {
                            AppInputField(
                                text: $bio,
                                label: "Leading picker",
                                placeholder: "0.00",
                                leadingPicker: .picker(
                                    label: "Currency",
                                    selection: $inputLeadingCurrency,
                                    options: [("USD", "USD"), ("EUR", "EUR"), ("GBP", "GBP"), ("INR", "INR")]
                                ),
                                leadingSeparator: true
                            )
                            AppInputField(
                                text: $bio,
                                label: "Trailing picker",
                                placeholder: "Enter weight",
                                trailingPicker: .picker(
                                    label: "Unit",
                                    selection: $inputTrailingUnit,
                                    options: [("kg", "kg"), ("lb", "lb"), ("oz", "oz")]
                                ),
                                trailingSeparator: true
                            )
                            AppInputField(
                                text: $bio,
                                label: "Both pickers + separators",
                                placeholder: "0.00",
                                leadingPicker: .picker(
                                    label: "From",
                                    selection: $inputLeadingCurrency,
                                    options: [("USD", "USD"), ("EUR", "EUR"), ("GBP", "GBP")]
                                ),
                                trailingPicker: .picker(
                                    label: "Unit",
                                    selection: $inputTrailingUnit,
                                    options: [("kg", "kg"), ("lb", "lb")]
                                ),
                                leadingSeparator: true,
                                trailingSeparator: true
                            )
                            AppInputField(
                                text: .constant("42.00"),
                                label: "Picker + success state",
                                state: .success,
                                hint: "Valid amount",
                                leadingPicker: .picker(
                                    label: "Currency",
                                    selection: $inputLeadingCurrency,
                                    options: [("USD", "USD"), ("EUR", "EUR")]
                                ),
                                leadingSeparator: true
                            )
                        }
                    }

                    // ── Input Field — Static Labels ──────────────────────────
                    ShowcaseSection(title: "Input Field — Static Labels") {
                        VStack(spacing: .space3) {
                            AppInputField(
                                text: $bio,
                                label: "Leading label",
                                placeholder: "0.00",
                                leadingLabel: AnyView(AppLabel(label: "USD", size: .md, type: .secondaryAction))
                            )
                            AppInputField(
                                text: $bio,
                                label: "Leading label + separator",
                                placeholder: "0.00",
                                leadingLabel: AnyView(AppLabel(label: "USD", size: .md, type: .secondaryAction)),
                                leadingSeparator: true
                            )
                            AppInputField(
                                text: $bio,
                                label: "Trailing label",
                                placeholder: "Enter amount",
                                trailingLabel: AnyView(AppLabel(label: "kg", size: .md, type: .information))
                            )
                            AppInputField(
                                text: $bio,
                                label: "Both labels + separators",
                                placeholder: "0.00",
                                leadingLabel: AnyView(AppLabel(label: "From", size: .md, type: .secondaryAction)),
                                trailingLabel: AnyView(AppLabel(label: "USD", size: .md, type: .brandInteractive)),
                                leadingSeparator: true,
                                trailingSeparator: true
                            )
                        }
                    }

                    // ── Form — Pickers + Input Fields ────────────────────
                    ShowcaseSection(title: "Form — Pickers + Input Fields") {
                        VStack(spacing: .space3) {
                            AppInputField(
                                text: $formName,
                                label: "Full Name",
                                placeholder: "Enter your name",
                                leadingIcon: AnyView(Ph.user.regular.iconSize(.md))
                            )
                            AppInputField(
                                text: $formEmail,
                                label: "Email",
                                placeholder: "you@example.com",
                                leadingIcon: AnyView(Ph.envelope.regular.iconSize(.md))
                            )
                            AppNativePicker(
                                label: "Country",
                                selection: $formCountry,
                                options: [("Australia", "AU"), ("India", "IN"), ("USA", "US"), ("UK", "UK")]
                            )
                            AppDateTimePicker(
                                label: "Date of Birth",
                                selection: $formDOB,
                                mode: .date
                            )
                            AppNativePicker(
                                label: "Preferred Language",
                                selection: $formLanguage,
                                options: [("English", "EN"), ("Hindi", "HI"), ("Spanish", "ES")]
                            )
                            AppInputField(
                                text: $formPhone,
                                label: "Phone",
                                placeholder: "+1 (555) 000-0000",
                                leadingIcon: AnyView(Ph.phone.regular.iconSize(.md))
                            )
                            AppTextField(
                                text: $formBio,
                                label: "Bio",
                                placeholder: "Tell us about yourself…"
                            )
                            AppButton(label: "Submit", variant: .primary) {}
                        }
                    }

                    // ── TextBlock ──────────────────────────────────────────
                    ShowcaseSection(title: "TextBlock — All slots") {
                        AppTextBlock(
                            overline: "Recent",
                            title: "Trip to Bali",
                            subtext: "Summer vacation",
                            body: "Some description can come here regarding the task.",
                            metadata: "Posted 2d ago"
                        )
                    }

                    ShowcaseSection(title: "TextBlock — Combinations") {
                        VStack(alignment: .leading, spacing: .space3) {
                            AppTextBlock(title: "Title only")
                            AppDivider(type: .row)
                            AppTextBlock(title: "Ayurveda Books", subtext: "bought for Anjali at airport")
                            AppDivider(type: .row)
                            AppTextBlock(body: "Some description text here.", metadata: "3 days ago")
                        }
                    }

                    // ── StepIndicator ─────────────────────────────────────
                    ShowcaseSection(title: "StepIndicator") {
                        HStack(spacing: .space6) {
                            VStack(spacing: .space2) {
                                AppStepIndicator(completed: false)
                                Text("incomplete")
                                    .font(.appCaptionSmall)
                                    .foregroundStyle(Color.typographyMuted)
                            }
                            VStack(spacing: .space2) {
                                AppStepIndicator(completed: true)
                                Text("completed")
                                    .font(.appCaptionSmall)
                                    .foregroundStyle(Color.typographyMuted)
                            }
                        }
                    }

                    // ── Stepper ───────────────────────────────────────────
                    ShowcaseSection(title: "Stepper — All completed") {
                        AppStepper(steps: [
                            AppStepperStep(title: "Ordered",   subtitle: "Mar 1", completed: true),
                            AppStepperStep(title: "Shipped",   subtitle: "Mar 2", completed: true),
                            AppStepperStep(title: "Delivered", subtitle: "Mar 4", completed: true),
                        ])
                    }

                    ShowcaseSection(title: "Stepper — Mixed state") {
                        AppStepper(steps: [
                            AppStepperStep(title: "Ayurveda Books", subtitle: "bought for Anjali at airport", completed: true),
                            AppStepperStep(title: "Pack luggage", completed: false),
                            AppStepperStep(title: "Depart",       subtitle: "Flight at 08:00", completed: false),
                        ])
                    }

                    ShowcaseSection(title: "Stepper — Single step with body") {
                        AppStepper(steps: [
                            AppStepperStep(title: "Submit application", body: "Fill in all required fields before submitting."),
                        ])
                    }

                    // ── ListItem ──────────────────────────────────────────
                    ShowcaseSection(title: "ListItem — Variants") {
                        VStack(spacing: 0) {
                            AppListItem(title: "Title only", divider: true)
                            AppListItem(
                                title: "Ayurveda Books",
                                subtitle: "bought for Anjali at airport",
                                divider: true
                            )
                            AppListItem(
                                title: "Pack luggage",
                                subtitle: "Ready for the trip",
                                thumbnail: AppThumbnailConfig(size: .sm, rounded: true),
                                trailing: .badge(label: "New", type: .brand),
                                divider: true
                            )
                            AppListItem(
                                title: "Depart",
                                subtitle: "Flight at 08:00",
                                trailing: .button(label: "Edit", action: {}),
                                divider: true
                            )
                            AppListItem(
                                title: "Trip to Bali",
                                subtitle: "Summer vacation",
                                body: "Remember to pack sunscreen.",
                                trailing: .iconButton(
                                    icon: AnyView(Ph.dotsThree.regular.iconSize(.md)),
                                    accessibilityLabel: "More options",
                                    action: {}
                                )
                            )
                        }
                    }

                    // ── Radio Buttons ──────────────────────────────────────
                    ShowcaseSection(title: "Radio Buttons — Standalone") {
                        VStack(alignment: .leading, spacing: .space3) {
                            AppRadioButton(checked: true, label: "Selected radio")
                            AppRadioButton(checked: false, label: "Unselected radio")
                            AppRadioButton(checked: true, label: "Disabled selected", disabled: true)
                        }
                    }

                    ShowcaseSection(title: "Radio Buttons — Group") {
                        AppRadioGroup(value: $radioValue) {
                            AppRadioButton(label: "Email", value: "email")
                            AppRadioButton(label: "SMS", value: "sms")
                            AppRadioButton(label: "Push notification", value: "push")
                        }
                    }

                    ShowcaseSection(title: "Radio Buttons — As ListItem") {
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

                    // ── Checkboxes ─────────────────────────────────────────
                    ShowcaseSection(title: "Checkboxes — Standalone") {
                        VStack(alignment: .leading, spacing: .space3) {
                            AppCheckbox(checked: true, label: "Checked")
                            AppCheckbox(checked: false, label: "Unchecked")
                            AppCheckbox(checked: true, indeterminate: true, label: "Indeterminate")
                            AppCheckbox(checked: true, label: "Disabled checked", disabled: true)
                        }
                    }

                    ShowcaseSection(title: "Checkboxes — Email Preferences") {
                        let allChecked = checkNotifications && checkUpdates && checkMarketing
                        let someChecked = checkNotifications || checkUpdates || checkMarketing

                        VStack(spacing: 0) {
                            AppListItem(
                                title: "Select all",
                                trailing: .checkbox(
                                    checked: allChecked,
                                    indeterminate: !allChecked && someChecked,
                                    onChange: { val in
                                        checkNotifications = val
                                        checkUpdates = val
                                        checkMarketing = val
                                    }
                                ),
                                divider: true
                            )
                            AppListItem(
                                title: "Notifications",
                                subtitle: "Transaction alerts and reminders",
                                trailing: .checkbox(checked: checkNotifications, onChange: { checkNotifications = $0 }),
                                divider: true
                            )
                            AppListItem(
                                title: "Product updates",
                                subtitle: "New features and improvements",
                                trailing: .checkbox(checked: checkUpdates, onChange: { checkUpdates = $0 }),
                                divider: true
                            )
                            AppListItem(
                                title: "Marketing",
                                subtitle: "Promotions and special offers",
                                trailing: .checkbox(checked: checkMarketing, onChange: { checkMarketing = $0 })
                            )
                        }
                    }

                    // ── Switches ────────────────────────────────────────────
                    ShowcaseSection(title: "Switches — Standalone") {
                        VStack(alignment: .leading, spacing: .space3) {
                            AppSwitch(checked: true, label: "On")
                            AppSwitch(checked: false, label: "Off")
                            AppSwitch(checked: true, label: "Disabled on", disabled: true)
                        }
                    }

                    ShowcaseSection(title: "Switches — Settings") {
                        VStack(spacing: 0) {
                            AppListItem(
                                title: "Dark mode",
                                subtitle: "Use dark color theme",
                                trailing: .toggle(checked: switchDarkMode, onChange: { switchDarkMode = $0 }),
                                divider: true
                            )
                            AppListItem(
                                title: "Notifications",
                                subtitle: "Enable push notifications",
                                trailing: .toggle(checked: switchNotifications, onChange: { switchNotifications = $0 }),
                                divider: true
                            )
                            AppListItem(
                                title: "Location services",
                                subtitle: "Allow access to your location",
                                trailing: .toggle(checked: switchLocation, onChange: { switchLocation = $0 })
                            )
                        }
                    }

                    // ═══════════════════════════════════════════════════════
                    // NATIVE COMPONENT WRAPPERS
                    // ═══════════════════════════════════════════════════════

                    AppDivider(type: .section, label: "Native Components")

                    // ── Native Picker ────────────────────────────────────
                    ShowcaseSection(title: "Native Picker — Menu") {
                        VStack(spacing: .space3) {
                            AppNativePicker(
                                label: "Country",
                                selection: $pickerSelected,
                                options: [("Australia", "AU"), ("India", "IN"), ("USA", "US")]
                            )
                            AppNativePicker(
                                label: "Size (error)",
                                selection: .constant("S"),
                                options: [("Small", "S"), ("Medium", "M"), ("Large", "L")],
                                showError: true,
                                errorMessage: "Please select a size"
                            )
                            AppNativePicker(
                                label: "Region (disabled)",
                                selection: .constant("N"),
                                options: [("North", "N"), ("South", "S")],
                                isDisabled: true
                            )
                        }
                    }

                    // ── Picker — Triggered from Components ──────────────
                    ShowcaseSection(title: "Picker — Triggered from Components") {
                        VStack(alignment: .leading, spacing: .space3) {
                            Text("Pickers can be triggered from any component using Menu:")
                                .font(.appCaptionSmall)
                                .foregroundStyle(Color.typographyMuted)

                            HScrollRow {
                                HStack(spacing: .space3) {
                                    // Picker from Button
                                    Menu {
                                        ForEach(["Australia", "India", "USA"], id: \.self) { option in
                                            Button(option) { pickerSelected = option == "Australia" ? "AU" : option == "India" ? "IN" : "US" }
                                        }
                                    } label: {
                                        AppButton(label: "Pick Country", variant: .secondary, size: .sm) {}
                                            .allowsHitTesting(false)
                                    }

                                    // Picker from Chip
                                    Menu {
                                        ForEach(["Small", "Medium", "Large"], id: \.self) { option in
                                            Button(option) { }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            AppChip(label: "Size", variant: .chipTabs, size: .md, isActive: false) {}
                                                .allowsHitTesting(false)
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundStyle(Color.typographySecondary)
                                        }
                                    }

                                    // Picker from IconButton
                                    Menu {
                                        ForEach(["Sort A\u{2013}Z", "Sort Z\u{2013}A", "Newest"], id: \.self) { option in
                                            Button(option) { }
                                        }
                                    } label: {
                                        AppIconButton(icon: AnyView(Ph.funnel.regular), label: "Filter", variant: .tertiary) {}
                                            .allowsHitTesting(false)
                                    }

                                    // Picker from Label
                                    Menu {
                                        ForEach(["USD", "EUR", "GBP", "INR"], id: \.self) { option in
                                            Button(option) { }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            AppLabel(label: "USD", size: .md, type: .secondaryAction)
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundStyle(Color.typographySecondary)
                                        }
                                    }
                                }
                                .padding(.trailing, .space4)
                            }
                        }
                    }

                    // ── DateTimePicker ────────────────────────────────────
                    ShowcaseSection(title: "DateTimePicker — Compact") {
                        AppDateTimePicker(label: "Date", selection: $selectedDate)
                    }

                    ShowcaseSection(title: "DateTimePicker — Graphical") {
                        AppDateTimePicker(
                            label: "Appointment",
                            selection: $selectedDate,
                            displayStyle: .graphical
                        )
                    }

                    ShowcaseSection(title: "DateTimePicker — Wheel (time)") {
                        AppDateTimePicker(
                            label: "Alarm",
                            selection: $selectedDate,
                            mode: .time,
                            displayStyle: .wheel
                        )
                    }

                    // ── ProgressLoader ────────────────────────────────────
                    ShowcaseSection(title: "ProgressLoader") {
                        VStack(spacing: .space4) {
                            HStack(spacing: .space6) {
                                AppProgressLoader()
                                AppProgressLoader(label: "Loading…")
                            }
                            AppProgressLoader(
                                variant: .definite(value: 0.65, total: 1.0),
                                label: "65%"
                            )
                            AppProgressLoader(
                                variant: .definite(value: 3, total: 10),
                                label: "Step 3 of 10"
                            )
                        }
                    }

                    // ── ColorPicker ──────────────────────────────────────
                    ShowcaseSection(title: "ColorPicker") {
                        VStack(spacing: .space3) {
                            AppColorPicker(label: "Accent Color", selection: $selectedColor)
                            AppColorPicker(
                                label: "Background (with opacity)",
                                selection: $selectedColor,
                                supportsOpacity: true
                            )
                        }
                    }

                    // ── BottomSheet — Default (medium + large) ─────────
                    ShowcaseSection(title: "BottomSheet — Default") {
                        AppButton(label: "Medium / Large Sheet", variant: .secondary) {
                            showSheet = true
                        }
                        .appBottomSheet(isPresented: $showSheet) {
                            VStack(alignment: .leading, spacing: .space4) {
                                Text("Default Sheet").font(.appTitleSmall)
                                Text("Snaps to medium (~50%) and large (~90%). Drag the handle to resize.")
                                    .font(.appBodyMedium)
                                    .foregroundStyle(Color.typographySecondary)
                                AppButton(label: "Close", variant: .primary) {
                                    showSheet = false
                                }
                                Spacer()
                            }
                        }
                    }

                    // ── BottomSheet — Small (fraction) ──────────────────
                    ShowcaseSection(title: "BottomSheet — Small (30%)") {
                        AppButton(label: "Compact Sheet", variant: .secondary, size: .sm) {
                            showSheetSmall = true
                        }
                        .appBottomSheet(
                            isPresented: $showSheetSmall,
                            detents: [.fraction(0.3)]
                        ) {
                            VStack(spacing: .space3) {
                                Ph.checkCircle.fill
                                    .iconSize(.xl)
                                    .foregroundStyle(Color.appSurfaceSuccessSolid)
                                Text("Action Complete")
                                    .font(.appTitleSmall)
                                Text("Your changes have been saved.")
                                    .font(.appBodySmall)
                                    .foregroundStyle(Color.typographySecondary)
                                AppButton(label: "Done", variant: .primary, size: .sm) {
                                    showSheetSmall = false
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }

                    // ── BottomSheet — Form ───────────────────────────────
                    ShowcaseSection(title: "BottomSheet — Form") {
                        AppButton(label: "Open Form Sheet", variant: .secondary, size: .sm) {
                            showSheetForm = true
                        }
                        .appBottomSheet(
                            isPresented: $showSheetForm,
                            detents: [.medium, .large]
                        ) {
                            VStack(alignment: .leading, spacing: .space4) {
                                HStack {
                                    Text("Quick Feedback").font(.appTitleSmall)
                                    Spacer()
                                    Button { showSheetForm = false } label: {
                                        Ph.xCircle.fill
                                            .iconSize(.md)
                                            .foregroundStyle(Color.typographyMuted)
                                    }
                                }

                                AppInputField(
                                    text: $sheetFormName,
                                    label: "Name",
                                    placeholder: "Enter your name"
                                )
                                AppInputField(
                                    text: $sheetFormEmail,
                                    label: "Email",
                                    placeholder: "you@example.com"
                                )

                                AppButton(label: "Submit", variant: .primary) {
                                    showSheetForm = false
                                }
                                Spacer()
                            }
                        }
                    }

                    // ── BottomSheet — Scrollable list ────────────────────
                    ShowcaseSection(title: "BottomSheet — List") {
                        AppButton(label: "Open List Sheet", variant: .secondary, size: .sm) {
                            showSheetList = true
                        }
                        .appBottomSheet(
                            isPresented: $showSheetList,
                            detents: [.medium, .large]
                        ) {
                            VStack(alignment: .leading, spacing: .space3) {
                                HStack {
                                    Text("Select Option").font(.appTitleSmall)
                                    Spacer()
                                    Button { showSheetList = false } label: {
                                        Ph.xCircle.fill
                                            .iconSize(.md)
                                            .foregroundStyle(Color.typographyMuted)
                                    }
                                }
                                ScrollView {
                                    VStack(spacing: 0) {
                                        ForEach(["Favourites", "Recent", "Documents", "Photos", "Music", "Videos", "Books", "Mail"], id: \.self) { label in
                                            AppListItem(
                                                title: label,
                                                trailing: .iconButton(
                                                    icon: AnyView(Ph.caretRight.regular.iconSize(.sm)),
                                                    accessibilityLabel: "Open \(label)",
                                                    action: { showSheetList = false }
                                                ),
                                                divider: true
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── ActionSheet ──────────────────────────────────────
                    ShowcaseSection(title: "ActionSheet") {
                        AppButton(label: "Show Action Sheet", variant: .secondary) {
                            showActionSheet = true
                        }
                        .appActionSheet(
                            isPresented: $showActionSheet,
                            title: "Post Options",
                            message: "Choose an action for this post.",
                            actions: [
                                .default("Edit") { },
                                .default("Share") { },
                                .destructive("Delete") { },
                                .cancel()
                            ]
                        )
                    }

                    // ── Alert Popup ──────────────────────────────────────
                    ShowcaseSection(title: "Alert Popup") {
                        AppButton(label: "Show Alert", variant: .danger) {
                            showAlert = true
                        }
                        .appAlert(
                            isPresented: $showAlert,
                            title: "Delete Item?",
                            message: "This action cannot be undone.",
                            buttons: [
                                .destructive("Delete") { },
                                .cancel()
                            ]
                        )
                    }

                    // ── Context Menu ─────────────────────────────────────
                    ShowcaseSection(title: "Context Menu — Long press") {
                        Text("Long-press me")
                            .font(.appBodyMedium)
                            .padding(.space3)
                            .background(
                                Color.surfacesBaseLowContrast,
                                in: RoundedRectangle(cornerRadius: .radiusMD)
                            )
                            .appContextMenu(items: [
                                .item("Edit", icon: AnyView(Ph.pencilSimple.regular)) { },
                                .item("Share", icon: AnyView(Ph.share.regular)) { },
                                .destructive("Delete", icon: AnyView(Ph.trash.regular)) { }
                            ])
                    }

                    ShowcaseSection(title: "Context Menu — Popover (tap)") {
                        AppPopoverMenu(isPresented: $showPopoverMenu, items: [
                            .item("Edit", icon: AnyView(Ph.pencilSimple.regular)) { },
                            .item("Duplicate", icon: AnyView(Ph.copy.regular)) { },
                            .destructive("Delete", icon: AnyView(Ph.trash.regular)) { }
                        ]) {
                            HStack(spacing: .space2) {
                                Text("Tap for menu")
                                    .font(.appBodyMedium)
                                Ph.dotsThreeCircle.regular
                                    .iconSize(.md)
                                    .foregroundStyle(Color.appIconPrimary)
                            }
                            .padding(.space3)
                            .background(
                                Color.surfacesBaseLowContrast,
                                in: RoundedRectangle(cornerRadius: .radiusMD)
                            )
                        }
                    }

                    // ── Carousel ─────────────────────────────────────────
                    ShowcaseSection(title: "Carousel — Paged") {
                        let cards = [
                            CarouselCard(id: 0, color: Color.appSurfaceAccentPrimary, label: "Card 1"),
                            CarouselCard(id: 1, color: Color.appSurfaceSuccessSolid, label: "Card 2"),
                            CarouselCard(id: 2, color: Color.appSurfaceErrorSolid, label: "Card 3"),
                        ]
                        AppCarousel(items: cards) { card in
                            RoundedRectangle(cornerRadius: .radiusLG)
                                .fill(card.color)
                                .overlay(
                                    Text(card.label)
                                        .font(.appTitleSmall)
                                        .foregroundStyle(.white)
                                )
                                .padding(.horizontal, .space4)
                        }
                    }

                    ShowcaseSection(title: "Carousel — Scroll Snap") {
                        let cards = [
                            CarouselCard(id: 0, color: Color.appSurfaceAccentPrimary, label: "Snap 1"),
                            CarouselCard(id: 1, color: Color.appSurfaceSuccessSolid, label: "Snap 2"),
                            CarouselCard(id: 2, color: Color.appSurfaceErrorSolid, label: "Snap 3"),
                        ]
                        AppCarousel(items: cards, style: .scrollSnap) { card in
                            RoundedRectangle(cornerRadius: .radiusLG)
                                .fill(card.color)
                                .overlay(
                                    Text(card.label)
                                        .font(.appBodyMediumEm)
                                        .foregroundStyle(.white)
                                )
                                .frame(width: 280, height: 160)
                        }
                    }

                    // ── Tooltip ──────────────────────────────────────────
                    ShowcaseSection(title: "Tooltip") {
                        HStack(spacing: .space6) {
                            AppTooltip(isPresented: $showTooltip, tipText: "Tap the heart to like this post", arrowEdge: .bottom) {
                                VStack(spacing: .space1) {
                                    Ph.heart.regular
                                        .iconSize(.lg)
                                        .foregroundStyle(Color.appIconPrimary)
                                    Text("Tap me")
                                        .font(.appCaptionSmall)
                                        .foregroundStyle(Color.typographyMuted)
                                }
                                .onTapGesture { showTooltip.toggle() }
                            }
                        }
                    }

                    // ── Range Slider ─────────────────────────────────────
                    ShowcaseSection(title: "RangeSlider — Continuous") {
                        AppRangeSlider(
                            lowerValue: $sliderLow,
                            upperValue: $sliderHigh,
                            range: 0...100,
                            showLabels: true
                        )
                    }

                    ShowcaseSection(title: "RangeSlider — Step 10") {
                        AppRangeSlider(
                            lowerValue: $sliderStepLow,
                            upperValue: $sliderStepHigh,
                            range: 0...100,
                            step: 10,
                            showLabels: true
                        )
                    }

                    // ── Bottom Nav Bar (note) ────────────────────────────
                    ShowcaseSection(title: "BottomNavBar") {
                        VStack(alignment: .leading, spacing: .space2) {
                            Text("✅ AdaptiveNavShell is live — this page uses it. On iPhone: bottom tabs. On iPad landscape: collapsible sidebar.")
                                .font(.appBodySmall)
                                .foregroundStyle(Color.typographySecondary)
                            Text("Uses AdaptiveNavShell.swift. Compact = TabView, Regular = icon-rail sidebar.")
                                .font(.appCaptionSmall)
                                .foregroundStyle(Color.typographyMuted)
                        }
                        .padding(.space3)
                        .background(
                            Color.surfacesBaseLowContrast,
                            in: RoundedRectangle(cornerRadius: .radiusMD)
                        )
                    }

                    // ── Page Header (note) ───────────────────────────────
                    ShowcaseSection(title: "PageHeader") {
                        VStack(alignment: .leading, spacing: .space2) {
                            Text("This page uses a large collapsing title via .navigationTitle(). Scroll up to see it collapse to inline.")
                                .font(.appBodySmall)
                                .foregroundStyle(Color.typographySecondary)
                            Text("AppPageHeader is a ViewModifier (.appPageHeader) for toolbar styling. See AppPageHeader.swift.")
                                .font(.appCaptionSmall)
                                .foregroundStyle(Color.typographyMuted)
                        }
                        .padding(.space3)
                        .background(
                            Color.surfacesBaseLowContrast,
                            in: RoundedRectangle(cornerRadius: .radiusMD)
                        )
                    }

                    // ── DateGrid ─────────────────────────────────────────
                    ShowcaseSection(title: "DateGrid — Full week strip") {
                        // Uncontrolled: manages its own selection, defaults to today
                        AppDateGrid()
                    }

                    ShowcaseSection(title: "DateGrid — Controlled selection") {
                        VStack(alignment: .leading, spacing: .space2) {
                            AppDateGrid(selectedDate: $selectedGridDate)
                            Text("Selected: \(selectedGridDate, formatter: mediumDateFormatter)")
                                .font(.appCaptionMedium)
                                .foregroundStyle(Color.typographyMuted)
                        }
                    }

                    ShowcaseSection(title: "DateGrid — Individual cells") {
                        // Five cells centred on today, middle one active
                        HStack(spacing: 0) {
                            ForEach(-2...2, id: \.self) { offset in
                                let d = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                                AppDateItem(date: d, isActive: offset == 0) { _ in }
                            }
                        }
                        .padding(.horizontal, CGFloat.space2)
                        .padding(.vertical, CGFloat.space1)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.surfacesBaseLowContrast)
                        )
                    }

                }
                .padding(.horizontal, .space4)
                .padding(.vertical, .space6)
            }
            .background(Color.surfacesBasePrimary)
            .navigationTitle("Components")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { } label: {
                        Ph.caretLeft.regular
                            .iconSize(.md)
                            .iconColor(.appIconPrimary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: .space2) {
                        Button { } label: {
                            Ph.magnifyingGlass.regular
                                .iconSize(.md)
                                .iconColor(.appIconPrimary)
                        }
                        Button { } label: {
                            Ph.bell.regular
                                .iconSize(.md)
                                .iconColor(.appIconPrimary)
                        }
                    }
                }
            }
        .toastOverlay(isPresented: $showToast) {
            AppToast(message: toastMessage, variant: toastVariant, dismissible: true, onDismiss: {
                withAnimation { showToast = false }
            })
            .id("\(toastMessage)-\(toastVariant)")
        }
    }

    // MARK: - Editor Tab (Apple Notes-style full page)

    @State private var showRawOutput = false
    @State private var showShareSheet = false

    private var editorTab: some View {
        VStack(spacing: 0) {
            // Full-screen markdown editor — no label, no border, no hint
            AppMarkdownEditor(
                text: $editorMarkdown,
                placeholder: "Start typing…",
                minHeight: 200,
                showChrome: false
            )
        }
        .background(Color.surfacesBasePrimary)
        .navigationTitle("Notes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    // Undo action placeholder
                } label: {
                    Ph.arrowCounterClockwise.regular
                        .iconSize(.md)
                        .iconColor(.appIconPrimary)
                }
                .accessibilityLabel("Undo")
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showShareSheet = true
                } label: {
                    Ph.shareNetwork.regular
                        .iconSize(.md)
                        .iconColor(.appIconPrimary)
                }
                .accessibilityLabel("Share")

                Button {
                    showRawOutput.toggle()
                } label: {
                    Ph.code.regular
                        .iconSize(.md)
                        .iconColor(.appIconPrimary)
                }
                .accessibilityLabel("View Raw")

                Button {
                    // Done — dismiss keyboard
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                } label: {
                    Text("Done")
                        .font(.appBodyMediumEm)
                        .foregroundStyle(Color.surfacesBrandInteractive)
                }
            }
        }
        .appBottomSheet(
            isPresented: $showRawOutput,
            detents: [.medium, .large]
        ) {
            VStack(alignment: .leading, spacing: .space3) {
                HStack {
                    Text("Raw Markdown").font(.appTitleSmall)
                    Spacer()
                    Button { showRawOutput = false } label: {
                        Ph.xCircle.fill
                            .iconSize(.md)
                            .foregroundStyle(Color.typographyMuted)
                    }
                }
                ScrollView {
                    Text(editorMarkdown.isEmpty ? "(empty)" : editorMarkdown)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Color.typographySecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("notes.md")
            if let _ = try? editorMarkdown.write(to: tempURL, atomically: true, encoding: .utf8) {
                ShareSheet(activityItems: [tempURL])
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Settings Tab

    private var settingsTab: some View {
        VStack(spacing: .space4) {
            Spacer()
            Ph.gear.regular
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .foregroundStyle(Color.typographyMuted)
            Text("Settings")
                .font(.appTitleSmall)
                .foregroundStyle(Color.typographyPrimary)
            Text("Another tab for AdaptiveNavShell demo.")
                .font(.appBodySmall)
                .foregroundStyle(Color.typographySecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, .space4)
        .frame(maxWidth: .infinity)
        .background(Color.surfacesBasePrimary)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Date Formatter (DateGrid demo)

    private var mediumDateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }

    // MARK: - Sheet List Icon Helper

    @ViewBuilder
    private func sheetListIcon(_ label: String) -> some View {
        switch label {
        case "Favourites": Ph.star.fill.iconSize(.md)
        case "Recent": Ph.clock.regular.iconSize(.md)
        case "Documents": Ph.folder.regular.iconSize(.md)
        case "Photos": Ph.image.regular.iconSize(.md)
        case "Music": Ph.musicNote.regular.iconSize(.md)
        case "Videos": Ph.filmStrip.regular.iconSize(.md)
        case "Books": Ph.bookOpen.regular.iconSize(.md)
        case "Mail": Ph.envelope.regular.iconSize(.md)
        default: Ph.circle.regular.iconSize(.md)
        }
    }
}

#Preview {
    ContentView()
}
