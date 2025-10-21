import Foundation

class JSONLoader {
    static let shared = JSONLoader()
    private let fileManager = FileManagerUtils.shared
    
    private init() {}
    
    // MARK: - Load from Bundle
    func loadFromBundle<T: Codable>(_ type: T.Type, filename: String) -> T? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("Could not find \(filename).json in bundle")
            return nil
        }
        
        return loadFromURL(type, url: url)
    }
    
    // MARK: - Load from URL
    func loadFromURL<T: Codable>(_ type: T.Type, url: URL) -> T? {
        guard let data = fileManager.loadData(from: url) else {
            print("Could not load data from \(url)")
            return nil
        }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to decode JSON from \(url): \(error)")
            return nil
        }
    }
    
    // MARK: - Load from String
    func loadFromString<T: Codable>(_ type: T.Type, jsonString: String) -> T? {
        guard let data = jsonString.data(using: .utf8) else {
            print("Could not convert string to data")
            return nil
        }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to decode JSON from string: \(error)")
            return nil
        }
    }
    
    // MARK: - Save to File
    func saveToFile<T: Codable>(_ object: T, url: URL) -> Bool {
        do {
            let data = try JSONEncoder().encode(object)
            return fileManager.saveData(data, to: url)
        } catch {
            print("Failed to encode JSON: \(error)")
            return false
        }
    }
    
    // MARK: - Save to String
    func saveToString<T: Codable>(_ object: T) -> String? {
        do {
            let data = try JSONEncoder().encode(object)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Failed to encode JSON to string: \(error)")
            return nil
        }
    }
    
    // MARK: - Pretty Print
    func prettyPrint<T: Codable>(_ object: T) -> String? {
        do {
            let data = try JSONEncoder().encode(object)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
            return String(data: prettyData, encoding: .utf8)
        } catch {
            print("Failed to pretty print JSON: \(error)")
            return nil
        }
    }
    
    // MARK: - Validate JSON
    func isValidJSON(_ data: Data) -> Bool {
        do {
            _ = try JSONSerialization.jsonObject(with: data, options: [])
            return true
        } catch {
            return false
        }
    }
    
    func isValidJSON(_ string: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return isValidJSON(data)
    }
    
    // MARK: - Merge JSON Objects
    func merge<T: Codable>(_ objects: [T]) -> [String: Any]? {
        var merged: [String: Any] = [:]
        
        for object in objects {
            guard let data = try? JSONEncoder().encode(object),
                  let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                continue
            }
            
            for (key, value) in jsonObject {
                merged[key] = value
            }
        }
        
        return merged.isEmpty ? nil : merged
    }
    
    // MARK: - Load Multiple Files
    func loadMultiple<T: Codable>(_ type: T.Type, from directory: URL) -> [T] {
        let urls = fileManager.contentsOfDirectory(at: directory) { url in
            url.pathExtension.lowercased() == "json"
        }
        
        var results: [T] = []
        for url in urls {
            if let object = loadFromURL(type, url: url) {
                results.append(object)
            }
        }
        
        return results
    }
    
    // MARK: - Load with Fallback
    func loadWithFallback<T: Codable>(_ type: T.Type, primaryURL: URL, fallbackURL: URL) -> T? {
        if let result = loadFromURL(type, url: primaryURL) {
            return result
        }
        
        print("Primary load failed, trying fallback...")
        return loadFromURL(type, url: fallbackURL)
    }
    
    // MARK: - Load with Default
    func loadWithDefault<T: Codable>(_ type: T.Type, url: URL, defaultObject: T) -> T {
        return loadFromURL(type, url: url) ?? defaultObject
    }
    
    // MARK: - Async Loading
    func loadAsync<T: Codable>(_ type: T.Type, url: URL) async -> T? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.loadFromURL(type, url: url)
                continuation.resume(returning: result)
            }
        }
    }
    
    // MARK: - Save Async
    func saveAsync<T: Codable>(_ object: T, url: URL) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.saveToFile(object, url: url)
                continuation.resume(returning: result)
            }
        }
    }
    
    // MARK: - Theme Loading Helpers
    func loadTheme(named name: String, for widgetType: WidgetType) -> ThemeModel? {
        let filename = "\(widgetType.rawValue)_\(name)"
        return loadFromBundle(ThemeModel.self, filename: filename)
    }
    
    func loadAllThemes(for widgetType: WidgetType) -> [ThemeModel] {
        let themeNames = getAvailableThemeNames(for: widgetType)
        var themes: [ThemeModel] = []
        
        for themeName in themeNames {
            if let theme = loadTheme(named: themeName, for: widgetType) {
                themes.append(theme)
            }
        }
        
        return themes
    }
    
    private func getAvailableThemeNames(for widgetType: WidgetType) -> [String] {
        switch widgetType {
        case .clock:
            return ["LiquidGlass", "Minimal", "DigitalNeon", "ClassicAnalog", "RetroFlip"]
        case .weather:
            return ["Glass", "Minimal", "Gradient", "Dark", "Retro"]
        case .music:
            return ["Glass", "Minimal", "Neon", "Dark", "Retro"]
        case .systemStats:
            return ["ModernGlass", "Terminal", "Radar", "FlatColor", "Vaporwave"]
        case .notes:
            return ["Glass", "Minimal", "Paper", "Dark", "Colorful"]
        }
    }
}

