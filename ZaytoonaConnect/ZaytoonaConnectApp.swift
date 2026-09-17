import SwiftUI

@main
struct ZaytoonaConnectApp: App {
    @StateObject private var model = ZaytoonaModel()
    @StateObject private var discovery = BonjourDiscovery()
    @StateObject private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .environmentObject(discovery)
                .environmentObject(locationManager)
        }
    }
}
