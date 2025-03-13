import SwiftUI
import WebKit
import NorioCore
import NorioExtensions

public struct BrowserView: View {
    @StateObject private var tabManager = TabManager()
    @State private var urlString: String = ""
    @State private var isLoading: Bool = false
    @State private var showSettings: Bool = false
    @State private var showExtensions: Bool = false
    @State private var showBookmarks: Bool = false
    @State private var showHistory: Bool = false
    @State private var showExtensionsDropdown: Bool = false
    @State private var installedExtensions: [ExtensionManager.Extension] = []
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 8) {
                // Back button
                Button(action: {
                    tabManager.currentTab?.goBack()
                }) {
                    Image(systemName: "chevron.left")
                        .frame(width: 32, height: 32)
                }
                .disabled(tabManager.currentTab == nil)
                
                // Forward button
                Button(action: {
                    tabManager.currentTab?.goForward()
                }) {
                    Image(systemName: "chevron.right")
                        .frame(width: 32, height: 32)
                }
                .disabled(tabManager.currentTab == nil)
                
                // Refresh button
                Button(action: {
                    if isLoading {
                        tabManager.currentTab?.stopLoading()
                    } else {
                        tabManager.currentTab?.reload()
                    }
                }) {
                    Image(systemName: isLoading ? "xmark" : "arrow.clockwise")
                        .frame(width: 32, height: 32)
                }
                .disabled(tabManager.currentTab == nil)
                
                // Address bar
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    TextField("Search or enter website name", text: $urlString, onCommit: loadUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal, 8)
                
                // Settings button
                Button(action: {
                    showSettings.toggle()
                }) {
                    Image(systemName: "gear")
                        .frame(width: 32, height: 32)
                }
                
                // Extensions dropdown menu
                ExtensionDropdownButton(
                    showDropdown: $showExtensionsDropdown,
                    extensions: installedExtensions,
                    onExtensionAction: { extension in
                        ExtensionManager.shared.runExtensionAction(extension)
                    },
                    onManageExtensions: {
                        showExtensions = true
                    }
                )
            }
            .padding(8)
            .background(Color(.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.3)),
                alignment: .bottom
            )
            
            // Tab bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(tabManager.tabs) { tab in
                        TabView(tab: tab, isSelected: tabManager.currentTab?.id == tab.id) {
                            tabManager.switchToTab(tab)
                        } onClose: {
                            tabManager.closeTab(tab)
                        }
                    }
                    
                    Button(action: {
                        tabManager.createNewTab()
                    }) {
                        Image(systemName: "plus")
                            .padding(8)
                            .frame(width: 32)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(height: 36)
            .background(Color(.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.3)),
                alignment: .bottom
            )
            
            // Web content view
            WebViewContainer(tab: tabManager.currentTab) { tab, title, url, isLoading in
                if let tab = tab, let url = url {
                    tabManager.updateTab(tab, title: title, url: url, isLoading: isLoading)
                    
                    // Update URL string if it's the current tab
                    if tabManager.currentTab?.id == tab.id {
                        self.urlString = url.absoluteString
                        self.isLoading = isLoading
                    }
                }
            }
            
            // Status bar
            HStack {
                if let tab = tabManager.currentTab, let url = tab.url {
                    Text(url.host ?? "")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(Color(.systemBackground))
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showExtensions) {
            ExtensionsView()
        }
        .sheet(isPresented: $showBookmarks) {
            BookmarksView()
        }
        .sheet(isPresented: $showHistory) {
            HistoryView()
        }
        .onAppear {
            // Load installed extensions when the view appears
            installedExtensions = ExtensionManager.shared.getInstalledExtensions()
        }
    }
    
    private func loadUrl() {
        guard !urlString.isEmpty else { return }
        
        var urlToLoad: URL?
        
        // Check if it's a valid URL
        if let url = URL(string: urlString), url.scheme != nil {
            urlToLoad = url
        }
        // Check if it's a domain without scheme
        else if let url = URL(string: "https://" + urlString) {
            urlToLoad = url
        }
        // Treat as search query
        else {
            let searchEngine = BrowserEngine.SearchEngine.google
            let encodedQuery = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            urlToLoad = URL(string: searchEngine.searchURL.absoluteString + encodedQuery)
        }
        
        if let url = urlToLoad {
            tabManager.currentTab?.loadURL(url)
        }
    }
}

