import SwiftUI

extension Color {
    static let zGold = Color(red: 0.94, green: 0.73, blue: 0.45)
    static let zIvory = Color(red: 0.91, green: 0.86, blue: 0.78)
    static let zPanel = Color.white.opacity(0.055)
}

struct ZBackground: View {
    var body: some View {
        ZStack {
            Color.black
            LinearGradient(colors: [Color(red: 0.04, green: 0.05, blue: 0.065), .black], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Color.zGold.opacity(0.08), .clear], center: .topTrailing, startRadius: 20, endRadius: 420)
        }.ignoresSafeArea()
    }
}

struct GlassPanel<Content: View>: View {
    var radius: CGFloat = 24
    let content: Content
    init(radius: CGFloat = 24, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.content = content()
    }
    var body: some View {
        content
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .background(Color.black.opacity(0.34), in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Color.white.opacity(0.10), lineWidth: 1))
    }
}

struct StatusDot: View {
    let active: Bool
    var body: some View {
        Circle()
            .fill(active ? Color.green : Color.orange)
            .frame(width: 9, height: 9)
            .shadow(color: active ? .green.opacity(0.65) : .orange.opacity(0.6), radius: 7)
    }
}

struct MetricBox: View {
    let icon: String
    let title: String
    let value: String
    let sub: String
    var accent: Color = .zGold

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(accent)
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(size: 22, weight: .semibold, design: .rounded)).monospacedDigit()
            Text(sub).font(.caption2).foregroundStyle(sub.contains("Offline") ? .orange : .secondary).lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
        .padding(14)
        .background(Color.zPanel, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.09)))
    }
}

struct ZPrimaryButton: ButtonStyle {
    var bright = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(bright ? Color.black : Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(bright ? Color.zIvory : Color.white.opacity(configuration.isPressed ? 0.14 : 0.07), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.11)))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct BrandHeader: View {
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Zaytoona")
                    .font(.custom("Snell Roundhand", size: 44))
                    .minimumScaleFactor(0.8)
                Text("CHEVROLET TAHOE • 2011")
                    .font(.caption2.weight(.medium))
                    .tracking(2.4)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "ellipsis")
                .font(.headline)
                .frame(width: 42, height: 42)
                .background(Color.white.opacity(0.06), in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.10)))
        }
    }
}
