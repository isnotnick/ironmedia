# ProxyBrowser - SOCKS5 iOS Web Browser

`ProxyBrowser` is a SwiftUI-based iOS browser application that routes all network traffic—including DNS resolution—through a user-configurable SOCKS5 proxy with username and password authentication.

## Features
- **Strict SOCKS5 Proxy Routing**: All HTTP/HTTPS browsing traffic and DNS lookups are routed through the configured SOCKS5 proxy.
- **Secure Credentials Storage**: SOCKS5 username and password are saved in the iOS Keychain.
- **DNS Options**: Support for standard proxy remote DNS or DNS-over-HTTPS (DoH) with custom DoH server URL (defaults to Cloudflare `https://1.1.1.1/dns-query`).
- **Tabbed Browsing**: Full multi-tab support with tab creation, closing, and grid switcher view. Option to restore open tabs on launch or start fresh.
- **Dedicated History View**: Searchable browsing history with individual item deletion and full history wipe.
- **Data Clearing & Privacy**: One-tap setting to wipe all `WKWebsiteDataStore` cache, cookies, local storage, and history.
- **Customizable Launch & New Tab**: Options for blank page or custom homepage URL on new tab creation.

---

## Requirements
- macOS with **Xcode 15.0+**
- iOS 17.0+ (Simulator or Physical Device)
- Apple Developer Account (Free Personal Team account is sufficient)

---

## How to Load and Build in Xcode

1. **Open the Project**:
   ```bash
   cd proxybrowser
   open ProxyBrowser.xcodeproj
   ```

2. **Select Target Device / Simulator**:
   - In Xcode's top toolbar, choose an iOS 17+ Simulator (e.g., *iPhone 15 Pro*) or your plugged-in physical iOS device.

3. **Build and Run**:
   - Press `Cmd + R` or click the **Play** button in Xcode.

---

## Instructions for Deploying to a Physical iOS Device

To install `ProxyBrowser` on a real iPhone/iPad for testing:

### Step 1: Connect Your Device & Select Personal Team
1. Connect your iPhone/iPad to your Mac using a Lightning/USB-C cable.
2. In Xcode, click on **ProxyBrowser** (the top-level project in the left Navigator panel).
3. Select the **ProxyBrowser** target, then click the **Signing & Capabilities** tab.
4. Under **Team**, select your Apple ID (*Personal Team*).
   - If no team appears, click **Add an Account...** and sign in with your Apple ID.
5. Xcode will automatically generate a Provisioning Profile for your device.

### Step 2: Enable Developer Mode on iOS (iOS 16/17+)
1. On your iPhone/iPad, open **Settings**.
2. Go to **Privacy & Security** -> scroll down to **Developer Mode**.
3. Toggle **Developer Mode** to **ON**.
4. Restart your device when prompted and confirm to turn on Developer Mode.

### Step 3: Trust Developer Certificate on iOS
1. In Xcode, select your physical device from the destination menu at the top.
2. Press `Cmd + R` to build and install the app on your device.
3. Once installed, if an "Untrusted Developer" dialog appears on your iPhone:
   - Go to **Settings** -> **General** -> **VPN & Device Management**.
   - Under *Developer App*, tap your Apple ID email.
   - Tap **Trust [Your Email]** and confirm.

4. Launch **ProxyBrowser** on your iPhone!

---

## App Usage & SOCKS5 Configuration

1. Launch `ProxyBrowser`.
2. Tap the **Settings** icon (gear) in the bottom right toolbar.
3. Enter your **SOCKS5 Proxy Details**:
   - **Host**: e.g., `192.168.1.100` or `myproxy.com`
   - **Port**: e.g., `1080`
   - **Username** & **Password** (if authentication is required)
4. Choose your **DNS Configuration** (Regular SOCKS5 DNS or DNS-over-HTTPS).
5. Tap **Done**.
6. Enter any URL or search query in the address bar to begin browsing through your proxy!
