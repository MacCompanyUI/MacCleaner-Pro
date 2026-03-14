import Foundation

struct ScanResult {
    let totalSize: Int64
    let totalFiles: Int
    let items: [ScanItem]
    let scanDate: Date
    let duration: TimeInterval
    
    var itemsByCategory: [CacheCategory: [ScanItem]] {
        Dictionary(grouping: items, by: { $0.category })
    }
    
    var sizeByCategory: [CacheCategory: Int64] {
        var result: [CacheCategory: Int64] = [:]
        for item in items {
            result[item.category, default: 0] += item.size
        }
        return result
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var chartData: [ChartData] {
        sizeByCategory.map { category, size in
            ChartData(category: category, size: size)
        }
        .sorted { $0.size > $1.size }
    }
}

struct ChartData: Identifiable {
    let id = UUID()
    let category: CacheCategory
    let size: Int64
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var percentage: Double {
        0.0
    }
}

enum ScanStatus: Equatable {
    case idle
    case scanning(progress: Double, currentPath: String)
    case completed(result: ScanResult)
    case error(message: String)
    
    var isScanning: Bool {
        if case .scanning = self { return true }
        return false
    }
    
    var result: ScanResult? {
        if case .completed(let result) = self { return result }
        return nil
    }
}
