/**
 * PhosphorSlim.swift
 *
 * Lightweight drop-in replacement for PhosphorSwift.
 * Contains only the icons actually used in this project (~45 icons vs 9,108).
 * Assets live in Resources/PhosphorIcons.xcassets.
 *
 * API is identical to PhosphorSwift:
 *   Ph.house.regular          → Image
 *   Ph.heart.fill.iconSize(.lg)
 *   Ph.warning.fill.iconColor(.appError)
 *
 * To add a new icon, run: /add-phosphor-icon <name>
 */

import SwiftUI

// MARK: - Ph enum (drop-in replacement)

public enum Ph: String, CaseIterable, Identifiable {
    public var id: Self { self }

    case arrowCounterClockwise = "arrow-counter-clockwise"
    case arrowRight = "arrow-right"
    case bell = "bell"
    case bookOpen = "book-open"
    case bookmark = "bookmark"
    case caretDown = "caret-down"
    case caretLeft = "caret-left"
    case caretRight = "caret-right"
    case check = "check"
    case checkCircle = "check-circle"
    case circle = "circle"
    case clock = "clock"
    case code = "code"
    case copy = "copy"
    case dotsThree = "dots-three"
    case dotsThreeCircle = "dots-three-circle"
    case envelope = "envelope"
    case envelopeSimple = "envelope-simple"
    case eye = "eye"
    case filmStrip = "film-strip"
    case folder = "folder"
    case funnel = "funnel"
    case gear = "gear"
    case googleLogo = "google-logo"
    case heart = "heart"
    case house = "house"
    case image = "image"
    case info = "info"
    case magnifyingGlass = "magnifying-glass"
    case microphone = "microphone"
    case musicNote = "music-note"
    case paperPlaneRight = "paper-plane-right"
    case pencilSimple = "pencil-simple"
    case phone = "phone"
    case plus = "plus"
    case share = "share"
    case shareNetwork = "share-network"
    case star = "star"
    case stop = "stop"
    case trash = "trash"
    case user = "user"
    case warning = "warning"
    case warningCircle = "warning-circle"
    case x = "x"
    case xCircle = "x-circle"
}

// MARK: - Weight variants

public extension Ph {
    enum IconWeight: String, CaseIterable, Identifiable {
        public var id: Self { self }

        case regular
        case thin
        case light
        case bold
        case fill
        case duotone
    }

    var regular: Image { Ph.icon(self.rawValue) }
    var thin: Image { Ph.icon("\(self.rawValue)-thin") }
    var light: Image { Ph.icon("\(self.rawValue)-light") }
    var bold: Image { Ph.icon("\(self.rawValue)-bold") }
    var fill: Image { Ph.icon("\(self.rawValue)-fill") }
    var duotone: Image { Ph.icon("\(self.rawValue)-duotone") }

    func weight(_ weight: IconWeight) -> Image {
        switch weight {
        case .regular: return self.regular
        case .thin: return self.thin
        case .light: return self.light
        case .bold: return self.bold
        case .fill: return self.fill
        case .duotone: return self.duotone
        }
    }

    private static func icon(_ name: String) -> Image {
        Image(name, bundle: .main)
            .interpolation(.medium)
            .resizable()
    }
}

// MARK: - Color blending (matches PhosphorSwift's .color() modifier)

struct ColorBlended: ViewModifier {
    fileprivate var color: Color

    public func body(content: Content) -> some View {
        VStack {
            ZStack {
                content
                self.color.blendMode(.sourceAtop)
            }
            .drawingGroup(opaque: false)
        }
    }
}

public extension View {
    func color(_ color: Color) -> some View {
        modifier(ColorBlended(color: color))
    }
}
