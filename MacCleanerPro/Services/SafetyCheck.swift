import Foundation

final class SafetyCheck {
    static let shared = SafetyCheck()
    
    private init() {}
    
    private let protectedSystemPaths: [String] = [
        "/System",
        "/Library",
        "/usr",
        "/bin",
        "/sbin",
        "/Applications",
        "/private"
    ]
    
    private let protectedUserPaths: [String] = [
        ".ssh",
        ".gnupg",
        ".aws",
        ".kube",
        ".docker",
        "Keychains",
        "Passwords"
    ]
    
    private let protectedExtensions: [String] = [
        ".keychain",
        ".p12",
        ".pem",
        ".crt",
        ".key",
        ".plist"
    ]
    
    private let minimumFileAgeHours: Int = 24
    
    func isSafeToDelete(path: String) -> Bool {
        let normalizedPath = normalizePath(path)
        
        guard !isProtectedSystemPath(normalizedPath) else {
            Logger.shared.log("Blocked: Protected system path: \(normalizedPath)", level: .warning)
            return false
        }
        
        guard !isProtectedUserPath(normalizedPath) else {
            Logger.shared.log("Blocked: Protected user path: \(normalizedPath)", level: .warning)
            return false
        }
        
        guard !hasProtectedExtension(normalizedPath) else {
            Logger.shared.log("Blocked: Protected extension: \(normalizedPath)", level: .warning)
            return false
        }
        
        guard isInAllowedCacheDirectory(normalizedPath) else {
            Logger.shared.log("Blocked: Not in allowed cache directory: \(normalizedPath)", level: .warning)
            return false
        }
        
        if let fileSize = getFileSize(path: normalizedPath), fileSize > 1024 * 1024 {
            guard isFileOldEnough(path: normalizedPath) else {
                Logger.shared.log("Warning: File too new (< 24h): \(normalizedPath)", level: .info)
            }
        }
        
        Logger.shared.log("Allowed: \(normalizedPath)", level: .debug)
        return true
    }
    
    func isSafeToScan(path: String) -> Bool {
        let normalizedPath = normalizePath(path)
        return !isProtectedSystemPath(normalizedPath)
    }
    
    func getBlockReason(path: String) -> String? {
        let normalizedPath = normalizePath(path)
        
        if isProtectedSystemPath(normalizedPath) {
            return "System path - removal may damage macOS"
        }
        
        if isProtectedUserPath(normalizedPath) {
            return "Protected user directory (keys, settings)"
        }
        
        if hasProtectedExtension(normalizedPath) {
            return "File with critical extension (certificates, settings)"
        }
        
        if !isInAllowedCacheDirectory(normalizedPath) {
            return "Path not in allowed cache directories"
        }
        
        return nil
    }
    
    private func normalizePath(_ path: String) -> String {
        return NSString(string: path).standardizingPath
    }
    
    private func isProtectedSystemPath(_ path: String) -> Bool {
        return protectedSystemPaths.contains { protectedPath in
            path.hasPrefix(protectedPath + "/") || path == protectedPath
        }
    }
    
    private func isProtectedUserPath(_ path: String) -> Bool {
        let pathComponents = path.components(separatedBy: "/")
        for protectedComponent in protectedUserPaths {
            if pathComponents.contains(protectedComponent) {
                return true
            }
        }
        return false
    }
    
    private func hasProtectedExtension(_ path: String) -> Bool {
        let fileExtension = (path as NSString).pathExtension.lowercased()
        return protectedExtensions.contains { "." + fileExtension == $0 }
    }
    
    private func isInAllowedCacheDirectory(_ path: String) -> Bool {
        let allowedDirectories = [
            "/Library/Caches",
            "/Library/Logs",
            "Library/Caches",
            "Library/Logs",
            "Caches",
            "Logs"
        ]
        
        return allowedDirectories.contains { allowedDir in
            path.contains(allowedDir)
        }
    }
    
    private func getFileSize(path: String) -> Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path) else {
            return nil
        }
        return attributes[.size] as? Int64
    }
    
    private func isFileOldEnough(path: String) -> Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path),
              let modificationDate = attributes[.modificationDate] as? Date else {
            return true
        }
        
        let minimumAge = TimeInterval(minimumFileAgeHours * 60 * 60)
        return Date().timeIntervalSince(modificationDate) >= minimumAge
    }
    
    static var allowedScanPaths: [String] {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        
        return [
            "\(homeDir)/Library/Caches",
            "\(homeDir)/Library/Logs",
            "/Library/Caches",
            "/Library/Logs"
        ]
    }
}
