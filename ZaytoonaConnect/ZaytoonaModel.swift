import Foundation
import SwiftUI
import UIKit
import CoreLocation
import MapKit

@MainActor
final class ZaytoonaModel: ObservableObject {
    @Published var baseURL: String
    @Published var pairCode: String
    @Published var status = ZaytoonaStatus()
    @Published var connected = false
    @Published var latencyMs: Int? = nil
    @Published var busy = false
    @Published var message = "Searching for Tahoe…"
    @Published var selectedTab: ZTab = .home
    @Published var lastTahoeLocation: SavedTahoeLocation?
    @Published var activities: [ActivityItem] = []
    @Published var autoFindEnabled: Bool
    @Published var phoneBattery: Int = 0
    @Published var lastTahoePlaceName: String = "No parking location saved"

    let discovery = BonjourDiscovery()
    let locationManager = LocationManager()
    private let client = ZaytoonaClient()
    private let defaults = UserDefaults.standard
    private var pollTask: Task<Void, Never>?
    private var lastConnectionState = false
    private var lastKnownCandidate: CLLocation?

    init() {
        baseURL = defaults.string(forKey: "receiver_base_url") ?? ""
        pairCode = defaults.string(forKey: "pair_code") ?? ""
        autoFindEnabled = defaults.object(forKey: "auto_find") as? Bool ?? true

        if let data = defaults.data(forKey: "last_tahoe_location"),
           let saved = try? JSONDecoder().decode(SavedTahoeLocation.self, from: data) {
            lastTahoeLocation = saved
        }
        if let data = defaults.data(forKey: "activity_items"),
           let saved = try? JSONDecoder().decode([ActivityItem].self, from: data) {
            activities = saved
        }

        UIDevice.current.isBatteryMonitoringEnabled = true
        updateBattery()
        locationManager.requestAccess()
        discovery.start()
        Task { [weak self] in await self?.refreshSavedPlaceName() }

        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.tick()
                try? await Task.sleep(nanoseconds: 2_500_000_000)
            }
        }
    }

    deinit { pollTask?.cancel() }

    func tick() async {
        updateBattery()
        if let current = locationManager.location { lastKnownCandidate = current }
        await autoConnectAndRefresh()
    }

    func setAutoFind(_ value: Bool) {
        autoFindEnabled = value
        defaults.set(value, forKey: "auto_find")
    }

    func autoConnectAndRefresh() async {
        if baseURL.isEmpty, let first = discovery.services.first {
            baseURL = first.baseURL
            defaults.set(baseURL, forKey: "receiver_base_url")
        }
        guard !baseURL.isEmpty else {
            transitionConnection(to: false)
            message = discovery.isSearching ? "Searching for Zaytoona…" : "Tahoe not found"
            return
        }
        do {
            let latency = try await client.ping(baseURL: baseURL)
            latencyMs = max(1, Int(latency.rounded()))
            transitionConnection(to: true)
            message = pairCode.isEmpty ? "Tahoe found • Pair once" : "Tahoe connected"
            if !pairCode.isEmpty, let s = try? await client.status(baseURL: baseURL, key: pairCode) { status = s }
        } catch {
            latencyMs = nil
            transitionConnection(to: false)
            message = "Receiver offline"
            if discovery.services.isEmpty { discovery.start() }
        }
    }

    private func transitionConnection(to newValue: Bool) {
        let wasConnected = lastConnectionState
        connected = newValue
        lastConnectionState = newValue

        if newValue, !wasConnected {
            addActivity(title: "Tahoe connected", detail: "Receiver online", symbol: "antenna.radiowaves.left.and.right")
        }

        if !newValue, wasConnected, autoFindEnabled {
            saveTahoeLocation(source: "Auto Find My Tahoe")
        }
    }

    func pair() async {
        let code = pairCode.filter(\.isNumber)
        pairCode = String(code.prefix(6))
        guard pairCode.count == 6 else { message = "Pair Code must be 6 digits"; return }
        if baseURL.isEmpty, let first = discovery.services.first { baseURL = first.baseURL }
        guard !baseURL.isEmpty else { message = "Tahoe receiver not found"; return }
        busy = true
        defer { busy = false }
        do {
            try await client.pair(baseURL: baseURL, key: pairCode)
            defaults.set(baseURL, forKey: "receiver_base_url")
            defaults.set(pairCode, forKey: "pair_code")
            connected = true
            message = "Paired ✓"
            addActivity(title: "iPhone paired", detail: "Trusted local connection", symbol: "checkmark.shield.fill")
            await refreshStatus()
        } catch { message = error.localizedDescription }
    }

    func refreshStatus() async {
        guard !baseURL.isEmpty else { return }
        do {
            status = try await client.status(baseURL: baseURL, key: pairCode)
            transitionConnection(to: status.ok)
        } catch { transitionConnection(to: false) }
    }

    func send(type: String, value: String = "") async -> Bool {
        guard !baseURL.isEmpty else { message = "Tahoe receiver not found"; return false }
        busy = true
        defer { busy = false }
        do {
            let response = try await client.command(baseURL: baseURL, key: pairCode, type: type, value: value)
            if response.ok {
                message = "Sent to Tahoe ✓"
                await refreshStatus()
                return true
            }
            message = response.message ?? "Command failed"
            return false
        } catch {
            message = error.localizedDescription
            return false
        }
    }

    func saveTahoeLocation(source: String = "Manual Save") {
        guard let loc = locationManager.location ?? lastKnownCandidate else {
            message = "Location is not available yet"
            locationManager.requestAccess()
            return
        }
        let saved = SavedTahoeLocation(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude, savedAt: Date(), source: source)
        lastTahoeLocation = saved
        if let data = try? JSONEncoder().encode(saved) { defaults.set(data, forKey: "last_tahoe_location") }
        addActivity(title: "Tahoe location saved", detail: source, symbol: "mappin.and.ellipse")
        message = "Tahoe location saved ✓"
        Task { [weak self] in await self?.refreshSavedPlaceName() }
    }

    func openWalkingDirections() {
        guard let saved = lastTahoeLocation else { message = "Save Tahoe location first"; return }
        let item = MKMapItem(placemark: MKPlacemark(coordinate: saved.coordinate))
        item.name = "Zaytoona • Tahoe"
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }

    func openDirections() {
        guard let saved = lastTahoeLocation else { message = "Save Tahoe location first"; return }
        let item = MKMapItem(placemark: MKPlacemark(coordinate: saved.coordinate))
        item.name = "Zaytoona • Tahoe"
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    func etaShareText() async -> String {
        guard let saved = lastTahoeLocation else { return "Zaytoona: Tahoe location has not been saved yet." }
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: saved.coordinate))
        guard let current = locationManager.location else {
            return "Zaytoona • Tahoe location: \(saved.latitude), \(saved.longitude)"
        }
        let source = MKMapItem(placemark: MKPlacemark(coordinate: current.coordinate))
        let req = MKDirections.Request()
        req.source = source
        req.destination = destination
        req.transportType = .walking
        if let response = try? await MKDirections(request: req).calculate(), let route = response.routes.first {
            let min = max(1, Int(route.expectedTravelTime / 60.0))
            return "I’m about \(min) min walking from Zaytoona 🚙 • Tahoe location: \(saved.latitude), \(saved.longitude)"
        }
        return "Zaytoona • Tahoe location: \(saved.latitude), \(saved.longitude)"
    }

    func clearSavedLocation() {
        lastTahoeLocation = nil
        lastTahoePlaceName = "No parking location saved"
        defaults.removeObject(forKey: "last_tahoe_location")
        message = "Saved Tahoe location cleared"
    }

    func refreshSavedPlaceName() async {
        guard let saved = lastTahoeLocation else {
            lastTahoePlaceName = "No parking location saved"
            return
        }
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: saved.latitude, longitude: saved.longitude)
        do {
            let marks = try await geocoder.reverseGeocodeLocation(location)
            if let mark = marks.first {
                let parts = [mark.locality, mark.subAdministrativeArea, mark.country].compactMap { $0 }.filter { !$0.isEmpty }
                lastTahoePlaceName = parts.isEmpty ? "Saved Tahoe location" : parts.joined(separator: ", ")
            } else {
                lastTahoePlaceName = "Saved Tahoe location"
            }
        } catch {
            lastTahoePlaceName = "Saved Tahoe location"
        }
    }

    func distanceToTahoeText() -> String {
        guard let current = locationManager.location, let saved = lastTahoeLocation else { return "—" }
        let target = CLLocation(latitude: saved.latitude, longitude: saved.longitude)
        let meters = current.distance(from: target)
        if meters < 1000 { return "\(Int(meters.rounded())) m" }
        return String(format: "%.1f km", meters / 1000.0)
    }

    func forgetPairing() {
        pairCode = ""
        defaults.removeObject(forKey: "pair_code")
        message = "Pair code removed"
    }

    func use(_ service: DiscoveredZaytoona) {
        baseURL = service.baseURL
        defaults.set(baseURL, forKey: "receiver_base_url")
        message = "Found \(service.name)"
    }

    func scanAgain() {
        discovery.start()
        message = "Searching for Tahoe…"
    }

    private func updateBattery() {
        let level = UIDevice.current.batteryLevel
        phoneBattery = level >= 0 ? Int((level * 100).rounded()) : 0
    }

    private func addActivity(title: String, detail: String, symbol: String) {
        activities.insert(ActivityItem(id: UUID(), title: title, detail: detail, date: Date(), symbol: symbol), at: 0)
        if activities.count > 20 { activities = Array(activities.prefix(20)) }
        if let data = try? JSONEncoder().encode(activities) { defaults.set(data, forKey: "activity_items") }
    }
}

enum ZTab: String, CaseIterable {
    case home, locate, park, activity, settings
    var title: String {
        switch self {
        case .home: return "Home"
        case .locate: return "Locate"
        case .park: return "Park"
        case .activity: return "Activity"
        case .settings: return "Settings"
        }
    }
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .locate: return "mappin.and.ellipse"
        case .park: return "parkingsign.circle.fill"
        case .activity: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}