// Extensions Dropdown Button
private struct ExtensionDropdownButton: View {
    @Binding var showDropdown: Bool
    let extensions: [ExtensionManager.Extension]
    let onExtensionAction: (ExtensionManager.Extension) -> Void
    let onManageExtensions: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: {
                showDropdown.toggle()
            }) {
                Image(systemName: "puzzlepiece.extension")
                    .frame(width: 32, height: 32)
            }
            
            if showDropdown {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(extensions) { extension in
                        ExtensionDropdownItem(extension: extension) {
                            onExtensionAction(extension)
                            showDropdown = false
                        }
                    }
                    
                    Divider()
                    
                    Button(action: {
                        onManageExtensions()
                        showDropdown = false
                    }) {
                        HStack {
                            Text("Manage Extensions")
                            Spacer()
                            Image(systemName: "gear")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .offset(y: 40)
                .transition(.opacity)
                .zIndex(1)
                .onTapGesture {
                    // Prevent tap from closing the dropdown
                }
                .onAppear {
                    // Add a global tap gesture to close the dropdown when tapping elsewhere
                    #if os(iOS)
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
                    tapGesture.cancelsTouchesInView = false
                    UIApplication.shared.windows.first?.addGestureRecognizer(tapGesture)
                    #endif
                }
                .onDisappear {
                    // Remove the global tap gesture
                    #if os(iOS)
                    if let gestureRecognizers = UIApplication.shared.windows.first?.gestureRecognizers {
                        for gesture in gestureRecognizers {
                            if let tapGesture = gesture as? UITapGestureRecognizer, 
                               tapGesture.name == "ExtensionDropdownCloseTap" {
                                UIApplication.shared.windows.first?.removeGestureRecognizer(tapGesture)
                            }
                        }
                    }
                    #endif
                }
            }
        }
        .frame(width: 32, height: 32)
    }
    
    #if os(iOS)
    @objc private func handleTap() {
        showDropdown = false
    }
    #endif
}

// Extension Dropdown Item
private struct ExtensionDropdownItem: View {
    let extension: ExtensionManager.Extension
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Extension icon (placeholder for now)
                Image(systemName: extension.type == .chrome ? "globe" : "flame.fill")
                    .foregroundColor(extension.type == .chrome ? .blue : .orange)
                    .frame(width: 24, height: 24)
                
                // Extension name
                Text(extension.name)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Tab View
private struct TabView: View {
    let tab: BrowserEngine.Tab
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tab.title.isEmpty ? "New Tab" : tab.title)
                .font(.footnote)
                .lineLimit(1)
                .padding(.leading, 8)
            
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 8)
        }
        .frame(width: 180, height: 36)
        .background(isSelected ? Color(.systemGray5) : Color(.systemBackground))
        .cornerRadius(8, corners: [.topLeft, .topRight])
        .onTapGesture {
            onSelect()
        }
    }
}

// WebView Container
private struct WebViewContainer: UIViewRepresentable {
    let tab: BrowserEngine.Tab?
    let onUpdate: (BrowserEngine.Tab?, String, URL, Bool) -> Void
    
    #if os(macOS)
    typealias UIViewType = NSView
    #else
    typealias UIViewType = UIView
    #endif
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    #if os(macOS)
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        if let tab = tab {
            tab.webView.frame = view.bounds
            tab.webView.autoresizingMask = [.width, .height]
            view.addSubview(tab.webView)
            
            tab.webView.navigationDelegate = context.coordinator
            tab.webView.uiDelegate = context.coordinator
            
            // Apply content blocker rules
            ContentBlocker.shared.applyRulesToWebView(tab.webView)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        updateView(nsView, context: context)
    }
    #else
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        if let tab = tab {
            tab.webView.frame = view.bounds
            tab.webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(tab.webView)
            
            tab.webView.navigationDelegate = context.coordinator
            tab.webView.uiDelegate = context.coordinator
            
            // Apply content blocker rules
            ContentBlocker.shared.applyRulesToWebView(tab.webView)
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        updateView(uiView, context: context)
    }
    #endif
    
