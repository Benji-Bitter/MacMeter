import SwiftUI
import Foundation
import Combine

// MARK: - Widget Manager
class WidgetManager: ObservableObject {
    @Published var widgets: [WidgetModel] = []
    @Published var isEditMode: Bool = false
    @Published var selectedWidget: WidgetModel?
    @Published var showWidgetMenu: Bool = false
    @Published var autoLaunch: Bool = false
    @Published var snapToGrid: Bool = true
    @Published var updateInterval: Double = 15.0
    
    private let layoutManager = WidgetLayoutManager()
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        startUpdateTimer()
    }
    
    deinit {
        updateTimer?.invalidate()
    }
    
    private func setupBindings() {
        // Bind to layout manager
        layoutManager.$widgets
            .assign(to: \.widgets, on: self)
            .store(in: &cancellables)
        
        layoutManager.$isEditMode
            .assign(to: \.isEditMode, on: self)
            .store(in: &cancellables)
        
        layoutManager.$selectedWidget
            .assign(to: \.selectedWidget, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Widget Management
    func addWidget(_ type: WidgetType, at position: CGPoint) {
        let widget: WidgetModel
        
        switch type {
        case .clock:
            widget = ClockWidgetModel(position: position)
        case .weather:
            widget = WeatherWidgetModel(position: position)
        case .music:
            widget = MusicWidgetModel(position: position)
        case .systemStats:
            widget = SystemStatsWidgetModel(position: position)
        case .notes:
            widget = NotesWidgetModel(position: position)
        }
        
        layoutManager.addWidget(widget)
    }
    
    func removeWidget(_ widget: WidgetModel) {
        layoutManager.removeWidget(widget)
    }
    
    func updateWidget(_ widget: WidgetModel) {
        layoutManager.updateWidget(widget)
    }
    
    func moveWidget(_ widget: WidgetModel, to position: CGPoint) {
        let finalPosition = snapToGrid ? snapToGridPosition(position) : position
        layoutManager.moveWidget(widget, to: finalPosition)
    }
    
    func resizeWidget(_ widget: WidgetModel, to size: CGSize) {
        let finalSize = snapToGrid ? snapToGridSize(size) : size
        layoutManager.resizeWidget(widget, to: finalSize)
    }
    
    func toggleEditMode() {
        layoutManager.toggleEditMode()
    }
    
    func selectWidget(_ widget: WidgetModel?) {
        layoutManager.selectedWidget = widget
    }
    
    // MARK: - Grid Snapping
    private func snapToGridPosition(_ position: CGPoint) -> CGPoint {
        let gridSize: CGFloat = 20
        return CGPoint(
            x: round(position.x / gridSize) * gridSize,
            y: round(position.y / gridSize) * gridSize
        )
    }
    
    private func snapToGridSize(_ size: CGSize) -> CGSize {
        let gridSize: CGFloat = 20
        return CGSize(
            width: max(100, round(size.width / gridSize) * gridSize),
            height: max(100, round(size.height / gridSize) * gridSize)
        )
    }
    
    // MARK: - Update Timer
    private func startUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateAllWidgets()
        }
    }
    
    func updateAllWidgets() {
        for widget in widgets {
            widget.updateData()
        }
    }
    
    func setUpdateInterval(_ interval: Double) {
        updateInterval = interval
        startUpdateTimer()
    }
    
    // MARK: - Layout Management
    func exportLayout() {
        layoutManager.exportLayout()
    }
    
    func importLayout() {
        layoutManager.importLayout()
    }
    
    func resetToDefaultLayout() {
        widgets.removeAll()
        layoutManager.loadDefaultLayout()
    }
    
    // MARK: - Widget Factory
    func createWidget(of type: WidgetType, at position: CGPoint) -> WidgetModel {
        switch type {
        case .clock:
            return ClockWidgetModel(position: position)
        case .weather:
            return WeatherWidgetModel(position: position)
        case .music:
            return MusicWidgetModel(position: position)
        case .systemStats:
            return SystemStatsWidgetModel(position: position)
        case .notes:
            return NotesWidgetModel(position: position)
        }
    }
    
    // MARK: - Keyboard Shortcuts
    func handleKeyboardShortcut(_ key: String) {
        switch key {
        case "e":
            toggleEditMode()
        case "a":
            showWidgetMenu = true
        case "h":
            toggleAllWidgets()
        case "r":
            resetToDefaultLayout()
        default:
            break
        }
    }
    
    func toggleAllWidgets() {
        let shouldShow = widgets.contains { !$0.isVisible }
        for widget in widgets {
            widget.isVisible = shouldShow
        }
        updateAllWidgets()
    }
}

// MARK: - Widget Factory
class WidgetFactory {
    static func createWidget(of type: WidgetType, at position: CGPoint, with configuration: WidgetConfiguration? = nil) -> WidgetModel {
        let widget: WidgetModel
        
        switch type {
        case .clock:
            widget = ClockWidgetModel(position: position)
        case .weather:
            widget = WeatherWidgetModel(position: position)
        case .music:
            widget = MusicWidgetModel(position: position)
        case .systemStats:
            widget = SystemStatsWidgetModel(position: position)
        case .notes:
            widget = NotesWidgetModel(position: position)
        }
        
        if let config = configuration {
            widget.isVisible = config.isVisible
            widget.theme = config.theme
            widget.customProperties = config.customProperties.compactMapValues { value in
                if let data = value.data(using: .utf8),
                   let jsonObject = try? JSONSerialization.jsonObject(with: data) {
                    return jsonObject
                } else {
                    return value
                }
            }
        }
        
        return widget
    }
}