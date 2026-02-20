import SwiftUI
import PhosphorSwift

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

// MARK: - Component Showcase

struct ContentView: View {
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
    @State private var toastVariant: AppToastVariant = .success
    @State private var toastMessage = ""

    // InputField
    @State private var name = ""
    @State private var email = "user@example"
    @State private var bio = ""

    var body: some View {
        NavigationStack {
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
                                label: isLoading ? "Loading…" : "Tap to Load",
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
                                        variant: .chipTabs,
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
                    ShowcaseSection(title: "Toast — All variants") {
                        VStack(spacing: .space3) {
                            AppToast(variant: .default, message: "Settings saved", dismissible: true)
                            AppToast(variant: .success, message: "Upload complete!", description: "Your file is ready to share.")
                            AppToast(variant: .warning, message: "Connection unstable", actionLabel: "Retry") {}
                            AppToast(variant: .error,   message: "Failed to save", description: "Check your connection.", dismissible: true)
                            AppToast(variant: .info,    message: "New update available", actionLabel: "Update now") {}
                        }
                    }

                    ShowcaseSection(title: "Toast — Live trigger") {
                        HScrollRow {
                            HStack(spacing: .space2) {
                                ForEach([
                                    ("Default", AppToastVariant.default),
                                    ("Success", AppToastVariant.success),
                                    ("Error",   AppToastVariant.error),
                                ], id: \.0) { label, variant in
                                    AppButton(label: label, variant: .secondary, size: .sm) {
                                        toastVariant = variant
                                        toastMessage = "\(label) notification"
                                        withAnimation { showToast = true }
                                    }
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

                }
                .padding(.horizontal, .space4)
                .padding(.vertical, .space6)
            }
            .background(Color.surfacesBasePrimary)
            .navigationTitle("Component Showcase")
            .navigationBarTitleDisplayMode(.large)
        }
        .toastOverlay(isPresented: $showToast) {
            AppToast(variant: toastVariant, message: toastMessage, dismissible: true) {
                withAnimation { showToast = false }
            }
        }
    }
}

#Preview {
    ContentView()
}
