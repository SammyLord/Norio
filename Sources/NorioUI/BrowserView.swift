import SwiftUI
import WebKit
import NorioCore
import NorioExtensions

#if os(macOS)
import AppKit
#else
import UIKit
#endif

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
                    goBack()
                }) {
                    Image(systemName: "chevron.left")
                        .frame(width: 32, height: 32)
                }
                .disabled(tabManager.currentTab == nil)
                .accessibilityIdentifier("backButton")
                
                // Forward button
                Button(action: {
                    goForward()
                }) {
                    Image(systemName: "chevron.right")
                        .frame(width: 32, height: 32)
                }
                .disabled(tabManager.currentTab == nil)
                .accessibilityIdentifier("forwardButton")
                
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
                .accessibilityIdentifier("refreshButton")
                
                // Address bar
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                        .accessibilityIdentifier("secureIndicator")
                    
                    TextField("Search or enter website name", text: $urlString, onCommit: loadUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .accessibilityIdentifier("addressBar")
                }
                .padding(.horizontal, 8)
                .accessibilityIdentifier("addressBarContainer")
                
                // Settings button
                Button(action: {
                    showSettings.toggle()
                }) {
                    Image(systemName: "gear")
                        .frame(width: 32, height: 32)
                }
                .accessibilityIdentifier("settingsButton")
                
                // Extensions dropdown menu
                ExtensionDropdownButton(
                    showDropdown: $showExtensionsDropdown,
                    extensions: installedExtensions,
                    onExtensionAction: { extensionItem in
                        ExtensionManager.shared.runExtensionAction(extensionItem)
                    },
                    onManageExtensions: {
                        showExtensions = true
                    }
                )
                .accessibilityIdentifier("extensionsDropdownButton")
            }
            .padding(8)
            .background(Color.background)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.3)),
                alignment: .bottom
            )
            .accessibilityIdentifier("toolbarContainer")
            
            // Tab bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(tabManager.tabs) { tab in
                        TabView(tab: tab, isSelected: tabManager.currentTab?.id == tab.id) {
                            tabManager.switchToTab(tab)
                        } onClose: {
                            tabManager.closeTab(tab)
                        }
                        .accessibilityIdentifier("tab-\(tab.id)")
                    }
                    
                    Button(action: {
                        tabManager.createNewTab()
                    }) {
                        Image(systemName: "plus")
                            .padding(8)
                            .frame(width: 32)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityIdentifier("newTabButton")
                }
                .accessibilityIdentifier("tabsContainer")
            }
            .frame(height: 36)
            .background(Color.background)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.3)),
                alignment: .bottom
            )
            .accessibilityIdentifier("tabBar")
            
            // Web content view
            BrowserWebViewContainer(tab: tabManager.currentTab) { tab, title, url, isLoading in
                if let tab = tab {
                    tabManager.updateTab(tab, title: title, url: url, isLoading: isLoading)
                    
                    // Update URL string if it's the current tab
                    if tabManager.currentTab?.id == tab.id {
                        self.urlString = url.absoluteString
                        self.isLoading = isLoading
                    }
                }
            }
            .accessibilityIdentifier("webViewContainer")
            
            // Status bar
            HStack {
                if let tab = tabManager.currentTab, let url = tab.url {
                    Text(url.host ?? "")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .accessibilityIdentifier("statusUrl")
                }
                Spacer()
            }
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(Color.background)
            .accessibilityIdentifier("statusBar")
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
    
    func goBack() {
        if let tab = tabManager.currentTab {
            _ = tab.goBack()
        }
    }
    
    func goForward() {
        if let tab = tabManager.currentTab {
            _ = tab.goForward()
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
                    ForEach(extensions) { extensionItem in
                        ExtensionDropdownItem(extensionItem: extensionItem) {
                            onExtensionAction(extensionItem)
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
                .background(Color.background)
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
                    setupTapHandler()
                    #endif
                }
                .onDisappear {
                    // Remove the global tap gesture
                    #if os(iOS)
                    tapHandler = nil
                    #endif
                }
            }
        }
        .frame(width: 32, height: 32)
    }
    
    #if os(iOS)
    // Using a class-based coordinator for Objective-C compatibility
    private final class TapHandler: NSObject {
        var onTap: () -> Void
        
        init(onTap: @escaping () -> Void) {
            self.onTap = onTap
            super.init()
        }
        
        @objc func handleTap() {
            onTap()
        }
    }
    
    private var tapHandler: TapHandler?
    
    private func setupTapHandler() {
        tapHandler = TapHandler(onTap: { [weak showDropdown] in
            showDropdown?.wrappedValue = false
        })
        
        let tapGesture = UITapGestureRecognizer(target: tapHandler, action: #selector(TapHandler.handleTap))
        tapGesture.cancelsTouchesInView = false
        tapGesture.name = "ExtensionDropdownCloseTap"
        UIApplication.shared.windows.first?.addGestureRecognizer(tapGesture)
    }
    #endif
}

