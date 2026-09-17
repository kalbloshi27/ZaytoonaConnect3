import SwiftUI
import UIKit

extension Color {
    static let zGold = Color(red: 0.82, green: 0.68, blue: 0.35)
    static let zCream = Color(red: 0.93, green: 0.88, blue: 0.79)
    static let zBackground = Color(red: 0.018, green: 0.019, blue: 0.022)
    static let zSurface = Color(red: 0.050, green: 0.052, blue: 0.058)
    static let zSurfaceRaised = Color(red: 0.072, green: 0.074, blue: 0.082)
    static let zPanel = Color.white.opacity(0.055)
    static let zPanelStrong = Color.white.opacity(0.085)
    static let zBorder = Color.white.opacity(0.085)
    static let zMuted = Color.white.opacity(0.55)
    static let zMutedStrong = Color.white.opacity(0.72)
    static let zGreen = Color(red: 0.39, green: 0.96, blue: 0.53)
    static let zRed = Color(red: 0.88, green: 0.20, blue: 0.18)
}

struct ZCardModifier: ViewModifier {
    var padding: CGFloat = 15
    var radius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.zSurfaceRaised, Color.zSurface],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(Color.zBorder, lineWidth: 1)
                    )
            )
    }
}

struct ZThinCardModifier: ViewModifier {
    var padding: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(Color.black.opacity(0.36))
                    .overlay(
                        RoundedRectangle(cornerRadius: 17, style: .continuous)
                            .stroke(Color.zBorder, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func zCard(_ padding: CGFloat = 15, radius: CGFloat = 20) -> some View {
        modifier(ZCardModifier(padding: padding, radius: radius))
    }

    func zThinCard(_ padding: CGFloat = 12) -> some View {
        modifier(ZThinCardModifier(padding: padding))
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

struct ZBrandHeader: View {
    var compact = false
    var trailingSystemName: String? = nil
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center) {
            Image("ZaytoonaLogo")
                .resizable()
                .scaledToFit()
                .frame(width: compact ? 180 : 218, alignment: .leading)

            Spacer()

            if let trailingSystemName {
                Button {
                    trailingAction?()
                } label: {
                    ZIconCircle(systemName: trailingSystemName)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ZIconCircle: View {
    let systemName: String
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(Color.black.opacity(0.46)))
            .overlay(Circle().stroke(Color.zBorder, lineWidth: 1))
    }
}

struct ZStatusDot: View {
    var active: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill((active ? Color.zGreen : Color.zRed).opacity(0.18))
                .frame(width: 25, height: 25)
            Circle()
                .fill(active ? Color.zGreen : Color.zRed)
                .frame(width: 8, height: 8)
                .shadow(color: (active ? Color.zGreen : Color.zRed).opacity(0.7), radius: 5)
        }
    }
}

struct ZSectionTitle: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.caption2.weight(.semibold))
            .tracking(1.45)
            .foregroundStyle(Color.zMuted)
    }
}

struct ZMetricCard: View {
    let icon: String
    let eyebrow: String
    let value: String
    let detail: String
    var accent: Color = .white

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(eyebrow, systemImage: icon)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.zMutedStrong)
                .lineLimit(1)

            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(accent)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(detail)
                .font(.caption2)
                .foregroundStyle(Color.zMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zThinCard(13)
    }
}
