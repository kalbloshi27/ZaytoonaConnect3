import SwiftUI

struct ParkingView: View {
    @EnvironmentObject private var model: ZaytoonaModel
    @EnvironmentObject private var locationManager: LocationManager

    var body: some View {
        ZStack {
            Color.zBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 5) {
                        Image(systemName: model.parkingSession == nil ? "car.circle" : "car.circle.fill")
                            .font(.system(size: 35))
                            .foregroundStyle(Color.zCream)

                        Text(model.parkingSession == nil ? "Parking Ready" : "Parking Active")
                            .font(.headline)

                        if let session = model.parkingSession {
                            TimelineView(.periodic(from: session.startedAt, by: 1)) { context in
                                Text(duration(from: session.startedAt, to: context.date))
                                    .font(.system(size: 41, weight: .medium, design: .rounded))
                                    .monospacedDigit()
                            }

                            Text("Since \(session.startedAt.formatted(date: .omitted, time: .shortened))")
                                .font(.subheadline)
                                .foregroundStyle(Color.zMuted)
                            Text(session.startedAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(Color.zMuted)
                        } else {
                            Text("Save the Tahoe location from your iPhone GPS.")
                                .font(.subheadline)
                                .foregroundStyle(Color.zMuted)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 10)

                    Image("TahoeRear")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 230)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.zBorder, lineWidth: 1)
                        )

                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.zCream)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Saved Tahoe Location")
                                .font(.headline)
                            Text(coordinateText)
                                .font(.caption.monospaced())
                                .foregroundStyle(Color.zMuted)
                        }

                        Spacer()

                        Button("Save Note") { }
                            .font(.caption.weight(.medium))
                            .buttonStyle(.bordered)
                            .tint(.white)
                    }
                    .zThinCard()

                    VStack(alignment: .leading, spacing: 11) {
                        Text("Photos (3)")
                            .font(.subheadline.weight(.semibold))

                        HStack(spacing: 8) {
                            photoThumb("TahoeFront")
                            photoThumb("TahoeRear")
                            photoThumb("TahoeFront")

                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.zPanelStrong)
                                .frame(height: 72)
                                .overlay(Image(systemName: "plus").font(.title3))
                        }
                    }
                    .zCard()

                    Button {
                        model.parkingSession == nil ? startParking() : endParking()
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: model.parkingSession == nil ? "parkingsign.circle.fill" : "stop.fill")
                            Text(model.parkingSession == nil ? "Start Parking" : "Stop Parking")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.vertical, 15)
                        .background(model.parkingSession == nil ? Color.zCream : Color.red.opacity(0.88))
                        .foregroundStyle(model.parkingSession == nil ? .black : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Parking")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func photoThumb(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var coordinateText: String {
        guard let session = model.parkingSession,
              let latitude = session.latitude,
              let longitude = session.longitude else {
            return "No parking location saved"
        }
        return String(format: "%.5f, %.5f", latitude, longitude)
    }

    private func startParking() {
        guard let coordinate = locationManager.location?.coordinate else {
            model.lastMessage = "Waiting for your iPhone location"
            return
        }
        model.parkingSession = ParkingSession(coordinate: coordinate)
        model.addActivity("Parking started", "Tahoe parking position saved")
    }

    private func endParking() {
        guard var session = model.parkingSession else { return }
        session.endedAt = Date()
        model.addActivity("Parking ended", "Session lasted \(duration(from: session.startedAt, to: Date()))")
        model.parkingSession = nil
    }

    private func duration(from start: Date, to end: Date) -> String {
        let seconds = max(0, Int(end.timeIntervalSince(start)))
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }
}
