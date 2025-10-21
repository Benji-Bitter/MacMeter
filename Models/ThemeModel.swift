import SwiftUI
import Foundation

// MARK: - Theme Model
struct ThemeModel: Codable {
    let name: String
    let background: String
    let font: String
    let primaryColor: String
    let accentColor: String
    let blurRadius: Double
    let shadowOpacity: Double
    let cornerRadius: Double
    let borderWidth: Double?
    let borderColor: String?
    let textShadow: Bool?
    let animationSpeed: Double?
    
    init(name: String, background: String = "ultraThinMaterial", font: String = "SF Pro Rounded", 
         primaryColor: String = "#FFFFFF", accentColor: String = "#00BFFF", 
         blurRadius: Double = 20, shadowOpacity: Double = 0.4, cornerRadius: Double = 12,
         borderWidth: Double? = nil, borderColor: String? = nil, textShadow: Bool? = nil,
         animationSpeed: Double? = nil) {
        self.name = name
        self.background = background
        self.font = font
        self.primaryColor = primaryColor
        self.accentColor = accentColor
        self.blurRadius = blurRadius
        self.shadowOpacity = shadowOpacity
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.textShadow = textShadow
        self.animationSpeed = animationSpeed
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var themes: [String: ThemeModel] = [:]
    @Published var currentTheme: String = "default"
    
    private let fileManager = FileManager.default
    private let themesPath: URL
    
    init() {
        let documentsDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.themesPath = documentsDirectory.appendingPathComponent("MacMeter/Themes")
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: themesPath, withIntermediateDirectories: true)
        
        loadDefaultThemes()
        loadCustomThemes()
    }
    
    func getTheme(named name: String) -> ThemeModel? {
        return themes[name]
    }
    
    func getThemeForWidget(_ widgetType: WidgetType, themeName: String) -> ThemeModel? {
        let fullThemeName = "\(widgetType.rawValue)_\(themeName)"
        return themes[fullThemeName]
    }
    
    func saveCustomTheme(_ theme: ThemeModel, for widgetType: WidgetType) {
        let fullThemeName = "\(widgetType.rawValue)_\(theme.name)"
        themes[fullThemeName] = theme
        
        do {
            let data = try JSONEncoder().encode(theme)
            let fileURL = themesPath.appendingPathComponent("\(fullThemeName).json")
            try data.write(to: fileURL)
        } catch {
            print("Failed to save custom theme: \(error)")
        }
    }
    
    private func loadDefaultThemes() {
        // Load default themes from bundle
        loadClockThemes()
        loadWeatherThemes()
        loadMusicThemes()
        loadSystemStatsThemes()
        loadNotesThemes()
    }
    
    private func loadCustomThemes() {
        do {
            let themeFiles = try fileManager.contentsOfDirectory(at: themesPath, includingPropertiesForKeys: nil)
            
            for fileURL in themeFiles where fileURL.pathExtension == "json" {
                do {
                    let data = try Data(contentsOf: fileURL)
                    let theme = try JSONDecoder().decode(ThemeModel.self, from: data)
                    let fileName = fileURL.deletingPathExtension().lastPathComponent
                    themes[fileName] = theme
                } catch {
                    print("Failed to load custom theme from \(fileURL): \(error)")
                }
            }
        } catch {
            print("Failed to load custom themes: \(error)")
        }
    }
    
    private func loadClockThemes() {
        let clockThemes = [
            ThemeModel(name: "LiquidGlass", background: "ultraThinMaterial", font: "SF Pro Rounded", 
                      primaryColor: "#FFFFFF", accentColor: "#00BFFF", blurRadius: 25, 
                      shadowOpacity: 0.6, cornerRadius: 20, textShadow: true, animationSpeed: 1.0),
            
            ThemeModel(name: "Minimal", background: "regularMaterial", font: "SF Pro Display", 
                      primaryColor: "#000000", accentColor: "#007AFF", blurRadius: 10, 
                      shadowOpacity: 0.2, cornerRadius: 8, animationSpeed: 0.5),
            
            ThemeModel(name: "DigitalNeon", background: "thickMaterial", font: "Menlo", 
                      primaryColor: "#00FF00", accentColor: "#FF00FF", blurRadius: 15, 
                      shadowOpacity: 0.8, cornerRadius: 12, borderWidth: 1, borderColor: "#00FF00", 
                      textShadow: true, animationSpeed: 2.0),
            
            ThemeModel(name: "ClassicAnalog", background: "regularMaterial", font: "Times New Roman", 
                      primaryColor: "#8B4513", accentColor: "#FFD700", blurRadius: 5, 
                      shadowOpacity: 0.3, cornerRadius: 100, animationSpeed: 0.3),
            
            ThemeModel(name: "RetroFlip", background: "thickMaterial", font: "Courier New", 
                      primaryColor: "#FF6B35", accentColor: "#F7931E", blurRadius: 8, 
                      shadowOpacity: 0.5, cornerRadius: 6, animationSpeed: 1.5)
        ]
        
        for theme in clockThemes {
            themes["clock_\(theme.name)"] = theme
        }
    }
    
