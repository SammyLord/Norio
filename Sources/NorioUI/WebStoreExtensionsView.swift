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

// Simple web view wrapper
struct StoreWebView: View {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var containerHeight: CGFloat
    
    var body: some View {
        #if os(macOS)
        WebViewWrapper(url: url, isLoading: $isLoading, containerHeight: $containerHeight)
            .frame(height: containerHeight)
            .accessibilityIdentifier("storeWebView")
        #else
        WebViewWrapper(url: url, isLoading: $isLoading, containerHeight: $containerHeight)
            .frame(height: containerHeight)
            .accessibilityIdentifier("storeWebView")
        #endif
    }
}

#if os(macOS)
// Platform-specific implementation
private struct WebViewWrapper: NSViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var containerHeight: CGFloat
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Use WKWebpagePreferences instead of WKPreferences for JavaScript
        let webpagePreferences = WKWebpagePreferences()
        webpagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = webpagePreferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewWrapper
        
        init(_ parent: WebViewWrapper) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            
            // Adjust container height based on content
            webView.evaluateJavaScript("document.body.scrollHeight") { (height, error) in
                if let height = height as? CGFloat, height > 0 {
                    self.parent.containerHeight = min(height, 600)
                } else {
                    self.parent.containerHeight = 500
                }
            }
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "installExtension" {
                if let body = message.body as? [String: String],
                   let id = body["id"],
                   let typeString = body["type"] {
                    let type = typeString == "chrome" ? ExtensionType.chrome : ExtensionType.firefox
                    handleExtensionInstall(id: id, type: type)
                }
            }
        }
        
        private func handleExtensionInstall(id: String, type: ExtensionType) {
            // Handle extension installation
            print("Installing extension: \(id) of type: \(type)")
        }
    }
}
#else
// Platform-specific implementation
private struct WebViewWrapper: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var containerHeight: CGFloat
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Use WKWebpagePreferences instead of WKPreferences for JavaScript
        let webpagePreferences = WKWebpagePreferences()
        webpagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = webpagePreferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewWrapper
        
        init(_ parent: WebViewWrapper) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            
            // Adjust container height based on content
            webView.evaluateJavaScript("document.body.scrollHeight") { (height, error) in
                if let height = height as? CGFloat, height > 0 {
                    self.parent.containerHeight = min(height, 600)
                } else {
                    self.parent.containerHeight = 500
                }
            }
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "installExtension" {
                if let body = message.body as? [String: String],
                   let id = body["id"],
                   let typeString = body["type"] {
                    let type = typeString == "chrome" ? ExtensionType.chrome : ExtensionType.firefox
                    handleExtensionInstall(id: id, type: type)
                }
            }
        }
        
        private func handleExtensionInstall(id: String, type: ExtensionType) {
            // Handle extension installation
            print("Installing extension: \(id) of type: \(type)")
        }
    }
}
#endif 