import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: ZaytoonaModel
    @EnvironmentObject private var discovery: BonjourDiscovery
    @EnvironmentObject private var locationManager: LocationManager

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "car.fill") }
            LocateView()
                .tabItem { Label("Locate", systemImage: "mappin.and.ellipse") }
            ParkingView()
                .tabItem { Label("Parking", systemImage: "parkingsign.circle.fill") }
            ActivityView()
                .tabItem { Label("Activity", systemImage: "clock.arrow.circlepath") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Color.zGold)
        .preferredColorScheme(.dark)
        .onAppear {
            locationManager.start()
            discovery.start()
        }
        .onReceive(discovery.$resolvedHost) { host in
            guard let host else { return }
            model.discoveredHost = host
            model.discoveredPort = discovery.resolvedPort
            Task { await refreshConnection() }
        }
    }

    @MainActor
    private func refreshConnection() async {
        let ok = await ZaytoonaClient().health(host: model.activeHost, port: model.discoveredPort)
        model.isConnected = ok
        model.lastMessage = ok ? "Tahoe connected" : "Tahoe not reachable"
    }
}
