import SwiftUI

struct BrowserView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var settings = AppSettings.shared

    @State private var addressText: String = ""
    @State private var isEditingAddress: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Address Bar & Navigation Header
            HStack(spacing: 8) {
                // Address Bar / Search Input
                HStack {
                    Image(systemName: settings.isProxyConfigured ? "lock.shield.fill" : "exclamationmark.shield.fill")
                        .foregroundColor(settings.isProxyConfigured ? .green : .red)
                        .font(.system(size: 14))

                    TextField("Search or enter website name", text: $addressText, onEditingChanged: { editing in
                        isEditingAddress = editing
                    }, onCommit: {
                        loadAddress()
                    })
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    .font(.subheadline)

                    if !addressText.isEmpty {
                        Button(action: {
                            addressText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(UIColor.tertiarySystemFill))
                .cornerRadius(10)

                if isEditingAddress {
                    Button("Cancel") {
                        isEditingAddress = false
                        if let active = viewModel.activeTab {
                            addressText = active.urlString == "about:blank" ? "" : active.urlString
                        }
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .font(.subheadline)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor.secondarySystemBackground))

            // MARK: - Loading Progress Bar
            if let activeTab = viewModel.activeTab, activeTab.isLoading {
                ProgressView(value: activeTab.estimatedProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(height: 2)
            } else {
                Divider()
            }

            // MARK: - Proxy Warning Banner if missing
            if !settings.isProxyConfigured {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    Text("SOCKS5 Proxy is not configured. Configure in Settings.")
                        .font(.caption)
                        .bold()
                    Spacer()
                    Button("Settings") {
                        viewModel.isShowingSettings = true
                    }
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                }
                .padding(8)
                .background(Color.red.opacity(0.15))
            }

            // MARK: - Active WebView Content
            ZStack {
                if let activeTab = viewModel.activeTab {
                    ProxyWebView(viewModel: viewModel, tab: activeTab)
                        .id(activeTab.id)
                } else {
                    Text("No Tab Selected")
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // MARK: - Bottom Navigation Toolbar
            HStack {
                // Back Button
                Button(action: {
                    NotificationCenter.default.post(name: NSNotification.Name("ProxyWebViewGoBack"), object: nil)
                }) {
                    Image(systemName: "chevron.backward")
                        .font(.title3)
                }
                .disabled(!(viewModel.activeTab?.canGoBack ?? false))

                Spacer()

                // Forward Button
                Button(action: {
                    NotificationCenter.default.post(name: NSNotification.Name("ProxyWebViewGoForward"), object: nil)
                }) {
                    Image(systemName: "chevron.forward")
                        .font(.title3)
                }
                .disabled(!(viewModel.activeTab?.canGoForward ?? false))

                Spacer()

                // Reload Button
                Button(action: {
                    NotificationCenter.default.post(name: NSNotification.Name("ProxyWebViewReload"), object: nil)
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                }

                Spacer()

                // Tabs Switcher Button
                Button(action: {
                    viewModel.isShowingTabSwitcher = true
                }) {
                    ZStack {
                        Image(systemName: "square")
                            .font(.title3)
                        Text("\(viewModel.tabs.count)")
                            .font(.system(size: 10, weight: .bold))
                    }
                }

                Spacer()

                // History Button
                Button(action: {
                    viewModel.isShowingHistory = true
                }) {
                    Image(systemName: "clock")
                        .font(.title3)
                }

                Spacer()

                // Settings Button
                Button(action: {
                    viewModel.isShowingSettings = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.title3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(UIColor.secondarySystemBackground))
        }
        .onAppear {
            updateAddressTextFromActiveTab()
        }
        .onChange(of: viewModel.activeTabId) { _ in
            updateAddressTextFromActiveTab()
        }
        .onChange(of: viewModel.activeTab?.urlString) { newUrl in
            if !isEditingAddress, let newUrl = newUrl {
                addressText = newUrl == "about:blank" ? "" : newUrl
            }
        }
        .sheet(isPresented: $viewModel.isShowingTabSwitcher) {
            TabSwitcherView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isShowingHistory) {
            HistoryView { selectedURL in
                viewModel.updateActiveTab(urlString: selectedURL)
            }
        }
        .sheet(isPresented: $viewModel.isShowingSettings) {
            SettingsView()
        }
    }

    private func updateAddressTextFromActiveTab() {
        if let active = viewModel.activeTab {
            addressText = active.urlString == "about:blank" ? "" : active.urlString
        }
    }

    private func loadAddress() {
        isEditingAddress = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        let trimmed = addressText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        viewModel.updateActiveTab(urlString: trimmed)
    }
}
