import SwiftUI
import MapKit

struct LocateView: View {
    @EnvironmentObject private var locationManager: LocationManager

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 29.3759, longitude: 47.9774),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(
                    coordinateRegion: $region,
                    interactionModes: .all,
                    showsUserLocation: true
                )
                .ignoresSafeArea(edges: .bottom)

                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Color.zGold)

                        VStack(alignment: .leading) {
                            Text("Find My Tahoe")
                                .font(.headline)

                            Text("Uses your iPhone location now. Tahoe parking position can be stored from Parking.")
                                .font(.caption)
                                .foregroundStyle(Color.zMuted)
                        }

                        Spacer()
                    }

                    Button("Recenter") {
                        recenter()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.zGold)
                    .foregroundStyle(.black)
                }
                .zCard()
                .padding()
            }
            .navigationTitle("Locate")
            .onAppear {
                locationManager.start()
                recenter()
            }
            .onChange(of: locationManager.location) { _ in
                recenter()
            }
        }
    }

    private func recenter() {
        guard let location = locationManager.location else { return }

        region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 900,
            longitudinalMeters: 900
        )
    }
}