// Extension Dropdown Item
private struct ExtensionDropdownItem: View {
    let extensionItem: ExtensionManager.Extension
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Extension icon (placeholder for now)
                Image(systemName: extensionItem.type == .chrome ? "globe" : "flame.fill")
                    .foregroundColor(extensionItem.type == .chrome ? .blue : .orange)
                    .frame(width: 24, height: 24)
                
                // Extension name
                Text(extensionItem.name)
                    .font(.system(size: 14, weight: .medium))
                
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
                .accessibilityIdentifier("tabTitle")
            
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 8)
            .accessibilityIdentifier("closeTabButton")
        }
        .frame(width: 180, height: 36)
        .background(isSelected ? Color.secondary.opacity(0.2) : Color.background)
        #if os(iOS)
        .cornerRadius(8, corners: [.topLeft, .topRight])
        #else
        .cornerRadius(8)
        #endif
        .onTapGesture {
            onSelect()
        }
        .accessibilityIdentifier("tab-content-\(tab.id)")
    }
}

#if os(macOS)
// WebView Container for macOS
private struct BrowserWebViewContainer: View {
    let tab: BrowserEngine.Tab?
    let onUpdate: (BrowserEngine.Tab?, String, URL, Bool) -> Void
    
    @State private var statusUrl: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        WebViewContainer(
            tab: tab,
            statusUrl: $statusUrl,
            isLoading: $isLoading
        )
        .onAppear {
            if let tab = tab, let url = tab.url {
                onUpdate(tab, tab.title, url, tab.isLoading)
            }
        }
        .onChange(of: statusUrl) { newValue in
            if let tab = tab, let url = tab.url {
                onUpdate(tab, tab.title, url, isLoading)
            }
        }
        .onChange(of: isLoading) { newValue in
            if let tab = tab, let url = tab.url {
                onUpdate(tab, tab.title, url, newValue)
            }
        }
    }
}
#else
// WebView Container for iOS
private struct BrowserWebViewContainer: View {
    let tab: BrowserEngine.Tab?
    let onUpdate: (BrowserEngine.Tab?, String, URL, Bool) -> Void
    
