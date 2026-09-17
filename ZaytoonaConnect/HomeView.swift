import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var model: ZaytoonaModel
    @EnvironmentObject private var discovery: BonjourDiscovery
    @State private var input = ""
    @State private var sending = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        header
                        connectionCard
                        sendCard
                        quickActions
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("ZAYTOONA")
                    .font(.caption.weight(.semibold))
                    .tracking(2.6)
                    .foregroundStyle(Color.zGold)
                Text("Tahoe Connect")
                    .font(.largeTitle.bold())
                Text("Local. Fast. Built for your Tahoe.")
                    .font(.subheadline)
                    .foregroundStyle(Color.zMuted)
            }
            Spacer()
            Image(systemName: "car.side.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.zGold)
        }
    }

    private var connectionCard: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(model.isConnected ? Color.green : Color.orange)
                .frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 4) {
                Text(model.isConnected ? "Tahoe Online" : "Searching for Tahoe")
                    .font(.headline)
                Text(model.activeHost ?? "No receiver found")
                    .font(.caption.monospaced())
                    .foregroundStyle(Color.zMuted)
            }
            Spacer()
            Button {
                discovery.start()
                Task { await pingTahoe() }
            } label: {
                Image(systemName: discovery.isSearching ? "antenna.radiowaves.left.and.right" : "arrow.clockwise")
                    .foregroundStyle(Color.zGold)
            }
        }
        .zCard()
    }

    private var sendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Send to Zaytoona", systemImage: "paperplane.fill")
                .font(.headline)
                .foregroundStyle(Color.zGold)

            TextField("Waze destination, YouTube Music link, or text…", text: $input, axis: .vertical)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.25)))

            Button {
                Task { await sendInput() }
            } label: {
                HStack {
                    Spacer()
                    if sending { ProgressView().tint(.black) }
                    Text(sending ? "Sending…" : "Send")
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(Color.zGold)
                .foregroundStyle(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || sending)

            Text(model.lastMessage)
                .font(.caption)
                .foregroundStyle(Color.zMuted)
        }
        .zCard()
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions").font(.headline)
            HStack(spacing: 10) {
                QuickAction(title: "Waze", icon: "location.fill") { input = "WAZE" }
                QuickAction(title: "Music", icon: "music.note") { input = "MUSIC" }
                QuickAction(title: "Home", icon: "house.fill") { Task { await send("HOME") } }
            }
        }
    }

    @MainActor
    private func pingTahoe() async {
        let ok = await ZaytoonaClient().health(host: model.activeHost, port: model.discoveredPort)
        model.isConnected = ok
        model.lastMessage = ok ? "Tahoe connected" : "Receiver not reachable yet"
    }

    @MainActor
    private func sendInput() async {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        sending = true
        defer { sending = false }
        await send(value)
        if model.isConnected { input = "" }
    }

    @MainActor
    private func send(_ value: String) async {
        do {
            try await ZaytoonaClient().send(host: model.activeHost, port: model.discoveredPort, pairCode: model.pairCode, value: value)
            model.isConnected = true
            model.lastMessage = "Sent to Tahoe"
            model.addActivity("Command sent", value)
        } catch {
            model.isConnected = false
            model.lastMessage = error.localizedDescription
        }
    }
}

private struct QuickAction: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.zPanel))
        }
    }
}
