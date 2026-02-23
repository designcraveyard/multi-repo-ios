// NativeComponentStyling.swift
// Centralized style configuration for all native SwiftUI component wrappers.
//
// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  HOW TO USE THIS FILE                                                       ║
// ║                                                                             ║
// ║  Each section below corresponds to one component in Components/Native/.     ║
// ║  To restyle any component:                                                  ║
// ║    1. Find the section (e.g., "MARK: - 6. Progress Loader")                ║
// ║    2. Change the token references in Colors / Layout / Typography           ║
// ║    3. Build — every usage of that component updates automatically           ║
// ║                                                                             ║
// ║  TOKEN QUICK REFERENCE                                                      ║
// ║  Colors  : Color.appSurface*, Color.appText*, Color.appBorder*             ║
// ║  Spacing : CGFloat.space1(4px) … space12(48px)  — 4px grid                ║
// ║  Radius  : CGFloat.radiusXS(4) radiusSM(8) radiusMD(12)                   ║
// ║            radiusLG(16) radiusXL(24) radius2XL(32)                        ║
// ║  Fonts   : Font.appBodyMedium, .appTitleSmall, .appCTAMedium …            ║
// ║                                                                             ║
// ║  RULE: Never hardcode a hex color or a raw point size in this file.        ║
// ║        Every value MUST be a token from DesignTokens.swift.                ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

import SwiftUI

// MARK: - 1. Picker / Dropdown / Select
// Native SwiftUI view : Picker with .pickerStyle(.menu) or .pickerStyle(.wheel)
// Wrapper             : Components/Native/AppNativePicker.swift

enum NativePickerStyling {

    struct Colors {
        // Tint color applied by iOS to:
        //   • the checkmark next to the selected row in .menu style
        //   • the chevron/caret indicator on the trigger button
        //   • the selection highlight ring in .wheel style
        // Change to Color.appSurfaceBrand for an all-black/white brand-colored picker.
        static let tint = Color.appSurfaceBrand

        // Foreground color of the label text shown on the closed picker trigger.
        // This is the text the user reads before opening the menu.
        static let label = Color.appTextPrimary

        // Foreground color of the currently selected option's row text inside
        // the open dropdown. Making this distinct from optionText helps users
        // quickly spot their current selection.
        static let selectedText = Color.appTextBrand

        // Foreground color of all unselected options in the open dropdown list.
        static let optionText = Color.appTextPrimary

        // Background of the floating menu card that appears when the picker opens.
        // Use appSurfaceBasePrimary for a plain white / pure-black card.
        // Use appSurfaceBaseLowContrast (current) for a slightly elevated look.
        static let menuBackground = Color.appSurfaceBaseLowContrast

        // Text/icon color rendered when isDisabled == true is passed to AppNativePicker.
        // The container is also rendered at 0.5 opacity (design system disabled convention).
        static let disabled = Color.appTextMuted

        // 1.5pt border drawn around the trigger container when showError == true.
        // Pair this with the errorText color for a consistent validation pattern.
        static let errorBorder = Color.appBorderError

        // Color of the helper / validation error message shown below the picker.
        static let errorText = Color.appTextError
    }

    struct Layout {
        // Corner radius of the trigger container box that wraps the Picker.
        static let cornerRadius = CGFloat.radiusMD    // 12px

        // Vertical padding inside the trigger container.
        static let paddingV = CGFloat.space2           // 8px

        // Horizontal padding inside the trigger container.
        static let paddingH = CGFloat.space4           // 16px

        // Width of the error-state border stroke in points.
        static let errorBorderWidth: CGFloat = 1.5

        // Width of the default (non-error) border stroke in points.
        static let defaultBorderWidth: CGFloat = 1.0
    }

    struct Typography {
        // Font for the picker trigger label and option rows.
        static let label = Font.appBodyMedium

        // Font for the helper / error text displayed below the picker.
        static let helper = Font.appCaptionMedium
    }
}

// MARK: - 2. Date / Time / DateTime Picker
// Native SwiftUI view : DatePicker with .graphical / .compact / .wheel style
// Wrapper             : Components/Native/AppDateTimePicker.swift

enum NativeDatePickerStyling {

