import Foundation
import SwiftUI
import WebKit
import NorioCore
import NorioExtensions

// This file ensures that all modules are properly imported and linked
// It's a workaround for the module linking issue in the iOS app target

// Reference ExtensionType from NorioCore to ensure it's linked
public func getDefaultExtensionType() -> ExtensionType {
    return .chrome
}

// Reference Extension from NorioExtensions to ensure it's linked
public func createDummyExtension() -> ExtensionManager.Extension? {
    return nil
} 