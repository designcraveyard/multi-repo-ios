import SwiftUI

// MARK: - Team Card View
// Displays a 6-member Pokémon team in a grid with coverage analysis.

struct TeamCardView: View {
    let data: TeamCardData

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: .space3) {
            Text("Your Team")
                .font(.appCaptionMedium)
                .foregroundStyle(Color.typographyMuted)
                .tracking(0.5)

            // 3-column grid of members
            LazyVGrid(columns: columns, spacing: .space3) {
                ForEach(data.team) { member in
                    memberCell(member)
                }
            }

            // Coverage footer
            if !data.coverage.uncovered.isEmpty || !data.coverage.doubleResisted.isEmpty {
                AppDivider(type: .row)
                coverageSection
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

    // MARK: - Member Cell

    @ViewBuilder
    private func memberCell(_ member: TeamMember) -> some View {
        VStack(spacing: 4) {
            AsyncImage(url: URL(string: member.sprite)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure, .empty:
                    Color.surfacesBaseLowContrast
                @unknown default:
                    Color.surfacesBaseLowContrast
                }
            }
            .frame(width: 52, height: 52)

            Text(member.name.capitalized)
                .font(.appCaptionSmall)
                .foregroundStyle(Color.typographyPrimary)
                .lineLimit(1)

            // Type badges
            VStack(spacing: 2) {
                ForEach(member.types, id: \.self) { type in
                    Text(type.capitalized)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(typeColor(type), in: Capsule())
                        .lineLimit(1)
                }
            }

            Text(member.role.capitalized)
                .font(.system(size: 9))
                .foregroundStyle(Color.typographyMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .space2)
        .background(Color.surfacesBaseLowContrast, in: RoundedRectangle(cornerRadius: .radiusMD))
    }

    // MARK: - Coverage

    @ViewBuilder
    private var coverageSection: some View {
        VStack(alignment: .leading, spacing: .space2) {
            if !data.coverage.uncovered.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Uncovered types")
                        .font(.appCaptionSmall)
                        .foregroundStyle(Color.appSurfaceErrorSolid)

                    HStack(spacing: 4) {
                        ForEach(data.coverage.uncovered, id: \.self) { type in
                            Text(type.capitalized)
                                .font(.appCaptionSmall)
                                .foregroundStyle(.white)
                                .padding(.horizontal, .space2)
                                .padding(.vertical, 2)
                                .background(typeColor(type), in: Capsule())
                        }
                    }
                }
            }

            if !data.coverage.doubleResisted.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Double resisted")
                        .font(.appCaptionSmall)
                        .foregroundStyle(Color.typographyMuted)

                    HStack(spacing: 4) {
                        ForEach(data.coverage.doubleResisted, id: \.self) { type in
                            Text(type.capitalized)
                                .font(.appCaptionSmall)
                                .foregroundStyle(.white)
                                .padding(.horizontal, .space2)
                                .padding(.vertical, 2)
                                .background(typeColor(type).opacity(0.6), in: Capsule())
                        }
                    }
                }
            }
        }
    }
}
