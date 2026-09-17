import Foundation

actor ZaytoonaClient {
    enum ClientError: LocalizedError {
        case invalidURL, badResponse, rejected(Int, String)
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid receiver URL"
            case .badResponse: return "Invalid response from Tahoe"
            case let .rejected(code, body): return "Tahoe rejected request (\(code)): \(body)"
            }
        }
    }

    private func url(_ base: String, _ path: String, query: [URLQueryItem] = []) throws -> URL {
        guard var c = URLComponents(string: base + path) else { throw ClientError.invalidURL }
        if !query.isEmpty { c.queryItems = query }
        guard let u = c.url else { throw ClientError.invalidURL }
        return u
    }

    func ping(baseURL: String) async throws -> Double {
        let start = Date()
        let (data, response) = try await URLSession.shared.data(from: url(baseURL, "/ping"))
        guard let http = response as? HTTPURLResponse else { throw ClientError.badResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw ClientError.rejected(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return Date().timeIntervalSince(start) * 1000
    }

    func pair(baseURL: String, key: String) async throws {
        let u = try url(baseURL, "/pair", query: [URLQueryItem(name: "key", value: key), URLQueryItem(name: "format", value: "json")])
        let (data, response) = try await URLSession.shared.data(from: u)
        guard let http = response as? HTTPURLResponse else { throw ClientError.badResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw ClientError.rejected(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
    }

    func status(baseURL: String, key: String) async throws -> ZaytoonaStatus {
        let u = try url(baseURL, "/status", query: key.isEmpty ? [] : [URLQueryItem(name: "key", value: key)])
        let (data, response) = try await URLSession.shared.data(from: u)
        guard let http = response as? HTTPURLResponse else { throw ClientError.badResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw ClientError.rejected(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return try JSONDecoder().decode(ZaytoonaStatus.self, from: data)
    }

    func command(baseURL: String, key: String, type: String, value: String = "") async throws -> ZaytoonaCommandResponse {
        let u = try url(baseURL, "/command")
        var req = URLRequest(url: u)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !key.isEmpty { req.setValue(key, forHTTPHeaderField: "X-Zaytoona-Key") }
        req.timeoutInterval = 8
        req.httpBody = try JSONSerialization.data(withJSONObject: ["key": key, "type": type, "value": value])
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw ClientError.badResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw ClientError.rejected(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return try JSONDecoder().decode(ZaytoonaCommandResponse.self, from: data)
    }
}
