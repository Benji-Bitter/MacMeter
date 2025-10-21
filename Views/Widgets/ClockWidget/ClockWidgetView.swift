import SwiftUI
import Foundation

// MARK: - Clock Widget Model
class ClockWidgetModel: WidgetModel {
    @Published var currentTime: Date = Date()
    @Published var showSeconds: Bool = false
    @Published var is24Hour: Bool = true
    @Published var isAnalog: Bool = false
    
    private var timer: Timer?
    
    override init(type: WidgetType = .clock, position: CGPoint, size: CGSize? = nil) {
        super.init(type: type, position: position, size: size)
        startTimer()
        loadCustomProperties()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    override func updateData() {
        currentTime = Date()
    }
    
    override func render() -> AnyView {
        return AnyView(ClockWidgetView(widget: self))
    }
    
    override func getDefaultSize() -> CGSize {
        return CGSize(width: 200, height: 200)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.currentTime = Date()
        }
    }
    
    private func loadCustomProperties() {
        if let showSeconds = customProperties["showSeconds"] as? Bool {
            self.showSeconds = showSeconds
        }
        if let is24Hour = customProperties["is24Hour"] as? Bool {
            self.is24Hour = is24Hour
        }
        if let isAnalog = customProperties["isAnalog"] as? Bool {
            self.isAnalog = isAnalog
        }
    }
}

// MARK: - Clock Widget View
struct ClockWidgetView: View {
    @ObservedObject var widget: ClockWidgetModel
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
            
            // Clock content
            if widget.isAnalog {
                AnalogClockView(widget: widget, animationPhase: animationPhase)
            } else {
                DigitalClockView(widget: widget, animationPhase: animationPhase)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                animationPhase = 1
            }
        }
    }
    
    // MARK: - Theme Helpers
    private func getTheme() -> ThemeModel? {
        return themeManager.getThemeForWidget(.clock, themeName: widget.theme)
    }
    
    private func getCornerRadius() -> CGFloat {
        return CGFloat(getTheme()?.cornerRadius ?? 12)
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
    
    private func getPrimaryColor() -> Color {
        return Color(hex: getTheme()?.primaryColor ?? "#FFFFFF")
    }
    
    private func getAccentColor() -> Color {
        return Color(hex: getTheme()?.accentColor ?? "#00BFFF")
    }
}

// MARK: - Digital Clock View
struct DigitalClockView: View {
    @ObservedObject var widget: ClockWidgetModel
    let animationPhase: Double
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            // Time
            Text(formattedTime)
                .font(.system(size: 32, weight: .light, design: .rounded))
                .foregroundColor(getPrimaryColor())
                .shadow(color: .black.opacity(getTextShadowOpacity()), radius: 2, x: 1, y: 1)
                .animation(.easeInOut(duration: 0.5), value: widget.currentTime)
            
            // Date
            Text(formattedDate)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(getAccentColor())
                .opacity(0.8)
        }
        .padding()
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = widget.is24Hour ? "HH:mm" : "h:mm a"
        if widget.showSeconds {
            formatter.dateFormat = widget.is24Hour ? "HH:mm:ss" : "h:mm:ss a"
        }
        return formatter.string(from: widget.currentTime)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: widget.currentTime)
    }
    
    private func getPrimaryColor() -> Color {
        let theme = themeManager.getThemeForWidget(.clock, themeName: widget.theme)
        return Color(hex: theme?.primaryColor ?? "#FFFFFF")
    }
    
    private func getAccentColor() -> Color {
        let theme = themeManager.getThemeForWidget(.clock, themeName: widget.theme)
        return Color(hex: theme?.accentColor ?? "#00BFFF")
    }
    
    private func getTextShadowOpacity() -> Double {
        let theme = themeManager.getThemeForWidget(.clock, themeName: widget.theme)
        return theme?.textShadow == true ? 0.5 : 0
    }
}

// MARK: - Analog Clock View
struct AnalogClockView: View {
    @ObservedObject var widget: ClockWidgetModel
    let animationPhase: Double
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // Clock face
            Circle()
                .stroke(getPrimaryColor().opacity(0.3), lineWidth: 2)
                .frame(width: 160, height: 160)
            
            // Hour markers
            ForEach(1...12, id: \.self) { hour in
                Rectangle()
                    .fill(getPrimaryColor())
                    .frame(width: 2, height: hour % 3 == 0 ? 12 : 6)
                    .offset(y: -70)
                    .rotationEffect(.degrees(Double(hour) * 30))
            }
            
            // Hour hand
            Rectangle()
                .fill(getPrimaryColor())
                .frame(width: 4, height: 40)
                .offset(y: -20)
                .rotationEffect(.degrees(hourAngle))
            
            // Minute hand
            Rectangle()
                .fill(getAccentColor())
                .frame(width: 3, height: 60)
                .offset(y: -30)
                .rotationEffect(.degrees(minuteAngle))
            
            // Second hand
            if widget.showSeconds {
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 1, height: 70)
                    .offset(y: -35)
                    .rotationEffect(.degrees(secondAngle))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: widget.currentTime)
            }
            
            // Center dot
            Circle()
                .fill(getPrimaryColor())
                .frame(width: 8, height: 8)
        }
    }
    
    private var hourAngle: Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: widget.currentTime)
        let minute = calendar.component(.minute, from: widget.currentTime)
        return Double(hour % 12) * 30 + Double(minute) * 0.5
    }
    
    private var minuteAngle: Double {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: widget.currentTime)
        return Double(minute) * 6
    }
    
    private var secondAngle: Double {
        let calendar = Calendar.current
        let second = calendar.component(.second, from: widget.currentTime)
        return Double(second) * 6
    }
    
    private func getPrimaryColor() -> Color {
        let theme = themeManager.getThemeForWidget(.clock, themeName: widget.theme)
        return Color(hex: theme?.primaryColor ?? "#FFFFFF")
    }
    
    private func getAccentColor() -> Color {
        let theme = themeManager.getThemeForWidget(.clock, themeName: widget.theme)
        return Color(hex: theme?.accentColor ?? "#00BFFF")
    }
}

