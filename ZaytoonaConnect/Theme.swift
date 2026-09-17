import SwiftUI

extension Color {
    static let zGold = Color(red: 0.82, green: 0.68, blue: 0.35)
    static let zBackground = Color(red: 0.035, green: 0.035, blue: 0.045)
    static let zPanel = Color.white.opacity(0.075)
    static let zPanelStrong = Color.white.opacity(0.12)
    static let zMuted = Color.white.opacity(0.62)
}

struct ZCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.zPanel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func zCard() -> some View { modifier(ZCardModifier()) }
}
