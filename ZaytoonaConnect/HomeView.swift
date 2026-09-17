import SwiftUI
import MapKit
import CoreLocation
import UIKit

struct HomeView: View {
    @EnvironmentObject private var model: ZaytoonaModel
    @EnvironmentObject private var discovery: BonjourDiscovery
    @EnvironmentObject private var locationManager: LocationManager

    @State private var phoneBattery = 0
    @State private var charging = false
    @State private var showSendSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 11) {
                        brandHeader
                        connectionPill
                        hero
                        metricRow
                        lastLocationCard
                        primaryActions
                        quickActions
                    }
                    .padding(.horizontal, 17)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSendSheet) {
                SendToTahoeSheet()
                    .environmentObject(model)
            }
            .onAppear {
                refreshBattery()
                Task { await pingTahoe() }
            }
        }
    }

    private var brandHeader: some View {
        HStack {
            Image("ZaytoonaLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 218, alignment: .leading)

            Spacer()

            Menu {
                Button {
                    showSendSheet = true
                } label: {
                    Label("Send to Tahoe", systemImage: "paperplane.fill")
                }

                Button {
                    discovery.start()
                    Task { await pingTahoe() }
                } label: {
                    Label("Refresh Connection", systemImage: "arrow.clockwise")
                }

                if model.parkingSession == nil {
                    Button {
                        saveParking()
                    } label: {
                        Label("Save Parking", systemImage: "parkingsign.circle.fill")
                    }
                }
            } label: {
                ZIconCircle(systemName: "ellipsis")
            }
        }
    }

    private var connectionPill: some View {
        HStack(spacing: 10) {
            ZStatusDot(active: model.isConnected)

            VStack(alignment: .leading, spacing: 2) {
                Text(model.isConnected ? "Tahoe Connected" : "Tahoe Offline")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(model.isConnected ? Color.zGreen : .white)

                HStack(spacing: 5) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text(model.isConnected ? "Receiver Online" : "Receiver not reachable")
                    if let ms = model.lastLatencyMs {
                        Text("• \(ms) ms")
                    }
                }
                .font(.caption2)
                .foregroundStyle(Color.zMuted)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(Color.black.opacity(0.38))
                .overlay(
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .stroke(Color.zBorder, lineWidth: 1)
                )
        )
    }

    private var hero: some View {
        ZStack(alignment: .bottom) {
            Image("TahoeFront")
                .resizable()
                .scaledToFill()
                .frame(height: 225)
                .clipped()

            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.12),
                    Color.zBackground.opacity(0.90)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.zBorder, lineWidth: 1)
        )
    }

    private var metricRow: some View {
        HStack(spacing: 9) {
            if let session = model.parkingSession {
                TimelineView(.periodic(from: session.startedAt, by: 1)) { context in
                    ZMetricCard(
                        icon: "clock",
                        eyebrow: "Parking Timer",
                        value: duration(from: session.startedAt, to: context.date),
                        detail: "Since \(session.startedAt.formatted(date: .omitted, time: .shortened))"
                    )
                }
            } else {
                ZMetricCard(
                    icon: "clock",
                    eyebrow: "Parking Timer",
                    value: "—",
                    detail: "Not active"
                )
            }

            ZMetricCard(
                icon: "battery.75percent",
                eyebrow: "Phone Battery",
                value: "\(phoneBattery)%",
                detail: charging ? "⚡ Charging" : "iPhone",
                accent: charging ? Color.zGreen : .white
            )
        }
    }

    private var lastLocationCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(Color.zCream)
                .frame(width: 31)

            VStack(alignment: .leading, spacing: 3) {
                Text("Last Known Location")
                    .font(.caption2)
                    .foregroundStyle(Color.zMuted)

                Text(model.parkingSession == nil ? "No parking saved" : "Saved Tahoe Location")
                    .font(.subheadline.weight(.semibold))

                if let session = model.parkingSession {
                    Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(Color.zMuted)
                } else {
                    Text("Save parking to remember where the Tahoe is")
                        .font(.caption2)
                        .foregroundStyle(Color.zMuted)
                }
            }

            Spacer()
        }
        .zThinCard(12)
    }

    private var primaryActions: some View {
        HStack(spacing: 9) {
            NavigationLink {
                LocateView()
            } label: {
                wideAction(
                    icon: "figure.walk",
                    title: "Walk to Tahoe",
                    subtitle: walkingSubtitle,
                    highlighted: true
                )
            }
            .buttonStyle(.plain)

            ShareLink(item: etaShareText) {
                wideAction(
                    icon: "arrowshape.turn.up.right.fill",
                    title: "Send ETA",
                    subtitle: "Share arrival time",
                    highlighted: false
                )
            }
            .buttonStyle(.plain)
            .disabled(parkedCoordinate == nil)
        }
    }

    private var quickActions: some View {
        HStack(spacing: 8) {
            quickButton(icon: "location.fill", title: "Directions") {
                walkToTahoe()
            }
            .disabled(parkedCoordinate == nil)

            ShareLink(item: locationShareText) {
                quickActionLabel(icon: "square.and.arrow.up", title: "Share Location")
            }
            .buttonStyle(.plain)
            .disabled(parkedCoordinate == nil)

            quickButton(icon: "bookmark.fill", title: model.parkingSession == nil ? "Save Parking" : "Parking Saved") {
                saveParking()
            }
        }
    }

    private func wideAction(
        icon: String,
        title: String,
        subtitle: String,
        highlighted: Bool
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(highlighted ? Color.black.opacity(0.60) : Color.zMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 61)
        .background(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(highlighted ? Color.zCream : Color.zSurfaceRaised)
                .overlay(
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .stroke(Color.zBorder, lineWidth: 1)
                )
        )
        .foregroundStyle(highlighted ? Color.black : Color.white)
    }

    private func quickButton(
        icon: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            quickActionLabel(icon: icon, title: title)
        }
        .buttonStyle(.plain)
    }

    private func quickActionLabel(icon: String, title: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
            Text(title)
                .font(.system(size: 10.5, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.zSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.zBorder, lineWidth: 1)
                )
        )
    }

    private var parkedCoordinate: CLLocationCoordinate2D? {
        guard let session = model.parkingSession,
              let latitude = session.latitude,
              let longitude = session.longitude else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private var walkingSubtitle: String {
        guard let parkedCoordinate,
              let current = locationManager.location else {
            return "Navigate on foot"
        }

        let parked = CLLocation(
            latitude: parkedCoordinate.latitude,
            longitude: parkedCoordinate.longitude
        )
        let meters = current.distance(from: parked)
        let minutes = max(1, Int(meters / 80))
        return String(format: "%.1f km • %d min", meters / 1000, minutes)
    }

    private var etaShareText: String {
        guard let parkedCoordinate,
              let current = locationManager.location else {
            return "Walking to Zaytoona."
        }

        let parked = CLLocation(
            latitude: parkedCoordinate.latitude,
            longitude: parkedCoordinate.longitude
        )
        let meters = current.distance(from: parked)
        let minutes = max(1, Int(meters / 80))
        return "I’m walking to Zaytoona — approximately \(minutes) minutes away."
    }

    private var locationShareText: String {
        guard let parkedCoordinate else {
            return "No Tahoe parking location is saved."
        }

        return "Zaytoona parking location: https://maps.apple.com/?ll=\(parkedCoordinate.latitude),\(parkedCoordinate.longitude)"
    }

    private func saveParking() {
        guard let coordinate = locationManager.location?.coordinate else {
            model.lastMessage = "Waiting for iPhone location"
            return
        }

        model.parkingSession = ParkingSession(coordinate: coordinate)
        model.addActivity("Parking started", "Tahoe parking position saved")
    }

    private func walkToTahoe() {
        guard let parkedCoordinate else { return }

        let item = MKMapItem(placemark: MKPlacemark(coordinate: parkedCoordinate))
        item.name = "Zaytoona"
        item.openInMaps(
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
            ]
        )
    }

    @MainActor
    private func pingTahoe() async {
        let result = await ZaytoonaClient().healthStatus(
            host: model.activeHost,
            port: model.discoveredPort
        )

        if result.ok {
            model.markConnected(latency: result.latencyMs)
            model.lastMessage = "Tahoe connected"
        } else {
            model.markDisconnected()
        }
    }

    private func refreshBattery() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        phoneBattery = level < 0 ? 0 : Int(level * 100)
        charging = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
    }

    private func duration(from start: Date, to end: Date) -> String {
        let seconds = max(0, Int(end.timeIntervalSince(start)))
        return String(
            format: "%02d:%02d:%02d",
            seconds / 3600,
            (seconds % 3600) / 60,
            seconds % 60
        )
    }
}