    struct Colors {
        // Accent color applied to:
        //   • Selected day circle in .graphical calendar grid
        //   • The "today" ring indicator
        //   • The spinner drum highlight band in .wheel style
        //   • The disclosure button in .compact style
        // Change to Color.appSurfaceBrand for a monochrome-brand calendar.
        static let tint = Color.appSurfaceBrand

        // Foreground color for the picker label text (the text passed as `label:`).
        // In .compact style this appears to the left of the date button.
        // In .graphical style this is the month/year header.
        static let label = Color.appTextPrimary

        // Background of the entire DatePicker component area.
        // .graphical renders a card; this fills its background.
        // Use appSurfaceBasePrimary for a clean white / pure-black card.
        static let background = Color.appSurfaceBaseLowContrast

        // Color of the selected date numeral text inside the calendar grid.
        // iOS renders this on top of the `tint` circle — should contrast well.
        static let selectedDayText = Color.appTextOnBrandPrimary  // white on indigo

        // Color of day numerals for dates that are NOT selected.
        static let dayText = Color.appTextPrimary

        // Color rendered for day numerals that fall outside the allowed date range
        // (i.e. dates before minimumDate or after maximumDate).
        static let disabledDayText = Color.appTextMuted

        // Foreground color for the weekday column headers (Mo, Tu, We …).
        static let weekdayHeader = Color.appTextSecondary
    }

    struct Layout {
        // Corner radius of the background card rendered in .graphical style.
        static let graphicalCornerRadius = CGFloat.radiusLG    // 16px

        // Vertical spacing between the label and the picker control.
        static let labelSpacing = CGFloat.space2               // 8px
    }

    struct Typography {
        // Font used for the label passed to DatePicker.
        static let label = Font.appBodyMedium

        // Font used for month/year navigation in .graphical style.
        // Note: iOS controls this internally; this token is used for any
        // supplementary Text views you add around the DatePicker.
        static let monthYear = Font.appBodyLargeEm

        // Font for the compact trigger button text (the formatted date string).
        // Note: iOS controls internal rendering; this applies to surrounding labels.
        static let compactDate = Font.appBodyMedium
    }
}

// MARK: - 3. Page Header (Large + Inline)
// Native SwiftUI view : NavigationStack + .toolbar {} modifiers
// Wrapper             : Components/Native/AppPageHeader.swift (ViewModifier)
//
// Apply as:  .modifier(AppPageHeaderModifier(title: "Screen", displayMode: .large))
// Or via:    .appPageHeader(title: "Screen", displayMode: .inline, trailingActions: [...])

enum NativePageHeaderStyling {

    struct Colors {
        // Background fill of the navigation bar area.
        // This is applied via .toolbarBackground(_:for:) on the NavigationStack.
        // Use appSurfaceBasePrimary for a standard white/black nav bar.
        // Use appSurfaceBrand for a bold brand-colored nav bar.
        static let background = Color.appSurfaceBasePrimary

        // Tint color applied to:
        //   • The back button chevron and "Back" text
        //   • All ToolbarItem buttons in the leading and trailing positions
        // Change to Color.appSurfaceAccentPrimary for an accent-colored nav bar.
        static let tint = Color.appTextBrand

        // Color of the large title text (when displayMode == .large).
        // iOS renders the large title using the UINavigationBar appearance;
        // setting foreground on the NavigationStack controls this in SwiftUI.
        static let largeTitle = Color.appTextPrimary

        // Color of the inline (small) title text (when displayMode == .inline).
        static let inlineTitle = Color.appTextPrimary

        // Color of the thin 1px separator line drawn below the nav bar.
        // Set to Color.clear to remove the separator line entirely.
        static let separator = Color.appBorderDefault
    }

    struct Typography {
        // Font used for the large title. iOS scales this automatically;
        // this token is used if you add a custom title view.
        static let largeTitle = Font.appTitleLarge

        // Font used for the inline (collapsed) title.
        static let inlineTitle = Font.appTitleSmall

        // Font applied to ToolbarItem button labels in the trailing slot.
        static let trailingAction = Font.appCTAMedium
    }
}

