import Foundation
import CoreLocation

struct ZaytoonaCommand: Codable {
    let key: String
    let type: String
    let value: String
}

struct ParkingSession: Identifiable, Codable {
    let id: UUID
    let startedAt: Date
    var endedAt: Date?
    var latitude: Double?
    var longitude: Double?

    init(id: UUID = UUID(), startedAt: Date = Date(), endedAt: Date? = nil, coordinate: CLLocationCoordinate2D? = nil) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.latitude = coordinate?.latitude
        self.longitude = coordinate?.longitude
    }
}

struct ActivityItem: Identifiable, Codable {
    let id: UUID
    let date: Date
    let title: String
    let detail: String

    init(id: UUID = UUID(), date: Date = Date(), title: String, detail: String) {
        self.id = id
        self.date = date
        self.title = title
        self.detail = detail
    }
}
