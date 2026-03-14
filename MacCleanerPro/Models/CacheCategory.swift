import Foundation

enum CacheCategory: String, CaseIterable, Identifiable {
    case applicationCache = "Application Cache"
    case systemLogs = "System Logs"
    case userLogs = "User Logs"
    case browserCache = "Browser Cache"
    case developerCache = "Developer Cache"
    case fontCache = "Font Cache"
    case other = "Other"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .applicationCache: return "folder.fill"
        case .systemLogs: return "doc.text.fill"
        case .userLogs: return "text.alignleft"
        case .browserCache: return "globe"
        case .developerCache: return "hammer.fill"
        case .fontCache: return "textformat"
        case .other: return "folder"
        }
    }
    
    var color: String {
        switch self {
        case .applicationCache: return "blue"
        case .systemLogs: return "orange"
        case .userLogs: return "yellow"
        case .browserCache: return "green"
        case .developerCache: return "purple"
        case .fontCache: return "pink"
        case .other: return "gray"
        }
    }
    
    var description: String {
        switch self {
        case .applicationCache:
            return "Application cache files (safe to remove)"
        case .systemLogs:
            return "System log files (old files only)"
        case .userLogs:
            return "User application log files"
        case .browserCache:
            return "Browser cache (may slow page loading)"
        case .developerCache:
            return "Xcode and developer tools cache"
        case .fontCache:
            return "Font cache (auto-regenerated)"
        case .other:
            return "Other files"
        }
    }
}
