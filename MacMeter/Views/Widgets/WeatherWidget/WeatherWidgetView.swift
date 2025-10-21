import SwiftUI
import Foundation

// MARK: - Weather Widget Model
class WeatherWidgetModel: WidgetModel {
    @Published var weatherData: WeatherData?
    @Published var isLoading: Bool = false
    @Published var showDetails: Bool = true
    @Published var temperatureUnit: String = "C"
    
    private let weatherScraper = WeatherScraper()
    private var cancellables = Set<AnyCancellable>()
    
    override init(type: WidgetType = .weather, position: CGPoint, size: CGSize? = nil) {
        super.init(type: type, position: position, size: size)
        setupWeatherScraper()
        loadCustomProperties()
    }
    
    override func updateData() {
        weatherScraper.refreshWeather()
    }
    
    override func render() -> AnyView {
        return AnyView(WeatherWidgetView(widget: self))
    }
    
    override func getDefaultSize() -> CGSize {
        return CGSize(width: 250, height: 150)
    }
    
    private func setupWeatherScraper() {
        weatherScraper.$currentWeather
            .assign(to: \.weatherData, on: self)
            .store(in: &cancellables)
        
        weatherScraper.$isLoading
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
    }
    
    private func loadCustomProperties() {
        if let showDetails = customProperties["showDetails"] as? Bool {
            self.showDetails = showDetails
        }
        if let temperatureUnit = customProperties["temperatureUnit"] as? String {
            self.temperatureUnit = temperatureUnit
        }
    }
    
    func formattedTemperature(_ temp: Double) -> String {
        if temperatureUnit == "F" {
            let fahrenheit = (temp * 9/5) + 32
            return "\(Int(fahrenheit))°F"
        } else {
            return "\(Int(temp))°C"
        }
    }
}

// MARK: - Weather Widget View
struct WeatherWidgetView: View {
    @ObservedObject var widget: WeatherWidgetModel
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
            
            // Weather content
            if widget.isLoading {
                LoadingView()
            } else if let weather = widget.weatherData {
                WeatherContentView(weather: weather, widget: widget, animationPhase: animationPhase)
            } else {
                ErrorView()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animationPhase = 1
            }
        }
    }
    
    // MARK: - Theme Helpers
    private func getTheme() -> ThemeModel? {
        return themeManager.getThemeForWidget(.weather, themeName: widget.theme)
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
}

// MARK: - Weather Content View
struct WeatherContentView: View {
    let weather: WeatherData
    @ObservedObject var widget: WeatherWidgetModel
    let animationPhase: Double
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Location and condition
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(weather.location)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(getPrimaryColor().opacity(0.8))
                    
                    Text(weather.condition)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(getAccentColor())
                }
                
                Spacer()
                
                // Weather icon
                Image(systemName: weather.icon)
                    .font(.system(size: 32))
                    .foregroundColor(getAccentColor())
                    .scaleEffect(1.0 + (animationPhase * 0.1))
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationPhase)
            }
            
            // Temperature
            HStack(alignment: .top) {
                Text(widget.formattedTemperature(weather.temperature))
                    .font(.system(size: 36, weight: .light, design: .rounded))
                    .foregroundColor(getPrimaryColor())
                    .shadow(color: .black.opacity(getTextShadowOpacity()), radius: 2, x: 1, y: 1)
                
                Spacer()
                
                if widget.showDetails {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(weather.humidity))%")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(getAccentColor())
                        
                        Text("\(Int(weather.windSpeed)) km/h")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(getAccentColor())
                    }
                }
            }
            
            // Last updated
            Text("Updated \(timeAgoString(from: weather.lastUpdated))")
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(getPrimaryColor().opacity(0.6))
        }
        .padding()
    }
    
    private func getPrimaryColor() -> Color {
        let theme = themeManager.getThemeForWidget(.weather, themeName: widget.theme)
        return Color(hex: theme?.primaryColor ?? "#FFFFFF")
    }
    
    private func getAccentColor() -> Color {
        let theme = themeManager.getThemeForWidget(.weather, themeName: widget.theme)
        return Color(hex: theme?.accentColor ?? "#87CEEB")
    }
    
    private func getTextShadowOpacity() -> Double {
        let theme = themeManager.getThemeForWidget(.weather, themeName: widget.theme)
        return theme?.textShadow == true ? 0.5 : 0
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        
        if minutes < 1 {
            return "just now"
        } else if minutes < 60 {
            return "\(minutes)m ago"
        } else {
            let hours = minutes / 60
            return "\(hours)h ago"
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "cloud.sun")
                .font(.system(size: 32))
                .foregroundColor(.blue)
                .rotationEffect(.degrees(rotationAngle))
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: rotationAngle)
            
            Text("Loading weather...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .onAppear {
            rotationAngle = 360
        }
    }
}

// MARK: - Error View
struct ErrorView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            Text("Weather unavailable")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

