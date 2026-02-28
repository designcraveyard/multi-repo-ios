// AppDateGrid.swift
// Figma source: bubbles-kit
//   DateItem (cell) → node 93:4399
//   DateGrid (strip) → node 95:2791
//
// Composed of two public types:
//   AppDateItem — single day cell, default / active / today states
//   AppDateGrid — horizontally scrollable date strip with week paging and managed selection
//
// Scroll behaviour (Outlook-style):
//   • The strip is a TabView in page mode — each page is one full week.
//   • Swiping to a new week automatically moves the selection to the same weekday.
//   • A light haptic fires on each week change.
//   • Today's cell always shows a 4 px brand-colour dot regardless of selection.
//
// Usage:
//   AppDateGrid()                                           // uncontrolled, today selected
//   AppDateGrid(onSelect: { date in … })                   // uncontrolled + callback
//   AppDateGrid(anchorDate: Date(), selectedDate: $sel) { date in … }  // controlled

import SwiftUI

// MARK: - Day abbreviation helpers

private let dayAbbreviations = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

private func dayAbbr(for date: Date) -> String {
    let weekday = Calendar.current.component(.weekday, from: date) - 1
    return dayAbbreviations[weekday]
}

private func formattedDay(_ date: Date) -> String {
    String(format: "%02d", Calendar.current.component(.day, from: date))
}

private func isSameDay(_ a: Date, _ b: Date) -> Bool {
    Calendar.current.isDate(a, inSameDayAs: b)
}

// MARK: - AppDateItem

/// Single day cell — day abbreviation stacked above the numeric date, with an optional today dot.
///
/// - Default: muted text on a transparent background.
/// - Active:  white card (`surfacesBasePrimary`) with Elevation-1 drop shadow;
///            date number in `typographyPrimary` at medium weight.
/// - Today:   4 px dot below the number — brand colour when inactive,
///            `typographyPrimary` (white on card) when active.
///
/// Figma: node 93:4399
public struct AppDateItem: View {

    // MARK: Props

    let date: Date
    let isActive: Bool
    let isDisabled: Bool
    let onSelect: (Date) -> Void

    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    public init(
        date: Date,
        isActive: Bool = false,
        isDisabled: Bool = false,
        onSelect: @escaping (Date) -> Void
    ) {
        self.date = date
        self.isActive = isActive
        self.isDisabled = isDisabled
        self.onSelect = onSelect
    }

    // MARK: Body

    public var body: some View {
        VStack(spacing: 2) { // Spacings/Micro = 2px
            // --- Day abbreviation: Badge/Medium — 10px semibold, always muted
            Text(dayAbbr(for: date))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.typographyMuted)
                .lineLimit(1)

            // --- Numeric date: Body/Large (default) or Body/LargeEmphasized (active)
            Text(formattedDay(date))
                .font(.system(size: 16, weight: isActive ? .medium : .regular))
                .foregroundStyle(isActive ? Color.typographyPrimary : Color.typographyMuted)
                .lineLimit(1)

            // --- Today indicator dot — always reserves space to keep all cells the same height.
            //     Brand colour when today+inactive; primary (white on card) when today+active.
            Circle()
                .fill(isActive ? Color.typographyPrimary : Color.surfacesBrandInteractive)
                .frame(width: 4, height: 4)
                .padding(.top, 2)
                .opacity(isToday ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .padding(CGFloat.space2) // Spacings/Small = 8px
        .background(backgroundShape)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isDisabled else { return }
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.prepare()
            gen.impactOccurred()
            onSelect(date)
        }
        .opacity(isDisabled ? 0.5 : 1.0)
        .allowsHitTesting(!isDisabled)
        .animation(.easeOut(duration: 0.15), value: isActive)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(dayAbbr(for: date)) \(formattedDay(date))" +
            "\(isActive ? ", selected" : "")" +
            "\(isToday ? ", today" : "")"
        )
        .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: Background

    /// Active: white card with Elevation-1 shadow.
    @ViewBuilder
    private var backgroundShape: some View {
        if isActive {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.surfacesBasePrimary)
                .shadow(color: Color.surfacesBaseHighContrast.opacity(0.6), radius: 8, x: 0, y: 2)
        } else {
            Color.clear
        }
    }
}

// MARK: - AppDateGrid

/// Horizontally paging week date selector (Outlook-style).
///
/// Uses `TabView(.page)` for reliable paging — Apple's first-party paging component
/// handles initial positioning, gesture disambiguation, and snap behaviour out of the box.
///
/// Swiping to a new week auto-selects the same weekday and fires a light haptic.
/// Today's cell always shows its indicator dot regardless of selection state.
///
/// Selection is self-managed (defaults to today) unless `selectedDate` binding is provided.
/// The strip spans ±52 weeks (±1 year) from the `anchorDate`'s week; page 0 = anchor week.
///
/// Figma: node 95:2791
public struct AppDateGrid: View {

    // MARK: Props

