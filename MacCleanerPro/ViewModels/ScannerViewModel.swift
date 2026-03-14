import Foundation
import AppKit

@MainActor
final class ScannerViewModel: ObservableObject {
    @Published private(set) var scanStatus: ScanStatus = .idle
    @Published private(set) var selectedItems: Set<ScanItem> = []
    @Published private(set) var isCleaning = false
    @Published private(set) var lastCleanResult: TrashManager.TrashResult?
    @Published private(set) var requiresFullDiskAccess = false
    @Published private(set) var hasFullDiskAccess = false
    
    var currentResult: ScanResult? {
        scanStatus.result
    }
    
    var totalSelectedSize: Int64 {
        selectedItems.reduce(0) { $0 + $1.size }
    }
    
    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSelectedSize, countStyle: .file)
    }
    
    var canClean: Bool {
        !selectedItems.isEmpty && !isCleaning
    }
    
    var isScanning: Bool {
        scanStatus.isScanning
    }
    
    private let fileManager = FileManager.default
    private var allScanItems: [ScanItem] = []
    private var scanTask: Task<Void, Never>?
    
    init() {
        checkFullDiskAccess()
    }
    
    func startScan() {
        Logger.shared.log("Starting scan...", level: .info)
        
        scanTask?.cancel()
        
        scanTask = Task {
            await performScan()
        }
    }
    
    func cancelScan() {
        scanTask?.cancel()
        Logger.shared.log("Scan cancelled", level: .info)
    }
    
    func toggleSelection(_ item: ScanItem) {
        if selectedItems.contains(item) {
            selectedItems.remove(item)
        } else {
            selectedItems.insert(item)
        }
    }
    
    func selectAllSafe() {
        selectedItems = Set(allScanItems.filter { $0.isSafeToDelete })
    }
    
    func deselectAll() {
        selectedItems.removeAll()
    }
    
    func cleanSelected() async {
        guard canClean else { return }
        
        isCleaning = true
        Logger.shared.log("Starting cleanup of \(selectedItems.count) items", level: .info)
        
        let paths = selectedItems.map { $0.path }
        
        do {
            let result = await TrashManager.shared.moveToTrash(paths: paths, requireConfirmation: true)
            lastCleanResult = result
            
            if result.success {
                if var currentResult = currentResult {
                    let remainingItems = currentResult.items.filter { !paths.contains($0.path) }
                    let newTotalSize = remainingItems.reduce(0) { $0 + $1.size }
                    
                    let updatedResult = ScanResult(
                        totalSize: newTotalSize,
                        totalFiles: remainingItems.count,
                        items: remainingItems,
                        scanDate: currentResult.scanDate,
                        duration: currentResult.duration
                    )
                    
                    scanStatus = .completed(result: updatedResult)
                    allScanItems = remainingItems
                }
                
                selectedItems.removeAll()
                
                Logger.shared.log("Cleanup completed: freed \(result.formattedSizeFreed)", level: .info)
            }
        } catch {
            Logger.shared.log("Cleanup error: \(error.localizedDescription)", level: .error)
        }
        
        isCleaning = false
    }
    
    func checkFullDiskAccess() {
        let testPath = "/Library/Application Support"
        let canAccess = fileManager.isReadableFile(atPath: testPath)
        
        hasFullDiskAccess = canAccess
        requiresFullDiskAccess = !canAccess
        
        Logger.shared.log("Full Disk Access: \(canAccess ? "granted" : "denied")", level: .info)
    }
    
    func requestFullDiskAccess() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
        
        Logger.shared.log("Requested Full Disk Access", level: .info)
    }
    
    private func performScan() async {
        await MainActor.run {
            scanStatus = .scanning(progress: 0, currentPath: "Initializing...")
        }
        
        let startTime = Date()
        var items: [ScanItem] = []
        var totalSize: Int64 = 0
        
        let pathsToScan = SafetyCheck.allowedScanPaths
        
        for (index, basePath) in pathsToScan.enumerated() {
            guard !Task.isCancelled else {
                Logger.shared.log("Scan cancelled at path: \(basePath)", level: .info)
                break
            }
            
            let progress = Double(index) / Double(pathsToScan.count)
            
            await MainActor.run {
                scanStatus = .scanning(progress: progress, currentPath: basePath)
            }
            
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: basePath, isDirectory: &isDirectory) else {
                Logger.shared.log("Path does not exist: \(basePath)", level: .debug)
                continue
            }
            
            let scannedItems = scanDirectory(atPath: basePath, baseCategory: categoryForPath(basePath))
            items.append(contentsOf: scannedItems)
            totalSize += scannedItems.reduce(0) { $0 + $1.size }
            
            Logger.shared.log("Scanned \(basePath): \(scannedItems.count) items", level: .debug)
        }
        
        items.sort { $0.size > $1.size }
        allScanItems = items
        
        let duration = Date().timeIntervalSince(startTime)
        
        await MainActor.run {
            let result = ScanResult(
                totalSize: totalSize,
                totalFiles: items.count,
                items: items,
                scanDate: Date(),
                duration: duration
            )
            scanStatus = .completed(result: result)
            Logger.shared.log("Scan completed: \(items.count) items, \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))", level: .info)
        }
    }
    
    private func scanDirectory(atPath path: String, baseCategory: CacheCategory) -> [ScanItem] {
        var items: [ScanItem] = []
        
        guard let enumerator = fileManager.enumerator(atPath: path) else {
            return items
        }
        
        while let filePath = enumerator.nextObject() as? String {
            let fullPath = (path as NSString).appendingPathComponent(filePath)
            
            guard SafetyCheck.shared.isSafeToScan(path: fullPath) else {
                enumerator.skipDescendants()
                continue
            }
            
            guard let size = fileManager.sizeOfItem(atPath: fullPath) else {
                continue
            }
            
            guard size >= 1024 else {
                continue
            }
            
            let isDir = fileManager.isDirectory(atPath: fullPath)
            let modDate = fileManager.modificationDateOfFile(atPath: fullPath)
            let category = determineCategory(forPath: fullPath, baseCategory: baseCategory)
            
            guard SafetyCheck.shared.isSafeToDelete(path: fullPath) else {
                continue
            }
            
            let item = ScanItem(
                path: fullPath,
                name: (fullPath as NSString).lastPathComponent,
                size: size,
                isDirectory: isDir,
                modificationDate: modDate,
                category: category
            )
            
            items.append(item)
        }
        
        return items
    }
    
    private func categoryForPath(_ path: String) -> CacheCategory {
        if path.contains("Caches") {
            if path.contains("Xcode") || path.contains("Developer") {
                return .developerCache
            }
            if path.contains("Safari") || path.contains("Chrome") || path.contains("Firefox") {
                return .browserCache
            }
            return .applicationCache
        }
        
        if path.contains("Logs") {
            if path.hasPrefix("/Library") {
                return .systemLogs
            }
            return .userLogs
        }
        
        if path.contains("Fonts") || path.contains("font") {
            return .fontCache
        }
        
        return .other
    }
    
    private func determineCategory(forPath path: String, baseCategory: CacheCategory) -> CacheCategory {
        let lowerPath = path.lowercased()
        
        if lowerPath.contains("xcode") || lowerPath.contains("developer") || lowerPath.contains("deriveddata") {
            return .developerCache
        }
        
        if lowerPath.contains("safari") || lowerPath.contains("chrome") || lowerPath.contains("firefox") ||
           lowerPath.contains("chromium") || lowerPath.contains("opera") {
            return .browserCache
        }
        
        if lowerPath.contains("font") || lowerPath.contains("typography") {
            return .fontCache
        }
        
        if lowerPath.contains("log") {
            return path.hasPrefix("/Library") ? .systemLogs : .userLogs
        }
        
        return baseCategory
    }
}
