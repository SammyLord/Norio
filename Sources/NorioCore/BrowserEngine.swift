import Foundation
import WebKit

public class BrowserEngine {
    public static let shared = BrowserEngine()
    
    private var configuration: WKWebViewConfiguration
    
    // Added settings for content blocking
    public var contentBlockingEnabled: Bool = true {
        didSet {
            if let contentBlocker = ContentBlocker.shared as? ContentBlocker {
                contentBlocker.isEnabled = contentBlockingEnabled
            }
        }
    }
    
    private init() {
        configuration = WKWebViewConfiguration()
        setupConfiguration()
    }
    
    private func setupConfiguration() {
        // Enable developer tools for macOS
        #if os(macOS)
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        #endif
        
        // Set default preferences
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        // Allow file access from file URLs
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        // Setup user content controller for extension support
        let userContentController = WKUserContentController()
        configuration.userContentController = userContentController
    }
    
    public func createWebView(frame: CGRect = .zero) -> WKWebView {
        let webView = WKWebView(frame: frame, configuration: configuration)
        
        // Apply content blocking if enabled
        if contentBlockingEnabled, 
           let contentBlocker = ContentBlocker.shared as? ContentBlocker {
            contentBlocker.applyRulesToWebView(webView)
        }
        
        return webView
    }
    
    public func injectScript(_ script: String, injectionTime: WKUserScriptInjectionTime = .atDocumentStart, forMainFrameOnly: Bool = false) {
        let userScript = WKUserScript(source: script, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly)
        configuration.userContentController.addUserScript(userScript)
    }
    
    public func addScriptMessageHandler(handler: WKScriptMessageHandler, name: String) {
        configuration.userContentController.add(handler, name: name)
    }
    
    public func removeScriptMessageHandler(name: String) {
        configuration.userContentController.removeScriptMessageHandler(forName: name)
    }
}

// Tab management
public extension BrowserEngine {
    class Tab {
        public let id: UUID
        public let webView: WKWebView
        public var title: String = ""
        public var url: URL?
        public var favicon: Data?
        public var isLoading: Bool = false
        
        init(id: UUID = UUID(), webView: WKWebView) {
            self.id = id
            self.webView = webView
        }
        
        public func loadURL(_ url: URL) {
            let request = URLRequest(url: url)
            webView.load(request)
            self.url = url
        }
        
        public func loadHTMLString(_ html: String, baseURL: URL? = nil) {
            webView.loadHTMLString(html, baseURL: baseURL)
        }
        
        public func goBack() -> Bool {
            if webView.canGoBack {
                webView.goBack()
                return true
            }
            return false
        }
        
        public func goForward() -> Bool {
            if webView.canGoForward {
                webView.goForward()
                return true
            }
            return false
        }
        
        public func reload() {
            webView.reload()
        }
        
        public func stopLoading() {
            webView.stopLoading()
        }
    }
}

// History, bookmarks and settings
public extension BrowserEngine {
    struct HistoryItem: Codable, Identifiable {
        public let id: UUID
        public let url: URL
        public let title: String
        public let visitDate: Date
        
        public init(id: UUID = UUID(), url: URL, title: String, visitDate: Date = Date()) {
            self.id = id
            self.url = url
            self.title = title
            self.visitDate = visitDate
        }
    }
    
    struct Bookmark: Codable, Identifiable {
        public let id: UUID
        public let url: URL
        public let title: String
        public let dateAdded: Date
        public let folder: String?
        
        public init(id: UUID = UUID(), url: URL, title: String, dateAdded: Date = Date(), folder: String? = nil) {
            self.id = id
            self.url = url
            self.title = title
            self.dateAdded = dateAdded
            self.folder = folder
        }
    }
    
    struct Settings: Codable {
        public var homepage: URL
        public var searchEngine: SearchEngine
        public var blockPopups: Bool
        public var enableDoNotTrack: Bool
        public var blockCookies: Bool
        public var clearHistoryOnExit: Bool
        
        public init(
            homepage: URL = URL(string: "https://www.google.com")!,
            searchEngine: SearchEngine = .google,
            blockPopups: Bool = true,
            enableDoNotTrack: Bool = true,
            blockCookies: Bool = false,
            clearHistoryOnExit: Bool = false
        ) {
            self.homepage = homepage
            self.searchEngine = searchEngine
            self.blockPopups = blockPopups
            self.enableDoNotTrack = enableDoNotTrack
            self.blockCookies = blockCookies
            self.clearHistoryOnExit = clearHistoryOnExit
        }
    }
    
    enum SearchEngine: String, Codable, CaseIterable {
        case google
        case bing
        case duckDuckGo
        case yahoo
        
        public var searchURL: URL {
            switch self {
            case .google:
                return URL(string: "https://www.google.com/search?q=")!
            case .bing:
                return URL(string: "https://www.bing.com/search?q=")!
            case .duckDuckGo:
                return URL(string: "https://duckduckgo.com/?q=")!
            case .yahoo:
                return URL(string: "https://search.yahoo.com/search?p=")!
            }
        }
    }
} 