import Foundation
import UserNotifications

public class NotificationManager {
    public static let shared = NotificationManager()
    
    private init() {
        // Request notification permissions on initialization
        requestPermissions()
    }
    
    // Request permissions to show notifications
    private func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                Logger.shared.error("Failed to request notification permissions: \(error.localizedDescription)")
            }
            
            if granted {
                Logger.shared.info("Notification permissions granted")
            } else {
                Logger.shared.warning("Notification permissions denied")
            }
        }
    }
    
    // Show a standard notification
    public func showNotification(title: String, message: String, identifier: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: identifier ?? UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.shared.error("Failed to show notification: \(error.localizedDescription)")
            }
        }
    }
    
    // Show extension-related notifications
    public func showExtensionInstalled(name: String, type: ExtensionType) {
        let extensionType = type == .chrome ? "Chrome extension" : "Firefox add-on"
        showNotification(
            title: "Extension Installed",
            message: "\(name) \(extensionType) has been successfully installed",
            identifier: "extension-installed-\(UUID().uuidString)"
        )
    }
    
    public func showExtensionRemoved(name: String) {
        showNotification(
            title: "Extension Removed",
            message: "\(name) has been removed",
            identifier: "extension-removed-\(UUID().uuidString)"
        )
    }
    
    public func showExtensionError(operation: String, error: Error) {
        showNotification(
            title: "Extension Error",
            message: "Failed to \(operation): \(error.localizedDescription)",
            identifier: "extension-error-\(UUID().uuidString)"
        )
    }
    
    public func showExtensionUpdated(name: String, fromVersion: String, toVersion: String) {
        showNotification(
            title: "Extension Updated",
            message: "\(name) has been updated from v\(fromVersion) to v\(toVersion)",
            identifier: "extension-updated-\(UUID().uuidString)"
        )
    }
    
    // Show content blocking notifications
    public func showContentBlockingStats(blocked: Int, percentage: Double) {
        showNotification(
            title: "Content Blocking",
            message: "Blocked \(blocked) items (\(Int(percentage))% of page content)",
            identifier: "content-blocking-stats-\(UUID().uuidString)"
        )
    }
    
    // Show browser-related notifications
    public func showDownloadCompleted(filename: String) {
        showNotification(
            title: "Download Complete",
            message: "\(filename) has been downloaded",
            identifier: "download-completed-\(UUID().uuidString)"
        )
    }
} 