private struct SendToTahoeSheet: View {
    @EnvironmentObject private var model: ZaytoonaModel
    @Environment(\.dismiss) private var dismiss

    @State private var input = ""
    @State private var sending = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        ZBrandHeader(compact: true)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Send to Tahoe")
                                .font(.title2.bold())
                            Text("Destination, YouTube Music link, or text")
                                .font(.subheadline)
                                .foregroundStyle(Color.zMuted)
                        }

                        TextField("Type or paste here…", text: $input, axis: .vertical)
                            .focused($inputFocused)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.send)
                            .onSubmit {
                                Task { await send() }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.zSurface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.zBorder, lineWidth: 1)
                                    )
                            )

                        HStack(spacing: 8) {
                            routeHint(icon: "location.fill", text: "Waze")
                            routeHint(icon: "music.note", text: "Music")
                            routeHint(icon: "text.bubble.fill", text: "Text")
                        }

                        Button {
                            inputFocused = false
                            hideKeyboard()
                            Task { await send() }
                        } label: {
                            HStack {
                                Spacer()
                                if sending {
                                    ProgressView()
                                        .tint(.black)
                                }
                                Text(sending ? "Sending…" : "Send to Zaytoona")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding(.vertical, 14)
                            .background(Color.zCream)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(
                            input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || sending
                        )

                        Text(model.lastMessage)
                            .font(.caption)
                            .foregroundStyle(Color.zMuted)
                    }
                    .padding(18)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        inputFocused = false
                        hideKeyboard()
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    inputFocused = true
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func routeHint(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(Color.zMutedStrong)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.zSurface)
        )
    }

    @MainActor
    private func send() async {
        let clean = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        sending = true
        defer { sending = false }

        do {
            try await ZaytoonaClient().send(
                host: model.activeHost,
                port: model.discoveredPort,
                pairCode: model.pairCode,
                value: clean
            )
            model.lastMessage = "Sent to Tahoe"
            model.addActivity("Command sent", clean)
            input = ""
            inputFocused = false
            hideKeyboard()
        } catch {
            model.lastMessage = error.localizedDescription
        }
    }
}