    private func updateView(_ view: UIViewType, context: Context) {
        // Clear existing subviews
        view.subviews.forEach { $0.removeFromSuperview() }
        
        // Add the current tab's WebView
        if let tab = tab {
            tab.webView.frame = view.bounds
            #if os(macOS)
            tab.webView.autoresizingMask = [.width, .height]
            #else
            tab.webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            #endif
            view.addSubview(tab.webView)
            
            tab.webView.navigationDelegate = context.coordinator
            tab.webView.uiDelegate = context.coordinator
            
            // Apply extensions and content blocker rules
            ExtensionManager.shared.applyExtensionsToWebView(tab.webView)
            ContentBlocker.shared.applyRulesToWebView(tab.webView)
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private var parent: WebViewContainer
        
        init(_ parent: WebViewContainer) {
            self.parent = parent
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            guard let tab = parent.tab else { return }
            parent.onUpdate(tab, tab.title, webView.url ?? URL(string: "about:blank")!, true)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let tab = parent.tab else { return }
            parent.onUpdate(tab, webView.title ?? "", webView.url ?? URL(string: "about:blank")!, false)
            
            // Check if we're on an extension store page and offer to install
            checkForExtensionInstallation(webView)
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            guard let tab = parent.tab else { return }
            parent.onUpdate(tab, "Error", webView.url ?? URL(string: "about:blank")!, false)
        }
        
        // MARK: - WKUIDelegate
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // Handle new window/tab requests
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
        
        // MARK: - Extension Installation Detection
        
        private func checkForExtensionInstallation(_ webView: WKWebView) {
            guard let url = webView.url?.absoluteString else { return }
            
            // Check if we're on a Chrome extension page
            if url.hasPrefix(ExtensionManager.chromeWebStoreBaseURL) {
                // Extract ID from URL
                let components = url.components(separatedBy: "/")
                if components.count > 5 {
                    let extensionId = components[5].split(separator: "?").first ?? ""
                    if !extensionId.isEmpty && extensionId.count == 32 {
                        offerToInstallExtension(
                            id: String(extensionId),
                            type: .chrome,
                            webView: webView
                        )
                    }
                }
            }
            // Check if we're on a Firefox addon page
            else if url.hasPrefix(ExtensionManager.firefoxAddonsBaseURL) {
                // Extract ID from URL
                let components = url.components(separatedBy: "/")
                if components.count >= 6 {
                    let extensionId = components[5].split(separator: "?").first ?? ""
                    if !extensionId.isEmpty {
                        offerToInstallExtension(
                            id: String(extensionId),
                            type: .firefox,
                            webView: webView
                        )
                    }
                }
            }
        }
        
        private func offerToInstallExtension(id: String, type: ExtensionManager.ExtensionType, webView: WKWebView) {
            #if os(macOS)
            let alert = NSAlert()
            alert.messageText = "Install Extension"
            alert.informativeText = "Would you like to install this \(type == .chrome ? "Chrome" : "Firefox") extension?"
            alert.addButton(withTitle: "Install")
            alert.addButton(withTitle: "Cancel")
            
            if alert.runModal() == .alertFirstButtonReturn {
                installExtension(id: id, type: type)
            }
            #else
            // On iOS, inject a banner into the page
            let bannerScript = """
            (function() {
                if (document.getElementById('norioInstallBanner')) return;
                
                var banner = document.createElement('div');
                banner.id = 'norioInstallBanner';
                banner.style.position = 'fixed';
                banner.style.top = '0';
                banner.style.left = '0';
                banner.style.right = '0';
                banner.style.backgroundColor = '#007AFF';
                banner.style.color = 'white';
                banner.style.padding = '10px';
                banner.style.textAlign = 'center';
                banner.style.zIndex = '9999';
                banner.style.fontFamily = '-apple-system, BlinkMacSystemFont, sans-serif';
                
                banner.innerHTML = '<div style="display: flex; justify-content: space-between; align-items: center;">' +
                    '<span>Install this \(type == .chrome ? "Chrome" : "Firefox") extension in Norio?</span>' +
                    '<button id="norioInstallButton" style="background-color: white; color: #007AFF; border: none; padding: 5px 10px; border-radius: 5px; font-weight: bold;">Install</button>' +
                    '</div>';
                
                document.body.insertBefore(banner, document.body.firstChild);
                document.body.style.marginTop = (banner.offsetHeight + 10) + 'px';
                
                document.getElementById('norioInstallButton').addEventListener('click', function() {
                    window.webkit.messageHandlers.installExtension.postMessage({
                        id: '\(id)',
                        type: '\(type == .chrome ? "chrome" : "firefox")'
                    });
                    banner.style.display = 'none';
                    document.body.style.marginTop = '0';
                });
            })();
            """
            
            // Add a script message handler for the install button
            webView.configuration.userContentController.add(self, name: "installExtension")
            
            // Inject the banner
            webView.evaluateJavaScript(bannerScript, completionHandler: nil)
            #endif
        }
        
        private func installExtension(id: String, type: ExtensionManager.ExtensionType) {
            switch type {
            case .chrome:
                ExtensionManager.shared.installChromeExtensionFromStore(id: id) { result in
                    self.handleInstallResult(result)
                }
            case .firefox:
                ExtensionManager.shared.installFirefoxExtensionFromStore(id: id) { result in
                    self.handleInstallResult(result)
                }
            }
        }
        
        private func handleInstallResult(_ result: Result<ExtensionManager.Extension, Error>) {
            DispatchQueue.main.async {
                #if os(macOS)
                let alert = NSAlert()
                switch result {
                case .success(let ext):
                    alert.messageText = "Extension Installed"
                    alert.informativeText = "\(ext.name) has been successfully installed."
                    alert.addButton(withTitle: "OK")
                case .failure(let error):
                    alert.messageText = "Installation Failed"
                    alert.informativeText = "The extension could not be installed: \(error.localizedDescription)"
                    alert.addButton(withTitle: "OK")
                }
                alert.runModal()
                #else
                // On iOS, show a banner notification
                let script: String
                switch result {
                case .success(let ext):
                    script = """
                    (function() {
                        var banner = document.createElement('div');
                        banner.style.position = 'fixed';
                        banner.style.top = '0';
                        banner.style.left = '0';
                        banner.style.right = '0';
                        banner.style.backgroundColor = '#4CD964';
                        banner.style.color = 'white';
                        banner.style.padding = '10px';
                        banner.style.textAlign = 'center';
                        banner.style.zIndex = '9999';
                        banner.style.fontFamily = '-apple-system, BlinkMacSystemFont, sans-serif';
                        banner.innerHTML = '\(ext.name) has been successfully installed.';
                        document.body.appendChild(banner);
                        setTimeout(function() { banner.style.display = 'none'; }, 3000);
                    })();
                    """
                case .failure:
                    script = """
                    (function() {
                        var banner = document.createElement('div');
                        banner.style.position = 'fixed';
                        banner.style.top = '0';
                        banner.style.left = '0';
                        banner.style.right = '0';
                        banner.style.backgroundColor = '#FF3B30';
                        banner.style.color = 'white';
                        banner.style.padding = '10px';
                        banner.style.textAlign = 'center';
                        banner.style.zIndex = '9999';
                        banner.style.fontFamily = '-apple-system, BlinkMacSystemFont, sans-serif';
                        banner.innerHTML = 'The extension could not be installed.';
                        document.body.appendChild(banner);
                        setTimeout(function() { banner.style.display = 'none'; }, 3000);
                    })();
                    """
                }
                self.parent.tab?.webView.evaluateJavaScript(script, completionHandler: nil)
                #endif
            }
        }
    }
}

// MARK: - Script Message Handler for iOS
#if os(iOS)
extension WebViewContainer.Coordinator: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "installExtension" {
            guard let body = message.body as? [String: String],
                  let id = body["id"],
                  let typeString = body["type"],
                  let type = typeString == "chrome" ? ExtensionManager.ExtensionType.chrome : ExtensionManager.ExtensionType.firefox else {
                return
            }
            
