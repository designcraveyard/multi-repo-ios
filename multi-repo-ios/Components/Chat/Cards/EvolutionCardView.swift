import SwiftUI

// MARK: - Evolution Card View
// Horizontal scrolling evolution chain with sprites, names, and trigger labels.

struct EvolutionCardView: View {
    let data: EvolutionCardData

    var body: some View {
        VStack(alignment: .leading, spacing: .space2) {
            Text("Evolution Chain")
                .font(.appCaptionMedium)
                .foregroundStyle(Color.typographyMuted)
                .tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .space1) {
                    ForEach(Array(data.chain.enumerated()), id: \.element.id) { index, stage in
                        if index > 0 {
                            // Arrow + trigger
                            VStack(spacing: 2) {
                                Text("→")
                                    .font(.appBodyMedium)
                                    .foregroundStyle(Color.typographyMuted)

                                Text(stage.trigger.capitalized.replacingOccurrences(of: "-", with: " "))
                                    .font(.appCaptionSmall)
                                    .foregroundStyle(Color.typographyMuted)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: 60)
                            }
                            .padding(.horizontal, .space1)
                        }

                        // Stage
                        VStack(spacing: .space1) {
                            AsyncImage(url: URL(string: stage.sprite)) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFit()
                                case .failure, .empty:
                                    Color.surfacesBaseLowContrast
                                @unknown default:
                                    Color.surfacesBaseLowContrast
                                }
                            }
                            .frame(width: 64, height: 64)

                            Text(stage.name.capitalized)
                                .font(.appCaptionMedium)
                                .foregroundStyle(Color.typographySecondary)
                                .lineLimit(1)
                        }
                        .frame(minWidth: 64)
                    }
                }
                .padding(.horizontal, .space1)
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
}
