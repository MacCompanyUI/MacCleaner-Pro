import Foundation

struct ScanItem: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let name: String
    let size: Int64
    let isDirectory: Bool
    let modificationDate: Date?
    let category: CacheCategory
    
    var isSafeToDelete: Bool {
        SafetyCheck.shared.isSafeToDelete(path: path)
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var systemImage: String {
        category.systemImage
    }
}

extension ScanItem {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ScanItem, rhs: ScanItem) -> Bool {
        lhs.id == rhs.id
    }
}