            installExtension(id: id, type: type)
        }
    }
}
#endif

// Tab Manager
private class TabManager: ObservableObject {
    @Published var tabs: [BrowserEngine.Tab] = []
    @Published var currentTab: BrowserEngine.Tab?
    
    init() {
        // Create initial tab
        createNewTab()
    }
    
    func createNewTab() {
        let webView = BrowserEngine.shared.createWebView()
        let tab = BrowserEngine.Tab(webView: webView)
        tabs.append(tab)
        currentTab = tab
        
        // Load homepage
        if let url = URL(string: "https://www.google.com") {
            tab.loadURL(url)
        }
    }
    
    func closeTab(_ tab: BrowserEngine.Tab) {
        guard tabs.count > 1 else { return }
        
        if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
            tabs.remove(at: index)
            
            // If closing the current tab, switch to the previous tab or the first available
            if currentTab?.id == tab.id {
                if index > 0 {
                    currentTab = tabs[index - 1]
                } else {
                    currentTab = tabs.first
                }
            }
        }
    }
    
    func switchToTab(_ tab: BrowserEngine.Tab) {
        currentTab = tab
    }
    
    func updateTab(_ tab: BrowserEngine.Tab, title: String, url: URL, isLoading: Bool) {
        if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
            tabs[index].title = title
            tabs[index].url = url
            tabs[index].isLoading = isLoading
            
            objectWillChange.send()
        }
    }
}

// Settings View
private struct SettingsView: View {
    @State private var showContentBlockingSettings = false
    @State private var contentBlockingEnabled = BrowserEngine.shared.contentBlockingEnabled
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("General")) {
                    Text("Homepage")
                    Text("Search Engine")
                    Text("Default Browser")
                }
                
                Section(header: Text("Privacy")) {
                    Toggle("Block Ads and Trackers", isOn: $contentBlockingEnabled)
                        .onChange(of: contentBlockingEnabled) { newValue in
                            BrowserEngine.shared.contentBlockingEnabled = newValue
                        }
                    
                    NavigationLink(destination: ContentBlockingSettingsView()) {
                        Text("Content Blocking Settings")
                    }
                    
                    Text("Block Cookies")
                    Text("Do Not Track")
                    Text("Clear Browsing Data")
                }
                
                Section(header: Text("Extensions")) {
                    NavigationLink(destination: ExtensionsView()) {
                        Text("Manage Extensions")
                    }
                }
                
                Section(header: Text("About")) {
                    Text("Version 1.0.0")
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
        }
    }
}

// Content Blocking Settings View
private struct ContentBlockingSettingsView: View {
    @State private var blockLists: [ContentBlocker.BlockList] = []
    @State private var isUpdating = false
    @State private var showAddListSheet = false
    @State private var lastUpdated: Date?
    
