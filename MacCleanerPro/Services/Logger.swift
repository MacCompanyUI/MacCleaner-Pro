import Foundation
import os.log

final class Logger {
    static let shared = Logger()
    
    private let fileManager = FileManager.default
    private let logFileURL: URL
    private let queue = DispatchQueue(label: "com.maccleanerpro.logger", qos: .utility)
    private let maxLogSizeBytes: Int64 = 10 * 1024 * 1024
    private let maxLogLines = 1000
    
    private let osLog: OSLog
    
    enum Level: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }
    
    private init() {
        let logsDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Logs", isDirectory: true)
            .appendingPathComponent("MacCleanerPro", isDirectory: true)
        
        try? fileManager.createDirectory(at: logsDir, withIntermediateDirectories: true)
        
        self.logFileURL = logsDir.appendingPathComponent("maccleaner.log")
        self.osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.maccleanerpro", category: "App")
        
        rotateLogIfNeeded()
    }
    
    func log(_ message: String, level: Level = .info, file: String = #file, function: String = #function) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(timestamp)] [\(level.rawValue)] [\(fileName):\(function)] \(message)"
        
        os_log("%{public}@", log: osLog, type: osLogType(for: level), logMessage)
        
        queue.async { [weak self] in
            self?.appendToLogFile(logMessage)
        }
    }
    
    var logFilePath: String {
        logFileURL.path
    }
    
    func readLastLines(count: Int = 100, completion: @escaping (String?) -> Void) {
        queue.async { [weak self] in
            guard let self = self else {
                completion(nil)
                return
            }
            
            do {
                let content = try String(contentsOf: self.logFileURL, encoding: .utf8)
                let lines = content.components(separatedBy: .newlines)
                let lastLines = lines.suffix(count)
                completion(lastLines.joined(separator: "\n"))
            } catch {
                completion(nil)
            }
        }
    }
    
    func clear() {
        queue.async { [weak self] in
            try? "".write(to: self!.logFileURL, atomically: true, encoding: .utf8)
        }
    }
    
    private func osLogType(for level: Level) -> OSLogType {
        switch level {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }
    
    private func appendToLogFile(_ message: String) {
        do {
            if let fileSize = getFileSize(), fileSize > maxLogSizeBytes {
                rotateLog()
            }
            
            if !fileManager.fileExists(atPath: logFileURL.path) {
                try "".write(to: logFileURL, atomically: true, encoding: .utf8)
            }
            
            let fileHandle = try FileHandle(forWritingTo: logFileURL)
            fileHandle.seekToEndOfFile()
            if let data = (message + "\n").data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
            
            trimLogFile()
        } catch {
            os_log("Failed to write to log file: %{public}@", log: osLog, type: .error, error.localizedDescription)
        }
    }
    
    private func getFileSize() -> Int64? {
        guard let attributes = try? fileManager.attributesOfItem(atPath: logFileURL.path) else {
            return nil
        }
        return attributes[.size] as? Int64
    }
    
    private func rotateLogIfNeeded() {
        guard let fileSize = getFileSize() else { return }
        if fileSize > maxLogSizeBytes {
            rotateLog()
        }
    }
    
    private func rotateLog() {
        let rotatedURL = logFileURL.deletingLastPathComponent()
            .appendingPathComponent("maccleaner.old.log")
        
        try? fileManager.removeItem(at: rotatedURL)
        try? fileManager.moveItem(at: logFileURL, to: rotatedURL)
    }
    
    private func trimLogFile() {
        guard let content = try? String(contentsOf: logFileURL, encoding: .utf8) else {
            return
        }
        
        let lines = content.components(separatedBy: .newlines)
        if lines.count > maxLogLines {
            let trimmedLines = lines.suffix(maxLogLines)
            try? trimmedLines.joined(separator: "\n").write(to: logFileURL, atomically: true, encoding: .utf8)
        }
    }
}
