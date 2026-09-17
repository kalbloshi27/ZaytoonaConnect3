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
    @Published var parkingSession: ParkingSession?
    @Published var activity: [ActivityItem] = []

    var activeHost: String? {
        let host = (discoveredHost?.isEmpty == false ? discoveredHost : manualHost)
        guard let host, !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return host.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init() {
        pairCode = UserDefaults.standard.string(forKey: "pairCode") ?? "000000"
        manualHost = UserDefaults.standard.string(forKey: "manualHost") ?? ""
    }

    func addActivity(_ title: String, _ detail: String) {
        activity.insert(ActivityItem(title: title, detail: detail), at: 0)
        if activity.count > 50 { activity.removeLast(activity.count - 50) }
    }
}
