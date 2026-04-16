import SwiftUI

// MARK: - Pokemon Card View
// Displays a Pokémon's sprite, types, base stats, abilities, height, and weight.

struct PokemonCardView: View {
    let data: PokemonCardData

    var body: some View {
        VStack(alignment: .leading, spacing: .space3) {
            // --- Header: sprite + name + id
            HStack(alignment: .center, spacing: .space3) {
                AsyncImage(url: URL(string: data.sprite)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit()
                    case .failure, .empty:
                        Color.surfacesBaseLowContrast
                    @unknown default:
                        Color.surfacesBaseLowContrast
                    }
                }
                .frame(width: 80, height: 80)

                VStack(alignment: .leading, spacing: .space1) {
                    Text(data.name.capitalized)
                        .font(.appTitleSmall)
                        .foregroundStyle(Color.typographyPrimary)

                    Text("#\(String(format: "%04d", data.id))")
                        .font(.appCaptionMedium)
                        .foregroundStyle(Color.typographyMuted)

                    // Type badges
                    HStack(spacing: .space1) {
                        ForEach(data.types, id: \.self) { type in
                            typeBadge(type)
                        }
                    }
                    .padding(.top, 2)
                }

                Spacer()
            }

            AppDivider(type: .row)

            // --- Stats
            VStack(alignment: .leading, spacing: .space2) {
                Text("Base Stats")
                    .font(.appCaptionMedium)
                    .foregroundStyle(Color.typographyMuted)
                    .tracking(0.5)

                ForEach(data.stats, id: \.name) { stat in
                    HStack(spacing: .space2) {
                        Text(statLabel(stat.name))
                            .font(.appCaptionSmall)
                            .foregroundStyle(Color.typographySecondary)
                            .frame(width: 40, alignment: .leading)

                        Text("\(stat.value)")
                            .font(.appCaptionSmall)
                            .foregroundStyle(Color.typographyPrimary)
                            .frame(width: 28, alignment: .trailing)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.surfacesBaseLowContrast)
                                    .frame(height: 6)

                                Capsule()
                                    .fill(statColor(stat.value))
                                    .frame(width: geo.size.width * CGFloat(min(stat.value, 255)) / 255.0, height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }

            AppDivider(type: .row)

            // --- Abilities
            VStack(alignment: .leading, spacing: .space1) {
                Text("Abilities")
                    .font(.appCaptionMedium)
                    .foregroundStyle(Color.typographyMuted)
                    .tracking(0.5)

                Text(data.abilities.map { $0.capitalized.replacingOccurrences(of: "-", with: " ") }.joined(separator: ", "))
                    .font(.appBodySmall)
                    .foregroundStyle(Color.typographySecondary)
            }

            // --- Footer: height + weight
            HStack(spacing: .space4) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Height")
                        .font(.appCaptionSmall)
                        .foregroundStyle(Color.typographyMuted)
                    Text(String(format: "%.1f m", data.height / 10))
                        .font(.appBodySmall)
                        .foregroundStyle(Color.typographySecondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weight")
                        .font(.appCaptionSmall)
                        .foregroundStyle(Color.typographyMuted)
                    Text(String(format: "%.1f kg", data.weight / 10))
                        .font(.appBodySmall)
                        .foregroundStyle(Color.typographySecondary)
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

    // MARK: - Type Badge

    @ViewBuilder
    private func typeBadge(_ type: String) -> some View {
        Text(type.capitalized)
            .font(.appCaptionSmall)
            .foregroundStyle(.white)
            .padding(.horizontal, .space2)
            .padding(.vertical, 3)
            .background(typeColor(type), in: Capsule())
    }

    // MARK: - Helpers

    private func statLabel(_ name: String) -> String {
        switch name.lowercased() {
        case "hp":             return "HP"
        case "attack":         return "ATK"
        case "defense":        return "DEF"
        case "special-attack": return "SP.A"
        case "special-defense": return "SP.D"
        case "speed":          return "SPD"
        default:               return name.prefix(4).uppercased()
        }
    }

    private func statColor(_ value: Int) -> Color {
        switch value {
        case 0..<50:  return Color.appSurfaceErrorSolid
        case 50..<80: return Color.appSurfaceWarningSolid
        case 80..<110: return Color.appSurfaceSuccessSolid
        default:      return Color.surfacesBrandInteractive
        }
    }
}

// MARK: - Type Color Map (shared across card views)

func typeColor(_ type: String) -> Color {
    switch type.lowercased() {
    case "fire":     return Color(red: 0.95, green: 0.37, blue: 0.10)
    case "water":    return Color(red: 0.25, green: 0.55, blue: 0.95)
    case "grass":    return Color(red: 0.30, green: 0.70, blue: 0.25)
    case "electric": return Color(red: 0.98, green: 0.78, blue: 0.10)
    case "psychic":  return Color(red: 0.95, green: 0.25, blue: 0.55)
    case "ice":      return Color(red: 0.40, green: 0.80, blue: 0.90)
    case "dragon":   return Color(red: 0.40, green: 0.25, blue: 0.90)
    case "dark":     return Color(red: 0.28, green: 0.22, blue: 0.18)
    case "fairy":    return Color(red: 0.90, green: 0.55, blue: 0.80)
    case "fighting": return Color(red: 0.75, green: 0.25, blue: 0.15)
    case "poison":   return Color(red: 0.62, green: 0.25, blue: 0.62)
    case "ground":   return Color(red: 0.82, green: 0.68, blue: 0.30)
    case "rock":     return Color(red: 0.68, green: 0.60, blue: 0.30)
    case "bug":      return Color(red: 0.60, green: 0.72, blue: 0.10)
    case "ghost":    return Color(red: 0.42, green: 0.28, blue: 0.55)
    case "steel":    return Color(red: 0.58, green: 0.58, blue: 0.70)
    case "flying":   return Color(red: 0.55, green: 0.65, blue: 0.90)
    case "normal":   return Color(red: 0.65, green: 0.65, blue: 0.55)
    default:         return Color.typographyMuted
    }
}
