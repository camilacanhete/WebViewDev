# WebViewDev

WebViewDev is a minimalist Android tool designed for web game developers. Its sole purpose is to provide a real mobile WebView environment to test and debug web games running on a local development server.

## 🚀 Purpose
Testing web games in a mobile browser is often not enough to catch mobile-specific WebView bugs or performance issues. WebViewDev allows you to point an Android app directly to your development machine's IP address, giving you a native-like container for your web project.

## ✨ Features
- **Dynamic URL Configuration**: On every launch, the app asks for your server's IP and port (e.g., `http://192.168.1.50:8080`).
- **Persistence**: Remembers your last used URL for quick access.
- **Autoplay Enabled**: `mediaPlaybackRequiresUserGesture` is set to `false`, allowing game audio and video to play immediately.
- **Modern Web Support**: JavaScript, DOM Storage, and Database APIs are enabled.

## 🛠 Debugging
WebViewDev is built with debugging in mind:
1. **Chrome DevTools**: Connect your device via USB, open Chrome on your desktop, and navigate to `chrome://inspect`. You can fully inspect the DOM, network, and performance of your game.
2. **Logcat**: All JavaScript `console.log`, `console.warn`, and `console.error` messages are bridged directly to Android Logcat under the tag `WebConsole`.

## 📦 How to Use

### On a Physical Device
1. **Run your local server**: Ensure your game server (Vite, Webpack, etc.) is running and listening on your local network (usually by binding to `0.0.0.0` or your local IP).
2. **Connect your device**: Ensure your Android device and development machine are on the same Wi-Fi network.
3. **Launch WebViewDev**: Enter your computer's local IP address and the port your server is using (e.g., `http://192.168.1.50:8080`).
4. **Confirm**: The app will load your game instantly.

### On an Android Emulator (For Dummies)
1. **Install it**: Open your Android Emulator. Simply **drag and drop** the `apk` file from your computer's folder directly onto the emulator screen. It will install automatically.
2. **Run your local server**: Ensure your game server (Vite, Webpack, etc.) is running and listening on your local network (usually by binding to `0.0.0.0` or your local IP).
3. **The Secret "Loopback" IP**: When you are inside an emulator, `localhost` refers to the *emulator itself*, not your computer. To talk to your computer's server, you MUST use:
   - **`http://10.0.2.2:PORT`** 
4. **Launch WebViewDev**: Open the app in the emulator and type `http://10.0.2.2:PORT`.
5. **Confirm**: The app will load your game instantly.

## ⌨️ Automation (ADB)
You can also launch the app with a specific URL via command line:
```bash
adb shell am start -n com.webview.localhost/.MainActivity --es "url" "http://YOUR_IP:PORT"
```

---
*Developed to bridge the gap between local web development and mobile reality.*
