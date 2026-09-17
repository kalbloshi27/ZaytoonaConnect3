import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var model: ZaytoonaModel
    @State private var sharePayload: SharePayload? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                BrandHeader()
                connectionCard
                hero
                metrics
                locationCard
                mainActions
                quickActions
                if !model.message.isEmpty {
                    Text(model.message).font(.caption).foregroundStyle(.secondary).padding(.top, 2)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 18)
        }
        .sheet(item: $sharePayload) { payload in
            ShareSheet(items: [payload.text])
        }
    }

    private var connectionCard: some View {
        HStack(spacing: 10) {
            StatusDot(active: model.connected)
            VStack(alignment: .leading, spacing: 2) {
                Text(model.connected ? "Tahoe Connected" : "Tahoe Offline").font(.headline)
                Text(model.connected ? "Receiver Online • \(model.latencyMs.map { "\($0) ms" } ?? "—")" : "Waiting for Zaytoona receiver")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(15)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.09)))
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            Image("ZaytoonaHero")
                .resizable().scaledToFill().frame(height: 330).clipped()
                .overlay(LinearGradient(colors: [.clear, .black.opacity(0.18), .black.opacity(0.78)], startPoint: .top, endPoint: .bottom))
            VStack(alignment: .leading, spacing: 5) {
                Text("ZAYTOONA").font(.caption.weight(.semibold)).tracking(2.6).foregroundStyle(.zGold)
                Text("More than a car.").font(.title2.weight(.semibold))
                Text("Your Tahoe, your place, your story.").font(.caption).foregroundStyle(.secondary)
            }.padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.10)))
    }

    private var metrics: some View {
        HStack(spacing: 10) {
            MetricBox(icon: "clock.fill", title: "Parking Timer", value: model.status.parkingRunning ? model.status.parkingElapsedText : "—", sub: model.status.parkingRunning ? "Active" : "Not running")
            MetricBox(icon: "battery.100percent", title: "Phone Battery", value: "\(model.phoneBattery)%", sub: UIDevice.current.batteryState == .charging ? "Charging" : "iPhone", accent: .green)
            MetricBox(icon: "antenna.radiowaves.left.and.right", title: "Connection", value: model.latencyMs.map { "\($0) ms" } ?? "—", sub: model.connected ? "Excellent" : "Offline", accent: model.connected ? .green : .orange)
        }
    }

    private var locationCard: some View {
        GlassPanel {
            HStack(spacing: 12) {
                Image(systemName: "mappin.and.ellipse").font(.system(size: 24, weight: .semibold)).foregroundStyle(.zGold)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Last Known Location").font(.caption).foregroundStyle(.secondary)
                    Text(model.lastTahoePlaceName)
                        .font(.headline)
                    if let saved = model.lastTahoeLocation {
                        Text(saved.savedAt.formatted(date: .abbreviated, time: .shortened)).font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button { model.selectedTab = .locate } label: {
                    Image(systemName: "map.fill").frame(width: 42, height: 42).background(Color.white.opacity(0.07), in: Circle())
                }
            }
        }
    }

    private var mainActions: some View {
        HStack(spacing: 10) {
            Button { model.openWalkingDirections() } label: { Label("Walk to Tahoe", systemImage: "figure.walk") }.buttonStyle(ZPrimaryButton(bright: true))
            Button {
                Task { sharePayload = SharePayload(text: await model.etaShareText()) }
            } label: { Label("Send ETA", systemImage: "arrowshape.turn.up.right.fill") }.buttonStyle(ZPrimaryButton())
        }
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            Button { model.openDirections() } label: { quick("Directions", "location.fill") }
            Button {
                if let saved = model.lastTahoeLocation {
                    sharePayload = SharePayload(text: "Zaytoona • Tahoe location: \(saved.latitude), \(saved.longitude)")
                }
            } label: { quick("Share Location", "square.and.arrow.up") }
            Button { model.saveTahoeLocation() } label: { quick("Save Parking", "bookmark.fill") }
        }
    }

    private func quick(_ title: String, _ icon: String) -> some View {
        VStack(spacing: 9) {
            Image(systemName: icon).font(.system(size: 19, weight: .semibold))
            Text(title).font(.caption2.weight(.medium)).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 78)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 19))
        .overlay(RoundedRectangle(cornerRadius: 19).stroke(Color.white.opacity(0.08)))
    }
}

private struct SharePayload: Identifiable { let id = UUID(); let text: String }
