import SwiftUI

// MARK: - SSE Stream Event View
// Displays a spinning star indicator with a status label while the agent is working.

struct SSEStreamEventView: View {
    let label: String

    @State private var isRotating = false

    var body: some View {
        HStack(spacing: CGFloat.space2) {
            Image(systemName: "sparkles")
                .font(.system(size: 14))
                .foregroundStyle(Color.appIconPrimary)
                .rotationEffect(Angle.degrees(isRotating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                    value: isRotating
                )

            Text(label)
                .font(.appBodySmall)
                .foregroundStyle(Color.typographySecondary)
        }
        .padding(.horizontal, CGFloat.space3)
        .padding(.vertical, CGFloat.space2)
        .background(
            Color.appSurfaceBaseLowContrast,
            in: Capsule()
        )
        .onAppear {
            isRotating = true
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SSEStreamEventView(label: "Thinking...")
        SSEStreamEventView(label: "Looking up Pokémon...")
        SSEStreamEventView(label: "Building your team...")
    }
    .padding()
}
