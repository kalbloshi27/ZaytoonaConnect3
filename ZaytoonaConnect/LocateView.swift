import SwiftUI
import MapKit

struct LocateView: View {
    @EnvironmentObject var model: ZaytoonaModel
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 29.3759, longitude: 47.9774), span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Find My Tahoe").font(.system(size: 31, weight: .bold))
                        Text("Zaytoona’s saved parking location").font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusDot(active: model.connected)
                }

                mapCard

                Button { model.openWalkingDirections() } label: {
                    Label("Walk to Tahoe", systemImage: "figure.walk")
                }.buttonStyle(ZPrimaryButton(bright: true))

                HStack(spacing: 10) {
                    Button { model.saveTahoeLocation() } label: { smallAction("Save Here", "mappin.and.ellipse") }
                    Button { model.openDirections() } label: { smallAction("Directions", "location.fill") }
                }

                if let saved = model.lastTahoeLocation {
                    GlassPanel {
                        HStack {
                            Image("ZaytoonaCar").resizable().scaledToFill().frame(width: 92, height: 68).clipShape(RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Zaytoona").font(.headline)
                                Text(model.lastTahoePlaceName).font(.caption).foregroundStyle(.secondary)
                                Text(saved.savedAt.formatted(date: .abbreviated, time: .shortened)).font(.caption2).foregroundStyle(.secondary)
                                Text("\(saved.latitude, specifier: "%.5f"), \(saved.longitude, specifier: "%.5f")").font(.caption2.monospaced()).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 18)
        }
        .onAppear { updateRegion() }
        .onChange(of: model.lastTahoeLocation) { _ in updateRegion() }
    }

    private var mapCard: some View {
        ZStack(alignment: .topLeading) {
            Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: true, annotationItems: annotationItems) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    VStack(spacing: 0) {
                        ZStack {
                            Circle().fill(Color.zGold).frame(width: 52, height: 52)
                            Image(systemName: "car.fill").foregroundStyle(.black).font(.system(size: 22, weight: .bold))
                        }
                        Image(systemName: "triangle.fill").foregroundStyle(Color.zGold).rotationEffect(.degrees(180)).offset(y: -5)
                    }
                }
            }
            .frame(height: 410)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text("Zaytoona").font(.headline)
                Text(model.lastTahoeLocation == nil ? "No saved location" : "\(model.lastTahoePlaceName) • \(model.distanceToTahoeText())").font(.caption).foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(12)
        }
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.10)))
    }

    private var annotationItems: [MapPoint] {
        guard let saved = model.lastTahoeLocation else { return [] }
        return [MapPoint(coordinate: saved.coordinate)]
    }

    private func updateRegion() {
        if let saved = model.lastTahoeLocation {
            region.center = saved.coordinate
            region.span = MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
        } else if let current = model.locationManager.location {
            region.center = current.coordinate
        }
    }

    private func smallAction(_ title: String, _ icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .frame(maxWidth: .infinity).padding(.vertical, 15)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 19))
            .overlay(RoundedRectangle(cornerRadius: 19).stroke(Color.white.opacity(0.09)))
    }
}

private struct MapPoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
