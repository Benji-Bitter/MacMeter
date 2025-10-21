import Foundation

class FileManagerUtils {
    static let shared = FileManagerUtils()
    private let fileManager = FileManager.default
    
    private init() {}
    
    // MARK: - Application Support Directory
    func getApplicationSupportDirectory() -> URL {
        let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportURL = urls.first!.appendingPathComponent("MacMeter")
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: appSupportURL.path) {
            try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        }
        
        return appSupportURL
    }
    
    // MARK: - Documents Directory
    func getDocumentsDirectory() -> URL {
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return urls.first!
    }
    
    // MARK: - Desktop Directory
    func getDesktopDirectory() -> URL {
        let urls = fileManager.urls(for: .desktopDirectory, in: .userDomainMask)
        return urls.first!
    }
    
    // MARK: - File Operations
    func saveData(_ data: Data, to url: URL) -> Bool {
        do {
            try data.write(to: url)
            return true
        } catch {
            print("Failed to save data to \(url): \(error)")
            return false
        }
    }
    
    func loadData(from url: URL) -> Data? {
        do {
            return try Data(contentsOf: url)
        } catch {
            print("Failed to load data from \(url): \(error)")
            return nil
        }
    }
    
    func saveString(_ string: String, to url: URL) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return saveData(data, to: url)
    }
    
    func loadString(from url: URL) -> String? {
        guard let data = loadData(from: url) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - JSON Operations
    func saveJSON<T: Codable>(_ object: T, to url: URL) -> Bool {
        do {
            let data = try JSONEncoder().encode(object)
            return saveData(data, to: url)
        } catch {
            print("Failed to encode JSON: \(error)")
            return false
        }
    }
    
    func loadJSON<T: Codable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = loadData(from: url) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to decode JSON: \(error)")
            return nil
        }
    }
    
    // MARK: - File Existence
    func fileExists(at url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }
    
    func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
    
    // MARK: - Directory Operations
    func createDirectory(at url: URL) -> Bool {
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            return true
        } catch {
            print("Failed to create directory at \(url): \(error)")
            return false
        }
    }
    
    func removeItem(at url: URL) -> Bool {
        do {
            try fileManager.removeItem(at: url)
            return true
        } catch {
            print("Failed to remove item at \(url): \(error)")
            return false
        }
    }
    
    func copyItem(from sourceURL: URL, to destinationURL: URL) -> Bool {
        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            return true
        } catch {
            print("Failed to copy item from \(sourceURL) to \(destinationURL): \(error)")
            return false
        }
    }
    
    func moveItem(from sourceURL: URL, to destinationURL: URL) -> Bool {
        do {
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            return true
        } catch {
            print("Failed to move item from \(sourceURL) to \(destinationURL): \(error)")
            return false
        }
    }
    
    // MARK: - Directory Contents
    func contentsOfDirectory(at url: URL) -> [URL] {
        do {
            return try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        } catch {
            print("Failed to get contents of directory \(url): \(error)")
            return []
        }
    }
    
    func contentsOfDirectory(at url: URL, matching predicate: (URL) -> Bool) -> [URL] {
        return contentsOfDirectory(at: url).filter(predicate)
    }
    
    // MARK: - File Attributes
    func getFileSize(at url: URL) -> Int64? {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64
        } catch {
            print("Failed to get file size for \(url): \(error)")
            return nil
        }
    }
    
    func getCreationDate(at url: URL) -> Date? {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            return attributes[.creationDate] as? Date
        } catch {
            print("Failed to get creation date for \(url): \(error)")
            return nil
        }
    }
    
    func getModificationDate(at url: URL) -> Date? {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            return attributes[.modificationDate] as? Date
        } catch {
            print("Failed to get modification date for \(url): \(error)")
            return nil
        }
    }
    
    // MARK: - Temporary Files
    func createTemporaryFile(withExtension ext: String = "tmp") -> URL? {
        let tempDirectory = fileManager.temporaryDirectory
        let fileName = UUID().uuidString + "." + ext
        return tempDirectory.appendingPathComponent(fileName)
    }
    
    func createTemporaryDirectory() -> URL? {
        let tempDirectory = fileManager.temporaryDirectory
        let directoryName = UUID().uuidString
        let tempURL = tempDirectory.appendingPathComponent(directoryName)
        
        if createDirectory(at: tempURL) {
            return tempURL
        }
        return nil
    }
    
    // MARK: - File Size Formatting
    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    // MARK: - Backup Operations
    func createBackup(of url: URL) -> URL? {
        let backupURL = url.appendingPathExtension("backup")
        if copyItem(from: url, to: backupURL) {
            return backupURL
        }
        return nil
    }
    
    func restoreFromBackup(_ backupURL: URL, to originalURL: URL) -> Bool {
        return copyItem(from: backupURL, to: originalURL)
    }
}

