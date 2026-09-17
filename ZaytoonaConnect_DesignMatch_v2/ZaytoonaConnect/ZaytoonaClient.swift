import Foundation

struct ZaytoonaClient {
    enum ClientError: LocalizedError {
        case missingHost
        case invalidURL
        case badResponse(Int)

        var errorDescription: String? {
            switch self {
            case .missingHost: return "No Tahoe receiver found."
            case .invalidURL: return "The Tahoe receiver address is invalid."
            case .badResponse(let code): return "Tahoe receiver returned HTTP \(code)."
            }
        }
    }

    func send(host: String?, port: Int, pairCode: String, type: String = "auto", value: String) async throws {
        guard let cleanHost = clean(host: host) else { throw ClientError.missingHost }
        guard let url = URL(string: "http://\(cleanHost):\(port)/command") else {
            throw ClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 8
        request.httpBody = try JSONEncoder().encode(ZaytoonaCommand(key: pairCode, type: type, value: value))

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else { throw ClientError.badResponse(http.statusCode) }
    }

    func health(host: String?, port: Int) async -> Bool {
        let result = await healthStatus(host: host, port: port)
        return result.ok
    }

    func healthStatus(host: String?, port: Int) async -> (ok: Bool, latencyMs: Int?) {
        guard let cleanHost = clean(host: host),
              let url = URL(string: "http://\(cleanHost):\(port)/health") else {
            return (false, nil)
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 3
        let started = Date()

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                return (false, nil)
            }

            let latency = max(1, Int(Date().timeIntervalSince(started) * 1000))
            return (true, latency)
        } catch {
            return (false, nil)
        }
    }

    private func clean(host: String?) -> String? {
        guard var host, !host.isEmpty else { return nil }
        host = host
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "https://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if host.hasSuffix(".") { host.removeLast() }
        return host.isEmpty ? nil : host
    }
}