// MARK: - 4. Bottom Sheet
// Native SwiftUI view : .sheet() + .presentationDetents() + presentation modifiers
// Wrapper             : Components/Native/AppBottomSheet.swift (ViewModifier)
//
// Apply as:
//   .appBottomSheet(isPresented: $showSheet, detents: [.medium, .large]) {
//       MySheetContent()
//   }

enum NativeBottomSheetStyling {

    struct Colors {
        // Fill color of the sheet's background surface.
        // Use appSurfaceBasePrimary for a standard white/black sheet.
        // Use appSurfaceBaseLowContrast for a slightly elevated off-white sheet.
        static let sheetBackground = Color.appSurfaceBasePrimary

        // Color of the drag indicator (the small rounded pill at the top of the sheet).
        // iOS tints this automatically; this value is used for any custom indicator
        // you render yourself inside the sheet content.
        // To control iOS's native indicator color you must use UISheetPresentationController.
        static let dragIndicator = Color.appBorderDefault
    }

    struct Layout {
        // Corner radius of the sheet's top-left and top-right corners.
        // Applied via .presentationCornerRadius(_:).
        static let cornerRadius = CGFloat.radiusXL    // 24px

        // Controls visibility of the native drag indicator pill.
        //   .visible  → always shows the grabber
        //   .hidden   → hides the grabber (use if your sheet has a custom header)
        //   .automatic → system decides based on sheet height
        static let dragIndicatorVisibility: Visibility = .visible

        // Default set of detents offered when none are specified by the caller.
        // .medium = ~50% screen height, .large = ~90% screen height.
        // To add a custom size: Set<PresentationDetent> = [.fraction(0.3), .large]
        static let defaultDetents: Set<PresentationDetent> = [.medium, .large]

        // Inner horizontal padding added around the sheet content area.
        static let contentPaddingH = CGFloat.space4    // 16px

        // Inner vertical padding at the top of the sheet content area.
        static let contentPaddingTop = CGFloat.space3  // 12px
    }
}

// MARK: - 5. Bottom Navigation Bar
// Native SwiftUI view : TabView
// Wrapper             : Components/Native/AppBottomNavBar.swift
//
// IMPORTANT: Call NativeBottomNavStyling.applyAppearance() once in
//            multi_repo_iosApp.swift's init() before any view renders.
//            UITabBar.appearance() must be applied before the first TabView appears.

enum NativeBottomNavStyling {

    struct Colors {
        // Background fill of the tab bar area.
        // This is set via UITabBarAppearance.backgroundColor.
        // Use appSurfaceBasePrimary for the standard white/black system bar.
        static let background = Color.appSurfaceBasePrimary

        // Icon tint for the currently selected (active) tab.
        // This colors the SF Symbol or custom icon in the selected tab item.
        static let activeIcon = Color.appTextBrand

        // Text color of the label beneath the currently selected tab icon.
        static let activeLabel = Color.appTextBrand

        // Icon tint for all unselected (inactive) tab items.
        static let inactiveIcon = Color.appTextMuted

        // Text color of the labels beneath all unselected tab items.
        static let inactiveLabel = Color.appTextMuted

        // Background color of the numeric badge bubble shown on tab icons.
        // Change to Color.appSurfaceErrorSolid for a standard red notification badge.
        static let badge = Color.appSurfaceErrorSolid

        // Text color of the badge numeral (the count shown in the badge bubble).
        static let badgeText = Color.appTextOnBrandPrimary // white on red
    }

    struct Typography {
        // Point size of the tab item label text.
        // UITabBarAppearance requires a raw CGFloat, not a Font token.
        // Equivalent to appCaptionSmall (10pt).
        static let labelSize: CGFloat = 10

        // Font weight for the active tab label (selected state).
        static let activeLabelWeight: UIFont.Weight = .semibold

        // Font weight for inactive tab labels.
        static let inactiveLabelWeight: UIFont.Weight = .regular
    }

    struct Layout {
        // Vertical offset of the tab icon within its cell.
        // Positive values push the icon down; negative values push it up.
        // Leave at 0 for standard system positioning.
        static let iconVerticalOffset: CGFloat = 0
    }

