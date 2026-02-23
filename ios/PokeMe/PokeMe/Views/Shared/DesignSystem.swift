import SwiftUI

// MARK: - UC Davis Brand Colors

enum UCDavisPalette {
    static let navy     = Color(red: 0/255,   green: 40/255,  blue: 85/255)   // #002855 UC Davis Navy
    static let gold     = Color(red: 255/255, green: 184/255, blue: 28/255)   // #FFB81C UC Davis Gold
    static let deepBlue = Color(red: 0/255,   green: 89/255,  blue: 140/255)  // #00598C Aggie Blue
    static let cream    = Color.white
    static let surface  = Color(.systemBackground)
    static let surfaceMuted = Color(.systemGray6)
    static let border   = gold.opacity(0.25)
    static let softBlue = deepBlue.opacity(0.12)
    static let softGold = gold.opacity(0.14)
    static let success  = Color(red: 0/255, green: 150/255, blue: 80/255)
    static let danger   = Color(red: 210/255, green: 50/255, blue: 50/255)
    static let textPrimary = Color.primary
    static let textMuted   = Color.secondary
}

// MARK: - Typography

enum AppFont {
    static let display  = Font.system(size: 54, weight: .black, design: .rounded)
    static let title    = Font.system(.title2, design: .rounded).weight(.bold)
    static let headline = Font.headline.weight(.semibold)
    static let body     = Font.body
    static let caption  = Font.caption
    static let pill     = Font.caption2.weight(.semibold)
}

// MARK: - Spacing

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}

// MARK: - Corner Radius

enum Radius {
    static let pill: CGFloat = 20
    static let card: CGFloat = 18
    static let button: CGFloat = 14
    static let sm: CGFloat = 10
}

// MARK: - Animated Background

struct UCDavisBackground: View {
    var animated: Bool = false
    @State private var shiftGradient = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: shiftGradient
                    ? [UCDavisPalette.gold, UCDavisPalette.deepBlue, UCDavisPalette.navy]
                    : [UCDavisPalette.navy, UCDavisPalette.deepBlue, UCDavisPalette.navy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: shiftGradient)

            RadialGradient(
                colors: [Color.white.opacity(0.18), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 260
            )
            .offset(x: 70, y: -150)
            .scaleEffect(pulse ? 1.08 : 0.94)

            RadialGradient(
                colors: [UCDavisPalette.gold.opacity(0.20), .clear],
                center: .bottomLeading,
                startRadius: 10,
                endRadius: 230
            )
            .offset(x: -80, y: 210)
            .scaleEffect(pulse ? 0.96 : 1.06)

            RoundedRectangle(cornerRadius: 180, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                .frame(width: 350, height: 210)
                .rotationEffect(.degrees(-24))
                .offset(x: -110, y: -250)

            RoundedRectangle(cornerRadius: 180, style: .continuous)
                .stroke(UCDavisPalette.gold.opacity(0.16), lineWidth: 1)
                .frame(width: 300, height: 180)
                .rotationEffect(.degrees(18))
                .offset(x: 130, y: 260)
        }
        .overlay(
            LinearGradient(
                colors: [Color.black.opacity(0.12), Color.clear, Color.black.opacity(0.14)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .ignoresSafeArea()
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                shiftGradient.toggle()
            }
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                pulse.toggle()
            }
        }
    }
}

// MARK: - Card Surface Modifier

private struct UCDavisCardSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [UCDavisPalette.surface.opacity(0.94), UCDavisPalette.surface.opacity(0.88)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(UCDavisPalette.border, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.32), lineWidth: 0.5)
                    .blendMode(.screen)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
    }
}

extension View {
    func ucDavisCardSurface(cornerRadius: CGFloat = 18) -> some View {
        modifier(UCDavisCardSurfaceModifier(cornerRadius: cornerRadius))
    }
}
