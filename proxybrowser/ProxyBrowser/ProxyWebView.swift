import SwiftUI
import WebKit
import Network

/// UIViewRepresentable wrapper for WKWebView configured with iOS 17 SOCKS5 Proxy settings.
struct ProxyWebView: UIViewRepresentable {
    @ObservedObject var viewModel: BrowserViewModel
    let tab: TabModel

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()

        // Configure SOCKS5 Proxy for iOS 17+
        let store = WKWebsiteDataStore.nonPersistent()
        applyProxySettings(to: store)
        configuration.websiteDataStore = store

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        // Register observers and notification listeners for navigation
        context.coordinator.setupObservers(for: webView)
        context.coordinator.setupNotificationListeners(for: webView)

        loadInitialRequest(in: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // If tab URL changed from address bar navigation
        if let currentURL = uiView.url?.absoluteString, currentURL != tab.urlString, !tab.urlString.isEmpty {
            if let newURL = URL(string: formattedURLString(tab.urlString)) {
                uiView.load(URLRequest(url: newURL))
            }
        }
    }

    private func applyProxySettings(to store: WKWebsiteDataStore) {
        let settings = AppSettings.shared

        guard settings.isProxyConfigured else {
            store.proxyConfigurations = []
            return
        }

        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(settings.proxyHost),
            port: NWEndpoint.Port(integerLiteral: UInt16(settings.proxyPort))
        )

        let proxyConfig = ProxyConfiguration.socks5(endpoint)

        // Set proxy credentials if available
        if !settings.proxyUsername.isEmpty || !settings.proxyPassword.isEmpty {
            let credential = URLCredential(
                user: settings.proxyUsername,
                password: settings.proxyPassword,
                persistence: .forSession
            )
            proxyConfig.credential = credential
        }

        store.proxyConfigurations = [proxyConfig]
    }

    private func loadInitialRequest(in webView: WKWebView) {
        let settings = AppSettings.shared

        guard settings.isProxyConfigured else {
            loadErrorHTML(in: webView, message: "SOCKS5 Proxy is not configured. Please open Settings to set up host and port.")
            return
        }

        let urlString = tab.urlString.isEmpty ? "about:blank" : tab.urlString
        if urlString == "about:blank" {
            webView.load(URLRequest(url: URL(string: "about:blank")!))
            return
        }

        if let url = URL(string: formattedURLString(urlString)) {
            webView.load(URLRequest(url: url))
        } else {
            loadErrorHTML(in: webView, message: "Invalid URL provided: \(urlString)")
        }
    }

    private func formattedURLString(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "about:blank" {
            return "about:blank"
        }
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return trimmed
        }
        return "https://" + trimmed
    }

    private func loadErrorHTML(in webView: WKWebView, message: String) {
        let errorHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    background-color: #f2f2f7;
                    color: #1c1c1e;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: center;
                    height: 100vh;
                    margin: 0;
                    padding: 20px;
                    box-sizing: border-box;
                    text-align: center;
                }
                .card {
                    background: white;
                    padding: 30px 24px;
                    border-radius: 16px;
                    box-shadow: 0 4px 12px rgba(0,0,0,0.08);
                    max-width: 400px;
                    width: 100%;
                }
                .icon {
                    font-size: 48px;
                    margin-bottom: 12px;
                }
                h2 {
                    margin: 0 0 10px 0;
                    font-size: 20px;
                    color: #e53935;
                }
                p {
                    font-size: 14px;
                    color: #666;
                    margin: 0;
                    line-height: 1.5;
                }
            </style>
        </head>
        <body>
            <div class="card">
                <div class="icon">🔒⚠️</div>
                <h2>Proxy Connection Failed</h2>
                <p>\(message)</p>
            </div>
        </body>
        </html>
        """
        webView.loadHTMLString(errorHTML, baseURL: nil)
    }

    // MARK: - WKWebView Coordinator
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: ProxyWebView
        private var progressObservation: NSKeyValueObservation?
        private var titleObservation: NSKeyValueObservation?
        private var notificationObservers: [NSObjectProtocol] = []

        init(parent: ProxyWebView) {
            self.parent = parent
        }

        deinit {
            notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
        }

        func setupObservers(for webView: WKWebView) {
            progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.parent.viewModel.updateActiveTab(progress: webView.estimatedProgress)
                }
            }

            titleObservation = webView.observe(\.title, options: [.new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    let title = webView.title ?? ""
                    self?.parent.viewModel.updateActiveTab(title: title.isEmpty ? "New Tab" : title)
                }
            }
        }

        func setupNotificationListeners(for webView: WKWebView) {
            let backObs = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ProxyWebViewGoBack"),
                object: nil,
                queue: .main
            ) { [weak webView] _ in
                if webView?.canGoBack == true {
                    webView?.goBack()
                }
            }

            let forwardObs = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ProxyWebViewGoForward"),
                object: nil,
                queue: .main
            ) { [weak webView] _ in
                if webView?.canGoForward == true {
                    webView?.goForward()
                }
            }

            let reloadObs = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ProxyWebViewReload"),
                object: nil,
                queue: .main
            ) { [weak webView] _ in
                webView?.reload()
            }

            notificationObservers.append(contentsOf: [backObs, forwardObs, reloadObs])
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.viewModel.updateActiveTab(
                    isLoading: true,
                    canGoBack: webView.canGoBack,
                    canGoForward: webView.canGoForward,
                    errorMessage: nil
                )
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                let currentURL = webView.url?.absoluteString ?? ""
                let pageTitle = webView.title ?? ""

                self.parent.viewModel.updateActiveTab(
                    urlString: currentURL,
                    title: pageTitle.isEmpty ? currentURL : pageTitle,
                    isLoading: false,
                    canGoBack: webView.canGoBack,
                    canGoForward: webView.canGoForward,
                    errorMessage: nil
                )

                if !currentURL.isEmpty && currentURL != "about:blank" {
                    HistoryManager.shared.addEntry(urlString: currentURL, title: pageTitle)
                }
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handleError(error, webView: webView)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handleError(error, webView: webView)
        }

        private func handleError(_ error: Error, webView: WKWebView) {
            DispatchQueue.main.async {
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                    return
                }

                let errorMsg = "Unable to connect via SOCKS5 proxy: \(error.localizedDescription)"
                self.parent.viewModel.updateActiveTab(
                    isLoading: false,
                    canGoBack: webView.canGoBack,
                    canGoForward: webView.canGoForward,
                    errorMessage: errorMsg
                )
                self.parent.loadErrorHTML(in: webView, message: errorMsg)
            }
        }

        func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            let settings = AppSettings.shared
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodSOCKSProxy ||
                challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic {
                if !settings.proxyUsername.isEmpty || !settings.proxyPassword.isEmpty {
                    let credential = URLCredential(user: settings.proxyUsername, password: settings.proxyPassword, persistence: .forSession)
                    completionHandler(.useCredential, credential)
                    return
                }
            }
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
