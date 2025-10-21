import SwiftUI

@main
struct MacMeterApp: App {
    @StateObject private var widgetManager = WidgetManager()
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            DesktopView()
                .environmentObject(widgetManager)
                .environmentObject(themeManager)
                .frame(minWidth: 1200, minHeight: 800)
                .background(Color.clear)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        // Menu bar for quick access
        MenuBarExtra("MacMeter", systemImage: "widget.and.arrow.forward") {
            MenuBarView()
                .environmentObject(widgetManager)
                .environmentObject(themeManager)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarView: View {
    @EnvironmentObject var widgetManager: WidgetManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingSettings = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Toggle Edit Mode") {
                widgetManager.toggleEditMode()
            }
            
            Button("Add Widget") {
                widgetManager.showWidgetMenu = true
            }
            
            Divider()
            
            Button("Settings") {
                showingSettings = true
            }
            
            Button("Quit MacMeter") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 200)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(widgetManager)
                .environmentObject(themeManager)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var widgetManager: WidgetManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("MacMeter Settings")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Auto-launch on login", isOn: $widgetManager.autoLaunch)
                
                Toggle("Snap to grid", isOn: $widgetManager.snapToGrid)
                
                HStack {
                    Text("Update interval:")
                    Spacer()
                    Picker("", selection: $widgetManager.updateInterval) {
                        Text("5s").tag(5.0)
                        Text("15s").tag(15.0)
                        Text("30s").tag(30.0)
                        Text("1m").tag(60.0)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 80)
                }
            }
            
            Spacer()
            
            HStack {
                Button("Export Layout") {
                    widgetManager.exportLayout()
                }
                
                Button("Import Layout") {
                    widgetManager.importLayout()
                }
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}
