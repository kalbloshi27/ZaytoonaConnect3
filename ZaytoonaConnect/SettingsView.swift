import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: ZaytoonaModel
    @EnvironmentObject private var discovery: BonjourDiscovery

    private enum Field: Hashable {
        case host
        case pairCode
    }

    @FocusState private var focusedField: Field?
    @State private var testing = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Settings")
                                    .font(.largeTitle.bold())
                                Text("Tahoe receiver and pairing")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.zMuted)
                            }
                            Spacer()
                        }

                        sectionCard(title: "Connection") {
                            settingsRow(
                                icon: "antenna.radiowaves.left.and.right",
                                title: "Bonjour",
                                value: discovery.isSearching ? "Searching…" : (model.discoveredHost ?? "Not found")
                            )

                            separator

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Manual Tahoe IP / hostname")
                                    .font(.caption)
                                    .foregroundStyle(Color.zMuted)

                                TextField("192.168.x.x", text: $model.manualHost)
                                    .focused($focusedField, equals: .host)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .keyboardType(.URL)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        focusedField = nil
                                        hideKeyboard()
                                    }
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 13).fill(Color.black.opacity(0.34)))
                            }
                            .padding(.vertical, 12)

                            Button {
                                focusedField = nil
                                hideKeyboard()
                                discovery.start()
                            } label: {
                                Label("Auto Find My Tahoe", systemImage: "location.magnifyingglass")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.bordered)
                            .tint(Color.zCream)
                        }

                        sectionCard(title: "Pairing") {
                            HStack(spacing: 12) {
                                Image(systemName: "key.fill")
                                    .foregroundStyle(Color.zCream)
                                    .frame(width: 25)

                                TextField("6-digit Pair Code", text: $model.pairCode)
                                    .focused($focusedField, equals: .pairCode)
                                    .keyboardType(.numberPad)
                                    .onChange(of: model.pairCode) { newValue in
                                        let digits = String(newValue.filter(\.isNumber).prefix(6))
                                        if digits != newValue { model.pairCode = digits }
                                    }
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 13).fill(Color.black.opacity(0.34)))
                        }

                        sectionCard(title: "Receiver") {
                            settingsRow(icon: "network", title: "Port", value: String(model.discoveredPort))
                            separator
                            settingsRow(icon: "lock.shield", title: "Transport", value: "Hotspot / Local Network")
                            separator
                            settingsRow(icon: "car.fill", title: "Navigation", value: "Waze on Tahoe")
                            separator
                            settingsRow(icon: "play.rectangle.fill", title: "CarPlay", value: "Separate launcher button")
                        }

                        Button {
                            focusedField = nil
                            hideKeyboard()
                            Task { await testConnection() }
                        } label: {
                            HStack {
                                Spacer()
                                if testing { ProgressView().tint(.black) }
                                Text(testing ? "Testing…" : "Test Connection")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding(.vertical, 14)
                            .background(Color.zCream)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(testing)

                        Text(model.lastMessage)
                            .font(.caption)
                            .foregroundStyle(Color.zMuted)
                    }
                    .padding(18)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                        hideKeyboard()
                    }
                }
            }
        }
    }

    private var separator: some View {
        Rectangle()
            .fill(Color.zBorder)
            .frame(height: 1)
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZSectionTitle(title: title)
                .padding(.bottom, 12)
            content()
        }
        .zCard()
    }

    private func settingsRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.zCream)
                .frame(width: 25)
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundStyle(Color.zMuted)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.vertical, 11)
    }

    @MainActor
    private func testConnection() async {
        testing = true
        defer { testing = false }

        let result = await ZaytoonaClient().healthStatus(host: model.activeHost, port: model.discoveredPort)
        if result.ok {
            model.markConnected(latency: result.latencyMs)
            model.lastMessage = "Tahoe connected successfully"
        } else {
            model.markDisconnected()
            model.lastMessage = "Tahoe receiver is not reachable"
        }
    }
}
