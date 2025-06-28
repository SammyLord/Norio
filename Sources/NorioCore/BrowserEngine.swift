import Foundation
import WebKit

public class BrowserEngine {
    public static let shared = BrowserEngine()
    
    private var configuration: WKWebViewConfiguration
    
    // Added settings for content blocking
    public var contentBlockingEnabled: Bool = true {
        didSet {
            ContentBlocker.shared.isEnabled = contentBlockingEnabled
        }
    }
    
    private init() {
        print("BrowserEngine: Initializing...")
        
        // Create configuration with timing
        let configurationStart = Date()
        configuration = WKWebViewConfiguration()
        let configurationTime = Date().timeIntervalSince(configurationStart)
        print("BrowserEngine: WKWebViewConfiguration created in \(configurationTime) seconds")
        
        setupConfiguration()
        print("BrowserEngine: Configuration setup complete")
    }
    
    private func setupConfiguration() {
        print("BrowserEngine: Setting up configuration...")
        // Enable developer tools for macOS
        #if os(macOS)
        print("BrowserEngine: Enabling developer tools for macOS")
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        #endif
        
        // Set default preferences using proper APIs
        print("BrowserEngine: Setting default preferences")
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        // Allow file access - needed for some gaming sites
        print("BrowserEngine: Enabling file access")
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        // Enable media capture permissions for gaming/WebRTC
        print("BrowserEngine: Configuring media permissions")
        configuration.preferences.setValue(true, forKey: "mockCaptureDevicesEnabled")
        
        // Configure website data store for better compatibility
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        
        // Allow media in window without user action for gaming
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Setup user content controller for extension support
        print("BrowserEngine: Setting up user content controller")
        let userContentController = WKUserContentController()
        configuration.userContentController = userContentController
        print("BrowserEngine: Configuration setup completed successfully")
    }
    