    @State private var statusUrl: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        WebViewContainer(
            tab: tab,
            statusUrl: $statusUrl,
            isLoading: $isLoading
        )
        .onAppear {
            if let tab = tab, let url = tab.url {
                onUpdate(tab, tab.title, url, tab.isLoading)
            }
        }
        .onChange(of: statusUrl) { newValue in
            if let tab = tab, let url = tab.url {
                onUpdate(tab, tab.title, url, isLoading)
            }
        }
        .onChange(of: isLoading) { newValue in
            if let tab = tab, let url = tab.url {
                onUpdate(tab, tab.title, url, newValue)
            }
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
            // Settings list
            List {
                // General settings
                Section(header: Text("General")) {
                    Text("Homepage")
                        .accessibilityIdentifier("homepageSetting")
                    Text("Search Engine")
                        .accessibilityIdentifier("searchEngineSetting")
                    Text("Default Browser")
                        .accessibilityIdentifier("defaultBrowserSetting")
                }
                
                // Privacy settings
                Section(header: Text("Privacy")) {
                    Toggle("Block Ads and Trackers", isOn: $contentBlockingEnabled)
                        .onChange(of: contentBlockingEnabled) { newValue in
                            BrowserEngine.shared.contentBlockingEnabled = newValue
                        }
                        .accessibilityIdentifier("contentBlockingToggle")
                    
                    NavigationLink(destination: ContentBlockingSettingsView()) {
                        Text("Content Blocking Settings")
                    }
                    .accessibilityIdentifier("contentBlockingSettingsLink")
                    
                    Text("Block Cookies")
                        .accessibilityIdentifier("blockCookiesSetting")
                    Text("Do Not Track")
                        .accessibilityIdentifier("doNotTrackSetting")
                    Text("Clear Browsing Data")
                        .accessibilityIdentifier("clearBrowsingDataSetting")
                }
                
                // About section
                Section(header: Text("About")) {
                    Text("Version 1.0.0")
                        .accessibilityIdentifier("versionInfo")
                }
            }
            #if os(iOS)
            .listStyle(InsetGroupedListStyle())
            #else
            .listStyle(DefaultListStyle())
            #endif
            .navigationTitle("Settings")
            .accessibilityIdentifier("settingsScreen")
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
                        .accessibilityIdentifier("noBlockListsMessage")
                } else {
                    ForEach(blockLists) { blockList in
                        BlockListRow(blockList: blockList) {
                            // Reload block lists after toggle
                            loadBlockLists()
                        }
                        .accessibilityIdentifier("blockList-\(blockList.id)")
                    }
                }
            }
            
            Section {
                Button(action: {
                    showAddListSheet = true
                }) {
                    Label("Add Custom Block List", systemImage: "plus")
                }
                .accessibilityIdentifier("addBlockListButton")
                
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
                .accessibilityIdentifier("updateBlockListsButton")
                
                Button(action: resetToDefaults) {
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                        .foregroundColor(.red)
                }
                .accessibilityIdentifier("resetToDefaultsButton")
            }
            
            if let lastUpdated = lastUpdated {
                Section(footer: Text("Last updated: \(lastUpdated, formatter: dateFormatter)")) {
                    EmptyView()
                }
            }
        }
        .onAppear(perform: loadBlockLists)
        .navigationTitle("Content Blocking")
        .accessibilityIdentifier("contentBlockingScreen")
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
                    .accessibilityIdentifier("blockListName")
                
                Text(categoryText)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(categoryColor.opacity(0.2))
                    .cornerRadius(4)
                    .accessibilityIdentifier("blockListCategory")
                
                if let lastUpdated = blockList.lastUpdated {
                    Text("Rules: \(blockList.ruleCount) • Updated: \(lastUpdated, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .accessibilityIdentifier("blockListDetails")
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .onChange(of: isEnabled) { newValue in
                    ContentBlocker.shared.setBlockListEnabled(blockList, enabled: newValue)
                    onToggle()
                }
                .accessibilityIdentifier("blockListToggle")
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
                        .accessibilityIdentifier("blockListNameField")
                    
                    TextField("URL", text: $url)
                        #if os(iOS)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        #endif
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                        .accessibilityIdentifier("blockListURLField")
                    
                    Picker("Category", selection: $category) {
                        Text("Ads").tag(ContentBlocker.BlockListCategory.ads)
                        Text("Trackers").tag(ContentBlocker.BlockListCategory.trackers)
                        Text("Both").tag(ContentBlocker.BlockListCategory.both)
                    }
                    .accessibilityIdentifier("blockListCategoryPicker")
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .accessibilityIdentifier("blockListErrorMessage")
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
                    .accessibilityIdentifier("addBlockListConfirmButton")
                }
            }
            .navigationTitle("Add Block List")
            .accessibilityIdentifier("addBlockListScreen")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onDismiss(false)
                    }
                    .accessibilityIdentifier("cancelAddBlockListButton")
                }
                #else
                ToolbarItem {
                    Button("Cancel") {
                        onDismiss(false)
                    }
                    .accessibilityIdentifier("cancelAddBlockListButton")
                }
                #endif
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
    @State private var showExtensionInstaller: Bool = false
    @State private var selectedExtensionType: ExtensionType = .chrome
    @State private var installURL: String = ""
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Installed Extensions")) {
                    if extensions.isEmpty {
                        Text("No extensions installed")
                            .foregroundColor(.gray)
                            .padding()
                            .accessibilityIdentifier("noExtensionsMessage")
                    } else {
                        ForEach(extensions) { extensionItem in
                            ExtensionListItem(extensionItem: extensionItem) {
                                // Reload extensions after a change
                                loadExtensions()
                            }
                            .contextMenu {
                                Button(role: .destructive, action: {
                                    ExtensionManager.shared.removeExtension(extensionItem.id)
                                    loadExtensions()
                                }) {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        showExtensionInstaller = true
                    }) {
                        Label("Install From URL", systemImage: "link")
                    }
                    .accessibilityIdentifier("installFromURLButton")
                }
            }
            #if os(iOS)
            .listStyle(InsetGroupedListStyle())
            #else
            .listStyle(DefaultListStyle())
            #endif
            .navigationTitle("Extensions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showExtensionInstaller = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("addExtensionButton")
                }
            }
            .sheet(isPresented: $showExtensionInstaller) {
                NavigationView {
                    InstallExtensionView(selectedType: $selectedExtensionType, url: $installURL) {
                        installExtension()
                    }
                    .navigationTitle("Install Extension")
                    .toolbar {
                        #if os(iOS)
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Cancel") {
                                showExtensionInstaller = false
                            }
                        }
                        #else
                        ToolbarItem {
                            Button("Cancel") {
                                showExtensionInstaller = false
                            }
                        }
                        #endif
                    }
                }
                #if os(iOS)
                .navigationViewStyle(StackNavigationViewStyle())
                #endif
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
                showExtensionInstaller = false
                loadExtensions()
            case .failure:
                // Extension installation failed
                // In a real app, show an error message
                showExtensionInstaller = false
            }
        }
    }
}

