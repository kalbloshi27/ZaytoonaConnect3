import SwiftUI

@main
struct ZaytoonaConnectApp: App {
    @StateObject private var model = ZaytoonaModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { phase in
                    if phase == .active {
                        model.locationManager.start()
                        model.scanAgain()
                        Task { await model.autoConnectAndRefresh() }
                    }
                }
        }
    }
}
