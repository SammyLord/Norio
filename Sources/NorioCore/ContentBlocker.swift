import Foundation
import WebKit

public class ContentBlocker {
    // Singleton instance
    public static let shared = ContentBlocker()
    
    // Default block lists
    private let defaultBlockLists: [BlockList] = [
        BlockList(name: "EasyList", url: URL(string: "https://easylist.to/easylist/easylist.txt")!, isEnabled: true, category: .ads),
        BlockList(name: "EasyPrivacy", url: URL(string: "https://easylist.to/easylist/easyprivacy.txt")!, isEnabled: true, category: .trackers),
        BlockList(name: "AdGuard Base", url: URL(string: "https://filters.adtidy.org/extension/ublock/filters/2_without_easylist.txt")!, isEnabled: true, category: .ads),
        BlockList(name: "uBlock Origin Filters", url: URL(string: "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt")!, isEnabled: true, category: .both)
    ]
    
    // Track lists that are currently enabled and loaded
    private var enabledBlockLists: [BlockList] = []
    
    // Content rule lists for WebKit
    private var contentRuleLists: [WKContentRuleList] = []
    
    // Statistics
    private(set) var totalBlockedCount: Int = 0
    public private(set) var lastUpdateDate: Date?
    
    // Settings
    public var isEnabled: Bool = true {
        didSet {
            if isEnabled != oldValue {
                updateContentBlocker()
            }
        }
    }
    
    private init() {
        loadSavedBlockLists()
    }
    
    // Block list model
    public struct BlockList: Identifiable, Codable, Equatable {
        public let id: UUID
        public let name: String
        public let url: URL
        public var isEnabled: Bool
        public let category: BlockListCategory
        public var lastUpdated: Date?
        public var ruleCount: Int = 0
        
        public init(id: UUID = UUID(), name: String, url: URL, isEnabled: Bool, category: BlockListCategory, lastUpdated: Date? = nil) {
            self.id = id
            self.name = name
            self.url = url
            self.isEnabled = isEnabled
            self.category = category
            self.lastUpdated = lastUpdated
        }
        
        public static func == (lhs: BlockList, rhs: BlockList) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    // Block list categories
    public enum BlockListCategory: String, Codable {
        case ads
        case trackers
        case both
    }
    
    // MARK: - Public Methods
    
    /// Apply content blocker rules to a WebView
    public func applyRulesToWebView(_ webView: WKWebView) {
        if !isEnabled || contentRuleLists.isEmpty {
            return
        }
        
        for ruleList in contentRuleLists {
            webView.configuration.userContentController.add(ruleList)
        }
    }
    
    /// Get all available block lists (including default ones)
    public func getAvailableBlockLists() -> [BlockList] {
        return enabledBlockLists
    }
    
    /// Enable or disable a block list
    public func setBlockListEnabled(_ blockList: BlockList, enabled: Bool) {
        if let index = enabledBlockLists.firstIndex(where: { $0.id == blockList.id }) {
            enabledBlockLists[index].isEnabled = enabled
            saveBlockLists()
            updateContentBlocker()
        }
    }
    
    /// Add a custom block list
    public func addCustomBlockList(name: String, url: URL, category: BlockListCategory, completion: @escaping (Result<BlockList, Error>) -> Void) {
        let newBlockList = BlockList(name: name, url: url, isEnabled: true, category: category)
        enabledBlockLists.append(newBlockList)
        saveBlockLists()
        
        downloadAndCompileBlockList(newBlockList) { [weak self] result in
            switch result {
            case .success:
                completion(.success(newBlockList))
                self?.updateContentBlocker()
            case .failure(let error):
                // Remove the block list if download fails
                self?.enabledBlockLists.removeAll { $0.id == newBlockList.id }
                self?.saveBlockLists()
                completion(.failure(error))
            }
        }
    }
    
    /// Remove a block list
    public func removeBlockList(_ blockList: BlockList) {
        enabledBlockLists.removeAll { $0.id == blockList.id }
        saveBlockLists()
        updateContentBlocker()
    }
    
