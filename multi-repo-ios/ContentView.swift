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

// MARK: - Component Showcase

struct ContentView: View {
    @State private var isLoading = false

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
                        HStack(spacing: 10) {
                            AppButton(label: "Large",  variant: .primary, size: .lg) {}
                            AppButton(label: "Medium", variant: .primary, size: .md) {}
                            AppButton(label: "Small",  variant: .primary, size: .sm) {}
                            Spacer()
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
                        HStack(spacing: .space3) {
                            AppIconButton(icon: AnyView(Ph.heart.regular),     label: "Like",    variant: .primary)     {}
                            AppIconButton(icon: AnyView(Ph.bookmark.regular),  label: "Save",    variant: .secondary)   {}
                            AppIconButton(icon: AnyView(Ph.share.regular),     label: "Share",   variant: .tertiary)    {}
                            AppIconButton(icon: AnyView(Ph.dotsThree.regular), label: "More",    variant: .quarternary) {}
                            AppIconButton(icon: AnyView(Ph.check.regular),     label: "Confirm", variant: .success)     {}
                            AppIconButton(icon: AnyView(Ph.trash.regular),     label: "Delete",  variant: .danger)      {}
                            Spacer()
                        }
                    }

                    // ── IconButton: Sizes ──────────────────────────────────
                    ShowcaseSection(title: "IconButton — Sizes") {
                        HStack(spacing: .space3) {
                            AppIconButton(icon: AnyView(Ph.star.regular), label: "Favourite", variant: .primary, size: .lg) {}
                            AppIconButton(icon: AnyView(Ph.star.regular), label: "Favourite", variant: .primary, size: .md) {}
                            AppIconButton(icon: AnyView(Ph.star.regular), label: "Favourite", variant: .primary, size: .sm) {}
                            Spacer()
                        }
                    }

                    // ── IconButton: States ─────────────────────────────────
                    ShowcaseSection(title: "IconButton — States") {
                        HStack(spacing: .space3) {
                            AppIconButton(icon: AnyView(Ph.heart.regular), label: "Loading",  variant: .primary,  isLoading: true)  {}
                            AppIconButton(icon: AnyView(Ph.heart.regular), label: "Disabled", variant: .primary,  isDisabled: true) {}
                            AppIconButton(icon: AnyView(Ph.trash.regular), label: "Disabled", variant: .danger,   isDisabled: true) {}
                            AppIconButton(icon: AnyView(Ph.share.regular), label: "Disabled", variant: .tertiary, isDisabled: true) {}
                            Spacer()
                        }
                    }

                    // ── Icons: Sizes ──────────────────────────────────────
                    ShowcaseSection(title: "Icons — Sizes") {
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
                            Spacer()
                        }
                    }

                    // ── Icons: Weights ────────────────────────────────────
                    ShowcaseSection(title: "Icons — Weights") {
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
                            Spacer()
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
    }
}

#Preview {
    ContentView()
}
