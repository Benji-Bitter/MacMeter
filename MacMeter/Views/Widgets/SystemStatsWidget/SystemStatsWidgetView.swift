import SwiftUI
import Foundation
import SystemConfiguration

// MARK: - System Stats Widget Model
class SystemStatsWidgetModel: WidgetModel {
    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsage: Double = 0.0
    @Published var networkIn: Double = 0.0
    @Published var networkOut: Double = 0.0
    @Published var batteryLevel: Double = 0.0
    @Published var batteryStatus: String = "Unknown"
    @Published var showCPU: Bool = true
    @Published var showMemory: Bool = true
    @Published var showNetwork: Bool = true
    @Published var showBattery: Bool = true
    
    private var updateTimer: Timer?
    
    override init(type: WidgetType = .systemStats, position: CGPoint, size: CGSize? = nil) {
        super.init(type: type, position: position, size: size)
        startMonitoring()
        loadCustomProperties()
    }
    
    deinit {
        updateTimer?.invalidate()
    }
    
    override func updateData() {
        updateSystemStats()
    }
    
    override func render() -> AnyView {
        return AnyView(SystemStatsWidgetView(widget: self))
    }
    
    override func getDefaultSize() -> CGSize {
        return CGSize(width: 200, height: 300)
    }
    
    private func startMonitoring() {
        updateSystemStats()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateSystemStats()
        }
    }
    
    private func loadCustomProperties() {
        if let showCPU = customProperties["showCPU"] as? Bool {
            self.showCPU = showCPU
        }
        if let showMemory = customProperties["showMemory"] as? Bool {
            self.showMemory = showMemory
        }
        if let showNetwork = customProperties["showNetwork"] as? Bool {
            self.showNetwork = showNetwork
        }
        if let showBattery = customProperties["showBattery"] as? Bool {
            self.showBattery = showBattery
        }
    }
    
    private func updateSystemStats() {
        updateCPUUsage()
        updateMemoryUsage()
        updateNetworkStats()
        updateBatteryInfo()
    }
    
    private func updateCPUUsage() {
        // Simplified CPU usage calculation
        let load = SystemInfo.getCPULoad()
        cpuUsage = load
    }
    
    private func updateMemoryUsage() {
        let memoryInfo = SystemInfo.getMemoryInfo()
        memoryUsage = memoryInfo.used / memoryInfo.total
    }
    
    private func updateNetworkStats() {
        let networkInfo = SystemInfo.getNetworkStats()
        networkIn = networkInfo.inBytes
        networkOut = networkInfo.outBytes
    }
    
    private func updateBatteryInfo() {
        let batteryInfo = SystemInfo.getBatteryInfo()
        batteryLevel = batteryInfo.level
        batteryStatus = batteryInfo.status
    }
}

