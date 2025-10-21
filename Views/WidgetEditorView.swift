import SwiftUI

struct WidgetEditorView: View {
    let widget: WidgetModel
    @EnvironmentObject var widgetManager: WidgetManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTheme: String
    @State private var customProperties: [String: Any]
    @State private var showingThemeEditor = false
    
    init(widget: WidgetModel) {
        self.widget = widget
        self._selectedTheme = State(initialValue: widget.theme)
        self._customProperties = State(initialValue: widget.customProperties)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Theme Selection
                    themeSection
                    
                    // Widget-specific customization
                    customizationSection
                    
                    // Advanced Options
                    advancedSection
                }
                .padding()
            }
            
            // Footer
            footerView
        }
        .frame(width: 500, height: 600)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var headerView: some View {
        HStack {
            Image(systemName: widget.type.icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Customize \(widget.type.displayName)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Position: \(Int(widget.position.x)), \(Int(widget.position.y)) • Size: \(Int(widget.size.width)) × \(Int(widget.size.height))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Theme")
                    .font(.headline)
                
                Spacer()
                
                Button("Edit Theme") {
                    showingThemeEditor = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(widget.getAvailableThemes(), id: \.self) { themeName in
                    ThemePreviewCard(
                        themeName: themeName,
                        isSelected: selectedTheme == themeName,
                        widgetType: widget.type,
                        action: {
                            selectedTheme = themeName
                            widget.applyTheme(themeName)
                            widgetManager.updateWidget(widget)
                        }
                    )
                }
            }
        }
    }
    
    private var customizationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Customization")
                .font(.headline)
            
            WidgetSpecificEditor(widget: widget, customProperties: $customProperties)
        }
    }
    
    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Advanced")
                .font(.headline)
            
            VStack(spacing: 8) {
                Toggle("Visible", isOn: Binding(
                    get: { widget.isVisible },
                    set: { 
                        widget.isVisible = $0
                        widgetManager.updateWidget(widget)
                    }
                ))
                
                HStack {
                    Text("Update Interval:")
                    Spacer()
                    Picker("", selection: Binding(
                        get: { widgetManager.updateInterval },
                        set: { widgetManager.setUpdateInterval($0) }
                    )) {
                        Text("5s").tag(5.0)
                        Text("15s").tag(15.0)
                        Text("30s").tag(30.0)
                        Text("1m").tag(60.0)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 80)
                }
            }
        }
    }
    
    private var footerView: some View {
        HStack {
            Button("Reset to Default") {
                resetToDefault()
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("Delete Widget") {
                widgetManager.removeWidget(widget)
                dismiss()
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
            
            Button("Done") {
                saveChanges()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private func resetToDefault() {
        selectedTheme = "default"
        customProperties = [:]
        widget.theme = "default"
        widget.customProperties = [:]
        widgetManager.updateWidget(widget)
    }
    
    private func saveChanges() {
        widget.theme = selectedTheme
        widget.customProperties = customProperties
        widgetManager.updateWidget(widget)
    }
}

struct ThemePreviewCard: View {
    let themeName: String
    let isSelected: Bool
    let widgetType: WidgetType
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Theme preview
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeColor)
                    .frame(height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                    .overlay(
                        Image(systemName: widgetType.icon)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    )
                
                Text(themeName)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var themeColor: Color {
        let theme = themeManager.getThemeForWidget(widgetType, themeName: themeName)
        return Color(hex: theme?.accentColor ?? "#007AFF")
    }
}

struct WidgetSpecificEditor: View {
    let widget: WidgetModel
    @Binding var customProperties: [String: Any]
    
    var body: some View {
        Group {
            switch widget.type {
            case .clock:
                ClockEditor(properties: $customProperties)
            case .weather:
                WeatherEditor(properties: $customProperties)
            case .music:
                MusicEditor(properties: $customProperties)
            case .systemStats:
                SystemStatsEditor(properties: $customProperties)
            case .notes:
                NotesEditor(properties: $customProperties)
            }
        }
    }
}

struct ClockEditor: View {
    @Binding var properties: [String: Any]
    @State private var showSeconds: Bool = false
    @State private var is24Hour: Bool = true
    @State private var isAnalog: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Show seconds", isOn: $showSeconds)
            Toggle("24-hour format", isOn: $is24Hour)
            Toggle("Analog display", isOn: $isAnalog)
        }
        .onAppear {
            loadProperties()
        }
        .onChange(of: showSeconds) { newValue in
            properties["showSeconds"] = newValue
        }
        .onChange(of: is24Hour) { newValue in
            properties["is24Hour"] = newValue
        }
        .onChange(of: isAnalog) { newValue in
            properties["isAnalog"] = newValue
        }
    }
    
    private func loadProperties() {
        showSeconds = properties["showSeconds"] as? Bool ?? false
        is24Hour = properties["is24Hour"] as? Bool ?? true
        isAnalog = properties["isAnalog"] as? Bool ?? false
    }
}

struct WeatherEditor: View {
    @Binding var properties: [String: Any]
    @State private var showDetails: Bool = true
    @State private var temperatureUnit: String = "C"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Show detailed info", isOn: $showDetails)
            
            HStack {
                Text("Temperature unit:")
                Picker("", selection: $temperatureUnit) {
                    Text("Celsius").tag("C")
                    Text("Fahrenheit").tag("F")
                }
                .pickerStyle(.menu)
            }
        }
        .onAppear {
            loadProperties()
        }
        .onChange(of: showDetails) { newValue in
            properties["showDetails"] = newValue
        }
        .onChange(of: temperatureUnit) { newValue in
            properties["temperatureUnit"] = newValue
        }
    }
    
    private func loadProperties() {
        showDetails = properties["showDetails"] as? Bool ?? true
        temperatureUnit = properties["temperatureUnit"] as? String ?? "C"
    }
}