    var body: some View {
        List {
            Section(header: Text("Block Lists")) {
                if blockLists.isEmpty {
                    Text("No block lists enabled")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    ForEach(blockLists) { blockList in
                        BlockListRow(blockList: blockList) {
                            // Reload block lists after toggle
                            loadBlockLists()
                        }
                    }
                }
            }
            
            Section {
                Button(action: {
                    showAddListSheet = true
                }) {
                    Label("Add Custom Block List", systemImage: "plus")
                }
                
                Button(action: updateBlockLists) {
                    if isUpdating {
                        HStack {
                            Text("Updating...")
                            Spacer()
                            ProgressView()
                        }
                    } else {
                        Label("Update Block Lists", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                .disabled(isUpdating)
                
                Button(action: resetToDefaults) {
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                        .foregroundColor(.red)
                }
            }
            
            if let lastUpdated = lastUpdated {
                Section(footer: Text("Last updated: \(lastUpdated, formatter: dateFormatter)")) {
                    EmptyView()
                }
            }
        }
        .onAppear(perform: loadBlockLists)
        .navigationTitle("Content Blocking")
        .sheet(isPresented: $showAddListSheet) {
            AddBlockListView { success in
                if success {
                    loadBlockLists()
                }
                showAddListSheet = false
            }
        }
    }
    
    private func loadBlockLists() {
        blockLists = ContentBlocker.shared.getAvailableBlockLists()
        lastUpdated = ContentBlocker.shared.lastUpdateDate
    }
    
    private func updateBlockLists() {
        isUpdating = true
        ContentBlocker.shared.updateAllBlockLists { result in
            isUpdating = false
            loadBlockLists()
        }
    }
    
    private func resetToDefaults() {
        ContentBlocker.shared.resetToDefaults()
        loadBlockLists()
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

// Block List Row
private struct BlockListRow: View {
    let blockList: ContentBlocker.BlockList
    let onToggle: () -> Void
    
    @State private var isEnabled: Bool
    
    init(blockList: ContentBlocker.BlockList, onToggle: @escaping () -> Void) {
        self.blockList = blockList
        self.onToggle = onToggle
        self._isEnabled = State(initialValue: blockList.isEnabled)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(blockList.name)
                    .font(.headline)
                
                Text(categoryText)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(categoryColor.opacity(0.2))
                    .cornerRadius(4)
                
                if let lastUpdated = blockList.lastUpdated {
                    Text("Rules: \(blockList.ruleCount) • Updated: \(lastUpdated, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .onChange(of: isEnabled) { newValue in
                    ContentBlocker.shared.setBlockListEnabled(blockList, enabled: newValue)
                    onToggle()
                }
        }
        .contextMenu {
            Button(action: {
                ContentBlocker.shared.removeBlockList(blockList)
                onToggle()
            }) {
                Label("Remove Block List", systemImage: "trash")
            }
        }
    }
    
    private var categoryText: String {
        switch blockList.category {
        case .ads: return "Ads"
        case .trackers: return "Trackers"
        case .both: return "Ads & Trackers"
        }
    }
    
    private var categoryColor: Color {
        switch blockList.category {
        case .ads: return .red
        case .trackers: return .blue
        case .both: return .purple
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }
}

// Add Block List View
private struct AddBlockListView: View {
    @State private var name: String = ""
    @State private var url: String = ""
    @State private var category: ContentBlocker.BlockListCategory = .both
    @State private var isAdding = false
    @State private var errorMessage: String?
    
    let onDismiss: (Bool) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Block List Details")) {
                    TextField("Name", text: $name)
                    
                    TextField("URL", text: $url)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                    
                    Picker("Category", selection: $category) {
                        Text("Ads").tag(ContentBlocker.BlockListCategory.ads)
                        Text("Trackers").tag(ContentBlocker.BlockListCategory.trackers)
                        Text("Both").tag(ContentBlocker.BlockListCategory.both)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(action: addBlockList) {
                        if isAdding {
                            HStack {
                                Text("Adding...")
                                Spacer()
                                ProgressView()
                            }
                        } else {
                            Text("Add Block List")
                        }
                    }
                    .disabled(isAdding || name.isEmpty || url.isEmpty)
                }
            }
            .navigationTitle("Add Block List")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onDismiss(false)
                    }
                }
            }
        }
    }
    
    private func addBlockList() {
        guard let listURL = URL(string: url) else {
            errorMessage = "Invalid URL format"
            return
        }
        
        isAdding = true
        errorMessage = nil
        
        ContentBlocker.shared.addCustomBlockList(name: name, url: listURL, category: category) { result in
            isAdding = false
            
            switch result {
            case .success:
                onDismiss(true)
            case .failure(let error):
                errorMessage = "Failed to add block list: \(error.localizedDescription)"
            }
        }
    }
}

