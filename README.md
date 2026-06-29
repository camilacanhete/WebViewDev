# WebViewDev

WebViewDev is a minimalist Android and iOS tool designed for web game developers. Its sole purpose is to provide a real mobile WebView environment to test and debug web games running on a local development server.

## 🚀 Purpose
Testing web games in a mobile browser is often not enough to catch mobile-specific WebView bugs or performance issues. WebViewDev allows you to point a native mobile app directly to your development machine's IP address, giving you a WebView container for your web project.

---

## 🤖 Android

### ✨ Features
- **Dynamic URL Configuration**: On every launch, the app asks for your server's IP and port (e.g., `http://192.168.1.50:8080`).
- **Persistence**: Remembers your last used URL for quick access.
- **Autoplay Enabled**: `mediaPlaybackRequiresUserGesture` is set to `false`, allowing game audio and video to play immediately.
- **Modern Web Support**: JavaScript, DOM Storage, and Database APIs are enabled.

### 🛠 Debugging
WebViewDev is built with debugging in mind:
1. **Chrome DevTools**: Connect your device via USB, open Chrome on your desktop, and navigate to `chrome://inspect`. You can fully inspect the DOM, network, and performance of your game.
2. **Logcat**: All JavaScript `console.log`, `console.warn`, and `console.error` messages are bridged directly to Android Logcat under the tag `WebConsole`.

### 📦 How to Use

#### On a Physical Device
1. **Run your local server**: Ensure your game server (Vite, Webpack, etc.) is running and listening on your local network (usually by binding to `0.0.0.0` or your local IP).
2. **Connect your device**: Ensure your Android device and development machine are on the same Wi-Fi network.
3. **Launch WebViewDev**: Enter your computer's local IP address and the port your server is using (e.g., `http://192.168.1.50:8080`).
4. **Confirm**: The app will load your game instantly.

#### On an Android Emulator
1. **Install it**: Open your Android Emulator. Simply **drag and drop** the `apk` file from your computer's folder directly onto the emulator screen. It will install automatically.
2. **Run your local server**: Ensure your game server (Vite, Webpack, etc.) is running and listening on your local network (usually by binding to `0.0.0.0` or your local IP).
3. **The Secret "Loopback" IP**: When you are inside an emulator, `localhost` refers to the *emulator itself*, not your computer. To talk to your computer's server, you MUST use:
   - **`http://10.0.2.2:PORT`**
4. **Launch WebViewDev**: Open the app in the emulator and type `http://10.0.2.2:PORT`.
5. **Confirm**: The app will load your game instantly.

---

## 🍎 iOS

### ✨ Features
- **Dynamic URL Configuration**: On every launch, the app asks for your server's IP and port (e.g., `http://192.168.1.50:8080`).
- **Persistence**: Remembers your last used URL for quick access.
- **Autoplay Enabled**: `mediaTypesRequiringUserActionForPlayback` is set to `[]`, allowing game audio and video to play immediately.
- **Modern Web Support**: JavaScript, DOM Storage, and IndexedDB APIs are enabled.
- **CORS Bypass**: All requests are transparently proxied through a custom URL scheme handler that injects `Access-Control-Allow-Origin: *`, eliminating cross-origin errors from your dev server.

### 🛠 Debugging
WebViewDev is built with debugging in mind:
1. **Safari Web Inspector**: On your Mac, open Safari → **Develop** menu → select your device or simulator → select the WebViewDev page. You can fully inspect the DOM, console, network, and performance of your game. Requires Safari DevTools to be enabled (`isInspectable = true` is already set).
2. **Simulator Console**: Logs from the WebView appear in Xcode's Console when running via Xcode, or in the macOS Console app filtered by the simulator process.

### 📦 How to Use

#### On a Physical Device
1. **Run your local server**: Ensure your game server (Vite, Webpack, etc.) is running and bound to `0.0.0.0` so it's reachable on your local network.
2. **Connect your device**: Ensure your iPhone and development machine are on the same Wi-Fi network.
3. **Build & install**: Open the Xcode project, select your physical device as the target, and hit **Run** (`⌘R`).
4. **Launch WebViewDev**: Enter your computer's local IP address and port (e.g., `http://192.168.1.50:8080`).
5. **Confirm**: The app will load your game instantly.

#### On the iOS Simulator
1. **Run your local server**: Ensure your game server is running and bound to `0.0.0.0` or `localhost` on your Mac.
2. **The Simulator shares your Mac's network**: Unlike Android, the iOS Simulator uses the host machine's network stack directly, so `localhost` and `127.0.0.1` work as-is — no special IP needed.
3. **Allow plain HTTP**: Add the following to your `Info.plist` to allow `http://localhost` connections (ATS blocks plain HTTP by default):
   ```xml
   <key>NSAppTransportSecurity</key>
   <dict>
       <key>NSAllowsLocalNetworking</key>
       <true/>
   </dict>
   ```
4. **Build & run**: Select any iOS Simulator as the target in Xcode and hit **Run** (`⌘R`).
5. **Launch WebViewDev**: Enter `http://localhost:PORT` and tap **Load**.
6. **Confirm**: The app will load your game instantly.

---

## ⌨️ Automation (ADB)
You can also launch the app with a specific URL via command line:
```bash
adb shell am start -n com.webview.localhost/.MainActivity --es "url" "http://YOUR_IP:PORT"
```

---
*Developed to bridge the gap between local web development and mobile reality.*