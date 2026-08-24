import Foundation
import Combine

enum DNSMode: String, CaseIterable, Identifiable {
    case regular = "Regular SOCKS5 DNS"
    case doh = "DNS-over-HTTPS (DoH)"

    var id: String { self.rawValue }
}

enum NewTabBehavior: String, CaseIterable, Identifiable {
    case blank = "Blank Page"
    case customURL = "Custom Homepage"

    var id: String { self.rawValue }
}

/// Observable app settings for proxy, DNS, and app preferences.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // MARK: - Proxy Settings
    @Published var proxyHost: String {
        didSet { UserDefaults.standard.set(proxyHost, forKey: "proxyHost") }
    }
    @Published var proxyPort: Int {
        didSet { UserDefaults.standard.set(proxyPort, forKey: "proxyPort") }
    }
    @Published var proxyUsername: String {
        didSet { KeychainHelper.shared.save(proxyUsername, forKey: "proxyUsername") }
    }
    @Published var proxyPassword: String {
        didSet { KeychainHelper.shared.save(proxyPassword, forKey: "proxyPassword") }
    }

    // MARK: - DNS Settings
    @Published var dnsMode: DNSMode {
        didSet { UserDefaults.standard.set(dnsMode.rawValue, forKey: "dnsMode") }
    }
    @Published var dohServerURL: String {
        didSet { UserDefaults.standard.set(dohServerURL, forKey: "dohServerURL") }
    }
    @Published var dohThroughProxy: Bool {
        didSet { UserDefaults.standard.set(dohThroughProxy, forKey: "dohThroughProxy") }
    }

    // MARK: - Tab & Launch Settings
    @Published var restoreOpenTabs: Bool {
        didSet { UserDefaults.standard.set(restoreOpenTabs, forKey: "restoreOpenTabs") }
    }
    @Published var newTabBehavior: NewTabBehavior {
        didSet { UserDefaults.standard.set(newTabBehavior.rawValue, forKey: "newTabBehavior") }
    }
    @Published var customHomepageURL: String {
        didSet { UserDefaults.standard.set(customHomepageURL, forKey: "customHomepageURL") }
    }

    // MARK: - Validation
    var isProxyConfigured: Bool {
        let trimmedHost = proxyHost.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedHost.isEmpty && proxyPort > 0 && proxyPort <= 65535
    }

    private init() {
        self.proxyHost = UserDefaults.standard.string(forKey: "proxyHost") ?? ""
        let savedPort = UserDefaults.standard.integer(forKey: "proxyPort")
        self.proxyPort = savedPort > 0 ? savedPort : 1080

        self.proxyUsername = KeychainHelper.shared.read(forKey: "proxyUsername") ?? ""
        self.proxyPassword = KeychainHelper.shared.read(forKey: "proxyPassword") ?? ""

        let rawDNS = UserDefaults.standard.string(forKey: "dnsMode") ?? DNSMode.regular.rawValue
        self.dnsMode = DNSMode(rawValue: rawDNS) ?? .regular

        self.dohServerURL = UserDefaults.standard.string(forKey: "dohServerURL") ?? "https://1.1.1.1/dns-query"
        self.dohThroughProxy = UserDefaults.standard.object(forKey: "dohThroughProxy") as? Bool ?? true

        self.restoreOpenTabs = UserDefaults.standard.object(forKey: "restoreOpenTabs") as? Bool ?? true

        let rawTabBehavior = UserDefaults.standard.string(forKey: "newTabBehavior") ?? NewTabBehavior.blank.rawValue
        self.newTabBehavior = NewTabBehavior(rawValue: rawTabBehavior) ?? .blank

        self.customHomepageURL = UserDefaults.standard.string(forKey: "customHomepageURL") ?? "https://check.torproject.org"
    }
}
