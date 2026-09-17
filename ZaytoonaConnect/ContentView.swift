import SwiftUI
import CoreLocation
import UIKit

struct ContentView: View {
    @EnvironmentObject private var model: ZaytoonaModel
    @EnvironmentObject private var discovery: BonjourDiscovery
    @EnvironmentObject private var locationManager: LocationManager

    @State private var selection: RootTab = .home

    private enum RootTab: String, CaseIterable {
        case home = "Home"
        case car = "Car"
        case trips = "Trips"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .car: return "car.side.fill"
            case .trips: return "map.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            Color.zBackground.ignoresSafeArea()

            Group {
                switch selection {
                case .home:
                    HomeView()
                case .car:
                    CarStatusView()
                case .trips:
                    ActivityView()
                case .settings:
                    SettingsView()
                }
            }
            .transition(.opacity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            rootTabBar
        }
        .preferredColorScheme(.dark)
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

    private var rootTabBar: some View {
        HStack(spacing: 0) {
            ForEach(RootTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 10.5, weight: .medium))
                    }
                    .foregroundStyle(selection == tab ? Color.zCream : Color.zMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 3)
        .padding(.bottom, 2)
        .background(
            Color.black.opacity(0.96)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.zBorder)
                        .frame(height: 1)
                }
        )
    }

    @MainActor
    private func refreshConnection() async {
        let result = await ZaytoonaClient().healthStatus(
            host: model.activeHost,
            port: model.discoveredPort
        )

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
                    VStack(spacing: 16) {
                        ZBrandHeader(compact: false)

                        VStack(spacing: 0) {
                            statusRow(
                                icon: "antenna.radiowaves.left.and.right",
                                title: "Receiver",
                                value: model.isConnected ? "Online" : "Offline",
                                detail: model.lastLatencyMs.map { "\($0) ms" } ?? "—",
                                state: model.isConnected ? .good : .bad
                            )
                            separator
                            statusRow(
                                icon: "clock",
                                title: "Last Connection",
                                value: model.lastConnectedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Not yet",
                                detail: "",
                                state: model.lastConnectedAt == nil ? .neutral : .good
                            )
                            separator
                            statusRow(
                                icon: "car.battery.50",
                                title: "Car Battery",
                                value: "Not reported",
                                detail: "Receiver data",
                                state: .neutral
                            )
                            separator
                            statusRow(
                                icon: "location.circle",
                                title: "Location Accuracy",
                                value: accuracyLabel,
                                detail: accuracyDetail,
                                state: locationManager.location == nil ? .neutral : .good
                            )
                            separator
                            statusRow(
                                icon: "iphone",
                                title: "Device Battery",
                                value: "\(phoneBattery)%",
                                detail: charging ? "Charging" : "",
                                state: phoneBattery > 20 ? .good : .bad
                            )
                            separator
                            statusRow(
                                icon: "wifi",
                                title: "Network",
                                value: model.activeHost == nil ? "Not connected" : "Local Network",
                                detail: model.activeHost ?? "",
                                state: model.activeHost == nil ? .neutral : .good
                            )
                            separator
                            statusRow(
                                icon: "internaldrive",
                                title: "Storage",
                                value: storageUsed,
                                detail: "iPhone",
                                state: .good
                            )
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 21, style: .continuous)
                                .fill(Color.zSurface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 21, style: .continuous)
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
                                colors: [.clear, Color.black.opacity(0.93)],
                                startPoint: .center,
                                endPoint: .bottom
                            )

                            VStack(alignment: .leading, spacing: 1) {
                                Text("Good Car")
                                    .font(.system(size: 20, weight: .light, design: .serif).italic())
                                Text("Good Days")
                                    .font(.system(size: 26, weight: .light, design: .serif).italic())
                                    .foregroundStyle(Color.zCream)
                            }
                            .padding(18)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.zBorder, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 17)
                    .padding(.top, 12)
                    .padding(.bottom, 26)
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

    private enum RowState {
        case good, bad, neutral
    }

    private var separator: some View {
        Rectangle()
            .fill(Color.zBorder)
            .frame(height: 1)
            .padding(.leading, 50)
    }

    private func statusRow(
        icon: String,
        title: String,
        value: String,
        detail: String,
        state: RowState
    ) -> some View {
        let accent: Color = {
            switch state {
            case .good: return .zGreen
            case .bad: return .zRed
            case .neutral: return .zCream
            }
        }()

        return HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 26)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white)

            Spacer(minLength: 10)

            HStack(spacing: 7) {
                if title == "Receiver" {
                    Circle()
                        .fill(accent)
                        .frame(width: 8, height: 8)
                        .shadow(color: accent.opacity(0.65), radius: 4)
                }

                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(state == .good ? accent : .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if !detail.isEmpty {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(Color.zMuted)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 14)
    }

    private var accuracyLabel: String {
        guard let accuracy = locationManager.location?.horizontalAccuracy, accuracy >= 0 else {
            return "Unavailable"
        }

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
        let result = await ZaytoonaClient().healthStatus(
            host: model.activeHost,
            port: model.discoveredPort
        )

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
