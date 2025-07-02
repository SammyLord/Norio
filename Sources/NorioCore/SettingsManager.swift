import Foundation

public class SettingsManager: ObservableObject {
    public static let shared = SettingsManager()
    
    @Published public var settings: BrowserEngine.Settings {
        didSet {
            saveSettings()
        }
    }
    
    private let settingsKey = "norio_settings"
    
    private init() {
        self.settings = Self.loadSettings()
    }
    
    private static func loadSettings() -> BrowserEngine.Settings {
        if let data = UserDefaults.standard.data(forKey: "norio_settings"),
           let decodedSettings = try? JSONDecoder().decode(BrowserEngine.Settings.self, from: data) {
            return decodedSettings
        }
        return BrowserEngine.Settings()
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
} 