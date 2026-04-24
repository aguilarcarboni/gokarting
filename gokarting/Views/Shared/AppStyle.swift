import SwiftUI

struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color.black, Color(red: 0.01, green: 0.04, blue: 0.10), Color.black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension View {
    @ViewBuilder
    func appScreenBackground() -> some View {
        self.background(AppBackground().ignoresSafeArea())
    }

    @ViewBuilder
    func glassCard(radius: CGFloat = 18) -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.regular, in: .rect(cornerRadius: radius))
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius))
                .overlay(RoundedRectangle(cornerRadius: radius).stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
    }

    @ViewBuilder
    func glassRoundedBackground(radius: CGFloat) -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.regular, in: .rect(cornerRadius: radius))
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius))
                .overlay(RoundedRectangle(cornerRadius: radius).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
    }

    @ViewBuilder
    func glassCapsuleBackground(accented: Bool, tint: Color = .red) -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(
                    accented ? .regular.tint(tint).interactive() : .regular,
                    in: .capsule
                )
        } else {
            self
                .background(accented ? AnyShapeStyle(tint) : AnyShapeStyle(.ultraThinMaterial), in: Capsule())
        }
    }

    @ViewBuilder
    func glassCircleBackground() -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.regular.interactive(), in: .circle)
        } else {
            self
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
    }
}