    /// Update all block lists
    public func updateAllBlockLists(completion: @escaping (Result<Int, Error>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var errorCount = 0
        
        for blockList in enabledBlockLists where blockList.isEnabled {
            dispatchGroup.enter()
            
            downloadAndCompileBlockList(blockList) { result in
                switch result {
                case .success:
                    break
                case .failure:
                    errorCount += 1
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            self.updateContentBlocker()
            self.lastUpdateDate = Date()
            
            if errorCount > 0 {
                completion(.failure(NSError(domain: "ContentBlocker", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(errorCount) block lists failed to update"])))
            } else {
                completion(.success(self.enabledBlockLists.count))
            }
        }
    }
    
    /// Reset to default block lists
    public func resetToDefaults() {
        enabledBlockLists = defaultBlockLists
        saveBlockLists()
        updateAllBlockLists { _ in }
    }
    
    // MARK: - Private Methods
    
    /// Load saved block lists from UserDefaults or use defaults
    private func loadSavedBlockLists() {
        if let savedData = UserDefaults.standard.data(forKey: "NorioBlockLists") {
            do {
                enabledBlockLists = try JSONDecoder().decode([BlockList].self, from: savedData)
            } catch {
                enabledBlockLists = defaultBlockLists
            }
        } else {
            enabledBlockLists = defaultBlockLists
        }
        
        updateContentBlocker()
    }
    
    /// Save current block lists to UserDefaults
    private func saveBlockLists() {
        do {
            let data = try JSONEncoder().encode(enabledBlockLists)
            UserDefaults.standard.set(data, forKey: "NorioBlockLists")
        } catch {
            print("Error saving block lists: \(error)")
        }
    }
    
    /// Update the content blocker with currently enabled lists
    private func updateContentBlocker() {
        if !isEnabled {
            contentRuleLists = []
            return
        }
        
        // Compile all enabled block lists
        for blockList in enabledBlockLists where blockList.isEnabled {
            compileRulesForBlockList(blockList) { _ in }
        }
    }
    
    /// Download and parse a block list
    private func downloadAndCompileBlockList(_ blockList: BlockList, completion: @escaping (Result<Void, Error>) -> Void) {
        // Download the block list
        let task = URLSession.shared.dataTask(with: blockList.url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data, let content = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "ContentBlocker", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid block list data"])))
                }
                return
            }
            
            // Parse the block list into a format compatible with WKContentRuleList
            let rules = self.parseBlockListContent(content)
            if rules.isEmpty {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "ContentBlocker", code: 3, userInfo: [NSLocalizedDescriptionKey: "No valid rules found in block list"])))
                }
                return
            }
            
            // Update rule count and last updated date
            if let index = self.enabledBlockLists.firstIndex(where: { $0.id == blockList.id }) {
                DispatchQueue.main.async {
                    self.enabledBlockLists[index].ruleCount = rules.count
                    self.enabledBlockLists[index].lastUpdated = Date()
                    self.saveBlockLists()
                }
            }
            
            // Compile rules
            self.compileJSONRules(rules, identifier: blockList.id.uuidString) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
        
        task.resume()
    }
    
    /// Parse block list content into WebKit-compatible rules
    private func parseBlockListContent(_ content: String) -> [[String: Any]] {
        var jsonRules: [[String: Any]] = []
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            // Skip comments, empty lines, and element hiding rules
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("!") || trimmedLine.hasPrefix("##") {
                continue
            }
            
            // Handle domain-specific rules
            if trimmedLine.contains("##") || trimmedLine.contains("#@#") {
                // Element hiding rules are currently not supported in this implementation
                continue
            }
            
            // Handle basic URL blocking rules
            if let rule = convertAdblockRuleToJSON(trimmedLine) {
                jsonRules.append(rule)
            }
        }
        
        return jsonRules
    }
    
    /// Convert an AdBlock Plus rule to a WebKit JSON content rule
    private func convertAdblockRuleToJSON(_ rule: String) -> [String: Any]? {
        var ruleParts = rule.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Skip unsupported rules
        if ruleParts.hasPrefix("@@") || 
           ruleParts.contains("$popup") || 
           ruleParts.contains("$third-party") {
            return nil
        }
        
        // Remove comments
        if let commentIndex = ruleParts.firstIndex(of: "#") {
            ruleParts = String(ruleParts[..<commentIndex])
        }
        
        // Skip empty rules after removing comments
        if ruleParts.isEmpty {
            return nil
        }
        
        // Create a basic block rule
        return [
            "trigger": ["url-filter": ruleParts.replacingOccurrences(of: "*", with: ".*")],
            "action": ["type": "block"]
        ]
    }
    
    /// Compile JSON rules into a WKContentRuleList
    private func compileJSONRules(_ rules: [[String: Any]], identifier: String, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: rules, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)!
            
            WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: identifier,
                encodedContentRuleList: jsonString
            ) { [weak self] contentRuleList, error in
                guard let self = self else { return }
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let contentRuleList = contentRuleList {
                    // Replace any existing rule list with the same identifier
                    self.contentRuleLists.removeAll { $0.identifier == identifier }
                    self.contentRuleLists.append(contentRuleList)
                    completion(.success(()))
                } else {
                    completion(.failure(NSError(domain: "ContentBlocker", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to compile content rule list"])))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Compile rules for a specific block list
    private func compileRulesForBlockList(_ blockList: BlockList, completion: @escaping (Result<Void, Error>) -> Void) {
        let blockListDirectory = getBlockListDirectory()
        let blockListFilePath = blockListDirectory.appendingPathComponent("\(blockList.id.uuidString).txt")
        
        // Check if the file exists
        if FileManager.default.fileExists(atPath: blockListFilePath.path),
           let content = try? String(contentsOf: blockListFilePath, encoding: .utf8) {
            // Parse block list and compile rules
            let rules = parseBlockListContent(content)
            compileJSONRules(rules, identifier: blockList.id.uuidString, completion: completion)
        } else {
            // Download the block list if the file doesn't exist
            downloadAndCompileBlockList(blockList, completion: completion)
        }
    }
    
    /// Get the directory for storing block lists
    private func getBlockListDirectory() -> URL {
        let applicationSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let blockListDirectory = applicationSupportDirectory.appendingPathComponent("Norio").appendingPathComponent("BlockLists")
        
        // Create the directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: blockListDirectory.path) {
            try? FileManager.default.createDirectory(at: blockListDirectory, withIntermediateDirectories: true)
        }
        
        return blockListDirectory
    }
} 