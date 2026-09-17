import SwiftUI

struct ParkingView: View {
    @EnvironmentObject private var model: ZaytoonaModel
    @EnvironmentObject private var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss

    @AppStorage("parkingNote") private var parkingNote = ""
    @State private var showNoteEditor = false
    @State private var draftNote = ""

    var body: some View {
        ZStack {
            Color.zBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    topBar
                    parkingHeader
                    carHero
                    locationCard
                    photoStrip
                    parkingButton
                }
                .padding(.horizontal, 17)
                .padding(.top, 7)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showNoteEditor) {
            noteEditor
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                ZIconCircle(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Parking")
                .font(.subheadline.weight(.semibold))

            Spacer()

            Button {
                draftNote = parkingNote
                showNoteEditor = true
            } label: {
                ZIconCircle(systemName: "ellipsis")
            }
            .buttonStyle(.plain)
        }
    }

    private var parkingHeader: some View {
        VStack(spacing: 5) {
            Image(systemName: model.parkingSession == nil ? "car.circle" : "car.circle.fill")
                .font(.system(size: 33))
                .foregroundStyle(Color.zCream)

            Text(model.parkingSession == nil ? "Parking Ready" : "Parking Active")
                .font(.headline)

            if let session = model.parkingSession {
                TimelineView(.periodic(from: session.startedAt, by: 1)) { context in
                    Text(duration(from: session.startedAt, to: context.date))
                        .font(.system(size: 40, weight: .medium, design: .rounded))
                        .monospacedDigit()
                }

                Text("Since \(session.startedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline)
                    .foregroundStyle(Color.zMuted)

                Text(session.startedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(Color.zMuted)
            } else {
                Text("Save the Tahoe location from your iPhone GPS")
                    .font(.subheadline)
                    .foregroundStyle(Color.zMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 3)
    }

    private var carHero: some View {
        ZStack(alignment: .bottom) {
            Image("TahoeRear")
                .resizable()
                .scaledToFill()
                .frame(height: 224)
                .clipped()

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.52)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.zBorder, lineWidth: 1)
        )
    }

    private var locationCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.zCream)

            VStack(alignment: .leading, spacing: 3) {
                Text("Saved Tahoe Location")
                    .font(.subheadline.weight(.semibold))
                Text(coordinateText)
                    .font(.caption2.monospaced())
                    .foregroundStyle(Color.zMuted)

                if !parkingNote.isEmpty {
                    Text(parkingNote)
                        .font(.caption2)
                        .foregroundStyle(Color.zMutedStrong)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button("Save Note") {
                draftNote = parkingNote
                showNoteEditor = true
            }
            .font(.caption.weight(.medium))
            .buttonStyle(.bordered)
            .tint(Color.zCream)
        }
        .zThinCard(12)
    }

    private var photoStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tahoe Photos")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 8) {
                photoThumb("TahoeFront")
                photoThumb("TahoeRear")
                photoThumb("TahoeFront")

                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color.zSurfaceRaised)
                    .frame(height: 67)
                    .overlay(
                        Image(systemName: "car.fill")
                            .font(.title3)
                            .foregroundStyle(Color.zMuted)
                    )
            }
        }
        .zCard(12, radius: 18)
    }

    private var parkingButton: some View {
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
            .background(model.parkingSession == nil ? Color.zCream : Color.zRed)
            .foregroundStyle(model.parkingSession == nil ? .black : .white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var noteEditor: some View {
        NavigationStack {
            ZStack {
                Color.zBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Parking Note")
                        .font(.title2.bold())

                    TextEditor(text: $draftNote)
                        .scrollContentBackground(.hidden)
                        .padding(10)
                        .frame(minHeight: 150)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.zSurface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.zBorder, lineWidth: 1)
                                )
                        )

                    Button {
                        parkingNote = draftNote.trimmingCharacters(in: .whitespacesAndNewlines)
                        showNoteEditor = false
                        hideKeyboard()
                    } label: {
                        Text("Save Note")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.zCream)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }

                    Spacer()
                }
                .padding(18)
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { hideKeyboard() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func photoThumb(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 67)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
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
        model.addActivity(
            "Parking ended",
            "Session lasted \(duration(from: session.startedAt, to: Date()))"
        )
        model.parkingSession = nil
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
