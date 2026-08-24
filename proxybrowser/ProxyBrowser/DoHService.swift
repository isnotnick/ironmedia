import Foundation
import Network

/// Service for resolving domain names via DNS-over-HTTPS (DoH) using JSON/wireformat queries.
final class DoHService {
    static let shared = DoHService()
    private init() {}

    /// Resolves hostname to IPv4/IPv6 address string via DoH endpoint.
    func resolveHost(_ host: String, completion: @escaping (Result<String, Error>) -> Void) {
        let settings = AppSettings.shared
        guard settings.dnsMode == .doh, !settings.dohServerURL.isEmpty else {
            completion(.failure(NSError(domain: "DoHService", code: -1, userInfo: [NSLocalizedDescriptionKey: "DoH mode is disabled or server URL is empty."])))
            return
        }

        var urlComponents = URLComponents(string: settings.dohServerURL)
        if urlComponents?.queryItems == nil {
            urlComponents?.queryItems = []
        }
        urlComponents?.queryItems?.append(URLQueryItem(name: "name", value: host))
        urlComponents?.queryItems?.append(URLQueryItem(name: "type", value: "A"))

        guard let dohURL = urlComponents?.url else {
            completion(.failure(NSError(domain: "DoHService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid DoH server URL construction."])))
            return
        }

        var request = URLRequest(url: dohURL)
        request.setValue("application/dns-json", forHTTPHeaderField: "Accept")

        // Configure URLSession with SOCKS5 Proxy if dohThroughProxy is enabled
        let configuration = URLSessionConfiguration.ephemeral
        if settings.dohThroughProxy && settings.isProxyConfigured {
            var proxyDict: [AnyHashable: Any] = [
                kCFStreamPropertySOCKSProxyHost as String: settings.proxyHost,
                kCFStreamPropertySOCKSProxyPort as String: settings.proxyPort
            ]
            if !settings.proxyUsername.isEmpty {
                proxyDict[kCFStreamPropertySOCKSUser as String] = settings.proxyUsername
            }
            if !settings.proxyPassword.isEmpty {
                proxyDict[kCFStreamPropertySOCKSPassword as String] = settings.proxyPassword
            }
            configuration.connectionProxyDictionary = proxyDict
        }

        let session = URLSession(configuration: configuration)
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let answers = json["Answer"] as? [[String: Any]],
                  let firstAnswer = answers.first(where: { ($0["type"] as? Int) == 1 }),
                  let ipAddress = firstAnswer["data"] as? String else {
                completion(.failure(NSError(domain: "DoHService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse DoH response for \(host)."])))
                return
            }

            completion(.success(ipAddress))
        }.resume()
    }
}
