import Foundation

extension FileManager {
    func sizeOfItem(atPath path: String) -> Int64? {
        var isDirectory: ObjCBool = false
        guard fileExists(atPath: path, isDirectory: &isDirectory) else {
            return nil
        }
        
        if isDirectory.boolValue {
            return sizeOfDirectory(atPath: path)
        } else {
            return sizeOfFile(atPath: path)
        }
    }
    
    private func sizeOfFile(atPath path: String) -> Int64? {
        guard let attributes = try? attributesOfItem(atPath: path),
              let size = attributes[.size] as? Int64 else {
            return nil
        }
        return size
    }
    
    func sizeOfDirectory(atPath path: String) -> Int64 {
        var totalSize: Int64 = 0
        
        guard let enumerator = enumerator(atPath: path) else {
            return 0
        }
        
        while let filePath = enumerator.nextObject() as? String {
            let fullPath = (path as NSString).appendingPathComponent(filePath)
            if let fileSize = sizeOfFile(atPath: fullPath) {
                totalSize += fileSize
            }
        }
        
        return totalSize
    }
    
    func modificationDateOfFile(atPath path: String) -> Date? {
        guard let attributes = try? attributesOfItem(atPath: path) else {
            return nil
        }
        return attributes[.modificationDate] as? Date
    }
    
    func isDirectory(atPath path: String) -> Bool {
        var isDirectory: ObjCBool = false
        return fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
    
    func filesInDirectory(
        atPath path: String,
        extensions: [String]? = nil,
        minSize: Int64 = 0,
        maxDepth: Int? = nil
    ) -> [String] {
        guard isDirectory(atPath: path) else { return [] }
        
        var result: [String] = []
        let baseDepth = path.components(separatedBy: "/").count
        
        guard let enumerator = enumerator(atPath: path) else {
            return []
        }
        
        while let filePath = enumerator.nextObject() as? String {
            if let maxDepth = maxDepth {
                let currentDepth = filePath.components(separatedBy: "/").count
                if currentDepth > maxDepth {
                    enumerator.skipDescendants()
                    continue
                }
            }
            
            let fullPath = (path as NSString).appendingPathComponent(filePath)
            
            if let extensions = extensions {
                let fileExtension = (fullPath as NSString).pathExtension.lowercased()
                guard extensions.contains(fileExtension) else { continue }
            }
            
            if minSize > 0 {
                guard let fileSize = sizeOfFile(atPath: fullPath), fileSize >= minSize else {
                    continue
                }
            }
            
            result.append(fullPath)
        }
        
        return result
    }
    
    func safeContentsOfDirectory(atPath path: String) -> [String] {
        do {
            return try contentsOfDirectory(atPath: path)
        } catch {
            Logger.shared.log("Error reading directory \(path): \(error.localizedDescription)", level: .warning)
            return []
        }
    }
}