struct MusicEditor: View {
    @Binding var properties: [String: Any]
    @State private var showControls: Bool = true
    @State private var showAlbumArt: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Show playback controls", isOn: $showControls)
            Toggle("Show album artwork", isOn: $showAlbumArt)
        }
        .onAppear {
            loadProperties()
        }
        .onChange(of: showControls) { newValue in
            properties["showControls"] = newValue
        }
        .onChange(of: showAlbumArt) { newValue in
            properties["showAlbumArt"] = newValue
        }
    }
    
    private func loadProperties() {
        showControls = properties["showControls"] as? Bool ?? true
        showAlbumArt = properties["showAlbumArt"] as? Bool ?? true
    }
}

struct SystemStatsEditor: View {
    @Binding var properties: [String: Any]
    @State private var showCPU: Bool = true
    @State private var showMemory: Bool = true
    @State private var showNetwork: Bool = true
    @State private var showBattery: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Show CPU usage", isOn: $showCPU)
            Toggle("Show memory usage", isOn: $showMemory)
            Toggle("Show network stats", isOn: $showNetwork)
            Toggle("Show battery info", isOn: $showBattery)
        }
        .onAppear {
            loadProperties()
        }
        .onChange(of: showCPU) { newValue in
            properties["showCPU"] = newValue
        }
        .onChange(of: showMemory) { newValue in
            properties["showMemory"] = newValue
        }
        .onChange(of: showNetwork) { newValue in
            properties["showNetwork"] = newValue
        }
        .onChange(of: showBattery) { newValue in
            properties["showBattery"] = newValue
        }
    }
    
    private func loadProperties() {
        showCPU = properties["showCPU"] as? Bool ?? true
        showMemory = properties["showMemory"] as? Bool ?? true
        showNetwork = properties["showNetwork"] as? Bool ?? true
        showBattery = properties["showBattery"] as? Bool ?? true
    }
}

struct NotesEditor: View {
    @Binding var properties: [String: Any]
    @State private var fontSize: Double = 14
    @State private var isEditable: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Font size:")
                Slider(value: $fontSize, in: 10...24, step: 1)
                Text("\(Int(fontSize))")
                    .frame(width: 30)
            }
            
            Toggle("Editable", isOn: $isEditable)
        }
        .onAppear {
            loadProperties()
        }
        .onChange(of: fontSize) { newValue in
            properties["fontSize"] = newValue
        }
        .onChange(of: isEditable) { newValue in
            properties["isEditable"] = newValue
        }
    }
    
    private func loadProperties() {
        fontSize = properties["fontSize"] as? Double ?? 14
        isEditable = properties["isEditable"] as? Bool ?? true
    }
}