private struct ExtensionListItem: View {
    let extensionItem: ExtensionManager.Extension
    let onUpdate: () -> Void
    @State private var isEnabled: Bool
    
    init(extensionItem: ExtensionManager.Extension, onUpdate: @escaping () -> Void) {
        self.extensionItem = extensionItem
        self.onUpdate = onUpdate
        self._isEnabled = State(initialValue: extensionItem.enabled)
    }
    
    var body: some View {
        HStack {
            // Extension icon
            Image(systemName: extensionItem.type == .chrome ? "globe" : "flame.fill")
                .foregroundColor(extensionItem.type == .chrome ? .blue : .orange)
                .frame(width: 24, height: 24)
                .accessibilityIdentifier("extensionIcon")
            
            // Extension details
            VStack(alignment: .leading, spacing: 2) {
                Text(extensionItem.name)
                    .font(.headline)
                    .accessibilityIdentifier("extensionName")
                
                Text(extensionItem.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .accessibilityIdentifier("extensionDescription")
                
                HStack {
                    Text("Version: \(extensionItem.version)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .accessibilityIdentifier("extensionVersion")
                    
                    Text(extensionItem.type == .chrome ? "Chrome" : "Firefox")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(extensionItem.type == .chrome ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                        .cornerRadius(4)
                        .accessibilityIdentifier("extensionType")
                }
            }
            
            Spacer()
            
            // Enable/disable toggle
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .onChange(of: isEnabled) { newValue in
                    ExtensionManager.shared.setExtensionEnabled(extensionItem.id, enabled: newValue)
                    onUpdate()
                }
                .accessibilityIdentifier("extensionToggle")
        }
        .padding(.vertical, 4)
    }
}

private struct InstallExtensionView: View {
    @Binding var selectedType: ExtensionType
    @Binding var url: String
    let onInstall: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Extension Type")) {
                    Picker("Type", selection: $selectedType) {
                        Text("Chrome Extension").tag(ExtensionType.chrome)
                        Text("Firefox Add-on").tag(ExtensionType.firefox)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("URL")) {
                    TextField("Extension URL", text: $url)
                        #if os(iOS)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        #endif
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                        .accessibilityIdentifier("extensionURLField")
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
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                #else
                ToolbarItem {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                #endif
            }
        }
    }
}

// Web Store Extensions View
private struct BrowserWebStoreView: View {
    enum StoreType {
        case chrome
        case firefox
        
        var title: String {
            switch self {
            case .chrome: return "Chrome Web Store"
            case .firefox: return "Firefox Add-ons"
            }
        }
        
        var searchPlaceholder: String {
            switch self {
            case .chrome: return "Search Chrome extensions"
            case .firefox: return "Search Firefox add-ons"
            }
        }
        
        var baseURL: String {
            switch self {
            case .chrome: return "https://chrome.google.com/webstore/category/extensions"
            case .firefox: return "https://addons.mozilla.org/en-US/firefox/extensions/"
            }
        }
        
        var exampleID: String {
            switch self {
            case .chrome: return "cjpalhdlnbpafiamejdnhcphjbkeiagm"
            case .firefox: return "ublock-origin"
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
        let type: ExtensionType
        
        var isInstalling = false
    }
    
    var body: some View {
        VStack {
            // Store selector
            storePickerView
            
            // Search bar
            searchBarView
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            // Results list
            resultsView
        }
        .navigationTitle("Browse Extensions")
        .onAppear {
            loadFeaturedExtensions()
        }
    }
    
    private var storePickerView: some View {
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
    }
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(selectedStore.searchPlaceholder, text: $searchText)
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
    }
    
    private var resultsView: some View {
        Group {
            if isSearching {
                ProgressView("Searching...")
                    .padding()
            } else if !searchResults.isEmpty {
                searchResultsListView
            } else {
                featuredExtensionsView
            }
        }
    }
    
    private var searchResultsListView: some View {
        ScrollView {
            searchResultsContent
        }
    }
    
    private var searchResultsContent: some View {
        LazyVStack {
            ForEach(searchResults.indices, id: \.self) { index in
                extensionResultItem(for: searchResults[index], at: index)
            }
        }
    }
    
    private var featuredExtensionsView: some View {
        ScrollView {
            featuredContent
        }
    }
    
    private var featuredContent: some View {
        VStack(alignment: .leading) {
            Text("Featured \(selectedStore.title) Extensions")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            if featuredExtensions.isEmpty {
                ProgressView("Loading featured extensions...")
                    .padding()
            } else {
                featuredExtensionsList
            }
            
            Text("Example: Search for an extension by ID: \(selectedStore.exampleID)")
                .font(.caption)
                .foregroundColor(.gray)
                .padding()
        }
    }
    
    private var featuredExtensionsList: some View {
        LazyVStack {
            ForEach(featuredExtensions.indices, id: \.self) { index in
                extensionResultItem(for: featuredExtensions[index], at: index)
            }
        }
    }
    
    private func extensionResultItem(for result: ExtensionResult, at index: Int) -> some View {
        ExtensionResultItem(
            result: result,
            onInstall: { installExtension(result) }
        )
        .padding(.horizontal)
        #if os(macOS)
        .background(index % 2 == 0 ? Color.white : Color.gray.opacity(0.1))
        #else
        .background(index % 2 == 0 ? Color.white : Color.gray.opacity(0.1))
        #endif
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
    let result: BrowserWebStoreView.ExtensionResult
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

#if os(iOS)
// Extension for rounded corners on specific corners
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
#endif

// MARK: - Color Extensions
extension Color {
    static var background: Color {
        #if os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color(UIColor.systemBackground)
        #endif
    }
} 