    public func createWebView(frame: CGRect = .zero) -> WKWebView {
        let webView = WKWebView(frame: frame, configuration: configuration)
        
        // Apply content blocking if enabled
        if contentBlockingEnabled {
            ContentBlocker.shared.applyRulesToWebView(webView)
        }
        
        // Inject pointer lock enhancement script for gaming
        injectPointerLockEnhancementScript()
        
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
    
    // Inject JavaScript to enhance pointer lock functionality
    private func injectPointerLockEnhancementScript() {
        let pointerLockScript = """
        (function() {
            console.log('=== Norio Enhanced Pointer Lock Enhancement v2.0 ===');
            
            // Test if Pointer Lock API is available
            const hasPointerLockAPI = 'requestPointerLock' in Element.prototype;
            const hasExitPointerLock = 'exitPointerLock' in Document.prototype;
            const hasPointerLockElement = 'pointerLockElement' in Document.prototype;
            
            console.log('Norio: Pointer Lock API Support Check:');
            console.log('  - requestPointerLock available:', hasPointerLockAPI);
            console.log('  - exitPointerLock available:', hasExitPointerLock);
            console.log('  - pointerLockElement available:', hasPointerLockElement);
            console.log('  - User Agent:', navigator.userAgent);
            console.log('  - WebKit version detected:', /Version\\/(\\d+\\.\\d+)/.exec(navigator.userAgent)?.[1] || 'unknown');
            
            if (!hasPointerLockAPI) {
                console.error('Norio: Pointer Lock API is not available in this WebView!');
                return;
            }
            
            // Track pointer lock attempts and user gesture state
            let lockAttempts = 0;
            let lockSuccessCount = 0;
            let lockErrorCount = 0;
            let userGestureActive = false;
            let lastUserGesture = 0;
            
            // Enhanced user gesture tracking
            function markUserGesture(eventType) {
                userGestureActive = true;
                lastUserGesture = Date.now();
                console.log('Norio: User gesture detected (' + eventType + '), pointer lock now available for 5 seconds');
                
                // User gesture expires after 5 seconds
                setTimeout(() => {
                    if (Date.now() - lastUserGesture >= 4900) {
                        userGestureActive = false;
                        console.log('Norio: User gesture expired, pointer lock may require new interaction');
                    }
                }, 5000);
            }
            
            // Track user gestures
            ['click', 'mousedown', 'touchstart', 'keydown'].forEach(eventType => {
                document.addEventListener(eventType, () => markUserGesture(eventType), { 
                    capture: true, 
                    passive: true 
                });
            });
            
            // Enhanced error reporting
            function getPointerLockErrorMessage(error) {
                if (!error) return 'Unknown error';
                
                switch (error.name || error.message) {
                    case 'NotSupportedError':
                        return 'Pointer lock not supported by this element or browser configuration';
                    case 'SecurityError':
                        return 'Security restriction - user gesture required or iframe limitations';
                    case 'InvalidStateError':
                        return 'Element not attached to document or invalid state';
                    case 'WrongDocumentError':
                        return 'Element belongs to wrong document';
                    case 'AbortError':
                        return 'Request was aborted - possibly conflicting with other pointer lock';
                    default:
                        return error.message || error.toString();
                }
            }
            
            // Override requestPointerLock with comprehensive tracking
            const originalRequestPointerLock = Element.prototype.requestPointerLock;
            Element.prototype.requestPointerLock = function(options) {
                lockAttempts++;
                const attemptId = lockAttempts;
                
                console.log('🎯 Norio: Pointer lock request #' + attemptId + ' initiated');
                console.log('  - Element:', this.tagName + (this.id ? '#' + this.id : '') + (this.className ? '.' + this.className.split(' ').join('.') : ''));
                console.log('  - Options:', JSON.stringify(options || {}));
                
                // Pre-flight checks
                const rect = this.getBoundingClientRect();
                const isVisible = rect.width > 0 && rect.height > 0;
                const isInViewport = rect.top >= 0 && rect.left >= 0 && rect.bottom <= window.innerHeight && rect.right <= window.innerWidth;
                const hasUserGesture = userGestureActive || (Date.now() - lastUserGesture < 5000);
                const documentHasFocus = document.hasFocus();
                const isInIframe = window !== window.top;
                
                console.log('  - Element visible:', isVisible, '(' + rect.width + 'x' + rect.height + ')');
                console.log('  - Element in viewport:', isInViewport);
                console.log('  - User gesture active:', hasUserGesture);
                console.log('  - Document has focus:', documentHasFocus);
                console.log('  - Current locked element:', document.pointerLockElement?.tagName || 'none');
                console.log('  - In iframe:', isInIframe);
                console.log('  - Sandbox restrictions:', document.getElementById('sandbox-info')?.textContent || 'none detected');
                
                if (!isVisible) {
                    console.warn('  ⚠️ Warning: Element is not visible, pointer lock may fail');
                }
                
                if (!hasUserGesture) {
                    console.warn('  ⚠️ Warning: No recent user gesture, pointer lock will likely fail');
                    console.warn('  📝 Tip: Pointer lock requires a recent click, keypress, or touch event');
                }
                
                if (!documentHasFocus) {
                    console.warn('  ⚠️ Warning: Document does not have focus');
                }
                
                if (isInIframe) {
                    console.warn('  ⚠️ Warning: In iframe, check permissions policy and sandbox attributes');
                }
                
                // Ensure element is focusable
                if (this.tabIndex === undefined || this.tabIndex < 0) {
                    this.tabIndex = -1;
                    console.log('  - Set tabIndex to -1 for focusability');
                }
                
                // Focus the element
                try {
                    this.focus();
                    console.log('  - Element focused successfully');
                } catch (e) {
                    console.warn('  - Failed to focus element:', e.message);
                }
                
                // Make the actual call
                try {
                    const result = originalRequestPointerLock.call(this, options || {});
                    console.log('  - requestPointerLock() call completed, result type:', typeof result);
                    
                    // Handle promise-based API
                    if (result && typeof result.then === 'function') {
                        console.log('  - Promise-based API detected');
                        return result.then(() => {
                            console.log('✅ Request #' + attemptId + ' promise resolved');
                        }).catch(error => {
                            lockErrorCount++;
                            console.error('❌ Request #' + attemptId + ' promise rejected:', getPointerLockErrorMessage(error));
                            throw error;
                        });
                    }
                    
                    console.log('  - Legacy callback-based API, waiting for events');
                    return result;
                } catch (error) {
                    lockErrorCount++;
                    console.error('❌ Request #' + attemptId + ' threw synchronous error:', getPointerLockErrorMessage(error));
                    throw error;
                }
            };
            
            // Enhanced event listeners
            document.addEventListener('pointerlockchange', function() {
                const element = document.pointerLockElement;
                if (element) {
                    lockSuccessCount++;
                    console.log('🎉 Norio: Pointer lock ACTIVATED!');
                    console.log('  - Locked element:', element.tagName + (element.id ? '#' + element.id : ''));
                    console.log('  - Success rate:', lockSuccessCount + '/' + lockAttempts + ' (' + Math.round(lockSuccessCount/lockAttempts*100) + '%)');
                    console.log('  - 💡 Mouse cursor should now be hidden and movement unlimited');
                    
                    // Create visual feedback
                    if (!document.getElementById('norio-pointer-lock-indicator')) {
                        const indicator = document.createElement('div');
                        indicator.id = 'norio-pointer-lock-indicator';
                        indicator.style.cssText = `
                            position: fixed;
                            top: 10px;
                            right: 10px;
                            background: #4CAF50;
                            color: white;
                            padding: 8px 12px;
                            border-radius: 4px;
                            font-family: monospace;
                            font-size: 12px;
                            z-index: 999999;
                            pointer-events: none;
                        `;
                        indicator.textContent = '🔒 Pointer Lock Active';
                        document.body.appendChild(indicator);
                    }
                } else {
                    console.log('🔓 Norio: Pointer lock DEACTIVATED');
                    
                    // Remove visual feedback
                    const indicator = document.getElementById('norio-pointer-lock-indicator');
                    if (indicator) {
                        indicator.remove();
                    }
                }
            });
            
            document.addEventListener('pointerlockerror', function(event) {
                lockErrorCount++;
                console.error('❌ Norio: Pointer lock ERROR occurred');
                console.log('  - Error rate:', lockErrorCount + '/' + lockAttempts + ' (' + Math.round(lockErrorCount/lockAttempts*100) + '%)');
                console.log('  - Event details:', event);
                
                // Diagnose the error after a short delay
                setTimeout(function() {
                    console.log('🔍 Error diagnosis:');
                    console.log('  - Document focus:', document.hasFocus());
                    console.log('  - Recent user gesture:', Date.now() - lastUserGesture < 5000);
                    console.log('  - Current URL:', window.location.href);
                    console.log('  - Page protocol:', window.location.protocol);
                    console.log('  - Is secure context:', window.isSecureContext);
                    console.log('  - In iframe:', window !== window.top);
                    
                    if (window !== window.top) {
                        console.log('  - Iframe sandbox:', document.querySelector('iframe')?.sandbox || 'none');
                    }
                    
                    console.log('💡 Common solutions:');
                    console.log('  1. Ensure user clicked/interacted recently');
                    console.log('  2. Check if page is in focus');
                    console.log('  3. Verify element is visible and attached to DOM');
                    console.log('  4. For iframes: check sandbox and permissions policy');
                    console.log('  5. Try calling requestPointerLock directly after user event');
                }, 100);
            });
            
            // Enhanced mouse movement tracking
            let mouseMoveCount = 0;
            let lastMovementTime = 0;
            document.addEventListener('mousemove', function(event) {
                if (document.pointerLockElement) {
                    mouseMoveCount++;
                    lastMovementTime = Date.now();
                    
                    // Log movement data occasionally
                    if (mouseMoveCount % 30 === 1) {
                        console.log('🖱️ Pointer lock movement (' + mouseMoveCount + ' total) - X:', event.movementX, 'Y:', event.movementY);
                    }
                }
            });
            
            // Auto-enhance gaming elements
            function enhanceGamingElements() {
                const canvases = document.querySelectorAll('canvas');
                const gameElements = document.querySelectorAll('[class*="game"], [id*="game"], [class*="play"], [id*="play"]');
                
                [...canvases, ...gameElements].forEach(element => {
                    if (element.dataset.norioEnhanced) return;
                    element.dataset.norioEnhanced = 'true';
                    
                    // Add click handler for automatic pointer lock
                    element.addEventListener('click', function(event) {
                        if (!document.pointerLockElement) {
                            console.log('🎮 Auto-requesting pointer lock on gaming element:', element.tagName);
                            
                            // Try with unadjustedMovement first, then fallback
                            element.requestPointerLock({ unadjustedMovement: true }).catch(err => {
                                console.warn('🎮 unadjustedMovement failed, trying standard pointer lock:', err.message);
                                return element.requestPointerLock();
                            }).catch(err2 => {
                                console.error('🎮 Both pointer lock attempts failed:', err2.message);
                            });
                        }
                    });
                    
                    // Add visual hint
                    if (element.tagName === 'CANVAS') {
                        element.title = element.title || 'Click to enable pointer lock for gaming';
                        element.style.cursor = element.style.cursor || 'crosshair';
                    }
                });
                
                console.log('🎮 Enhanced ' + (canvases.length + gameElements.length) + ' gaming elements for automatic pointer lock');
            }
            
            // Run enhancement on page load and DOM changes
            enhanceGamingElements();
            
            const observer = new MutationObserver(enhanceGamingElements);
            observer.observe(document.body, { childList: true, subtree: true });
            
            // Global debugging function
            window.norioPointerLockDebug = function() {
                console.log('=== Norio Pointer Lock Status ===');
                console.log('API Available:', hasPointerLockAPI);
                console.log('Current locked element:', document.pointerLockElement?.tagName || 'none');
                console.log('Document has focus:', document.hasFocus());
                console.log('User gesture active:', userGestureActive);
                console.log('Lock attempts:', lockAttempts);
                console.log('Successful locks:', lockSuccessCount);
                console.log('Lock errors:', lockErrorCount);
                console.log('Mouse movements received:', mouseMoveCount);
                console.log('Last movement time:', lastMovementTime ? new Date(lastMovementTime).toLocaleTimeString() : 'never');
                console.log('Time since last user gesture:', Math.round((Date.now() - lastUserGesture) / 1000) + 's');
                console.log('Enhanced gaming elements:', document.querySelectorAll('[data-norio-enhanced]').length);
                console.log('===================================');
                
                // Test pointer lock capability
                const testElement = document.querySelector('canvas') || document.body;
                console.log('🧪 Testing pointer lock capability...');
                testElement.requestPointerLock().catch(err => {
                    console.log('Test result: Failed -', getPointerLockErrorMessage(err));
                });
            };
            
            // Ready notification
            window.dispatchEvent(new CustomEvent('norioPointerLockReady', {
                detail: {
                    apiAvailable: hasPointerLockAPI,
                    version: '2.0',
                    timestamp: Date.now()
                }
            }));
            
            console.log('=== Norio Pointer Lock Enhancement v2.0 Ready ===');
            console.log('💡 Type norioPointerLockDebug() in console for status check');
            
        })();
        """
        
        injectScript(pointerLockScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }
}

// Tab management
public extension BrowserEngine {
    // Tab model
    class Tab: Identifiable, Equatable {
        public let id: UUID
        public let webView: WKWebView
        public var title: String = ""
        public var url: URL?
        public var favicon: Data?
        public var isLoading: Bool = false
        
        public init(id: UUID = UUID(), webView: WKWebView) {
            self.id = id
            self.webView = webView
        }
        
        public func loadURL(_ url: URL) {
            if url.absoluteString == "about:blank" {
                webView.loadHTMLString("", baseURL: nil)
            } else {
                let request = URLRequest(url: url)
                webView.load(request)
            }
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
        
        public static func == (lhs: BrowserEngine.Tab, rhs: BrowserEngine.Tab) -> Bool {
            lhs.id == rhs.id
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
            homepage: URL = URL(string: "about:blank")!,
            searchEngine: SearchEngine = .duckDuckGo,
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