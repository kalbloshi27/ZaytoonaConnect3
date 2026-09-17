import Foundation

@MainActor
final class BonjourDiscovery: NSObject, ObservableObject, NetServiceBrowserDelegate, NetServiceDelegate {
    @Published var services: [DiscoveredZaytoona] = []
    @Published var isSearching = false
    private let browser = NetServiceBrowser()
    private var resolving: [NetService] = []

    override init() {
        super.init()
        browser.delegate = self
    }

    func start() {
        services.removeAll()
        resolving.removeAll()
        isSearching = true
        browser.stop()
        browser.searchForServices(ofType: "_zaytoona._tcp.", inDomain: "local.")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        resolving.append(service)
        service.delegate = self
        service.resolve(withTimeout: 4)
    }

    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let host = sender.hostName, sender.port > 0 else { return }
        let item = DiscoveredZaytoona(name: sender.name, host: host, port: sender.port)
        if !services.contains(where: { $0.host == item.host && $0.port == item.port }) { services.append(item) }
        isSearching = false
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) { isSearching = false }
}