    private func loadWeatherThemes() {
        let weatherThemes = [
            ThemeModel(name: "Glass", background: "ultraThinMaterial", font: "SF Pro Rounded", 
                      primaryColor: "#FFFFFF", accentColor: "#87CEEB", blurRadius: 20, 
                      shadowOpacity: 0.4, cornerRadius: 16, textShadow: true),
            
            ThemeModel(name: "Minimal", background: "regularMaterial", font: "SF Pro Display", 
                      primaryColor: "#000000", accentColor: "#007AFF", blurRadius: 10, 
                      shadowOpacity: 0.2, cornerRadius: 8),
            
            ThemeModel(name: "Gradient", background: "thickMaterial", font: "SF Pro Rounded", 
                      primaryColor: "#FFFFFF", accentColor: "#FF6B6B", blurRadius: 15, 
                      shadowOpacity: 0.6, cornerRadius: 20, textShadow: true),
            
            ThemeModel(name: "Dark", background: "thickMaterial", font: "SF Pro Display", 
                      primaryColor: "#FFFFFF", accentColor: "#00D4FF", blurRadius: 25, 
                      shadowOpacity: 0.8, cornerRadius: 12),
            
            ThemeModel(name: "Retro", background: "regularMaterial", font: "Courier New", 
                      primaryColor: "#00FF00", accentColor: "#FF00FF", blurRadius: 5, 
                      shadowOpacity: 0.3, cornerRadius: 4, borderWidth: 2, borderColor: "#00FF00")
        ]
        
        for theme in weatherThemes {
            themes["weather_\(theme.name)"] = theme
        }
    }
    
    private func loadMusicThemes() {
        let musicThemes = [
            ThemeModel(name: "Glass", background: "ultraThinMaterial", font: "SF Pro Rounded", 
                      primaryColor: "#FFFFFF", accentColor: "#FF3B30", blurRadius: 20, 
                      shadowOpacity: 0.4, cornerRadius: 16),
            
            ThemeModel(name: "Minimal", background: "regularMaterial", font: "SF Pro Display", 
                      primaryColor: "#000000", accentColor: "#007AFF", blurRadius: 10, 
                      shadowOpacity: 0.2, cornerRadius: 8),
            
            ThemeModel(name: "Neon", background: "thickMaterial", font: "SF Pro Rounded", 
                      primaryColor: "#00FFFF", accentColor: "#FF00FF", blurRadius: 15, 
                      shadowOpacity: 0.8, cornerRadius: 12, textShadow: true),
            
            ThemeModel(name: "Dark", background: "thickMaterial", font: "SF Pro Display", 
                      primaryColor: "#FFFFFF", accentColor: "#FF9500", blurRadius: 25, 
                      shadowOpacity: 0.6, cornerRadius: 16),
            
            ThemeModel(name: "Retro", background: "regularMaterial", font: "Courier New", 
                      primaryColor: "#FFD700", accentColor: "#FF4500", blurRadius: 8, 
                      shadowOpacity: 0.4, cornerRadius: 6)
        ]
        
        for theme in musicThemes {
            themes["music_\(theme.name)"] = theme
        }
    }
    
    private func loadSystemStatsThemes() {
        let systemThemes = [
            ThemeModel(name: "ModernGlass", background: "ultraThinMaterial", font: "SF Mono", 
                      primaryColor: "#FFFFFF", accentColor: "#00D4FF", blurRadius: 20, 
                      shadowOpacity: 0.4, cornerRadius: 16),
            
            ThemeModel(name: "Terminal", background: "thickMaterial", font: "Menlo", 
                      primaryColor: "#00FF00", accentColor: "#FFFFFF", blurRadius: 5, 
                      shadowOpacity: 0.2, cornerRadius: 4, borderWidth: 1, borderColor: "#00FF00"),
            
            ThemeModel(name: "Radar", background: "regularMaterial", font: "SF Pro Display", 
                      primaryColor: "#00FF00", accentColor: "#FF0000", blurRadius: 10, 
                      shadowOpacity: 0.6, cornerRadius: 8, textShadow: true),
            
            ThemeModel(name: "FlatColor", background: "regularMaterial", font: "SF Pro Rounded", 
                      primaryColor: "#FFFFFF", accentColor: "#FF6B6B", blurRadius: 0, 
                      shadowOpacity: 0.3, cornerRadius: 12),
            
            ThemeModel(name: "Vaporwave", background: "thickMaterial", font: "SF Pro Rounded", 
                      primaryColor: "#FF00FF", accentColor: "#00FFFF", blurRadius: 15, 
                      shadowOpacity: 0.8, cornerRadius: 20, textShadow: true)
        ]
        
        for theme in systemThemes {
            themes["systemStats_\(theme.name)"] = theme
        }
    }
    
    private func loadNotesThemes() {
        let notesThemes = [
            ThemeModel(name: "Glass", background: "ultraThinMaterial", font: "SF Pro Text", 
                      primaryColor: "#000000", accentColor: "#007AFF", blurRadius: 20, 
                      shadowOpacity: 0.4, cornerRadius: 16),
            
            ThemeModel(name: "Minimal", background: "regularMaterial", font: "SF Pro Text", 
                      primaryColor: "#000000", accentColor: "#8E8E93", blurRadius: 10, 
                      shadowOpacity: 0.2, cornerRadius: 8),
            
            ThemeModel(name: "Paper", background: "regularMaterial", font: "Times New Roman", 
                      primaryColor: "#000000", accentColor: "#8B4513", blurRadius: 5, 
                      shadowOpacity: 0.3, cornerRadius: 4),
            
            ThemeModel(name: "Dark", background: "thickMaterial", font: "SF Pro Text", 
                      primaryColor: "#FFFFFF", accentColor: "#00D4FF", blurRadius: 25, 
                      shadowOpacity: 0.6, cornerRadius: 12),
            
            ThemeModel(name: "Colorful", background: "ultraThinMaterial", font: "SF Pro Rounded", 
                      primaryColor: "#000000", accentColor: "#FF6B6B", blurRadius: 15, 
                      shadowOpacity: 0.5, cornerRadius: 20)
        ]
        
        for theme in notesThemes {
            themes["notes_\(theme.name)"] = theme
        }
    }
}
