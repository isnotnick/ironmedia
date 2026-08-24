import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showingClearConfirmation = false
    @State private var clearCompletedAlert = false

    var body: some View {
        NavigationView {
            Form {
                // MARK: - Proxy Credentials Section
                Section(header: Text("SOCKS5 Proxy Configuration"), footer: Text("All web traffic and DNS lookups are routed exclusively through this proxy.")) {
                    HStack {
                        Text("Host")
                            .frame(width: 80, alignment: .leading)
                        TextField("e.g. 192.168.1.100 or proxy.com", text: $settings.proxyHost)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }

                    HStack {
                        Text("Port")
                            .frame(width: 80, alignment: .leading)
                        TextField("1080", value: $settings.proxyPort, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                    }

                    HStack {
                        Text("Username")
                            .frame(width: 80, alignment: .leading)
                        TextField("Optional", text: $settings.proxyUsername)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }

                    HStack {
                        Text("Password")
                            .frame(width: 80, alignment: .leading)
                        SecureField("Optional", text: $settings.proxyPassword)
                    }
                }

                // MARK: - DNS Settings Section
                Section(header: Text("DNS Configuration"), footer: Text("Choose standard proxy remote DNS or DNS-over-HTTPS.")) {
                    Picker("DNS Resolution Mode", selection: $settings.dnsMode) {
                        ForEach(DNSMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }

                    if settings.dnsMode == .doh {
                        HStack {
                            Text("DoH Server")
                            TextField("https://1.1.1.1/dns-query", text: $settings.dohServerURL)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }

                        Toggle("Route DoH via SOCKS5 Proxy", isOn: $settings.dohThroughProxy)
                    }
                }

                // MARK: - Tab & Launch Settings Section
                Section(header: Text("Browsing & Tab Behavior")) {
                    Toggle("Restore Open Tabs on Launch", isOn: $settings.restoreOpenTabs)

                    Picker("New Tab Start Page", selection: $settings.newTabBehavior) {
                        ForEach(NewTabBehavior.allCases) { behavior in
                            Text(behavior.rawValue).tag(behavior)
                        }
                    }

                    if settings.newTabBehavior == .customURL {
                        HStack {
                            Text("Homepage")
                            TextField("https://check.torproject.org", text: $settings.customHomepageURL)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                    }
                }

                // MARK: - Privacy & Data Clearing
                Section(header: Text("Privacy & Data Clearing")) {
                    Button(role: .destructive, action: {
                        showingClearConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear Browsing Data, Cookies & History")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Clear All Browsing Data?", isPresented: $showingClearConfirmation, titleVisibility: .visible) {
                Button("Clear Everything", role: .destructive) {
                    DataWiperService.shared.wipeAllBrowsingData {
                        clearCompletedAlert = true
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently remove all open tabs history, cookies, cache, and local web storage.")
            }
            .alert("Browsing Data Cleared", isPresented: $clearCompletedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("All cache, cookies, local storage, and browsing history have been wiped.")
            }
        }
    }
}
