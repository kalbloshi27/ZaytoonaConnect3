import SwiftUI

struct ParkingView: View {
    @EnvironmentObject var model: ZaytoonaModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                Text(model.status.parkingRunning ? "Parking Active" : "Parking")
                    .font(.caption.weight(.semibold)).tracking(2).foregroundStyle(.secondary)
                Text(model.status.parkingRunning ? model.status.parkingElapsedText : "00:00:00")
                    .font(.system(size: 52, weight: .light, design: .rounded)).monospacedDigit()

                ZStack(alignment: .bottomLeading) {
                    Image("ZaytoonaHero").resizable().scaledToFill().frame(height: 330).clipped()
                        .overlay(LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .top, endPoint: .bottom))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Zaytoona").font(.title2.weight(.bold))
                        Text(model.lastTahoeLocation == nil ? "Save your parking location" : "Parking location saved")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }.padding(18)
                }
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.10)))

                Button {
                    Task {
                        if model.status.parkingRunning {
                            _ = await model.send(type: "parking_stop")
                        } else {
                            model.saveTahoeLocation(source: "Parking Started")
                            _ = await model.send(type: "parking_start")
                        }
                    }
                } label: {
                    Label(model.status.parkingRunning ? "Stop Parking" : "Start Parking", systemImage: model.status.parkingRunning ? "stop.fill" : "play.fill")
                }
                .buttonStyle(ZPrimaryButton(bright: !model.status.parkingRunning))

                HStack(spacing: 10) {
                    MetricBox(icon: "mappin.fill", title: "Location", value: model.lastTahoeLocation == nil ? "—" : "Saved", sub: model.lastTahoeLocation?.source ?? "No location")
                    MetricBox(icon: "clock.arrow.circlepath", title: "Status", value: model.status.parkingRunning ? "Active" : "Idle", sub: model.connected ? "Receiver online" : "Local mode", accent: model.status.parkingRunning ? .green : .zGold)
                }
            }
            .padding(.horizontal, 18).padding(.top, 18).padding(.bottom, 18)
        }
    }
}
