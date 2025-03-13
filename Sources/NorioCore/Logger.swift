import Foundation
import os.log

public class Logger {
    public static let shared = Logger()
    
    private let osLog: OSLog
    private let isDebugMode: Bool
    
    private init() {
        osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.norio.browser", category: "Norio")
        
        #if DEBUG
        isDebugMode = true
        #else
        isDebugMode = false
        #endif
    }
    
    public func log(_ message: String, level: OSLogType = .default, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        
        os_log("%{public}@", log: osLog, type: level, logMessage)
        
        if isDebugMode {
            print("[\(level)] \(logMessage)")
        }
    }
    
    public func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    public func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    public func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .default, file: file, function: function, line: line)
    }
    
    public func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    public func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .fault, file: file, function: function, line: line)
    }
} 