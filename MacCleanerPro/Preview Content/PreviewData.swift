import Foundation

struct PreviewData {
    static let sampleItems: [ScanItem] = [
        ScanItem(
            path: "/Users/user/Library/Caches/com.apple.Safari/fsCachedData",
            name: "fsCachedData",
            size: 524_288_000,
            isDirectory: true,
            modificationDate: Date().addingTimeInterval(-86400 * 5),
            category: .browserCache
        ),
        ScanItem(
            path: "/Users/user/Library/Caches/com.google.Chrome/Default/Cache",
            name: "Cache",
            size: 312_524_288,
            isDirectory: true,
            modificationDate: Date().addingTimeInterval(-86400 * 2),
            category: .browserCache
        ),
        ScanItem(
            path: "/Users/user/Library/Caches/com.apple.Xcode/DerivedData",
            name: "DerivedData",
            size: 1_073_741_824,
            isDirectory: true,
            modificationDate: Date().addingTimeInterval(-86400 * 10),
            category: .developerCache
        ),
        ScanItem(
            path: "/Users/user/Library/Logs/Homebrew",
            name: "Homebrew",
            size: 52_428_800,
            isDirectory: true,
            modificationDate: Date().addingTimeInterval(-86400),
            category: .userLogs
        ),
        ScanItem(
            path: "/Users/user/Library/Caches/Logs/system.log",
            name: "system.log",
            size: 10_485_760,
            isDirectory: false,
            modificationDate: Date().addingTimeInterval(-3600),
            category: .systemLogs
        ),
        ScanItem(
            path: "/Users/user/Library/Caches/com.spotify.client/Storage",
            name: "Storage",
            size: 209_715_200,
            isDirectory: true,
            modificationDate: Date().addingTimeInterval(-86400 * 3),
            category: .applicationCache
        ),
        ScanItem(
            path: "/Users/user/Library/Caches/fontconfig",
            name: "fontconfig",
            size: 15_728_640,
            isDirectory: true,
            modificationDate: Date().addingTimeInterval(-86400 * 30),
            category: .fontCache
        ),
        ScanItem(
            path: "/Users/user/Library/Caches/TemporaryItems",
            name: "TemporaryItems",
            size: 104_857_600,
            isDirectory: true,
            modificationDate: Date().addingTimeInterval(-86400),
            category: .other
        )
    ]
    
    static let sampleResult: ScanResult = {
        let items = sampleItems
        let totalSize = items.reduce(0) { $0 + $1.size }
        return ScanResult(
            totalSize: totalSize,
            totalFiles: items.count,
            items: items,
            scanDate: Date(),
            duration: 2.5
        )
    }()
}
