import SwiftUI
import WebKit
import NorioCore
import NorioExtensions

struct WebViewContainer: UIViewRepresentable {
    var tab: BrowserEngine.Tab?
    @Binding var statusUrl: String
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool
    
    let tabId: String
    
    init(tab: BrowserEngine.Tab?, statusUrl: Binding<String>, canGoBack: Binding<Bool>, canGoForward: Binding<Bool>, isLoading: Binding<Bool>) {
        self.tab = tab
        self._statusUrl = statusUrl
        self._canGoBack = canGoBack
        self._canGoForward = canGoForward
        self._isLoading = isLoading
        self.tabId = tab?.id.uuidString ?? UUID().uuidString
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = tab?.webView ?? BrowserEngine.shared.createWebView()
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // Set accessibility identifier for testing
        webView.accessibilityIdentifier = "webView-\(tabId)"
        
        // Configure user scripts controller for extension support
        if #available(iOS 14.0, macOS 11.0, *) {
            webView.configuration.userContentController.addScriptMessageHandler(
                context.coordinator,
                contentWorld: .page,
                name: "installExtension"
            )
        } else {
            webView.configuration.userContentController.add(context.coordinator, name: "installExtension")
        }
        
        // Apply extensions to this WebView
        ExtensionManager.shared.applyExtensionsToWebView(webView)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Update the URL status when the tab changes
        if let url = tab?.url {
            let host = url.host ?? ""
            statusUrl = host
        }
        
        // Update navigation state
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        isLoading = tab?.isLoading ?? false
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebViewContainer
        
        init(_ parent: WebViewContainer) {
            self.parent = parent
        }
        
        // MARK: - WKNavigationDelegate methods
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let url = webView.url {
                let host = url.host ?? ""
                parent.statusUrl = host
                
                // Update tab info
                parent.tab?.title = webView.title ?? ""
                parent.tab?.url = url
                parent.tab?.isLoading = false
            }
            
            parent.isLoading = false
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
            
            // Inject extension content scripts for this page
            injectExtensionContentScripts(webView: webView, url: webView.url)
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
        
        // Handle SSL certificate errors and other policy decisions
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Check if we should block content (ads, trackers)
            if let url = navigationAction.request.url, ContentBlocker.shared.shouldBlockRequest(url: url) {
                decisionHandler(.cancel)
                return
            }
            
            // Check if this is a store extension URL (Chrome or Firefox add-on)
            if handleExtensionStoreUrl(navigationAction.request.url) {
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
        
        // MARK: - WKUIDelegate methods
        
        // Handle JavaScript alerts
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completionHandler()
            })
            
            // Get the root view controller to present the alert
            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                rootVC.present(alert, animated: true)
            } else {
                completionHandler()
            }
        }
        
        // Handle JavaScript confirm dialogs
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completionHandler(false)
            })
            
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completionHandler(true)
            })
            
            // Get the root view controller to present the alert
            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                rootVC.present(alert, animated: true)
            } else {
                completionHandler(false)
            }
        }
        
        // Handle JavaScript text input dialogs
        func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
            let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
            
            alert.addTextField { textField in
                textField.text = defaultText
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completionHandler(nil)
            })
            
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completionHandler(alert.textFields?.first?.text)
            })
            
            // Get the root view controller to present the alert
            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                rootVC.present(alert, animated: true)
            } else {
                completionHandler(nil)
            }
        }
        
        // MARK: - WKScriptMessageHandler
        
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
        
        // MARK: - Private helper methods
        
        // Handle installation of extensions from web stores
        private func handleExtensionInstall(id: String, type: ExtensionManager.ExtensionType) {
            switch type {
            case .chrome:
                ExtensionManager.shared.installChromeExtensionFromStore(id: id) { result in
                    switch result {
                    case .success(let ext):
                        // No need to show notification here; ExtensionManager already does that
                        Logger.shared.info("Chrome extension \(ext.name) installed successfully")
                    case .failure(let error):
                        NotificationManager.shared.showExtensionError(operation: "install Chrome extension", error: error)
                    }
                }
            case .firefox:
                ExtensionManager.shared.installFirefoxExtensionFromStore(id: id) { result in
                    switch result {
                    case .success(let ext):
                        // No need to show notification here; ExtensionManager already does that
                        Logger.shared.info("Firefox add-on \(ext.name) installed successfully")
                    case .failure(let error):
                        NotificationManager.shared.showExtensionError(operation: "install Firefox add-on", error: error)
                    }
                }
            }
        }
        
        // Inject content scripts for loaded page
        private func injectExtensionContentScripts(webView: WKWebView, url: URL?) {
            guard let url = url else { return }
            
            // Check for URL pattern matching with installed extensions
            // This would typically be handled by the user scripts in the WebView configuration
            // But we might need additional dynamic injections based on page content
            
            // Inject extension-specific JavaScript for this page
            // This is handled by the UserScripts registered in the ExtensionManager
        }
        
        // Handle extension store URLs
        private func handleExtensionStoreUrl(_ url: URL?) -> Bool {
            guard let url = url, let urlString = url.absoluteString as String? else { return false }
            
            // Check if this is a Chrome Web Store extension URL
            if urlString.starts(with: ExtensionManager.chromeWebStoreBaseURL) {
                let components = urlString.components(separatedBy: "/")
                if components.count >= 6, components[5] != "" {
                    let extensionId = components[5]
                    // Ask user if they want to install this extension
                    promptToInstallExtension(id: extensionId, type: .chrome)
                    return true
                }
            }
            
            // Check if this is a Firefox Add-ons URL
            if urlString.starts(with: ExtensionManager.firefoxAddonsBaseURL) {
                let components = urlString.components(separatedBy: "/")
                if components.count >= 7, components[6] != "" {
                    let extensionId = components[6]
                    // Ask user if they want to install this extension
                    promptToInstallExtension(id: extensionId, type: .firefox)
                    return true
                }
            }
            
            return false
        }
        
        // Prompt to install an extension
        private func promptToInstallExtension(id: String, type: ExtensionManager.ExtensionType) {
            let storeName = type == .chrome ? "Chrome Web Store" : "Firefox Add-ons"
            let alert = UIAlertController(
                title: "Install Extension",
                message: "Do you want to install this extension from the \(storeName)?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            alert.addAction(UIAlertAction(title: "Install", style: .default) { _ in
                self.handleExtensionInstall(id: id, type: type)
            })
            
            // Get the root view controller to present the alert
            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                rootVC.present(alert, animated: true)
            }
        }
        
        // Update the showNotification method to use NotificationManager
        private func showNotification(title: String, message: String) {
            NotificationManager.shared.showNotification(title: title, message: message)
        }
    }
} 