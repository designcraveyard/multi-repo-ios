// AppThumbnail.swift
// Figma source: bubbles-kit › node 82:1235 "Thumbnail"
//
// Axes: Sizes(xs/sm/md/lg/xl/xxl) × Rounded(Off/On) = 12
//
// Usage:
//   AppThumbnail(size: .md)                                   // placeholder silhouette
//   AppThumbnail(url: URL(string: "https://…"), size: .lg)    // async remote image
//   AppThumbnail(size: .xl, rounded: true) { Text("AB") }    // initials fallback

import SwiftUI

// MARK: - Types

public enum AppThumbnailSize {
    case xs   // 32pt
    case sm   // 40pt
    case md   // 48pt
    case lg   // 64pt
    case xl   // 80pt
    case xxl  // 96pt
}

// MARK: - Size Spec

private extension AppThumbnailSize {
    var points: CGFloat {
        switch self {
        case .xs:  return 32
        case .sm:  return 40
        case .md:  return 48
        case .lg:  return 64
        case .xl:  return 80
        case .xxl: return 96
        }
    }

    var cornerRadius: CGFloat {
        // Mirrors --radius-sm token (8pt on mobile)
        return CGFloat.radiusSM
    }

    var placeholderIconSize: CGFloat {
        return points * 0.6
    }
}

// MARK: - AppThumbnail

public struct AppThumbnail<FallbackContent: View>: View {

    let url: URL?
    let image: Image?
    let size: AppThumbnailSize
    let rounded: Bool
    let accessibilityLabel: String
    let fallback: () -> FallbackContent

    // Remote-image load state
    @State private var loadedImage: UIImage? = nil
    @State private var loadFailed: Bool = false

    // ── Initialisers ──────────────────────────────────────────────────────────

    public init(
        url: URL? = nil,
        image: Image? = nil,
        size: AppThumbnailSize = .md,
        rounded: Bool = false,
        accessibilityLabel: String = "",
        @ViewBuilder fallback: @escaping () -> FallbackContent
    ) {
        self.url = url
        self.image = image
        self.size = size
        self.rounded = rounded
        self.accessibilityLabel = accessibilityLabel
        self.fallback = fallback
    }

    // ── Body ─────────────────────────────────────────────────────────────────

    public var body: some View {
        let pts = size.points

        ZStack {
            if let img = image {
                img
                    .resizable()
                    .scaledToFill()
            } else if let loaded = loadedImage {
                Image(uiImage: loaded)
                    .resizable()
                    .scaledToFill()
            } else {
                // Fallback slot or silhouette placeholder
                Color.surfacesBaseLowContrast
                fallbackView
            }
        }
        .frame(width: pts, height: pts)
        .clipShape(clipShapeForRounded)
        .accessibilityLabel(accessibilityLabel)
        .task(id: url?.absoluteString) {
            await loadRemoteImage()
        }
    }

    // ── Fallback view ─────────────────────────────────────────────────────────

    @ViewBuilder
    private var fallbackView: some View {
        if FallbackContent.self == EmptyView.self {
            silhouettePlaceholder
        } else {
            fallback()
                .font(fallbackFont)
                .foregroundStyle(Color.typographySecondary)
        }
    }

    private var fallbackFont: Font {
        switch size {
        case .xs, .sm: return .appCaptionSmall
        case .md, .lg: return .appCaptionMedium
        case .xl, .xxl: return .appBodySmall
        }
    }

    @ViewBuilder
    private var silhouettePlaceholder: some View {
        let iconPts = size.placeholderIconSize
        Image(systemName: "person.fill")
            .resizable()
            .scaledToFit()
            .frame(width: iconPts, height: iconPts)
            .foregroundStyle(Color.typographyMuted)
    }

    // ── Shape helper ──────────────────────────────────────────────────────────

    private var clipShapeForRounded: AnyShape {
        if rounded {
            AnyShape(Circle())
        } else {
            AnyShape(RoundedRectangle(cornerRadius: size.cornerRadius))
        }
    }

    // ── Async image loader ────────────────────────────────────────────────────

    private func loadRemoteImage() async {
        guard let url, loadedImage == nil, !loadFailed else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let ui = UIImage(data: data) {
                await MainActor.run { loadedImage = ui }
            } else {
                await MainActor.run { loadFailed = true }
            }
        } catch {
            await MainActor.run { loadFailed = true }
        }
    }
}

// MARK: - Convenience init (no fallback slot)

extension AppThumbnail where FallbackContent == EmptyView {
    public init(
        url: URL? = nil,
        image: Image? = nil,
        size: AppThumbnailSize = .md,
        rounded: Bool = false,
        accessibilityLabel: String = ""
    ) {
        self.init(
            url: url,
            image: image,
            size: size,
            rounded: rounded,
            accessibilityLabel: accessibilityLabel,
            fallback: { EmptyView() }
        )
    }
}

// MARK: - AnyShape helper

private struct AnyShape: Shape {
    private let _path: (CGRect) -> Path
    init<S: Shape>(_ shape: S) { _path = { rect in shape.path(in: rect) } }
    func path(in rect: CGRect) -> Path { _path(rect) }
}

// MARK: - Preview

#Preview("Thumbnail Sizes") {
    VStack(spacing: CGFloat.space4) {

        Text("Square (Rounded: Off)").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
        HStack(spacing: CGFloat.space3) {
            AppThumbnail(size: .xs)
            AppThumbnail(size: .sm)
            AppThumbnail(size: .md)
            AppThumbnail(size: .lg)
            AppThumbnail(size: .xl)
            AppThumbnail(size: .xxl)
        }

        Text("Circular (Rounded: On)").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
        HStack(spacing: CGFloat.space3) {
            AppThumbnail(size: .xs,  rounded: true)
            AppThumbnail(size: .sm,  rounded: true)
            AppThumbnail(size: .md,  rounded: true)
            AppThumbnail(size: .lg,  rounded: true)
            AppThumbnail(size: .xl,  rounded: true)
            AppThumbnail(size: .xxl, rounded: true)
        }

        Text("With initials fallback").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
        HStack(spacing: CGFloat.space3) {
            AppThumbnail(size: .lg, rounded: true) { Text("AB") }
            AppThumbnail(size: .xl, rounded: true) { Text("JD") }
            AppThumbnail(size: .xxl, rounded: false) { Text("MK") }
        }

        Text("With local image").font(.appCaptionMedium).foregroundStyle(Color.typographyMuted)
        AppThumbnail(
            image: Image(systemName: "photo"),
            size: .xxl,
            rounded: true,
            accessibilityLabel: "Profile photo"
        )
    }
    .padding(CGFloat.space4)
    .background(Color.surfacesBasePrimary)
}