// Extensions View
private struct ExtensionsView: View {
    @State private var extensions: [ExtensionManager.Extension] = []
    @State private var showInstallSheet: Bool = false
    @State private var showWebStoresSheet: Bool = false
    @State private var installURL: String = ""
    @State private var selectedExtensionType: ExtensionManager.ExtensionType = .chrome
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Installed Extensions")) {
                    if extensions.isEmpty {
                        Text("No extensions installed")
                            .foregroundColor(.gray)
                            .italic()
                            .padding(.vertical, 8)
                    } else {
                        ForEach(extensions) { extensionItem in
                            ExtensionListItem(extension: extensionItem) {
                                // Reload extensions after a change
                                loadExtensions()
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        showWebStoresSheet = true
                    }) {
                        Label("Browse Extension Stores", systemImage: "safari")
                    }
                    
                    Button(action: {
                        showInstallSheet = true
                    }) {
                        Label("Install From URL", systemImage: "link")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Extensions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showInstallSheet = false
                        showWebStoresSheet = false
                    }
                }
            }
            .sheet(isPresented: $showInstallSheet) {
                InstallExtensionView(selectedType: $selectedExtensionType, url: $installURL) {
                    installExtension()
                }
            }
            .sheet(isPresented: $showWebStoresSheet) {
                NavigationView {
                    WebStoreExtensionsView()
                        .navigationBarItems(trailing: Button("Done") {
                            showWebStoresSheet = false
                            // Refresh the list after possibly installing from stores
                            loadExtensions()
                        })
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
            .onAppear {
                loadExtensions()
            }
        }
    }
    
    private func loadExtensions() {
        extensions = ExtensionManager.shared.getInstalledExtensions()
    }
    
    private func installExtension() {
        guard let url = URL(string: installURL) else { return }
        
        switch selectedExtensionType {
        case .chrome:
            ExtensionManager.shared.installChromeExtension(from: url) { result in
                handleInstallResult(result)
            }
        case .firefox:
            ExtensionManager.shared.installFirefoxExtension(from: url) { result in
                handleInstallResult(result)
            }
        }
    }
    
    private func handleInstallResult(_ result: Result<ExtensionManager.Extension, Error>) {
        DispatchQueue.main.async {
            switch result {
            case .success:
                // Extension installed successfully
                installURL = ""
                showInstallSheet = false
                loadExtensions()
            case .failure:
                // Extension installation failed
                // In a real app, show an error message
                showInstallSheet = false
            }
        }
    }
}

private struct ExtensionListItem: View {
    let extension: ExtensionManager.Extension
    let onUpdate: () -> Void
    @State private var isEnabled: Bool
    
    init(extension: ExtensionManager.Extension, onUpdate: @escaping () -> Void) {
        self.extension = `extension`
        self.onUpdate = onUpdate
        self._isEnabled = State(initialValue: `extension`.enabled)
    }
    