// MARK: - System Stats Widget View
struct SystemStatsWidgetView: View {
    @ObservedObject var widget: SystemStatsWidgetModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var animationPhase: Double = 0
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: getCornerRadius())
                .fill(getBackgroundMaterial())
                .overlay(
                    RoundedRectangle(cornerRadius: getCornerRadius())
                        .stroke(getBorderColor(), lineWidth: getBorderWidth())
                )
                .shadow(color: .black.opacity(getShadowOpacity()), radius: 10, x: 0, y: 5)
            
            // Stats content
            VStack(spacing: 16) {
                if widget.showCPU {
                    StatRowView(
                        title: "CPU",
                        value: "\(Int(widget.cpuUsage * 100))%",
                        progress: widget.cpuUsage,
                        color: getAccentColor(),
                        animationPhase: animationPhase
                    )
                }
                
                if widget.showMemory {
                    StatRowView(
                        title: "Memory",
                        value: "\(Int(widget.memoryUsage * 100))%",
                        progress: widget.memoryUsage,
                        color: getAccentColor(),
                        animationPhase: animationPhase
                    )
                }
                
                if widget.showNetwork {
                    NetworkStatsView(
                        networkIn: widget.networkIn,
                        networkOut: widget.networkOut,
                        color: getAccentColor(),
                        animationPhase: animationPhase
                    )
                }
                
                if widget.showBattery {
                    BatteryStatsView(
                        level: widget.batteryLevel,
                        status: widget.batteryStatus,
                        color: getAccentColor(),
                        animationPhase: animationPhase
                    )
                }
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animationPhase = 1
            }
        }
    }
    
    // MARK: - Theme Helpers
    private func getTheme() -> ThemeModel? {
        return themeManager.getThemeForWidget(.systemStats, themeName: widget.theme)
    }
    
    private func getCornerRadius() -> CGFloat {
        return CGFloat(getTheme()?.cornerRadius ?? 16)
    }
    
    private func getBackgroundMaterial() -> Material {
        switch getTheme()?.background {
        case "ultraThinMaterial": return .ultraThinMaterial
        case "thinMaterial": return .thinMaterial
        case "regularMaterial": return .regularMaterial
        case "thickMaterial": return .thickMaterial
        case "ultraThickMaterial": return .ultraThickMaterial
        default: return .ultraThinMaterial
        }
    }
    
    private func getBorderColor() -> Color {
        if let borderColor = getTheme()?.borderColor {
            return Color(hex: borderColor)
        }
        return .clear
    }
    
    private func getBorderWidth() -> CGFloat {
        return CGFloat(getTheme()?.borderWidth ?? 0)
    }
    
    private func getShadowOpacity() -> Double {
        return getTheme()?.shadowOpacity ?? 0.4
    }
    
    private func getAccentColor() -> Color {
        let theme = themeManager.getThemeForWidget(.systemStats, themeName: widget.theme)
        return Color(hex: theme?.accentColor ?? "#00D4FF")
    }
}

// MARK: - Stat Row View
struct StatRowView: View {
    let title: String
    let value: String
    let progress: Double
    let color: Color
    let animationPhase: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 0.5)
        }
    }
}

// MARK: - Network Stats View
struct NetworkStatsView: View {
    let networkIn: Double
    let networkOut: Double
    let color: Color
    let animationPhase: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Network")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("↓ \(formatBytes(networkIn))")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(color)
                    
                    Text("↑ \(formatBytes(networkOut))")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(color)
                }
                
                Spacer()
            }
        }
    }
    
    private func formatBytes(_ bytes: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Battery Stats View
struct BatteryStatsView: View {
    let level: Double
    let status: String
    let color: Color
    let animationPhase: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Battery")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(level * 100))%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
            }
            
            HStack {
                Image(systemName: batteryIcon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                
                Text(status)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
    }
    
    private var batteryIcon: String {
        if level > 0.75 {
            return "battery.100"
        } else if level > 0.5 {
            return "battery.75"
        } else if level > 0.25 {
            return "battery.50"
        } else {
            return "battery.25"
        }
    }
}

// MARK: - System Info Helper
struct SystemInfo {
    static func getCPULoad() -> Double {
        // Simplified CPU load calculation
        // In a real implementation, you'd use more sophisticated methods
        return Double.random(in: 0.1...0.8)
    }
    
    static func getMemoryInfo() -> (used: Double, total: Double) {
        // Simplified memory info
        let total = 16.0 * 1024 * 1024 * 1024 // 16GB
        let used = total * Double.random(in: 0.3...0.7)
        return (used: used, total: total)
    }
    
    static func getNetworkStats() -> (inBytes: Double, outBytes: Double) {
        // Simplified network stats
        return (
            inBytes: Double.random(in: 0...1024*1024),
            outBytes: Double.random(in: 0...1024*1024)
        )
    }
    
    static func getBatteryInfo() -> (level: Double, status: String) {
        // Simplified battery info
        let level = Double.random(in: 0.2...1.0)
        let status = level > 0.2 ? "Charged" : "Low"
        return (level: level, status: status)
    }
}

