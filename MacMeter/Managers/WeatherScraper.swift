import Foundation
import CoreLocation
import Combine

// MARK: - Weather Data Models
struct WeatherData: Codable {
    let temperature: Double
    let condition: String
    let icon: String
    let humidity: Double
    let windSpeed: Double
    let location: String
    let lastUpdated: Date
    
    init(temperature: Double, condition: String, icon: String, humidity: Double = 0, windSpeed: Double = 0, location: String = "Unknown") {
        self.temperature = temperature
        self.condition = condition
        self.icon = icon
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.location = location
        self.lastUpdated = Date()
    }
}

// MARK: - Weather Scraper
class WeatherScraper: NSObject, ObservableObject {
    @Published var currentWeather: WeatherData?
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 900 // 15 minutes
    
    override init() {
        super.init()
        setupLocationManager()
        startLocationUpdates()
    }
    
    deinit {
        updateTimer?.invalidate()
    }
    
    // MARK: - Location Management
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func startLocationUpdates() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        } else {
            // Fallback to default location (San Francisco)
            fetchWeatherForLocation(latitude: 37.7749, longitude: -122.4194, locationName: "San Francisco")
        }
    }
    
    // MARK: - Weather Fetching
    func fetchWeatherForLocation(latitude: Double, longitude: Double, locationName: String) {
        isLoading = true
        error = nil
        
        // Try multiple weather sources
        fetchFromWttrIn(latitude: latitude, longitude: longitude, locationName: locationName)
    }
    
    private func fetchFromWttrIn(latitude: Double, longitude: Double, locationName: String) {
        let urlString = "https://wttr.in/\(latitude),\(longitude)?format=j1"
        
        guard let url = URL(string: urlString) else {
            handleError("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.handleError("Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    self?.handleError("No data received")
                    return
                }
                
                self?.parseWttrInData(data, locationName: locationName)
            }
        }.resume()
    }
    
    private func parseWttrInData(_ data: Data, locationName: String) {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let current = json?["current_condition"] as? [[String: Any]],
                  let weather = current.first else {
                handleError("Invalid weather data format")
                return
            }
            
            let tempC = weather["temp_C"] as? String ?? "0"
            let condition = weather["weatherDesc"] as? [[String: Any]] ?? []
            let conditionText = condition.first?["value"] as? String ?? "Unknown"
            let humidity = weather["humidity"] as? String ?? "0"
            let windSpeed = weather["windspeedKmph"] as? String ?? "0"
            
            let weatherData = WeatherData(
                temperature: Double(tempC) ?? 0,
                condition: conditionText,
                icon: getWeatherIcon(for: conditionText),
                humidity: Double(humidity) ?? 0,
                windSpeed: Double(windSpeed) ?? 0,
                location: locationName
            )
            
            self.currentWeather = weatherData
            self.error = nil
            
        } catch {
            handleError("Failed to parse weather data: \(error.localizedDescription)")
        }
    }
    
    private func getWeatherIcon(for condition: String) -> String {
        let conditionLower = condition.lowercased()
        
        if conditionLower.contains("sun") || conditionLower.contains("clear") {
            return "sun.max.fill"
        } else if conditionLower.contains("cloud") {
            return "cloud.fill"
        } else if conditionLower.contains("rain") {
            return "cloud.rain.fill"
        } else if conditionLower.contains("snow") {
            return "cloud.snow.fill"
        } else if conditionLower.contains("storm") || conditionLower.contains("thunder") {
            return "cloud.bolt.fill"
        } else if conditionLower.contains("fog") || conditionLower.contains("mist") {
            return "cloud.fog.fill"
        } else {
            return "questionmark.circle.fill"
        }
    }
    
    private func handleError(_ message: String) {
        error = message
        print("WeatherScraper Error: \(message)")
    }
    
    // MARK: - Auto Update
    func startAutoUpdate() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            if let location = self?.currentLocation {
                self?.fetchWeatherForLocation(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    locationName: "Current Location"
                )
            }
        }
    }
    
    func stopAutoUpdate() {
        updateTimer?.invalidate()
    }
    
    // MARK: - Manual Refresh
    func refreshWeather() {
        if let location = currentLocation {
            fetchWeatherForLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                locationName: "Current Location"
            )
        } else {
            // Fallback to default location if no current location
            fetchWeatherForLocation(latitude: 37.7749, longitude: -122.4194, locationName: "San Francisco")
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension WeatherScraper: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        
        // Fetch weather for the new location
        fetchWeatherForLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            locationName: "Current Location"
        )
        
        // Start auto-updates
        startAutoUpdate()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        // Fallback to default location
        fetchWeatherForLocation(latitude: 37.7749, longitude: -122.4194, locationName: "San Francisco")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            // Use default location
            fetchWeatherForLocation(latitude: 37.7749, longitude: -122.4194, locationName: "San Francisco")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}