    var body: some View {
        HStack {
            // Extension icon
            Image(systemName: `extension`.type == .chrome ? "globe" : "flame.fill")
                .foregroundColor(`extension`.type == .chrome ? .blue : .orange)
                .frame(width: 24, height: 24)
            
            // Extension details
            VStack(alignment: .leading, spacing: 2) {
                Text(`extension`.name)
                    .font(.headline)
                
                Text(`extension`.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                HStack {
                    Text("Version: \(`extension`.version)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text(`extension`.type == .chrome ? "Chrome" : "Firefox")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(`extension`.type == .chrome ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Enable/disable toggle
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .onChange(of: isEnabled) { newValue in
                    ExtensionManager.shared.setExtensionEnabled(`extension`.id, enabled: newValue)
                    onUpdate()
                }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button(action: {
                // Remove the extension
                ExtensionManager.shared.removeExtension(`extension`.id)
                onUpdate()
            }) {
                Label("Remove Extension", systemImage: "trash")
            }
        }
    }
}

private struct InstallExtensionView: View {
    @Binding var selectedType: ExtensionManager.ExtensionType
    @Binding var url: String
    let onInstall: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Extension Type")) {
                    Picker("Type", selection: $selectedType) {
                        Text("Chrome Extension").tag(ExtensionManager.ExtensionType.chrome)
                        Text("Firefox Add-on").tag(ExtensionManager.ExtensionType.firefox)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Extension URL"), footer: Text("Enter the URL of the extension file (.crx or .xpi)")) {
                    TextField("https://example.com/extension.crx", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section {
                    Button("Install Extension") {
                        onInstall()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(url.isEmpty)
                }
            }
            .navigationTitle("Install Extension")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// Web Store Extensions View
private struct WebStoreExtensionsView: View {
    enum StoreType {
        case chrome
        case firefox
        
        var title: String {
            switch self {
            case .chrome: return "Chrome Web Store"
            case .firefox: return "Firefox Add-ons"
            }
        }
        
        var placeholderText: String {
            switch self {
            case .chrome: return "Chrome extension ID or name"
            case .firefox: return "Firefox add-on ID or name"
            }
        }
        
        var exampleID: String {
            switch self {
            case .chrome: return "bkbeeeffjjeopflfhgeknacdieedcoml" // Ghostery example
            case .firefox: return "ghostery" // Ghostery example
            }
        }
    }
    
    @State private var selectedStore: StoreType = .chrome
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var searchResults: [ExtensionResult] = []
    @State private var isInstalling: Bool = false
    @State private var errorMessage: String?
    @State private var featuredExtensions: [ExtensionResult] = []
    
    struct ExtensionResult: Identifiable {
        let id: String
        let name: String
        let description: String
        let storeURL: URL
        let iconURL: URL?
        let type: ExtensionManager.ExtensionType
        
        var isInstalling = false
    }
    
    var body: some View {
        VStack {
            // Store selector
            Picker("Store", selection: $selectedStore) {
                Text("Chrome Web Store").tag(StoreType.chrome)
                Text("Firefox Add-ons").tag(StoreType.firefox)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.top)
            .onChange(of: selectedStore) { _ in
                // Clear search when changing stores
                searchText = ""
                searchResults = []
                loadFeaturedExtensions()
            }
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField(selectedStore.placeholderText, text: $searchText)
                    .submitLabel(.search)
                    .onSubmit {
                        searchExtensions()
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        searchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button("Search") {
                    searchExtensions()
                }
                .disabled(searchText.isEmpty || isSearching)
            }
            .padding()
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            // Results list
            if isSearching {
                ProgressView("Searching...")
                    .padding()
            } else if !searchResults.isEmpty {
                ScrollView {
                    LazyVStack {
                        ForEach(searchResults.indices, id: \.self) { index in
                            ExtensionResultItem(
                                result: searchResults[index],
                                onInstall: { installExtension(searchResults[index]) }
                            )
                            .padding(.horizontal)
                            .background(index % 2 == 0 ? Color(.systemBackground) : Color(.systemGray6))
                        }
                    }
                }
            } else {
                // Featured extensions
                ScrollView {
                    VStack(alignment: .leading) {
                        Text("Featured \(selectedStore.title) Extensions")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        if featuredExtensions.isEmpty {
                            ProgressView("Loading featured extensions...")
                                .padding()
                        } else {
                            LazyVStack {
                                ForEach(featuredExtensions.indices, id: \.self) { index in
                                    ExtensionResultItem(
                                        result: featuredExtensions[index],
                                        onInstall: { installExtension(featuredExtensions[index]) }
                                    )
                                    .padding(.horizontal)
                                    .background(index % 2 == 0 ? Color(.systemBackground) : Color(.systemGray6))
                                }
                            }
                        }
                        
                        Text("Example: Search for an extension by ID: \(selectedStore.exampleID)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
            }
        }
        .navigationTitle("Browse Extensions")
        .onAppear {
            loadFeaturedExtensions()
        }
    }
    
    private func loadFeaturedExtensions() {
        // In a real app, we would fetch these from the stores' APIs
        // For this demo, we'll use hardcoded featured extensions
        
        switch selectedStore {
        case .chrome:
            featuredExtensions = [
                ExtensionResult(
                    id: "cjpalhdlnbpafiamejdnhcphjbkeiagm",
                    name: "uBlock Origin",
                    description: "Finally, an efficient blocker. Easy on CPU and memory.",
                    storeURL: URL(string: "\(ExtensionManager.chromeWebStoreBaseURL)cjpalhdlnbpafiamejdnhcphjbkeiagm")!,
                    iconURL: nil,
                    type: .chrome
                ),
                ExtensionResult(
                    id: "mlomiejdfkolichcflejclcbmpeaniij",
                    name: "Ghostery",
                    description: "Blocks ads, stop trackers, and speed up websites.",
                    storeURL: URL(string: "\(ExtensionManager.chromeWebStoreBaseURL)mlomiejdfkolichcflejclcbmpeaniij")!,
                    iconURL: nil,
                    type: .chrome
                ),
                ExtensionResult(
                    id: "gcbommkclmclpchllfjekcdonpmejbdp",
                    name: "HTTPS Everywhere",
                    description: "Encrypt the web! Automatically use HTTPS security on many sites.",
                    storeURL: URL(string: "\(ExtensionManager.chromeWebStoreBaseURL)gcbommkclmclpchllfjekcdonpmejbdp")!,
                    iconURL: nil,
                    type: .chrome
                )
            ]
        case .firefox:
            featuredExtensions = [
                ExtensionResult(
                    id: "ublock-origin",
                    name: "uBlock Origin",
                    description: "Finally, an efficient blocker. Easy on CPU and memory.",
                    storeURL: URL(string: "\(ExtensionManager.firefoxAddonsBaseURL)ublock-origin")!,
                    iconURL: nil,
                    type: .firefox
                ),
                ExtensionResult(
                    id: "ghostery",
                    name: "Ghostery",
                    description: "Blocks ads, stop trackers, and speed up websites.",
                    storeURL: URL(string: "\(ExtensionManager.firefoxAddonsBaseURL)ghostery")!,
                    iconURL: nil,
                    type: .firefox
                ),
                ExtensionResult(
                    id: "https-everywhere",
                    name: "HTTPS Everywhere",
                    description: "Encrypt the web! Automatically use HTTPS security on many sites.",
                    storeURL: URL(string: "\(ExtensionManager.firefoxAddonsBaseURL)https-everywhere")!,
                    iconURL: nil,
                    type: .firefox
                )
            ]
        }
    }
    
    private func searchExtensions() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        // In a real app, we would search the stores' APIs
        // For this demo, we'll simulate search results
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            switch selectedStore {
            case .chrome:
                // Check if user entered an ID directly
                if searchText.matches("^[a-z]{32}$") {
                    searchResults = [
                        ExtensionResult(
                            id: searchText,
                            name: "Chrome Extension \(searchText.prefix(6))...",
                            description: "Extension matching ID \(searchText)",
                            storeURL: URL(string: "\(ExtensionManager.chromeWebStoreBaseURL)\(searchText)")!,
                            iconURL: nil,
                            type: .chrome
                        )
                    ]
                } else {
                    // Simulate search results
                    searchResults = featuredExtensions.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                    
                    if searchResults.isEmpty {
                        errorMessage = "No extensions found matching '\(searchText)'"
                    }
                }
            case .firefox:
                // Check if user entered an ID directly
                if searchText.contains("@mozilla.org") {
                    let cleanID = searchText.replacingOccurrences(of: "@mozilla.org", with: "")
                    searchResults = [
                        ExtensionResult(
                            id: cleanID,
                            name: "Firefox Add-on \(cleanID)",
                            description: "Add-on matching ID \(searchText)",
                            storeURL: URL(string: "\(ExtensionManager.firefoxAddonsBaseURL)\(cleanID)")!,
                            iconURL: nil,
                            type: .firefox
                        )
                    ]
                } else {
                    // Simulate search results
                    searchResults = featuredExtensions.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                    
                    if searchResults.isEmpty {
                        errorMessage = "No add-ons found matching '\(searchText)'"
                    }
                }
            }
            
            isSearching = false
        }
    }
    
    private func installExtension(_ result: ExtensionResult) {
        isInstalling = true
        errorMessage = nil
        
        // Update the isInstalling flag in the search results
        if let index = searchResults.firstIndex(where: { $0.id == result.id }) {
            searchResults[index].isInstalling = true
        }
        
        // Update the isInstalling flag in the featured extensions
        if let index = featuredExtensions.firstIndex(where: { $0.id == result.id }) {
            featuredExtensions[index].isInstalling = true
        }
        
        // Install from the appropriate store
        switch result.type {
        case .chrome:
            ExtensionManager.shared.installChromeExtensionFromStore(id: result.id) { installResult in
                handleInstallResult(result: result, installResult: installResult)
            }
        case .firefox:
            ExtensionManager.shared.installFirefoxExtensionFromStore(id: result.id) { installResult in
                handleInstallResult(result: result, installResult: installResult)
            }
        }
    }
    
    private func handleInstallResult(result: ExtensionResult, installResult: Result<ExtensionManager.Extension, Error>) {
        DispatchQueue.main.async {
            isInstalling = false
            
            // Reset the isInstalling flag in the search results
            if let index = searchResults.firstIndex(where: { $0.id == result.id }) {
                searchResults[index].isInstalling = false
            }
            
            // Reset the isInstalling flag in the featured extensions
            if let index = featuredExtensions.firstIndex(where: { $0.id == result.id }) {
                featuredExtensions[index].isInstalling = false
            }
            
            switch installResult {
            case .success:
                // Show success message
                errorMessage = "Successfully installed \(result.name)"
            case .failure(let error):
                // Show error message
                errorMessage = "Failed to install: \(error.localizedDescription)"
            }
        }
    }
}

// Extension Result Item
private struct ExtensionResultItem: View {
    let result: WebStoreExtensionsView.ExtensionResult
    let onInstall: () -> Void
    
    var body: some View {
        HStack {
            // Extension icon (placeholder for now)
            Image(systemName: result.type == .chrome ? "globe" : "flame.fill")
                .foregroundColor(result.type == .chrome ? .blue : .orange)
                .frame(width: 48, height: 48)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            // Extension details
            VStack(alignment: .leading, spacing: 4) {
                Text(result.name)
                    .font(.headline)
                
                Text(result.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack {
                    Link("View in \(result.type == .chrome ? "Chrome Web Store" : "Firefox Add-ons")", destination: result.storeURL)
                        .font(.caption)
                }
            }
            .padding(.leading, 8)
            
            Spacer()
            
            // Install button
            Button(action: onInstall) {
                if result.isInstalling {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(width: 80)
                } else {
                    Text("Install")
                        .frame(width: 80)
                }
            }
            .buttonStyle(BorderedButtonStyle())
            .disabled(result.isInstalling)
        }
        .padding(.vertical, 8)
    }
}

// Add this extension to make regex matching easier
extension String {
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression) != nil
    }
}

// Bookmarks View
private struct BookmarksView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Bookmarks will be listed here")
                    .padding()
                    .foregroundColor(.gray)
            }
            .navigationTitle("Bookmarks")
        }
    }
}

// History View
private struct HistoryView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("History will be listed here")
                    .padding()
                    .foregroundColor(.gray)
            }
            .navigationTitle("History")
        }
    }
}

// Helper for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
} 