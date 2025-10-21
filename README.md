# MacMeter

**MacMeter** is a next-generation desktop widget engine for macOS, built natively with Swift and SwiftUI. It provides a beautiful, customizable alternative to Rainmeter, allowing users to add, edit, style, and move widgets directly on their desktop without any coding required.

![MacMeter Demo](https://via.placeholder.com/800x400/1a1a1a/ffffff?text=MacMeter+Desktop+Widgets)

## ✨ Features

### 🧩 Widget System
- **5 Pre-built Widgets**: Clock, Weather, Music Player, System Stats, and Notes
- **Real-time Updates**: Live data updates with customizable intervals
- **Drag & Drop**: Easy widget positioning and resizing
- **Edit Mode**: Visual editing with snap-to-grid support
- **Theme System**: 5 unique themes per widget type

### 🎨 Customization
- **Visual Theme Editor**: Change colors, fonts, transparency, and effects
- **JSON-based Themes**: Easy theme creation and sharing
- **Live Preview**: See changes instantly
- **Export/Import**: Share layouts and themes with others

### 🖥️ macOS Integration
- **Native Performance**: Built with SwiftUI for optimal performance
- **Menu Bar Access**: Quick access to settings and controls
- **Auto-launch**: Start with your Mac
- **Keyboard Shortcuts**: Power user features

## 🚀 Getting Started

### Requirements
- macOS 13.0 (Sonoma) or later
- Xcode 15.0 or later (for building from source)
- Swift 5.9 or later

### Installation

#### Option 1: Download from Releases
1. Download the latest release from the [Releases page](https://github.com/yourusername/MacMeter/releases)
2. Drag MacMeter.app to your Applications folder
3. Launch MacMeter from Applications or Spotlight

#### Option 2: Build from Source
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/MacMeter.git
   cd MacMeter
   ```

2. Open the project in Xcode:
   ```bash
   open MacMeter.xcodeproj
   ```

3. Build and run the project (⌘+R)

### First Launch
1. Launch MacMeter
2. Click the menu bar icon to access the widget menu
3. Add your first widget by clicking "Add Widget"
4. Choose from Clock, Weather, Music, System Stats, or Notes
5. Drag widgets to position them on your desktop
6. Press 'E' to enter edit mode for advanced customization

## 📱 Available Widgets

### 🕒 Clock Widget
- **Digital & Analog**: Choose your preferred display style
- **Customizable Format**: 12/24 hour, with/without seconds
- **5 Themes**: LiquidGlass, Minimal, DigitalNeon, ClassicAnalog, RetroFlip

### 🌤️ Weather Widget
- **Real-time Data**: Automatic location detection and weather updates
- **Detailed Info**: Temperature, conditions, humidity, wind speed
- **5 Themes**: Glass, Minimal, Gradient, Dark, Retro

### 🎵 Music Widget
- **Apple Music Integration**: Display currently playing tracks
- **Playback Controls**: Play, pause, skip, previous
- **Album Artwork**: Beautiful album art display
- **5 Themes**: Glass, Minimal, Neon, Dark, Retro

### 💻 System Stats Widget
- **Real-time Monitoring**: CPU, Memory, Network, Battery
- **Customizable Display**: Show/hide individual stats
- **5 Themes**: ModernGlass, Terminal, Radar, FlatColor, Vaporwave

### 📝 Notes Widget
- **Sticky Notes**: Quick note-taking on your desktop
- **Auto-save**: Never lose your notes
- **Editable**: Click to edit, right-click for options
- **5 Themes**: Glass, Minimal, Paper, Dark, Colorful

## 🎨 Theme System

Each widget comes with 5 pre-built themes, and you can create custom themes by editing JSON files:

```json
{
  "name": "CustomTheme",
  "background": "ultraThinMaterial",
  "font": "SF Pro Rounded",
  "primaryColor": "#FFFFFF",
  "accentColor": "#00BFFF",
  "blurRadius": 20,
  "shadowOpacity": 0.4,
  "cornerRadius": 12,
  "textShadow": true,
  "animationSpeed": 1.0
}
```

### Theme Properties
- **background**: Material type (ultraThinMaterial, thinMaterial, regularMaterial, thickMaterial)
- **font**: Font family name
- **primaryColor**: Main text color (hex format)
- **accentColor**: Accent color for highlights (hex format)
- **blurRadius**: Background blur amount
- **shadowOpacity**: Shadow intensity
- **cornerRadius**: Corner rounding
- **textShadow**: Enable/disable text shadows
- **animationSpeed**: Animation timing multiplier

## ⌨️ Keyboard Shortcuts

- **E**: Toggle edit mode
- **A**: Show widget menu
- **H**: Hide/show all widgets
- **R**: Reset to default layout
- **⌘+Q**: Quit MacMeter

## 🛠️ Development

### Project Structure
```
MacMeter/
├── MacMeterApp.swift          # Main app entry point
├── Models/                    # Data models and protocols
│   ├── WidgetProtocol.swift   # Widget interface
│   ├── WidgetModel.swift      # Base widget model
│   └── ThemeModel.swift       # Theme data model
├── Managers/                  # Core managers
│   ├── WidgetManager.swift    # Widget lifecycle management
│   └── WeatherScraper.swift   # Weather data fetching
├── Views/                     # SwiftUI views
│   ├── DesktopView.swift      # Main desktop view
│   ├── WidgetMenuView.swift   # Widget selection menu
│   └── Widgets/               # Individual widget views
├── Extensions/                # Swift extensions
├── Utils/                     # Utility classes
└── Resources/                 # Assets and themes
```

### Architecture
MacMeter follows the **MVVM (Model-View-ViewModel)** pattern:

- **Models**: Data structures and business logic
- **Views**: SwiftUI user interface components
- **ViewModels**: Observable objects that manage view state
- **Managers**: Singleton services for cross-cutting concerns

### Adding New Widgets

1. Create a new widget model class inheriting from `WidgetModel`
2. Implement the required protocol methods
3. Create a SwiftUI view for the widget
4. Add the widget type to the `WidgetType` enum
5. Update the `WidgetFactory` to handle the new type

Example:
```swift
class CustomWidgetModel: WidgetModel {
    override init(type: WidgetType = .custom, position: CGPoint, size: CGSize? = nil) {
        super.init(type: type, position: position, size: size)
    }
    
    override func render() -> AnyView {
        return AnyView(CustomWidgetView(widget: self))
    }
}
```

### Creating Custom Themes

1. Create a JSON file in the appropriate theme directory
2. Follow the theme schema defined in `ThemeModel`
3. Use the theme in your widget by calling `themeManager.getThemeForWidget()`

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Add tests if applicable
5. Commit your changes: `git commit -m 'Add amazing feature'`
6. Push to the branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftUI best practices
- Add documentation for public APIs
- Write unit tests for business logic

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by [Rainmeter](https://www.rainmeter.net/) for Windows
- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Weather data provided by [wttr.in](https://wttr.in/)
- Icons from [SF Symbols](https://developer.apple.com/sf-symbols/)

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/MacMeter/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/MacMeter/discussions)
- **Email**: support@macmeter.app

## 🗺️ Roadmap

### Version 1.1
- [ ] Additional widget types (Calendar, RSS, Stocks)
- [ ] Widget animations and transitions
- [ ] Custom widget creation tool
- [ ] Widget marketplace

### Version 1.2
- [ ] Multi-monitor support
- [ ] Widget groups and folders
- [ ] Advanced theming with gradients
- [ ] Widget scripting support

### Version 2.0
- [ ] Plugin system for third-party widgets
- [ ] Cloud sync for layouts and themes
- [ ] Widget sharing platform
- [ ] Advanced customization options

---

**Made with ❤️ for the macOS community**




