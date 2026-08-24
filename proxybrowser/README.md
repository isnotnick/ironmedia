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
- macOS with **Xcode Command Line Tools** / **Apple SDKs**
- iOS 17.0+ (Simulator or Physical Device)
- Apple Developer Account (Free Personal Team account is sufficient for signing)

---

## Method A: Graphical Interface (Xcode GUI)

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

## Method B: Command-Line Toolchain (Terminal CLI without opening Xcode GUI)

You can build, sign, and deploy `ProxyBrowser` completely from the terminal using Apple's command-line toolchain (`xcodebuild`, `xcrun`, `codesign`, `xcrun devicectl` / `ios-deploy`).

### 1. Build & Run on iOS Simulator via CLI

To compile for the iOS Simulator and launch it without opening Xcode:

```bash
cd proxybrowser

# 1. List available iOS Simulator devices
xcrun simctl list devices available | grep iPhone

# 2. Boot a simulator (e.g. iPhone 15 Pro)
xcrun simctl boot "iPhone 15 Pro"
open -a Simulator

# 3. Build the app for simulator destination
xcodebuild -project ProxyBrowser.xcodeproj \
           -scheme ProxyBrowser \
           -sdk iphonesimulator \
           -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
           build

# 4. Install onto the booted simulator
xcrun simctl install booted build/Release-iphonesimulator/ProxyBrowser.app

# 5. Launch the application
xcrun simctl launch booted com.example.ProxyBrowser
```

---

### 2. Build, Code-Sign & Deploy to Physical iOS Device via CLI

#### Step 1: Find your Code Signing Identity & Team ID
```bash
# List valid developer signing certificates stored in Keychain
security find-identity -v -p codesigning
```
*(Copy your "Apple Development: your@email.com (XXXXXXXXXX)" identity name or SHA-1 hash)*

#### Step 2: Compile & Sign using `xcodebuild`
```bash
cd proxybrowser

# Build & sign for physical iOS device target
xcodebuild -project ProxyBrowser.xcodeproj \
           -scheme ProxyBrowser \
           -sdk iphoneos \
           -configuration Release \
           DEVELOPMENT_TEAM="YOUR_TEAM_ID" \
           CODE_SIGN_IDENTITY="Apple Development" \
           build
```

#### Step 3: Package as `.ipa` (Optional for distribution)
```bash
mkdir -p Payload
cp -r build/Release-iphoneos/ProxyBrowser.app Payload/
zip -r ProxyBrowser.ipa Payload
rm -rf Payload
```

#### Step 4: Deploy directly to Connected iPhone/iPad via CLI
Using `xcrun devicectl` (macOS 14+ / iOS 17+):
```bash
# List connected physical devices and get Device Identifier / UUID
xcrun devicectl list devices

# Install app package onto physical device
xcrun devicectl device install app --device <DEVICE_UUID> build/Release-iphoneos/ProxyBrowser.app

# Process launch on physical device
xcrun devicectl device process launch --device <DEVICE_UUID> com.example.ProxyBrowser
```

*Alternative using open-source `ios-deploy` CLI tool:*
```bash
# Install ios-deploy via Homebrew if needed: brew install ios-deploy
ios-deploy --bundle build/Release-iphoneos/ProxyBrowser.app --debug
```

---

## Technical Note: Non-macOS / Standalone CLI Toolchains

> **Can iOS apps be compiled on Linux or Windows without macOS?**

Official Apple iOS SDK frameworks (e.g., `UIKit`, `SwiftUI`, `WebKit`, `Network`, `Security`) are proprietary software provided by Apple. Compiling an iOS app requires:
1. Apple's iOS SDK headers, frameworks, and `swiftc` compiler configured with `arm64-apple-ios17.0` target triples.
2. Apple's linker (`ld64`) and code-signing tool (`codesign` / `ldid`).

While open-source cross-compiling toolchains (such as `osxcross` / `cctools-port` / `clang`) exist, they require extracting Apple's proprietary SDK files from a macOS installation or Xcode package. On macOS, the Apple Command-Line Tools (`xcodebuild` / `xcrun`) provide the official, fully supported CLI workflow without needing to launch the Xcode graphical app.

---

## Physical Device Setup & iOS Trust Steps

If running on a physical iPhone for the first time:

1. **Enable Developer Mode** on iOS:
   - Go to **Settings** -> **Privacy & Security** -> **Developer Mode** -> Toggle **ON** and restart device.

2. **Trust Developer Certificate**:
   - Go to **Settings** -> **General** -> **VPN & Device Management** -> Tap your Apple ID under *Developer App* -> Tap **Trust**.

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
