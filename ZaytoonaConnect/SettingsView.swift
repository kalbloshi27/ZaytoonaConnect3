import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: ZaytoonaModel
    @EnvironmentObject private var discovery: BonjourDiscovery

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zBackground.ignoresSafeArea()
                Form {
                    Section("Connection") {
                        row("antenna.radiowaves.left.and.right", "Bonjour", discovery.isSearching ? "Searching…" : (model.discoveredHost ?? "Not found"))
                        TextField("Manual Tahoe IP / hostname", text: $model.manualHost)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button("Auto Find My Tahoe") { discovery.start() }
                    }

                    Section("Pairing") {
                        HStack {
                            Image(systemName: "key.fill").foregroundStyle(Color.zGold).frame(width: 26)
                            TextField("6-digit Pair Code", text: $model.pairCode)
                                .keyboardType(.numberPad)
                                .onChange(of: model.pairCode) { _, newValue in
                                    let digits = String(newValue.filter(\.isNumber).prefix(6))
                                    if digits != newValue { model.pairCode = digits }
                                }
                        }
                    }

                    Section("Receiver") {
                        row("network", "Port", String(model.discoveredPort))
                        row("lock.shield", "Transport", "Personal Hotspot / Local Network")
                        row("car.fill", "Navigation", "Waze on Tahoe")
                        row("play.rectangle.fill", "CarPlay", "Separate launcher button")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
    }

    @ViewBuilder
    private func row(_ icon: String, _ title: String, _ value: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(Color.zGold).frame(width: 26)
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary).multilineTextAlignment(.trailing)
        }
    }
}
