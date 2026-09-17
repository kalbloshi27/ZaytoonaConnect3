import Foundation
import Combine

@MainActor
final class ZaytoonaModel: ObservableObject {
    @Published var pairCode: String {
        didSet { UserDefaults.standard.set(pairCode, forKey: "pairCode") }
    }

    @Published var manualHost: String {
        didSet { UserDefaults.standard.set(manualHost, forKey: "manualHost") }
    }

    @Published var discoveredHost: String?
    @Published var discoveredPort: Int = 8765
    @Published var isConnected = false
    @Published var lastMessage = "Ready"
    @Published var lastConnectedAt: Date?
    @Published var lastLatencyMs: Int?

    @Published var parkingSession: ParkingSession? {
        didSet { persistParkingSession() }
    }

    @Published var activity: [ActivityItem] = []

    var activeHost: String? {
        if let discoveredHost, !discoveredHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return discoveredHost.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let manual = manualHost.trimmingCharacters(in: .whitespacesAndNewlines)
        return manual.isEmpty ? nil : manual
    }

    init() {
        pairCode = UserDefaults.standard.string(forKey: "pairCode") ?? "000000"
        manualHost = UserDefaults.standard.string(forKey: "manualHost") ?? ""

        if let data = UserDefaults.standard.data(forKey: "parkingSession"),
           let session = try? JSONDecoder().decode(ParkingSession.self, from: data) {
            parkingSession = session
        } else {
            parkingSession = nil
        }
    }

    func markConnected(latency: Int?) {
        isConnected = true
        lastConnectedAt = Date()
        lastLatencyMs = latency
    }

    func markDisconnected() {
        isConnected = false
        lastLatencyMs = nil
    }

    func addActivity(_ title: String, _ detail: String) {
        activity.insert(ActivityItem(title: title, detail: detail), at: 0)
        if activity.count > 50 { activity.removeLast(activity.count - 50) }
    }

    private func persistParkingSession() {
        if let parkingSession,
           let data = try? JSONEncoder().encode(parkingSession) {
            UserDefaults.standard.set(data, forKey: "parkingSession")
        } else {
            UserDefaults.standard.removeObject(forKey: "parkingSession")
        }
    }
}
