import SwiftUI
import WebKit
import NorioCore
import NorioExtensions

#if os(macOS)
struct WebViewContainer: NSViewRepresentable {
    var tab: BrowserEngine.Tab?
    @Binding var statusUrl: String
    @Binding var isLoading: Bool
    var onNavigationAction: ((URL) -> Bool)?
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = tab?.webView ?? BrowserEngine.shared.createWebView()
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // Configure user scripts controller for extension support
        // Remove existing handler first to avoid duplicates
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "installExtension")
        webView.configuration.userContentController.add(context.coordinator, name: "installExtension")
        
        // Apply extensions to this WebView
        ExtensionManager.shared.applyExtensionsToWebView(webView)
        
        // Enhanced mouse and focus handling for gaming
        webView.allowsBackForwardNavigationGestures = false // Disable to prevent conflicts with games
        
        // Ensure the WebView can receive all mouse events
        DispatchQueue.main.async {
            // Make sure the WebView accepts first responder
            webView.window?.makeFirstResponder(webView)
            
            // Enable mouse tracking for better game compatibility
            if let contentView = webView.superview {
                let trackingArea = NSTrackingArea(
                    rect: contentView.bounds,
                    options: [.activeInActiveApp, .mouseMoved, .inVisibleRect],
                    owner: webView,
                    userInfo: nil
                )
                contentView.addTrackingArea(trackingArea)
            }
        }
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Update the URL status when the tab changes
        if let url = tab?.url {
            statusUrl = url.host ?? ""
            isLoading = tab?.isLoading ?? false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebViewContainer
        
        init(_ parent: WebViewContainer) {
            self.parent = parent
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            
            if let url = webView.url {
                parent.statusUrl = url.host ?? ""
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
        
        // MARK: - WKUIDelegate
        
        // Support for pointer lock and fullscreen requests
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            // Allow media capture for gaming sites that might need microphone/camera
            decisionHandler(.grant)
        }
        
        // MARK: - WKScriptMessageHandler
        
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
        
        // MARK: - Extension Installation
        
        private func handleExtensionInstall(id: String, type: ExtensionType) {
            switch type {
            case .chrome:
                ExtensionManager.shared.installChromeExtensionFromStore(id: id) { result in
                    // Handle result
                }
            case .firefox:
                ExtensionManager.shared.installFirefoxExtensionFromStore(id: id) { result in
                    // Handle result
                }
            }
        }
    }
}
#else
struct WebViewContainer: UIViewRepresentable {
    var tab: BrowserEngine.Tab?
    @Binding var statusUrl: String
    @Binding var isLoading: Bool
    var onNavigationAction: ((URL) -> Bool)?
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = tab?.webView ?? BrowserEngine.shared.createWebView()
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // Configure user scripts controller for extension support
        // Remove existing handler first to avoid duplicates
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "installExtension")
        webView.configuration.userContentController.add(context.coordinator, name: "installExtension")
        
        // Apply extensions to this WebView
        ExtensionManager.shared.applyExtensionsToWebView(webView)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Update the URL status when the tab changes
        if let url = tab?.url {
            statusUrl = url.host ?? ""
            isLoading = tab?.isLoading ?? false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebViewContainer
        
        init(_ parent: WebViewContainer) {
            self.parent = parent
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            
            if let url = webView.url {
                parent.statusUrl = url.host ?? ""
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
        
        // MARK: - WKUIDelegate
        
        // Support for pointer lock and fullscreen requests
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            // Allow media capture for gaming sites that might need microphone/camera
            decisionHandler(.grant)
        }
        
        #if os(iOS)
        // Handle device orientation requests (useful for mobile gaming)
        @available(iOS 15.0, *)
        func webView(_ webView: WKWebView, requestDeviceOrientationAndMotionPermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant)
        }
        
        // Enable context menu for debugging if needed
        @available(iOS 13.0, *)
        func webView(_ webView: WKWebView, contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
            completionHandler(nil) // No context menu for gaming experience
        }
        #endif
        
        // MARK: - WKScriptMessageHandler
        
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
        
        // MARK: - Extension Installation
        
        private func handleExtensionInstall(id: String, type: ExtensionType) {
            switch type {
            case .chrome:
                ExtensionManager.shared.installChromeExtensionFromStore(id: id) { result in
                    // Handle result
                }
            case .firefox:
                ExtensionManager.shared.installFirefoxExtensionFromStore(id: id) { result in
                    // Handle result
                }
            }
        }
    }
}
#endif 

struct WebViewContainerView: View {
    let webView: WKWebView
    
    var body: some View {
        #if os(macOS)
        WebView(webView: webView)
        #else
        WebView(webView: webView)
        #endif
    }
}

private struct WebView: View {
    let webView: WKWebView
    
    var body: some View {
        #if os(macOS)
        NSViewRepresentableWebView(webView: webView)
        #else
        UIViewRepresentableWebView(webView: webView)
        #endif
    }
}

#if os(macOS)
private struct NSViewRepresentableWebView: NSViewRepresentable {
    let webView: WKWebView
    
    func makeNSView(context: Context) -> WKWebView {
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Update if needed
    }
}
#else
private struct UIViewRepresentableWebView: UIViewRepresentable {
    let webView: WKWebView
    
    func makeUIView(context: Context) -> WKWebView {
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Update if needed
    }
}
#endif 