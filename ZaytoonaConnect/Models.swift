import Foundation
import CoreLocation

struct ZaytoonaMediaStatus: Codable, Equatable {
    var title: String = "Nothing playing"
    var artist: String = ""
    var playing: Bool = false
    var durationMs: Int64 = 0
    var positionMs: Int64 = 0
    var packageName: String = ""
    var hasAccess: Bool = false
}

struct ZaytoonaStatus: Codable, Equatable {
    var ok: Bool = false
    var service: String = "Zaytoona"
    var version: String = ""
    var receiverOnline: Bool = false
    var localIp: String = ""
    var phoneTrusted: Bool = false
    var activeProfile: String = "daily"
    var parkingRunning: Bool = false
    var parkingElapsedMs: Int64 = 0
    var parkingElapsedText: String = "00:00:00"
    var lastDestination: String = ""
    var media: ZaytoonaMediaStatus = .init()
}

struct ZaytoonaCommandResponse: Codable {
    var ok: Bool
    var type: String?
    var message: String?
    var error: String?
}

struct DiscoveredZaytoona: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let host: String
    let port: Int
    var baseURL: String {
        let clean = host.hasSuffix(".") ? String(host.dropLast()) : host
        return "http://\(clean):\(port)"
    }
}

struct SavedTahoeLocation: Codable, Equatable {
    var latitude: Double
    var longitude: Double
    var savedAt: Date
    var source: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct ActivityItem: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let detail: String
    let date: Date
    let symbol: String
}
