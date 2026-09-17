import SwiftUI
import MapKit
import CoreLocation

private struct TahoeMapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct LocateView: View {
    @EnvironmentObject private var model: ZaytoonaModel
    @EnvironmentObject private var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 29.3759, longitude: 47.9774),
        span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
    )

    var body: some View {
        ZStack {
            Map(
                coordinateRegion: $region,
                interactionModes: .all,
                showsUserLocation: true,
                annotationItems: pins
            ) { pin in
                MapAnnotation(coordinate: pin.coordinate) {
                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(Color.zBackground)
                                .frame(width: 66, height: 66)
                                .overlay(Circle().stroke(Color.zCream, lineWidth: 2))

                            Image("TahoeFront")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 55, height: 55)
                                .clipShape(Circle())
                        }

                        Image(systemName: "triangle.fill")
                            .font(.system(size: 13))
                            .rotationEffect(.degrees(180))
                            .foregroundStyle(Color.zCream)
                            .offset(y: -3)
                    }
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 12) {
                topBar
                Spacer()
                tahoeCard
            }
            .padding(.horizontal, 15)
            .padding(.top, 6)
            .padding(.bottom, 12)
        }
        .navigationBarHidden(true)
        .onAppear {
            locationManager.start()
            recenter()
        }
        .onChange(of: locationManager.location) { _ in
            if parkedCoordinate == nil {
                recenter()
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                ZIconCircle(systemName: "chevron.left", size: 38)
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.zMuted)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Zaytoona")
                        .font(.subheadline.weight(.semibold))
                    Text(model.isConnected ? receiverSubtitle : "Receiver offline")
                        .font(.caption2)
                        .foregroundStyle(model.isConnected ? Color.zGreen : Color.zMuted)
                }

                Spacer()

                ZStatusDot(active: model.isConnected)
            }
            .zThinCard(10)

            Button {
                recenter()
            } label: {
                ZIconCircle(systemName: "location.fill", size: 38)
            }
            .buttonStyle(.plain)
        }
    }

    private var tahoeCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image("TahoeFront")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 69, height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Zaytoona")
                        .font(.headline)
                    Text(walkingInfo)
                        .font(.subheadline)
                    Text(parkingCoordinateText)
                        .font(.caption2)
                        .foregroundStyle(Color.zMuted)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    recenter()
                } label: {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Color.zPanelStrong))
                }
                .buttonStyle(.plain)
            }

            Button {
                walkToTahoe()
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "figure.walk")
                    Text("Start Walking")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(Color.zCream)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .disabled(parkedCoordinate == nil)

            HStack(spacing: 11) {
                mapAction(icon: "speaker.wave.2.fill", title: "Play Sound") {
                    Task { await sendTahoeCommand("FIND_SOUND") }
                }

                mapAction(icon: "flashlight.on.fill", title: "Flash Lights") {
                    Task { await sendTahoeCommand("FLASH_LIGHTS") }
                }

                mapAction(icon: "location.fill", title: "Directions") {
                    walkToTahoe()
                }
            }
        }
        .zCard(14, radius: 21)
    }

    private func mapAction(
        icon: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 39, height: 39)
                    .background(Circle().fill(Color.zPanelStrong))
                Text(title)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var pins: [TahoeMapPin] {
        guard let parkedCoordinate else { return [] }
        return [TahoeMapPin(coordinate: parkedCoordinate)]
    }

    private var parkedCoordinate: CLLocationCoordinate2D? {
        guard let session = model.parkingSession,
              let latitude = session.latitude,
              let longitude = session.longitude else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private var receiverSubtitle: String {
        if let ms = model.lastLatencyMs {
            return "Live • \(ms) ms"
        }
        return "Live • Local Network"
    }

    private var walkingInfo: String {
        guard let parkedCoordinate,
              let current = locationManager.location else {
            return "Saved parking location"
        }

        let parked = CLLocation(
            latitude: parkedCoordinate.latitude,
            longitude: parkedCoordinate.longitude
        )
        let meters = current.distance(from: parked)
        return String(
            format: "%.1f km • ~%d min walk",
            meters / 1000,
            max(1, Int(meters / 80))
        )
    }

    private var parkingCoordinateText: String {
        guard let parkedCoordinate else {
            return "No Tahoe parking location saved"
        }
        return String(
            format: "%.5f, %.5f",
            parkedCoordinate.latitude,
            parkedCoordinate.longitude
        )
    }

    private func recenter() {
        if let parkedCoordinate {
            region = MKCoordinateRegion(
                center: parkedCoordinate,
                latitudinalMeters: 900,
                longitudinalMeters: 900
            )
        } else if let coordinate = locationManager.location?.coordinate {
            region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 900,
                longitudinalMeters: 900
            )
        }
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
    private func sendTahoeCommand(_ command: String) async {
        do {
            try await ZaytoonaClient().send(
                host: model.activeHost,
                port: model.discoveredPort,
                pairCode: model.pairCode,
                value: command
            )
            model.lastMessage = "Command sent"
            model.addActivity("Tahoe action", command)
        } catch {
            model.lastMessage = error.localizedDescription
        }
    }
}
