import Foundation
import Combine

@MainActor
final class BonjourDiscovery: NSObject, ObservableObject, @preconcurrency NetServiceBrowserDelegate, @preconcurrency NetServiceDelegate {
    @Published private(set) var isSearching = false
    @Published private(set) var resolvedHost: String?
    @Published private(set) var resolvedPort: Int = 8765

    private let browser = NetServiceBrowser()
    private var services: [NetService] = []

    override init() {
        super.init()
        browser.delegate = self
    }

    func start() {
        guard !isSearching else { return }
        resolvedHost = nil
        services.removeAll()
        isSearching = true
        browser.searchForServices(ofType: "_zaytoona._tcp.", inDomain: "local.")
    }

    func stop() {
        browser.stop()
        isSearching = false
    }

    nonisolated func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            services.append(service)
            service.delegate = self
            service.resolve(withTimeout: 5)
        }
    }

    nonisolated func netServiceDidResolveAddress(_ sender: NetService) {
        let host = sender.hostName?.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        let port = sender.port
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let host, !host.isEmpty {
                resolvedHost = host
                resolvedPort = port > 0 ? port : 8765
                stop()
            }
        }
    }

    nonisolated func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        Task { @MainActor [weak self] in self?.isSearching = false }
    }

    nonisolated func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        // Keep searching. Another advertised service may resolve successfully.
    }
}
