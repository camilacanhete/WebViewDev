//
//  ContentView.swift
//  WebViewDev
//

import SwiftUI
import WebKit

// MARK: - CORS Scheme Handler
// Intercepts devhttp:// and devhttps:// requests, forwards them as real
// http:// / https:// requests via URLSession, then injects CORS headers.
class CORSSchemeHandler: NSObject, WKURLSchemeHandler {

    private var activeTasks: [ObjectIdentifier: URLSessionDataTask] = [:]
    private let lock = NSLock()

    func webView(_ webView: WKWebView,
                 start urlSchemeTask: any WKURLSchemeTask) {

        guard let original = urlSchemeTask.request.url,
              var components = URLComponents(url: original, resolvingAgainstBaseURL: false)
        else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }

        // Strip the "dev" prefix: devhttp → http, devhttps → https
        let realScheme = original.scheme?
            .replacingOccurrences(of: "devhttp", with: "http") ?? "http"
        components.scheme = realScheme

        guard let realURL = components.url else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }

        var request = urlSchemeTask.request
        request.url = realURL

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                // Ignore cancellation errors (task stopped by WebKit)
                let nsError = error as NSError
                if nsError.code == NSURLErrorCancelled { return }
                urlSchemeTask.didFailWithError(error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  let url = httpResponse.url
            else {
                urlSchemeTask.didFailWithError(URLError(.badServerResponse))
                return
            }

            // Rebuild headers with CORS headers injected
            var headers = httpResponse.allHeaderFields as? [String: String] ?? [:]
            headers["Access-Control-Allow-Origin"]  = "*"
            headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
            headers["Access-Control-Allow-Headers"] = "*"

            // Rewrite any Location / content URLs back to devhttp://
            if let location = headers["Location"] {
                headers["Location"] = location
                    .replacingOccurrences(of: "http://",  with: "devhttp://")
                    .replacingOccurrences(of: "https://", with: "devhttps://")
            }

            let newResponse = HTTPURLResponse(
                url: url,
                statusCode: httpResponse.statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: headers
            )!

            urlSchemeTask.didReceive(newResponse)
            urlSchemeTask.didReceive(data ?? Data())
            urlSchemeTask.didFinish()
        }

        lock.lock()
        activeTasks[ObjectIdentifier(urlSchemeTask)] = task
        lock.unlock()

        task.resume()
    }

    func webView(_ webView: WKWebView,
                 stop urlSchemeTask: any WKURLSchemeTask) {
        lock.lock()
        let task = activeTasks.removeValue(forKey: ObjectIdentifier(urlSchemeTask))
        lock.unlock()
        task?.cancel()
    }
}

// MARK: - WebView (UIViewRepresentable)
struct WebView: UIViewRepresentable {
    let url: URL?
    @Binding var isLoading: Bool
    var onError: (Error) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()

        let webpagePreferences = WKWebpagePreferences()
        webpagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = webpagePreferences

        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences

        configuration.websiteDataStore = WKWebsiteDataStore.default()
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsInlineMediaPlayback = true

        // Register our custom schemes
        let handler = CORSSchemeHandler()
        configuration.setURLSchemeHandler(handler, forURLScheme: "devhttp")
        configuration.setURLSchemeHandler(handler, forURLScheme: "devhttps")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.isInspectable = true

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url else { return }
        let alreadyLoaded = uiView.url == url
        let isLoading     = uiView.isLoading && uiView.url == url
        guard !alreadyLoaded && !isLoading else { return }
        uiView.load(URLRequest(url: url))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading, onError: onError)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        var onError: (Error) -> Void

        init(isLoading: Binding<Bool>, onError: @escaping (Error) -> Void) {
            _isLoading = isLoading
            self.onError = onError
        }

        func webView(_ webView: WKWebView,
                     didStartProvisionalNavigation navigation: WKNavigation!) {
            isLoading = true
        }

        func webView(_ webView: WKWebView,
                     didFinish navigation: WKNavigation!) {
            isLoading = false
        }

        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            isLoading = false
            let nsError = error as NSError
            guard nsError.code != NSURLErrorCancelled else { return }
            onError(error)
        }

        func webView(_ webView: WKWebView,
                     didFail navigation: WKNavigation!,
                     withError error: Error) {
            isLoading = false
            let nsError = error as NSError
            guard nsError.code != NSURLErrorCancelled else { return }
            onError(error)
        }
    }
}

// MARK: - ContentView
struct ContentView: View {
    @State private var urlString: String = ""
    @State private var currentURL: URL?   = nil
    @State private var isLoading: Bool    = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    private let lastURLKey = "lastURL"

    var body: some View {
        VStack(spacing: 0) {

            HStack {
                TextField(
                    "e.g. http://localhost:8080",
                    text: $urlString
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(.URL)
                .onSubmit { loadURL() }

                Button("Load") { loadURL() }
                    .disabled(urlString.isEmpty)
                    .padding(.leading, 4)
            }
            .padding()
            .background(Color(UIColor.systemBackground))

            ZStack {
                if let url = currentURL {
                    WebView(url: url, isLoading: $isLoading) { error in
                        errorMessage = error.localizedDescription
                        showErrorAlert = true
                    }
                    .ignoresSafeArea(edges: .bottom)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "safari")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Enter a server URL and tap Load")
                            .foregroundColor(.secondary)
                    }
                }

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.5)
                }
            }
        }
        .alert("Load Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            if let saved = UserDefaults.standard.string(forKey: lastURLKey),
               !saved.isEmpty {
                urlString = saved
                loadURL()
            }
        }
    }

    private func loadURL() {
        var trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if !trimmed.hasPrefix("http://") && !trimmed.hasPrefix("https://") {
            trimmed = "http://" + trimmed
        }

        guard let url = URL(string: trimmed) else {
            errorMessage = "Invalid URL — please check the format."
            showErrorAlert = true
            return
        }

        // Rewrite http(s):// → devhttp(s):// so our scheme handler intercepts it
        let devURL = url.absoluteString
            .replacingOccurrences(of: "http://",  with: "devhttp://")
            .replacingOccurrences(of: "https://", with: "devhttps://")

        UserDefaults.standard.set(trimmed, forKey: lastURLKey) // save original
        urlString  = trimmed

        currentURL = URL(string: devURL)

        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
