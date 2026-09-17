import SwiftUI
import UIKit

extension Color {
    static let zGold = Color(red: 0.82, green: 0.68, blue: 0.35)
    static let zCream = Color(red: 0.91, green: 0.85, blue: 0.75)
    static let zBackground = Color(red: 0.025, green: 0.025, blue: 0.03)
    static let zPanel = Color.white.opacity(0.06)
    static let zPanelStrong = Color.white.opacity(0.10)
    static let zBorder = Color.white.opacity(0.09)
    static let zMuted = Color.white.opacity(0.58)
    static let zGreen = Color(red: 0.35, green: 0.95, blue: 0.50)
}

struct ZCardModifier: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.zPanel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.zBorder, lineWidth: 1)
                    )
            )
    }
}

struct ZThinCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(Color.black.opacity(0.34))
                    .overlay(
                        RoundedRectangle(cornerRadius: 17, style: .continuous)
                            .stroke(Color.zBorder, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func zCard(_ padding: CGFloat = 16) -> some View { modifier(ZCardModifier(padding: padding)) }
    func zThinCard() -> some View { modifier(ZThinCardModifier()) }

    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

struct ZRoundIcon: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .semibold))
            .frame(width: 40, height: 40)
            .background(Circle().fill(Color.black.opacity(0.45)))
            .overlay(Circle().stroke(Color.zBorder, lineWidth: 1))
    }
}

struct ZSectionTitle: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.caption2.weight(.semibold))
            .tracking(1.4)
            .foregroundStyle(Color.zMuted)
    }
}
