import SwiftUI

struct ParkingView: View {
    @EnvironmentObject private var model: ZaytoonaModel
    @EnvironmentObject private var locationManager: LocationManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zBackground.ignoresSafeArea()
                VStack(spacing: 18) {
                    Spacer()
                    Image(systemName: model.parkingSession == nil ? "parkingsign.circle" : "parkingsign.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(Color.zGold)
                    Text(model.parkingSession == nil ? "Parking Ready" : "Parking Session Active")
                        .font(.title2.bold())

                    if let session = model.parkingSession {
                        Text("Started \(session.startedAt.formatted(date: .omitted, time: .shortened))")
                            .foregroundStyle(Color.zMuted)
                        TimelineView(.periodic(from: session.startedAt, by: 1)) { context in
                            Text(duration(from: session.startedAt, to: context.date))
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        }
                        Button("End Parking") { endParking() }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                    } else {
                        Text("Start a session to remember where you left the Tahoe.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.zMuted)
                        Button("Start Parking") { startParking() }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.zGold)
                            .foregroundStyle(.black)
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Parking")
        }
    }

    private func startParking() {
        model.parkingSession = ParkingSession(coordinate: locationManager.location?.coordinate)
        model.addActivity("Parking started", "Tahoe parking position saved")
    }

    private func endParking() {
        guard var session = model.parkingSession else { return }
        session.endedAt = Date()
        model.parkingSession = nil
        model.addActivity("Parking ended", "Session finished")
    }

    private func duration(from start: Date, to end: Date) -> String {
        let seconds = max(0, Int(end.timeIntervalSince(start)))
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }
}
