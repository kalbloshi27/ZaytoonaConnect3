import SwiftUI
import MapKit
import CoreLocation
import UIKit

struct HomeView: View {
    @EnvironmentObject private var model: ZaytoonaModel
    @EnvironmentObject private var discovery: BonjourDiscovery
    @EnvironmentObject private var locationManager: LocationManager

    @State private var input = ""
    @State private var sending = false
    @State private var phoneBattery = 0
    @State private var charging = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        header
                        connectionCard
                        hero
                        infoRow
                        locationCard
                        primaryActions
                        secondaryActions
                        sendCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 24)
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
                refreshBattery()
                Task { await pingTahoe() }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Image("ZaytoonaLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 210)

            Spacer()

            Button {
                discovery.start()
                Task { await pingTahoe() }
            } label: {
                ZRoundIcon(systemName: "ellipsis")
            }
            .buttonStyle(.plain)
        }
    }

    private var connectionCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill((model.isConnected ? Color.zGreen : Color.orange).opacity(0.18))
                    .frame(width: 42, height: 42)
                Circle()
                    .fill(model.isConnected ? Color.zGreen : Color.orange)
                    .frame(width: 10, height: 10)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(model.isConnected ? "Tahoe Connected" : "Tahoe Offline")
                    .font(.headline)
                    .foregroundStyle(model.isConnected ? Color.zGreen : .white)

                HStack(spacing: 5) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text(model.isConnected ? "Receiver Online" : "Receiver not reachable")
                    if let ms = model.lastLatencyMs {
                        Text("• \(ms) ms")
                    }
                }
                .font(.caption)
                .foregroundStyle(Color.zMuted)
            }

            Spacer()
        }
        .zThinCard()
    }

    private var hero: some View {
        ZStack(alignment: .bottom) {
            Image("TahoeFront")
                .resizable()
                .scaledToFill()
                .frame(height: 235)
                .clipped()

            LinearGradient(
                colors: [.clear, Color.zBackground.opacity(0.78)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(Color.zBorder, lineWidth: 1)
        )
    }

    private var infoRow: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Label("Parking Timer", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(Color.zMuted)

                if let session = model.parkingSession {
                    TimelineView(.periodic(from: session.startedAt, by: 1)) { context in
                        Text(duration(from: session.startedAt, to: context.date))
                            .font(.title2.monospacedDigit().weight(.semibold))
                    }
                    Text("Since \(session.startedAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(Color.zMuted)
                } else {
                    Text("Not Active")
                        .font(.title3.weight(.semibold))
                    Text("Save parking below")
                        .font(.caption2)
                        .foregroundStyle(Color.zMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .zThinCard()

            VStack(alignment: .leading, spacing: 5) {
                Label("Phone Battery", systemImage: "battery.75")
                    .font(.caption)
                    .foregroundStyle(Color.zMuted)
                Text("\(phoneBattery)%")
                    .font(.title2.weight(.semibold))
                Text(charging ? "⚡ Charging" : "iPhone")
                    .font(.caption2)
                    .foregroundStyle(charging ? Color.zGreen : Color.zMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .zThinCard()
        }
    }

    private var locationCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.and.ellipse")
                .font(.title3)
                .foregroundStyle(Color.zCream)
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text("Last Known Location")
                    .font(.caption)
                    .foregroundStyle(Color.zMuted)

                Text(model.parkingSession == nil ? "No parking saved" : "Zaytoona • Saved Tahoe Location")
                    .font(.subheadline.weight(.semibold))

                if let coordinate = parkedCoordinate {
                    Text(String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude))
                        .font(.caption2.monospaced())
                        .foregroundStyle(Color.zMuted)
                }
            }

            Spacer()
        }
        .zThinCard()
    }

    private var primaryActions: some View {
        HStack(spacing: 10) {
            NavigationLink {
                LocateView()
            } label: {
                actionCard(
                    icon: "figure.walk",
                    title: "Walk to Tahoe",
                    subtitle: walkingSubtitle,
                    highlighted: true
                )
            }
            .buttonStyle(.plain)

            ShareLink(item: etaShareText) {
                actionCard(
                    icon: "arrowshape.turn.up.right.fill",
                    title: "Send ETA",
                    subtitle: "Share your arrival time",
                    highlighted: false
                )
            }
            .buttonStyle(.plain)
            .disabled(parkedCoordinate == nil)
        }
    }

    private var secondaryActions: some View {
        HStack(spacing: 10) {
            smallAction(icon: "location.fill", title: "Directions") {
                walkToTahoe()
            }
            .disabled(parkedCoordinate == nil)

            ShareLink(item: locationShareText) {
                smallActionLabel(icon: "square.and.arrow.up", title: "Share Location")
            }
            .buttonStyle(.plain)
            .disabled(parkedCoordinate == nil)

            smallAction(icon: "bookmark.fill", title: "Save Parking") {
                saveParking()
            }
        }
    }

    private var sendCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Label("Send to Tahoe", systemImage: "paperplane.fill")
                    .font(.headline)
                Spacer()
                Text("Waze • Music • Text")
                    .font(.caption2)
                    .foregroundStyle(Color.zMuted)
            }

            TextField("Destination, YouTube Music link, or text…", text: $input, axis: .vertical)
                .focused($inputFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.send)
                .onSubmit {
                    Task { await sendInput() }
                    inputFocused = false
                    hideKeyboard()
                }
                .padding(13)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(Color.black.opacity(0.38))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(Color.zBorder, lineWidth: 1)
                        )
                )

            Button {
                inputFocused = false
                hideKeyboard()
                Task { await sendInput() }
            } label: {
                HStack {
                    Spacer()
                    if sending { ProgressView().tint(.black) }
                    Text(sending ? "Sending…" : "Send to Zaytoona")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.vertical, 13)
                .background(Color.zCream)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || sending)

            Text(model.lastMessage)
                .font(.caption)
                .foregroundStyle(Color.zMuted)
        }
        .zCard()
    }

    private func actionCard(icon: String, title: String, subtitle: String, highlighted: Bool) -> some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 23, weight: .semibold))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(highlighted ? Color.black.opacity(0.65) : Color.zMuted)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .frame(maxWidth: .infinity, minHeight: 62)
        .background(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(highlighted ? Color.zCream : Color.zPanelStrong)
                .overlay(
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .stroke(Color.zBorder, lineWidth: 1)
                )
        )
        .foregroundStyle(highlighted ? .black : .white)
    }

    private func smallAction(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            smallActionLabel(icon: icon, title: title)
        }
        .buttonStyle(.plain)
    }

    private func smallActionLabel(icon: String, title: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
            Text(title)
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.zPanel)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.zBorder, lineWidth: 1)
                )
        )
        .foregroundStyle(.white)
    }

    private var parkedCoordinate: CLLocationCoordinate2D? {
        guard let session = model.parkingSession,
              let latitude = session.latitude,
              let longitude = session.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private var walkingSubtitle: String {
        guard let parkedCoordinate,
              let current = locationManager.location else { return "Navigate on foot" }
        let parked = CLLocation(latitude: parkedCoordinate.latitude, longitude: parkedCoordinate.longitude)
        let meters = current.distance(from: parked)
        let km = meters / 1000
        let minutes = max(1, Int(meters / 80))
        return String(format: "%.1f km • ~%d min", km, minutes)
    }

    private var etaShareText: String {
        guard let parkedCoordinate else { return "Zaytoona parking location is not saved yet." }
        return "Zaytoona is parked here: https://maps.apple.com/?ll=\(parkedCoordinate.latitude),\(parkedCoordinate.longitude)"
    }

    private var locationShareText: String {
        etaShareText
    }

    @MainActor
    private func pingTahoe() async {
        let result = await ZaytoonaClient().healthStatus(host: model.activeHost, port: model.discoveredPort)
        if result.ok {
            model.markConnected(latency: result.latencyMs)
            model.lastMessage = "Tahoe connected"
        } else {
            model.markDisconnected()
            model.lastMessage = "Receiver not reachable"
        }
    }

    @MainActor
    private func sendInput() async {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        sending = true
        defer { sending = false }

        do {
            try await ZaytoonaClient().send(
                host: model.activeHost,
                port: model.discoveredPort,
                pairCode: model.pairCode,
                value: value
            )
            model.markConnected(latency: model.lastLatencyMs)
            model.lastMessage = "Sent to Tahoe"
            model.addActivity("Command sent", value)
            input = ""
        } catch {
            model.markDisconnected()
            model.lastMessage = error.localizedDescription
        }
    }

    private func refreshBattery() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        phoneBattery = level < 0 ? 0 : Int(level * 100)
        charging = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
    }

    private func saveParking() {
        guard let coordinate = locationManager.location?.coordinate else {
            model.lastMessage = "Waiting for your iPhone location"
            return
        }
        model.parkingSession = ParkingSession(coordinate: coordinate)
        model.addActivity("Parking saved", "Tahoe location saved from iPhone GPS")
    }

    private func walkToTahoe() {
        guard let coordinate = parkedCoordinate else { return }
        let placemark = MKPlacemark(coordinate: coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = "Zaytoona"
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }

    private func duration(from start: Date, to end: Date) -> String {
        let seconds = max(0, Int(end.timeIntervalSince(start)))
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }
}
