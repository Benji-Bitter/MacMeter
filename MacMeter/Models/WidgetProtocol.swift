import SwiftUI
import Foundation

// MARK: - Widget Protocol
protocol WidgetProtocol: ObservableObject, Identifiable {
    var id: UUID { get }
    var type: WidgetType { get }
    var position: CGPoint { get set }
    var size: CGSize { get set }
    var isVisible: Bool { get set }
    var isEditing: Bool { get set }
    var theme: String { get set }
    var customProperties: [String: Any] { get set }
    
    func updateData()
    func render() -> AnyView
    func getDefaultSize() -> CGSize
    func getAvailableThemes() -> [String]
    func applyTheme(_ themeName: String)
}

// MARK: - Widget Type Enum
enum WidgetType: String, CaseIterable, Codable {
    case clock = "clock"
    case weather = "weather"
    case music = "music"
    case systemStats = "systemStats"
    case notes = "notes"
    
    var displayName: String {
        switch self {
        case .clock: return "Clock"
        case .weather: return "Weather"
        case .music: return "Music Player"
        case .systemStats: return "System Stats"
        case .notes: return "Notes"
        }
    }
    
    var icon: String {
        switch self {
        case .clock: return "clock"
        case .weather: return "cloud.sun"
        case .music: return "music.note"
        case .systemStats: return "chart.bar"
        case .notes: return "note.text"
        }
    }
}

// MARK: - Widget Base Model
class WidgetModel: WidgetProtocol {
    let id = UUID()
    let type: WidgetType
    var position: CGPoint
    var size: CGSize
    var isVisible: Bool = true
    var isEditing: Bool = false
    var theme: String = "default"
    var customProperties: [String: Any] = [:]
    
    init(type: WidgetType, position: CGPoint, size: CGSize? = nil) {
        self.type = type
        self.position = position
        self.size = size ?? getDefaultSize()
    }
    
    func updateData() {
        // Override in subclasses
    }
    
    func render() -> AnyView {
        // Override in subclasses
        return AnyView(EmptyView())
    }
    
    func getDefaultSize() -> CGSize {
        switch type {
        case .clock: return CGSize(width: 200, height: 200)
        case .weather: return CGSize(width: 250, height: 150)
        case .music: return CGSize(width: 300, height: 100)
        case .systemStats: return CGSize(width: 200, height: 300)
        case .notes: return CGSize(width: 250, height: 200)
        }
    }
    
    func getAvailableThemes() -> [String] {
        switch type {
        case .clock: return ["LiquidGlass", "Minimal", "DigitalNeon", "ClassicAnalog", "RetroFlip"]
        case .weather: return ["Glass", "Minimal", "Gradient", "Dark", "Retro"]
        case .music: return ["Glass", "Minimal", "Neon", "Dark", "Retro"]
        case .systemStats: return ["ModernGlass", "Terminal", "Radar", "FlatColor", "Vaporwave"]
        case .notes: return ["Glass", "Minimal", "Paper", "Dark", "Colorful"]
        }
    }
    
    func applyTheme(_ themeName: String) {
        self.theme = themeName
        // Theme application logic will be handled by individual widgets
    }
}

// MARK: - Widget Configuration
struct WidgetConfiguration: Codable {
    let id: UUID
    let type: WidgetType
    var position: CGPoint
    var size: CGSize
    var isVisible: Bool
    var theme: String
    var customProperties: [String: String]
    
    init(from widget: WidgetModel) {
        self.id = widget.id
        self.type = widget.type
        self.position = widget.position
        self.size = widget.size
        self.isVisible = widget.isVisible
        self.theme = widget.theme
        self.customProperties = widget.customProperties.compactMapValues { value in
            if let stringValue = value as? String {
                return stringValue
            } else if let data = try? JSONSerialization.data(withJSONObject: value),
                      let stringValue = String(data: data, encoding: .utf8) {
                return stringValue
            }
            return nil
        }
    }
}