    // Applies UIKit appearance settings to UITabBar.
    // Call ONCE in multi_repo_iosApp.init() before any scene renders.
    static func applyAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Colors.background)

        // Active (selected) tab item styling
        appearance.stackedLayoutAppearance.selected.iconColor =
            UIColor(Colors.activeIcon)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Colors.activeLabel),
            .font: UIFont.systemFont(ofSize: Typography.labelSize,
                                     weight: Typography.activeLabelWeight)
        ]
        appearance.stackedLayoutAppearance.selected.badgeBackgroundColor =
            UIColor(Colors.badge)
        appearance.stackedLayoutAppearance.selected.badgeTextAttributes = [
            .foregroundColor: UIColor(Colors.badgeText)
        ]

        // Inactive tab item styling
        appearance.stackedLayoutAppearance.normal.iconColor =
            UIColor(Colors.inactiveIcon)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Colors.inactiveLabel),
            .font: UIFont.systemFont(ofSize: Typography.labelSize,
                                     weight: Typography.inactiveLabelWeight)
        ]
        appearance.stackedLayoutAppearance.normal.badgeBackgroundColor =
            UIColor(Colors.badge)
        appearance.stackedLayoutAppearance.normal.badgeTextAttributes = [
            .foregroundColor: UIColor(Colors.badgeText)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - 6. Progress Loader (Indefinite + Definite)
// Native SwiftUI view : ProgressView (circular) / ProgressView(value:total:) (linear)
// Wrapper             : Components/Native/AppProgressLoader.swift

enum NativeProgressLoaderStyling {

    struct Colors {
        // The accent color applied to the spinning indicator (indefinite)
        // or the filled portion of the linear progress bar (definite).
        // Change to Color.appSurfaceBrand for a monochrome loader.
        static let tint = Color.appSurfaceBrand

        // Background (unfilled) track color for the linear determinate bar.
        // Note: SwiftUI does not directly expose the track color via .tint().
        // AppProgressLoader draws a custom track underneath the native ProgressView.
        static let track = Color.appSurfaceBaseLowContrast

        // Color of the optional descriptive label rendered below the loader.
        static let label = Color.appTextSecondary
    }

    struct Layout {
        // Scale factor for the circular indefinite spinner.
        // 1.0 = native default size (~20pt diameter).
        // 1.5 = medium prominent loader; 2.0 = large full-screen loader.
        static let scale: CGFloat = 1.0

        // Height of the linear determinate progress bar track.
        static let linearTrackHeight: CGFloat = 6

        // Corner radius of the linear progress bar ends.
        static let linearTrackRadius: CGFloat = 3

        // Vertical gap between the spinner/bar and the optional label text.
        static let labelSpacing = CGFloat.space2    // 8px
    }

    struct Typography {
        // Font for the optional label text displayed below the loader.
        static let label = Font.appBodyMedium
    }
}

// MARK: - 7. Carousel + Carousel Dots
// Native SwiftUI view : TabView with .tabViewStyle(.page) or
//                       ScrollView with .scrollTargetBehavior(.paging)
// Wrapper             : Components/Native/AppCarousel.swift

enum NativeCarouselStyling {

    struct Colors {
        // Fill color of the dot representing the currently visible page.
        // A wider capsule is used for the active dot (see Layout.dotActiveWidth).
        static let dotActive = Color.appSurfaceBrand

        // Fill color of all dots representing pages that are NOT currently visible.
        static let dotInactive = Color.surfacesBaseHighContrast

        // Background of the page indicator row (the row containing all dots).
        // Set to Color.clear (default) to render dots directly on the carousel content.
        static let dotRowBackground = Color.clear
    }

    struct Layout {
        // Height of the fixed-height frame applied to the paged TabView carousel.
        // Change this to match the card or image height your content needs.
        static let pagedHeight: CGFloat = 240

        // Horizontal gap between adjacent cards in the scroll-snap (.scrollSnap) style.
        static let cardSpacing = CGFloat.space3    // 12px

        // Diameter of the inactive dot indicator circles.
        static let dotInactiveWidth: CGFloat = 6
        static let dotHeight: CGFloat = 6

        // Width of the active dot — a wider capsule visually marks the current page.
        static let dotActiveWidth: CGFloat = 18

        // Horizontal gap between adjacent dot indicators.
        static let dotGap = CGFloat.space1         // 4px

        // Vertical gap between the carousel content and the dots row below it.
        static let dotsSpacing = CGFloat.space3    // 12px
    }
}

// MARK: - 8. Context Menu + Popover Menu
// Native SwiftUI views : .contextMenu {} (long-press menu)
//                        .popover(isPresented:) (tap-triggered popover)
// Wrapper              : Components/Native/AppContextMenu.swift

enum NativeContextMenuStyling {

    struct Colors {
        // Text/icon color for standard (non-destructive) menu items.
        // Note: iOS tints .contextMenu items automatically using system colors.
        // This color is used for AppPopoverMenu which renders a custom popover card.
        static let itemText = Color.appTextPrimary

        // Text/icon color for items marked with role: .destructive.
        // iOS renders .contextMenu destructive items in red automatically.
        // AppPopoverMenu uses this explicitly to color its destructive rows.
        static let destructiveText = Color.appTextError

        // Background fill of the AppPopoverMenu card.
        static let background = Color.appSurfaceBasePrimary

        // Color of the 1px divider lines drawn between menu rows in AppPopoverMenu.
        static let rowDivider = Color.appBorderMuted
    }

    struct Layout {
        // Minimum width of the AppPopoverMenu card in points.
        // Prevents the popover from being too narrow for long labels.
        static let minWidth: CGFloat = 180

        // Horizontal padding inside each menu row.
        static let itemPaddingH = CGFloat.space4    // 16px

        // Vertical padding inside each menu row.
        static let itemPaddingV = CGFloat.space3    // 12px

        // Horizontal gap between the icon and the label text within a row.
        static let itemIconSpacing = CGFloat.space2  // 8px

        // Corner radius of the AppPopoverMenu card.
        static let cornerRadius = CGFloat.radiusMD   // 12px
    }

    struct Typography {
        // Font used for menu item labels in AppPopoverMenu.
        static let item = Font.appBodyMedium
    }
}

// MARK: - 9. Action Sheet
// Native SwiftUI view : .confirmationDialog(_:isPresented:titleVisibility:actions:message:)
// Wrapper             : Components/Native/AppActionSheet.swift (ViewModifier)
//
// iOS applies system styling to confirmationDialog — color overrides are limited.
// The primary customization points are:
//   • Marking actions as .destructive (system renders them in red automatically)
//   • Marking the cancel action with .cancel (system styles and positions it)
// No Colors/Layout structs are needed; the design tokens apply only to any
// supplementary views you add around the sheet trigger.

enum NativeActionSheetStyling {

    // Currently a namespace only — confirmationDialog styling is handled by iOS.
    //
    // If you need to match a non-standard brand color scheme:
    //   → Replace .confirmationDialog with a custom sheet containing AppButton rows
    //     styled with NativePickerStyling or your own token set.
    //
    // The AppActionSheetAction type supports three roles:
    //   .default(label)     → standard blue action
    //   .destructive(label) → iOS renders in red
    //   .cancel(label)      → iOS positions at bottom, bold weight

    struct Typography {
        // Font used for any Text views you place in the message: slot.
        // iOS controls the title font; this applies only to supplementary content.
        static let message = Font.appBodyMedium
    }
}

// MARK: - 10. Alert Popup
// Native SwiftUI view : .alert(_:isPresented:actions:message:)
// Wrapper             : Components/Native/AppAlertPopup.swift (ViewModifier)
//
// iOS applies system styling to .alert — background, blur, and title style are fixed.
// Customization is limited to:
//   • Button roles (.destructive renders red, .cancel renders bold)
//   • The message: Text content
// No further token overrides are available for .alert without private API.

enum NativeAlertStyling {

    // Currently a namespace only — alert styling is fully managed by iOS.
    //
    // Design guideline: alerts should have at most two actions.
    //   • One primary action (nil role)
    //   • One cancel action (.cancel role)
    // For multi-action scenarios, use AppActionSheet instead.

    struct Typography {
        // Font for the message Text passed in the message: slot.
        static let message = Font.appBodyMedium
    }
}

// MARK: - 11. Tooltip
// Native SwiftUI view : .popover(isPresented:arrowEdge:content:)
// Wrapper             : Components/Native/AppTooltip.swift
//
// SwiftUI has no dedicated tooltip API on iOS. The .popover modifier is used
// and configured with .presentationCompactAdaptation(.popover) to prevent it
// from expanding to a full sheet on compact size classes.

enum NativeTooltipStyling {

    struct Colors {
        // Background fill of the tooltip bubble.
        // Use a high-contrast color so the tooltip reads clearly against content.
        static let background = Color.appSurfaceInversePrimary  // dark in light mode

        // Text color inside the tooltip. Should contrast with `background`.
        static let text = Color.appTextInversePrimary           // light in light mode
    }

    struct Layout {
        // Corner radius of the tooltip bubble.
        static let cornerRadius = CGFloat.radiusSM    // 8px

        // Horizontal padding inside the tooltip bubble.
        static let paddingH = CGFloat.space3           // 12px

        // Vertical padding inside the tooltip bubble.
        static let paddingV = CGFloat.space2           // 8px

        // Maximum width of the tooltip bubble before text wraps.
        static let maxWidth: CGFloat = 240

        // Default edge from which the tooltip arrow points toward the anchor view.
        // .top → arrow at the top, bubble appears below the anchor.
        // .bottom → arrow at the bottom, bubble appears above the anchor.
        static let defaultArrowEdge: Edge = .top
    }

    struct Typography {
        // Font for the tooltip body text.
        static let content = Font.appBodySmall
    }
}

// MARK: - 12. Color Picker
// Native SwiftUI view : ColorPicker
// Wrapper             : Components/Native/AppColorPicker.swift
//
// SwiftUI's ColorPicker presents the system color wheel sheet.
// Styling options are limited: only the label font/color and the tint
// of the trigger button swatch are configurable through the public API.

enum NativeColorPickerStyling {

    struct Colors {
        // Foreground color of the label text shown next to the color swatch.
        static let label = Color.appTextPrimary

        // Tint applied to interactive elements around the picker trigger.
        // The actual color swatch always shows the currently selected color.
        static let tint = Color.appSurfaceBrand
    }

    struct Typography {
        // Font for the label shown next to the color swatch trigger.
        static let label = Font.appBodyMedium
    }
}

// MARK: - 13. Range Slider
// Native SwiftUI view : Two overlapping Slider views + custom track overlay
// Wrapper             : Components/Native/AppRangeSlider.swift
//
// SwiftUI has no built-in range slider. This implementation uses two standard
// Slider views stacked in a ZStack:
//   • The lower Slider controls the minimum bound
//   • The upper Slider controls the maximum bound
// Both sliders' tracks are hidden via .tint(.clear); a custom active-track
// Rectangle is drawn between the two thumb positions.

enum NativeRangeSliderStyling {

    struct Colors {
        // Fill color of the active track segment (the portion between the two thumbs).
        static let trackActive = Color.appSurfaceBrand

        // Fill color of the inactive track segments (left of lower thumb and
        // right of upper thumb).
        static let trackBackground = Color.appSurfaceBaseLowContrast

        // Fill color of the thumb circles for both the lower and upper handles.
        // Note: SwiftUI's Slider uses a system white thumb that cannot be recolored
        // without a custom gesture approach. This token is reserved for future use
        // if the implementation is upgraded to a fully custom drag gesture slider.
        static let thumb = Color.appSurfaceBasePrimary

        // Shadow/border around each thumb to make it pop against the track.
        static let thumbShadow = Color.appBorderDefault

        // Optional label text color for min/max bound labels rendered below the slider.
        static let label = Color.appTextMuted
    }

    struct Layout {
        // Height of the slider track bar.
        static let trackHeight: CGFloat = 4

        // Corner radius applied to the track bar ends (creates pill shape).
        static let trackCornerRadius: CGFloat = 2

        // Total height of the slider component including thumb hit area.
        // Must be at least 44pt to satisfy accessibility minimum touch target.
        static let totalHeight: CGFloat = 44

        // Diameter of the thumb circles (informational — set by system on native Slider).
        static let thumbDiameter: CGFloat = 24

        // Vertical gap between the track and optional min/max label text.
        static let labelSpacing = CGFloat.space1  // 4px
    }

    struct Typography {
        // Font for optional min / max bound labels rendered below the slider.
        static let boundLabel = Font.appCaptionSmall
    }
}
