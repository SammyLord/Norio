import Foundation
import UserNotifications

// ExtensionType is defined in ExtensionTypes.swift (part of the same module)
// Explicitly importing it to ensure it's accessible
import NorioCore

// No need to import or create a typealias since both are in the same module

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
                print("Error requesting notification authorization: \(error.localizedDescription)")
                return
            }
            
            print("Notification authorization \(granted ? "granted" : "denied")")
        }
    }
    
    // Show a standard notification
    public func showNotification(title: String, message: String, identifier: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: identifier ?? UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error.localizedDescription)")
            }
        }
    }
    
    // Show extension-related notifications
    public func showExtensionInstalled(name: String, type: ExtensionType) {
        let typeStr = type == .chrome ? "Chrome" : "Firefox"
        let message = "The \(name) extension has been installed for \(typeStr)."
        showNotification(title: "Extension Installed", message: message, identifier: "extension-installed-\(type.rawValue)-\(name)")
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
