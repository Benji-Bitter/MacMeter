import SwiftUI
import Foundation

// MARK: - Base Widget Model Extensions
extension WidgetModel {
    func toConfiguration() -> WidgetConfiguration {
        return WidgetConfiguration(from: self)
    }
    
    static func fromConfiguration(_ config: WidgetConfiguration) -> WidgetModel {
        let widget = WidgetModel(type: config.type, position: config.position, size: config.size)
        widget.isVisible = config.isVisible
        widget.theme = config.theme
        
        // Convert string properties back to their original types
        for (key, value) in config.customProperties {
            if let data = value.data(using: .utf8),
               let jsonObject = try? JSONSerialization.jsonObject(with: data) {
                widget.customProperties[key] = jsonObject
            } else {
                widget.customProperties[key] = value
            }
        }
        
        return widget
    }
}

// MARK: - Widget Layout Manager
class WidgetLayoutManager: ObservableObject {
    @Published var widgets: [WidgetModel] = []
    @Published var isEditMode: Bool = false
    @Published var selectedWidget: WidgetModel?
    @Published var dragOffset: CGSize = .zero
    
    private let fileManager = FileManager.default
    private let documentsPath: URL
    
    init() {
        let documentsDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.documentsPath = documentsDirectory.appendingPathComponent("MacMeter")
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: documentsPath, withIntermediateDirectories: true)
        
        loadLayout()
    }
    
    func addWidget(_ widget: WidgetModel) {
        widgets.append(widget)
        saveLayout()
    }
    
    func removeWidget(_ widget: WidgetModel) {
        widgets.removeAll { $0.id == widget.id }
        saveLayout()
    }
    
    func updateWidget(_ widget: WidgetModel) {
        if let index = widgets.firstIndex(where: { $0.id == widget.id }) {
            widgets[index] = widget
            saveLayout()
        }
    }
    
    func moveWidget(_ widget: WidgetModel, to position: CGPoint) {
        if let index = widgets.firstIndex(where: { $0.id == widget.id }) {
            widgets[index].position = position
            saveLayout()
        }
    }
    
    func resizeWidget(_ widget: WidgetModel, to size: CGSize) {
        if let index = widgets.firstIndex(where: { $0.id == widget.id }) {
            widgets[index].size = size
            saveLayout()
        }
    }
    
    func toggleEditMode() {
        isEditMode.toggle()
        if !isEditMode {
            selectedWidget = nil
        }
    }
    
    private func saveLayout() {
        let configurations = widgets.map { $0.toConfiguration() }
        
        do {
            let data = try JSONEncoder().encode(configurations)
            let fileURL = documentsPath.appendingPathComponent("layout.json")
            try data.write(to: fileURL)
        } catch {
            print("Failed to save layout: \(error)")
        }
    }
    
    private func loadLayout() {
        let fileURL = documentsPath.appendingPathComponent("layout.json")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            loadDefaultLayout()
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let configurations = try JSONDecoder().decode([WidgetConfiguration].self, from: data)
            self.widgets = configurations.map { WidgetModel.fromConfiguration($0) }
        } catch {
            print("Failed to load layout: \(error)")
            loadDefaultLayout()
        }
    }
    
    private func loadDefaultLayout() {
        // Add some default widgets for first-time users
        let clockWidget = ClockWidgetModel(position: CGPoint(x: 50, y: 50))
        let weatherWidget = WeatherWidgetModel(position: CGPoint(x: 300, y: 50))
        
        widgets = [clockWidget, weatherWidget]
        saveLayout()
    }
    
    func exportLayout() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "MacMeter_Layout.json"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let configurations = widgets.map { $0.toConfiguration() }
                let data = try JSONEncoder().encode(configurations)
                try data.write(to: url)
            } catch {
                print("Failed to export layout: \(error)")
            }
        }
    }
    
    func importLayout() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                let configurations = try JSONDecoder().decode([WidgetConfiguration].self, from: data)
                self.widgets = configurations.map { WidgetModel.fromConfiguration($0) }
                saveLayout()
            } catch {
                print("Failed to import layout: \(error)")
            }
        }
    }
}
