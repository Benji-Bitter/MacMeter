import SwiftUI

extension View {
    func blurBackground(_ material: Material = .ultraThinMaterial, radius: CGFloat = 20) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: 12)
                .fill(material)
                .blur(radius: radius)
        )
    }
    
    func glassEffect(cornerRadius: CGFloat = 12, shadowRadius: CGFloat = 10) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: shadowRadius, x: 0, y: 5)
        )
    }
    
    func neonGlow(color: Color = .blue, radius: CGFloat = 10) -> some View {
        self.overlay(
            self.blur(radius: radius)
                .opacity(0.5)
                .blendMode(.screen)
        )
        .overlay(
            self.blur(radius: radius / 2)
                .opacity(0.8)
                .blendMode(.screen)
        )
    }
    
    func animatedGlow(color: Color = .blue, radius: CGFloat = 10, duration: Double = 2.0) -> some View {
        self.overlay(
            self.blur(radius: radius)
                .opacity(0.3)
                .blendMode(.screen)
                .animation(.easeInOut(duration: duration).repeatForever(autoreverses: true), value: radius)
        )
    }
    
    func pulseEffect(scale: CGFloat = 1.1, duration: Double = 1.0) -> some View {
        self.scaleEffect(scale)
            .animation(.easeInOut(duration: duration).repeatForever(autoreverses: true), value: scale)
    }
    
    func shimmerEffect() -> some View {
        self.overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .white.opacity(0.3), .clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .rotationEffect(.degrees(30))
                .offset(x: -200)
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: 200)
        )
        .clipped()
    }
}

