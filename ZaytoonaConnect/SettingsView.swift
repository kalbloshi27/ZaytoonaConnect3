import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var model: ZaytoonaModel
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Settings").font(.system(size: 32, weight: .bold))
                Text("Zaytoona Connect v2 • iPhone 16 UI").font(.subheadline).foregroundStyle(.secondary)

                GlassPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Tahoe Connection", systemImage: "antenna.radiowaves.left.and.right").font(.headline)
                        TextField("http://192.168.x.x:8765", text: $model.baseURL)
                            .textInputAutocapitalization(.never).keyboardType(.URL)
                            .padding(12).background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                        SecureField("6-digit Pair Code", text: $model.pairCode)
                            .keyboardType(.numberPad)
                            .padding(12).background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                        Button { Task { await model.pair() } } label: { Label("Pair iPhone", systemImage: "link") }.buttonStyle(ZPrimaryButton(bright: true))
                        Button { model.scanAgain() } label: { Label("Search Again", systemImage: "arrow.clockwise") }.buttonStyle(ZPrimaryButton())
                    }
                }

                GlassPanel {
                    Toggle(isOn: Binding(get: { model.autoFindEnabled }, set: { model.setAutoFind($0) })) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Auto Find My Tahoe").font(.headline)
                            Text("Save the iPhone’s last location when Zaytoona disconnects.").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .tint(.zGold)
                }

                GlassPanel {
                    VStack(spacing: 12) {
                        Button { model.locationManager.requestAccess() } label: { settingsRow("Location Permission", "location.fill") }
                        Button { model.saveTahoeLocation() } label: { settingsRow("Save Current Location", "mappin.and.ellipse") }
                        Button { model.clearSavedLocation() } label: { settingsRow("Clear Saved Tahoe Location", "trash") }
                        Button { model.forgetPairing() } label: { settingsRow("Forget Pairing", "xmark.shield") }
                    }
                }

                Text("No Bluetooth features are used by Zaytoona Connect v2.")
                    .font(.caption2).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .center).padding(.top, 4)
            }
            .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 18)
        }
    }

    private func settingsRow(_ title: String, _ icon: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(.zGold).frame(width: 26)
            Text(title).foregroundStyle(.white)
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }.padding(.vertical, 4)
    }
}
