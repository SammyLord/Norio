import SwiftUI
import WebKit
import NorioCore
import NorioExtensions

struct WebStoreExtensionsView: View {
    enum StoreType: Int {
        case chrome
        case firefox
        
        var title: String {
            switch self {
            case .chrome: return "Chrome Web Store"
            case .firefox: return "Firefox Add-ons"
            }
        }
        
        var baseURL: String {
            switch self {
            case .chrome: return "https://chrome.google.com/webstore/category/extensions"
            case .firefox: return "https://addons.mozilla.org/en-US/firefox/extensions/"
            }
        }
        
        var searchURL: String {
            switch self {
            case .chrome: return "https://chrome.google.com/webstore/search/"
            case .firefox: return "https://addons.mozilla.org/en-US/firefox/search/?q="
            }
        }
    }
    
    @State private var selectedStore: StoreType = .chrome
    @State private var searchText: String = ""
    @State private var currentURL: URL?
    @State private var isLoading: Bool = false
    @State private var webViewContainerHeight: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Store selector
            Picker("Store", selection: $selectedStore) {
                Text("Chrome").tag(StoreType.chrome)
                    .accessibilityIdentifier("chromeStoreButton")
                Text("Firefox").tag(StoreType.firefox)
                    .accessibilityIdentifier("firefoxStoreButton")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .onChange(of: selectedStore) { newValue in
                loadStore(newValue)
            }
            .accessibilityIdentifier("storeTypePicker")
            
            // Search bar
            HStack {
                TextField("Search Extensions", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .accessibilityIdentifier("extensionSearchField")
                
                Button(action: performSearch) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.blue)
                }
                .disabled(searchText.isEmpty)
                .accessibilityIdentifier("extensionSearchButton")
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Divider
            Divider()
            
            // Loading indicator
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                    .accessibilityIdentifier("storeLoadingIndicator")
            }
            
            // Web view
            if let url = currentURL {
                StoreWebView(url: url, isLoading: $isLoading, containerHeight: $webViewContainerHeight)
                    .frame(height: webViewContainerHeight)
                    .accessibilityIdentifier("storeWebView")
            } else {
                Text("Select a store to browse extensions")
                    .foregroundColor(.gray)
                    .padding()
                    .accessibilityIdentifier("storeEmptyMessage")
            }
            
            Spacer()
        }
        .navigationTitle(selectedStore.title)
        .onAppear {
            loadStore(selectedStore)
        }
    }
    
    private func loadStore(_ store: StoreType) {
        currentURL = URL(string: store.baseURL)
        isLoading = true
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        let encodedSearch = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let searchURLString = selectedStore.searchURL + encodedSearch
        
        if let url = URL(string: searchURLString) {
            currentURL = url
            isLoading = true
        }
    }
}

struct StoreWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var containerHeight: CGFloat
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: StoreWebView
        
        init(_ parent: StoreWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            
            // Inject script to detect extension install buttons
            let script = """
            (function() {
                // For Chrome Web Store
                document.querySelectorAll('.webstore-test-button-label').forEach(function(button) {
                    if (button.textContent.includes('Add to Chrome') || button.textContent.includes('Install')) {
                        button.addEventListener('click', function() {
                            // Get the extension ID from the URL
                            var extensionId = window.location.pathname.split('/').pop();
                            if (extensionId) {
                                window.webkit.messageHandlers.installExtension.postMessage({
                                    'id': extensionId,
                                    'type': 'chrome'
                                });
                            }
                        });
                    }
                });
                
                // For Firefox Add-ons
                document.querySelectorAll('.AMInstallButton-button').forEach(function(button) {
                    if (button.textContent.includes('Add to Firefox') || button.textContent.includes('Install')) {
                        button.addEventListener('click', function() {
                            // Get the extension ID from the URL
                            var path = window.location.pathname;
                            var matches = path.match(/\\/addon\\/([^\\/]+)/);
                            if (matches && matches[1]) {
                                window.webkit.messageHandlers.installExtension.postMessage({
                                    'id': matches[1],
                                    'type': 'firefox'
                                });
                            }
                        });
                    }
                });
            })();
            """
            
            webView.evaluateJavaScript(script, completionHandler: nil)
            
            // Set container height based on content
            webView.evaluateJavaScript("document.body.scrollHeight") { (height, error) in
                if let height = height as? CGFloat, height > 0 {
                    self.parent.containerHeight = min(height, UIScreen.main.bounds.height * 0.8)
                } else {
                    self.parent.containerHeight = UIScreen.main.bounds.height * 0.7
                }
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Check if this is an extension install link
            if let url = navigationAction.request.url?.absoluteString {
                // For Chrome Web Store
                if url.contains("chrome.google.com/webstore/detail/") {
                    let components = url.components(separatedBy: "/")
                    if components.count > 5, let extensionId = components.last, !extensionId.isEmpty {
                        handleExtensionInstall(id: extensionId, type: .chrome)
                        decisionHandler(.cancel)
                        return
                    }
                }
                
                // For Firefox Add-ons
                if url.contains("addons.mozilla.org") && url.contains("/addon/") {
                    let components = url.components(separatedBy: "/addon/")
                    if components.count > 1, let idPart = components.last, !idPart.isEmpty {
                        let extensionId = idPart.components(separatedBy: "/").first ?? idPart
                        handleExtensionInstall(id: extensionId, type: .firefox)
                        decisionHandler(.cancel)
                        return
                    }
                }
            }
            
            decisionHandler(.allow)
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "installExtension" {
                guard let body = message.body as? [String: String],
                      let id = body["id"],
                      let typeString = body["type"],
                      let type = typeString == "chrome" ? ExtensionManager.ExtensionType.chrome : ExtensionManager.ExtensionType.firefox else {
                    return
                }
                
                handleExtensionInstall(id: id, type: type)
            }
        }
        
        private func handleExtensionInstall(id: String, type: ExtensionManager.ExtensionType) {
            switch type {
            case .chrome:
                ExtensionManager.shared.installChromeExtensionFromStore(id: id) { result in
                    switch result {
                    case .success(let ext):
                        Logger.shared.info("Chrome extension \(ext.name) installed successfully")
                    case .failure(let error):
                        NotificationManager.shared.showExtensionError(operation: "install Chrome extension", error: error)
                    }
                }
            case .firefox:
                ExtensionManager.shared.installFirefoxExtensionFromStore(id: id) { result in
                    switch result {
                    case .success(let ext):
                        Logger.shared.info("Firefox add-on \(ext.name) installed successfully")
                    case .failure(let error):
                        NotificationManager.shared.showExtensionError(operation: "install Firefox add-on", error: error)
                    }
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.userContentController.add(context.coordinator, name: "installExtension")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true
        
        // Set accessibility identifier for testing
        webView.accessibilityIdentifier = "extensionStoreWebView"
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
} 