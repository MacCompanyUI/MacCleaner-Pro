import Foundation
import AppKit

final class TrashManager {
    static let shared = TrashManager()
    
    private init() {}
    
    struct TrashResult {
        let success: Bool
        let movedToTrash: [String]
        let failed: [(path: String, error: String)]
        let totalSizeFreed: Int64
        
        var formattedSizeFreed: String {
            ByteCountFormatter.string(fromByteCount: totalSizeFreed, countStyle: .file)
        }
    }
    
    func moveToTrash(paths: [String], requireConfirmation: Bool = true) async -> TrashResult {
        var movedToTrash: [String] = []
        var failed: [(path: String, error: String)] = []
        var totalSizeFreed: Int64 = 0
        
        Logger.shared.log("Starting trash operation for \(paths.count) items", level: .info)
        
        let safePaths = paths.filter { path in
            let isSafe = SafetyCheck.shared.isSafeToDelete(path: path)
            if !isSafe {
                let reason = SafetyCheck.shared.getBlockReason(path: path) ?? "Unknown reason"
                failed.append((path: path, error: reason))
                Logger.shared.log("Blocked from trash: \(path) - \(reason)", level: .warning)
            }
            return isSafe
        }
        
        guard !safePaths.isEmpty else {
            Logger.shared.log("No safe paths to trash", level: .warning)
            return TrashResult(success: false, movedToTrash: [], failed: failed, totalSizeFreed: 0)
        }
        
        let totalSize = safePaths.reduce(0) { partialResult, path in
            partialResult + (FileManager.default.sizeOfItem(atPath: path) ?? 0)
        }
        
        if requireConfirmation && totalSize > 100 * 1024 * 1024 {
            Logger.shared.log("Large trash operation: \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))", level: .info)
        }
        
        for path in safePaths {
            do {
                let size = FileManager.default.sizeOfItem(atPath: path) ?? 0
                
                let url = URL(fileURLWithPath: path)
                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                
                movedToTrash.append(path)
                totalSizeFreed += size
                
                Logger.shared.log("Moved to trash: \(path) (\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)))", level: .info)
            } catch {
                failed.append((path: path, error: error.localizedDescription))
                Logger.shared.log("Failed to trash \(path): \(error.localizedDescription)", level: .error)
            }
        }
        
        let success = !movedToTrash.isEmpty
        Logger.shared.log("Trash operation completed: \(movedToTrash.count) succeeded, \(failed.count) failed", level: .info)
        
        return TrashResult(
            success: success,
            movedToTrash: movedToTrash,
            failed: failed,
            totalSizeFreed: totalSizeFreed
        )
    }
    
    func emptyTrash() async -> Result<Int64, Error> {
        Logger.shared.log("Emptying Trash (irreversible operation)", level: .warning)
        
        return .failure(NSError(
            domain: "TrashManager",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Emptying Trash requires additional permissions. Please empty Trash manually."]
        ))
    }
}
