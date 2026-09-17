import SwiftUI
import CoreLocation
import UIKit

struct ContentView: View {
    @EnvironmentObject private var model: ZaytoonaModel
    @EnvironmentObject private var discovery: BonjourDiscovery
    @EnvironmentObject private var locationManager: LocationManager

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            CarStatusView()
                .tabItem { Label("Car", systemImage: "car.side.fill") }

            ActivityView()
                .tabItem { Label("Trips", systemImage: "map.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Color.zCream)
        .preferredColorScheme(.dark)
        .toolbarBackground(Color.black.opacity(0.96), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onAppear {
            locationManager.start()
            discovery.start()
            UIDevice.current.isBatteryMonitoringEnabled = true
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
        let result = await ZaytoonaClient().healthStatus(host: model.activeHost, port: model.discoveredPort)
        if result.ok {
            model.markConnected(latency: result.latencyMs)
            model.lastMessage = "Tahoe connected"
        } else {
            model.markDisconnected()
            model.lastMessage = "Tahoe not reachable"
        }
    }
}

private struct CarStatusView: View {
    @EnvironmentObject private var model: ZaytoonaModel
    @EnvironmentObject private var discovery: BonjourDiscovery
    @EnvironmentObject private var locationManager: LocationManager

    @State private var phoneBattery = 0
    @State private var charging = false
    @State private var storageUsed = "—"

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        HStack {
                            Image("ZaytoonaLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 205)
                            Spacer()
                        }

                        VStack(spacing: 0) {
                            statusRow(
                                icon: "antenna.radiowaves.left.and.right",
                                title: "Receiver",
                                value: model.isConnected ? "Online" : "Offline",
                                detail: model.lastLatencyMs.map { "\($0) ms" } ?? "—",
                                good: model.isConnected
                            )
                            divider
                            statusRow(
                                icon: "clock",
                                title: "Last Connection",
                                value: model.lastConnectedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Not yet",
                                detail: "",
                                good: model.lastConnectedAt != nil
                            )
                            divider
                            statusRow(
                                icon: "car.battery.50",
                                title: "Car Battery",
                                value: "Awaiting Tahoe",
                                detail: "— V",
                                good: false
                            )
                            divider
                            statusRow(
                                icon: "location.circle",
                                title: "Location Accuracy",
                                value: accuracyLabel,
                                detail: accuracyDetail,
                                good: locationManager.location != nil
                            )
                            divider
                            statusRow(
                                icon: "iphone",
                                title: "Device Battery",
                                value: "\(phoneBattery)%",
                                detail: charging ? "Charging" : "",
                                good: phoneBattery > 20
                            )
                            divider
                            statusRow(
                                icon: "wifi",
                                title: "Network",
                                value: model.activeHost == nil ? "Not connected" : "Local Network",
                                detail: model.activeHost ?? "",
                                good: model.activeHost != nil
                            )
                            divider
                            statusRow(
                                icon: "internaldrive",
                                title: "Storage",
                                value: storageUsed,
                                detail: "iPhone",
                                good: true
                            )
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.zPanel)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(Color.zBorder, lineWidth: 1)
                                )
                        )

                        ZStack(alignment: .bottomLeading) {
                            Image("TahoeFront")
                                .resizable()
                                .scaledToFill()
                                .frame(height: 225)
                                .clipped()

                            LinearGradient(
                                colors: [.clear, .black.opacity(0.88)],
                                startPoint: .center,
                                endPoint: .bottom
                            )

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Good Car")
                                    .font(.title3.italic())
                                Text("Good Days")
                                    .font(.title2.italic())
                                    .foregroundStyle(Color.zCream)
                            }
                            .padding(18)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.zBorder, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .onAppear { refreshDeviceInfo() }
            .refreshable {
                discovery.start()
                await refreshReceiver()
                refreshDeviceInfo()
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.zBorder)
            .frame(height: 1)
            .padding(.leading, 50)
    }

    private func statusRow(icon: String, title: String, value: String, detail: String, good: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(good ? Color.zGreen : Color.zCream)
                .frame(width: 26)

            Text(title)
                .font(.subheadline)

            Spacer(minLength: 10)

            HStack(spacing: 7) {
                if title == "Receiver" {
                    Circle()
                        .fill(good ? Color.zGreen : Color.red)
                        .frame(width: 8, height: 8)
                }

                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(good ? Color.zGreen : .white)
                    .lineLimit(1)

                if !detail.isEmpty {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Color.zMuted)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
    }

    private var accuracyLabel: String {
        guard let accuracy = locationManager.location?.horizontalAccuracy, accuracy >= 0 else { return "Unavailable" }
        switch accuracy {
        case ..<8: return "Excellent"
        case ..<20: return "Good"
        default: return "Approximate"
        }
    }

    private var accuracyDetail: String {
        guard let accuracy = locationManager.location?.horizontalAccuracy, accuracy >= 0 else { return "" }
        return "~ \(Int(accuracy)) m"
    }

    @MainActor
    private func refreshReceiver() async {
        let result = await ZaytoonaClient().healthStatus(host: model.activeHost, port: model.discoveredPort)
        if result.ok {
            model.markConnected(latency: result.latencyMs)
        } else {
            model.markDisconnected()
        }
    }

    private func refreshDeviceInfo() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        phoneBattery = level < 0 ? 0 : Int(level * 100)
        charging = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full

        if let values = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let total = values[.systemSize] as? NSNumber,
           let free = values[.systemFreeSize] as? NSNumber,
           total.doubleValue > 0 {
            let used = 1 - (free.doubleValue / total.doubleValue)
            storageUsed = "\(Int(used * 100))% used"
        }
    }
}
