// AppCarousel.swift
// Style source: NativeComponentStyling.swift › NativeCarouselStyling
//
// Two carousel styles supported:
//   .paged     — Full-width pages via TabView + .tabViewStyle(.page)
//   .scrollSnap — Card-width snap via ScrollView + .scrollTargetBehavior(.paging)
//
// Usage:
//   struct Card: Identifiable { let id: Int; let color: Color }
//   let cards = [Card(id: 0, color: .red), Card(id: 1, color: .blue)]
//
//   // Full-width paged:
//   AppCarousel(items: cards) { card in
//       RoundedRectangle(cornerRadius: 12).fill(card.color)
//   }
//
//   // Card-width snap (showDots: false):
//   AppCarousel(items: cards, style: .scrollSnap, showDots: false) { card in
//       RoundedRectangle(cornerRadius: 12).fill(card.color).frame(width: 280)
//   }

import SwiftUI

// MARK: - Carousel Style

/// Controls the layout and interaction mode of the carousel.
public enum AppCarouselStyle {
    /// Full-width swiping pages using TabView with .page style.
    case paged
    /// Card-width snapping using ScrollView with .scrollTargetBehavior(.paging).
    case scrollSnap
}

// MARK: - AppCarousel

/// A styled carousel component with animated dot indicators.
/// All visual tokens come from `NativeCarouselStyling` in `NativeComponentStyling.swift`.
public struct AppCarousel<Item: Identifiable, Content: View>: View {

    // MARK: - Properties

    let items: [Item]
    var style: AppCarouselStyle = .paged
    var showDots: Bool = true
    @ViewBuilder let content: (Item) -> Content

    @State private var currentPage: Int = 0

    // MARK: - Body

    public var body: some View {
        VStack(spacing: NativeCarouselStyling.Layout.dotsSpacing) {
            switch style {
            case .paged:
                TabView(selection: $currentPage) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        content(item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: NativeCarouselStyling.Layout.pagedHeight)

            case .scrollSnap:
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: NativeCarouselStyling.Layout.cardSpacing) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            content(item)
                                .containerRelativeFrame(.horizontal)
                                .id(index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: Binding(
                    get: { currentPage },
                    set: { currentPage = $0 ?? 0 }
                ))
            }

            if showDots && items.count > 1 {
                AppCarouselDots(count: items.count, currentPage: $currentPage)
            }
        }
    }
}

// MARK: - AppCarouselDots

/// Animated pill-style dot indicators for AppCarousel.
/// The active dot expands to a wider capsule; inactive dots are small circles.
public struct AppCarouselDots: View {

    let count: Int
    @Binding var currentPage: Int

    public var body: some View {
        HStack(spacing: NativeCarouselStyling.Layout.dotGap) {
            ForEach(0..<count, id: \.self) { index in
                let isActive = index == currentPage
                Capsule()
                    .fill(isActive
                        ? NativeCarouselStyling.Colors.dotActive
                        : NativeCarouselStyling.Colors.dotInactive)
                    .frame(
                        width: isActive
                            ? NativeCarouselStyling.Layout.dotActiveWidth
                            : NativeCarouselStyling.Layout.dotInactiveWidth,
                        height: NativeCarouselStyling.Layout.dotHeight
                    )
                    .animation(.spring(duration: 0.3), value: currentPage)
                    // Tapping a dot jumps to that page
                    .onTapGesture { currentPage = index }
            }
        }
        .padding(NativeCarouselStyling.Layout.dotGap)
        .background(NativeCarouselStyling.Colors.dotRowBackground)
    }
}

// MARK: - Preview

private struct PreviewCard: Identifiable {
    let id: Int
    let color: Color
}

#Preview {
    let cards = [
        PreviewCard(id: 0, color: Color.appSurfaceAccentPrimary),
        PreviewCard(id: 1, color: Color.appSurfaceSuccessSolid),
        PreviewCard(id: 2, color: Color.appSurfaceErrorSolid),
    ]

    VStack(spacing: 40) {
        Text("Paged").font(.appBodyMediumEm)
        AppCarousel(items: cards) { card in
            RoundedRectangle(cornerRadius: .radiusLG)
                .fill(card.color)
                .padding(.horizontal, .space4)
        }

        Text("Scroll Snap").font(.appBodyMediumEm)
        AppCarousel(items: cards, style: .scrollSnap) { card in
            RoundedRectangle(cornerRadius: .radiusLG)
                .fill(card.color)
                .frame(width: 280, height: 160)
        }
    }
    .padding()
}