    let anchorDate: Date
    @Binding var selectedDate: Date
    let onSelect: ((Date) -> Void)?
    let startOfWeek: Int

    // MARK: State

    @State private var internalSelected: Date
    /// The week offset of the currently visible page (0 = anchor week).
    /// TabView(selection:) respects the initial value, so page 0 shows immediately.
    @State private var currentPage: Int = 0
    private let isControlled: Bool

    private var activeDate: Date {
        isControlled ? selectedDate : internalSelected
    }

    // MARK: Init (uncontrolled)

    /// Creates an uncontrolled `AppDateGrid` that manages its own selection state.
    public init(
        anchorDate: Date = Date(),
        onSelect: ((Date) -> Void)? = nil,
        startOfWeek: Int = 1
    ) {
        self.anchorDate = anchorDate
        self._selectedDate = .constant(Date()) // unused — internal state overrides
        self.onSelect = onSelect
        self.startOfWeek = startOfWeek
        self._internalSelected = State(initialValue: Calendar.current.startOfDay(for: Date()))
        self.isControlled = false
    }

    // MARK: Init (controlled)

    /// Creates a controlled `AppDateGrid` driven by an external `Binding<Date>`.
    public init(
        anchorDate: Date = Date(),
        selectedDate: Binding<Date>,
        onSelect: ((Date) -> Void)? = nil,
        startOfWeek: Int = 1
    ) {
        self.anchorDate = anchorDate
        self._selectedDate = selectedDate
        self.onSelect = onSelect
        self.startOfWeek = startOfWeek
        self._internalSelected = State(initialValue: selectedDate.wrappedValue)
        self.isControlled = true
    }

    // MARK: Body

    public var body: some View {
        TabView(selection: $currentPage) {
            ForEach(-52...52, id: \.self) { weekOffset in
                weekRow(for: weekOffset)
                    .tag(weekOffset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 76) // day-abbr (12) + date (20) + dot (6) + spacing (4) + cell padding (16) + row padding (8) + shadow room (10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.surfacesBaseLowContrast)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onChange(of: currentPage) { _, newOffset in
            handleWeekChange(to: newOffset)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Week date selector")
    }

    // MARK: Week row

    /// One full-width page of 7 `AppDateItem` cells.
    @ViewBuilder
    private func weekRow(for offset: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(datesForWeek(offset), id: \.self) { day in
                AppDateItem(
                    date: day,
                    isActive: isSameDay(day, activeDate)
                ) { picked in
                    if !isControlled { internalSelected = picked }
                    onSelect?(picked)
                }
            }
        }
        .padding(.horizontal, CGFloat.space2) // Dimensions/2 = 8px
        .padding(.vertical, CGFloat.space1)   // Dimensions/1 = 4px
    }

    // MARK: Week change handler

    /// When the user scrolls to a new week, moves selection to the same weekday in that week
    /// and fires a light haptic — unless the current selection is already in that week.
    private func handleWeekChange(to offset: Int) {
        let weekDays = datesForWeek(offset)
        // If the selected date is already in this week, nothing to do.
        guard !weekDays.contains(where: { isSameDay($0, activeDate) }) else { return }

        // Find the day in the new week whose weekday matches the current selection.
        let targetWeekday = Calendar.current.component(.weekday, from: activeDate)
        guard let matchDay = weekDays.first(where: {
            Calendar.current.component(.weekday, from: $0) == targetWeekday
        }) else { return }

        if !isControlled { internalSelected = matchDay }
        onSelect?(matchDay)

        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.prepare()
        gen.impactOccurred()
    }

    // MARK: Date helpers

    /// Returns the 7 dates for the week at `offset` weeks from the anchor date's week.
    private func datesForWeek(_ offset: Int) -> [Date] {
        var cal = Calendar.current
        cal.firstWeekday = startOfWeek
        guard
            let anchorWeekStart = cal.dateInterval(of: .weekOfYear, for: anchorDate)?.start,
            let weekStart = cal.date(byAdding: .weekOfYear, value: offset, to: anchorWeekStart)
        else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: weekStart) }
    }
}

// MARK: - Preview

#Preview("DateGrid — Default") {
    VStack(spacing: CGFloat.space6) {

        Text("Swipe left/right to navigate weeks (same weekday auto-selected)")
            .font(.appCaptionMedium)
            .foregroundStyle(Color.typographyMuted)

        AppDateGrid()

        Text("Individual cells")
            .font(.appCaptionMedium)
            .foregroundStyle(Color.typographyMuted)

        HStack(spacing: 0) {
            let dates: [Date] = (0..<7).map {
                Calendar.current.date(byAdding: .day, value: $0 - 3, to: Date())!
            }
            ForEach(dates, id: \.self) { d in
                AppDateItem(date: d, isActive: Calendar.current.isDateInToday(d)) { _ in }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.surfacesBaseLowContrast)
        )
    }
    .padding(.space4)
    .background(Color.surfacesBasePrimary)
}
