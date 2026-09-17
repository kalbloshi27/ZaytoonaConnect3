import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: ZaytoonaModel

    var body: some View {
        ZStack(alignment: .bottom) {
            ZBackground()
            Group {
                switch model.selectedTab {
                case .home: HomeView()
                case .locate: LocateView()
                case .park: ParkingView()
                case .activity: ActivityView()
                case .settings: SettingsView()
                }
            }
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 82) }

            ZBottomBar()
        }
        .tint(.zGold)
    }
}

struct ZBottomBar: View {
    @EnvironmentObject var model: ZaytoonaModel
    var body: some View {
        HStack(spacing: 4) {
            ForEach(ZTab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) { model.selectedTab = tab }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.icon).font(.system(size: 18, weight: .semibold))
                        Text(tab.title).font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(model.selectedTab == tab ? Color.zGold : Color.white.opacity(0.48))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 7)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.72))
        .overlay(alignment: .top) { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1) }
    }
}
