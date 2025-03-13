import Foundation

// MARK: - Module Linker for NorioCore
// This file ensures that all types in NorioCore module are properly linked
// It helps to resolve linking issues in iOS app target

/// Reference to ensure ExtensionType is linked in iOS builds
public func ensureExtensionTypeLinked() -> ExtensionType {
    return .chrome
}

/// Reference to ensure Logger is linked
public func ensureLoggerLinked() -> Logger {
    return Logger.shared
}

/// Reference to ensure NotificationManager is linked
public func ensureNotificationManagerLinked() -> NotificationManager {
    return NotificationManager.shared
}
