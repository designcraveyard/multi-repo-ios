import SwiftUI

// MARK: - Type Matchup Card View
// Shows weaknesses, resistances, and immunities for a Pokémon.

struct TypeMatchupCardView: View {
    let data: TypeMatchupCardData

    var body: some View {
        VStack(alignment: .leading, spacing: .space3) {
            // Header
            HStack {
                Text("Type Matchup")
                    .font(.appCaptionMedium)
                    .foregroundStyle(Color.typographyMuted)
                    .tracking(0.5)
                Spacer()
                Text(data.pokemon.capitalized)
                    .font(.appBodySmall)
                    .foregroundStyle(Color.typographySecondary)
            }

            // Weaknesses
            if !data.weaknesses.isEmpty {
                matchupSection(
                    title: "Weak to",
                    color: Color.appSurfaceErrorSolid.opacity(0.12),
                    textColor: Color.appSurfaceErrorSolid
                ) {
                    ForEach(data.weaknesses, id: \.type) { item in
                        typeMultiplierBadge(item, highlightColor: Color.appSurfaceErrorSolid.opacity(0.18))
                    }
                }
            }

            // Resistances
            if !data.resistances.isEmpty {
                matchupSection(
                    title: "Resists",
                    color: Color.appSurfaceSuccessSolid.opacity(0.12),
                    textColor: Color.appSurfaceSuccessSolid
                ) {
                    ForEach(data.resistances, id: \.type) { item in
                        typeMultiplierBadge(item, highlightColor: Color.appSurfaceSuccessSolid.opacity(0.18))
                    }
                }
            }

            // Immunities
            if !data.immunities.isEmpty {
                matchupSection(
                    title: "Immune to",
                    color: Color.surfacesBaseLowContrast,
                    textColor: Color.typographySecondary
                ) {
                    ForEach(data.immunities, id: \.self) { type in
                        Text(type.capitalized)
                            .font(.appCaptionSmall)
                            .foregroundStyle(Color.typographySecondary)
                            .padding(.horizontal, .space2)
                            .padding(.vertical, 3)
                            .background(typeColor(type).opacity(0.25), in: Capsule())
                    }
                }
            }
        }
        .padding(.space3)
        .background(
            RoundedRectangle(cornerRadius: .radiusLG)
                .fill(Color.surfacesBasePrimary)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLG)
                .strokeBorder(Color.borderDefault, lineWidth: 1)
        )
        .frame(maxWidth: 320)
    }

    // MARK: - Section

    @ViewBuilder
    private func matchupSection<Content: View>(
        title: String,
        color: Color,
        textColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: .space2) {
            Text(title)
                .font(.appCaptionSmall)
                .foregroundStyle(textColor)

            FlowLayout(spacing: 4) {
                content()
            }
        }
        .padding(.space2)
        .background(color, in: RoundedRectangle(cornerRadius: .radiusSM))
    }

    @ViewBuilder
    private func typeMultiplierBadge(_ item: TypeMultiplier, highlightColor: Color) -> some View {
        HStack(spacing: 3) {
            Text(item.type.capitalized)
                .font(.appCaptionSmall)
                .foregroundStyle(.white)

            Text(multiplierLabel(item.multiplier))
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, .space2)
        .padding(.vertical, 3)
        .background(typeColor(item.type), in: Capsule())
    }

    private func multiplierLabel(_ value: Double) -> String {
        if value == Double(Int(value)) {
            return "×\(Int(value))"
        }
        return "×\(value)"
    }
}

// MARK: - Flow Layout (wrapping HStack)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
