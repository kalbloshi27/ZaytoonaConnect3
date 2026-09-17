import SwiftUI
import MapKit

struct LocateView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $position) {
                    UserAnnotation()
                }
                .ignoresSafeArea(edges: .bottom)

                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Color.zGold)
                        VStack(alignment: .leading) {
                            Text("Find My Tahoe").font(.headline)
                            Text("Uses your iPhone location now. Tahoe parking position can be stored from Parking.")
                                .font(.caption)
                                .foregroundStyle(Color.zMuted)
                        }
                        Spacer()
                    }
                    Button("Recenter") {
                        if let location = locationManager.location {
                            position = .region(MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 900, longitudinalMeters: 900))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.zGold)
                    .foregroundStyle(.black)
                }
                .zCard()
                .padding()
            }
            .navigationTitle("Locate")
            .onAppear { locationManager.start() }
        }
    }
}
