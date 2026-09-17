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
        guard var host, !host.isEmpty else { throw ClientError.missingHost }
        host = host.replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "https://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if host.hasSuffix(".") { host.removeLast() }

        guard let url = URL(string: "http://\(host):\(port)/command") else {
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
        guard var host, !host.isEmpty else { return false }
        host = host.replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "https://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if host.hasSuffix(".") { host.removeLast() }
        guard let url = URL(string: "http://\(host):\(port)/health") else { return false }

        var request = URLRequest(url: url)
        request.timeoutInterval = 3
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return (200...299).contains(http.statusCode)
        } catch {
            return false
        }
    }
}
