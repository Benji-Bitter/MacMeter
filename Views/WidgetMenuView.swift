import SwiftUI

struct WidgetMenuView: View {
    @EnvironmentObject var widgetManager: WidgetManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Widget")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    widgetManager.showWidgetMenu = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(.ultraThinMaterial)
            
            // Widget options
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(WidgetType.allCases, id: \.self) { widgetType in
                    WidgetOptionCard(widgetType: widgetType)
                }
            }
            .padding()
        }
        .frame(width: 300, height: 400)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 20)
    }
}

struct WidgetOptionCard: View {
    let widgetType: WidgetType
    @EnvironmentObject var widgetManager: WidgetManager
    
    var body: some View {
        Button(action: {
            addWidget()
        }) {
            VStack(spacing: 8) {
                Image(systemName: widgetType.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.primary)
                
                Text(widgetType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
    
    private func addWidget() {
        let centerPosition = CGPoint(x: 400, y: 300)
        widgetManager.addWidget(widgetType, at: centerPosition)
        widgetManager.showWidgetMenu = false
    }
}

struct WidgetCustomizationView: View {
    let widget: WidgetModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTheme: String
    @State private var customProperties: [String: Any]
    
    init(widget: WidgetModel) {
        self.widget = widget
        self._selectedTheme = State(initialValue: widget.theme)
        self._customProperties = State(initialValue: widget.customProperties)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Customize \(widget.type.displayName)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Theme selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Theme")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(widget.getAvailableThemes(), id: \.self) { themeName in
                        ThemeOptionCard(
                            themeName: themeName,
                            isSelected: selectedTheme == themeName,
                            action: {
                                selectedTheme = themeName
                                widget.applyTheme(themeName)
                            }
                        )
                    }
                }
            }
            
            // Custom properties based on widget type
            WidgetSpecificCustomization(widget: widget, customProperties: $customProperties)
            
            Spacer()
        }
        .padding()
        .frame(width: 500, height: 600)
    }
}

struct ThemeOptionCard: View {
    let themeName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(height: 40)
                
                Text(themeName)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

struct WidgetSpecificCustomization: View {
    let widget: WidgetModel
    @Binding var customProperties: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Customization")
                .font(.headline)
            
            switch widget.type {
            case .clock:
                ClockCustomizationView(properties: $customProperties)
            case .weather:
                WeatherCustomizationView(properties: $customProperties)
            case .music:
                MusicCustomizationView(properties: $customProperties)
            case .systemStats:
                SystemStatsCustomizationView(properties: $customProperties)
            case .notes:
                NotesCustomizationView(properties: $customProperties)
            }
        }
    }
}

struct ClockCustomizationView: View {
    @Binding var properties: [String: Any]
    @State private var showSeconds: Bool = false
    @State private var is24Hour: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Show seconds", isOn: $showSeconds)
            Toggle("24-hour format", isOn: $is24Hour)
        }
        .onChange(of: showSeconds) { newValue in
            properties["showSeconds"] = newValue
        }
        .onChange(of: is24Hour) { newValue in
            properties["is24Hour"] = newValue
        }
    }
}

struct WeatherCustomizationView: View {
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
        .onChange(of: showDetails) { newValue in
            properties["showDetails"] = newValue
        }
        .onChange(of: temperatureUnit) { newValue in
            properties["temperatureUnit"] = newValue
        }
    }
}

struct MusicCustomizationView: View {
    @Binding var properties: [String: Any]
    @State private var showControls: Bool = true
    @State private var showAlbumArt: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Show playback controls", isOn: $showControls)
            Toggle("Show album artwork", isOn: $showAlbumArt)
        }
        .onChange(of: showControls) { newValue in
            properties["showControls"] = newValue
        }
        .onChange(of: showAlbumArt) { newValue in
            properties["showAlbumArt"] = newValue
        }
    }
}

struct SystemStatsCustomizationView: View {
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
}

struct NotesCustomizationView: View {
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
        .onChange(of: fontSize) { newValue in
            properties["fontSize"] = newValue
        }
        .onChange(of: isEditable) { newValue in
            properties["isEditable"] = newValue
        }
    }
}
