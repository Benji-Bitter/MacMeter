import SwiftUI
import Foundation

// MARK: - Notes Widget Model
class NotesWidgetModel: WidgetModel {
    @Published var text: String = ""
    @Published var fontSize: Double = 14
    @Published var isEditable: Bool = true
    @Published var lastSaved: Date = Date()
    
    private var saveTimer: Timer?
    
    override init(type: WidgetType = .notes, position: CGPoint, size: CGSize? = nil) {
        super.init(type: type, position: position, size: size)
        loadCustomProperties()
        loadSavedText()
        startAutoSave()
    }
    
    deinit {
        saveTimer?.invalidate()
    }
    
    override func updateData() {
        // Notes don't need external data updates
    }
    
    override func render() -> AnyView {
        return AnyView(NotesWidgetView(widget: self))
    }
    
    override func getDefaultSize() -> CGSize {
        return CGSize(width: 250, height: 200)
    }
    
    private func loadCustomProperties() {
        if let fontSize = customProperties["fontSize"] as? Double {
            self.fontSize = fontSize
        }
        if let isEditable = customProperties["isEditable"] as? Bool {
            self.isEditable = isEditable
        }
    }
    
    private func loadSavedText() {
        let key = "notes_\(id.uuidString)"
        if let savedText = UserDefaults.standard.string(forKey: key) {
            text = savedText
        } else {
            text = "Click to add notes..."
        }
    }
    
    private func startAutoSave() {
        saveTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.saveText()
        }
    }
    
    func saveText() {
        let key = "notes_\(id.uuidString)"
        UserDefaults.standard.set(text, forKey: key)
        lastSaved = Date()
    }
    
    func clearText() {
        text = ""
        saveText()
    }
}

// MARK: - Notes Widget View
struct NotesWidgetView: View {
    @ObservedObject var widget: NotesWidgetModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isEditing: Bool = false
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
            
            // Notes content
            VStack(spacing: 0) {
                // Header
                NotesHeaderView(widget: widget, animationPhase: animationPhase)
                
                // Text content
                NotesContentView(widget: widget, isEditing: $isEditing)
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
        return themeManager.getThemeForWidget(.notes, themeName: widget.theme)
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

// MARK: - Notes Header View
struct NotesHeaderView: View {
    @ObservedObject var widget: NotesWidgetModel
    let animationPhase: Double
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Image(systemName: "note.text")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(getAccentColor())
                .scaleEffect(1.0 + (animationPhase * 0.1))
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationPhase)
            
            Text("Notes")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(getPrimaryColor())
            
            Spacer()
            
            Text(timeAgoString(from: widget.lastSaved))
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(getPrimaryColor().opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(getAccentColor().opacity(0.1))
        )
    }
    
    private func getPrimaryColor() -> Color {
        let theme = themeManager.getThemeForWidget(.notes, themeName: widget.theme)
        return Color(hex: theme?.primaryColor ?? "#000000")
    }
    
    private func getAccentColor() -> Color {
        let theme = themeManager.getThemeForWidget(.notes, themeName: widget.theme)
        return Color(hex: theme?.accentColor ?? "#007AFF")
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        
        if minutes < 1 {
            return "now"
        } else if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            return "\(hours)h"
        }
    }
}

// MARK: - Notes Content View
struct NotesContentView: View {
    @ObservedObject var widget: NotesWidgetModel
    @Binding var isEditing: Bool
    @EnvironmentObject var themeManager: ThemeManager
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if widget.isEditable {
                TextEditor(text: $widget.text)
                    .font(.system(size: CGFloat(widget.fontSize), weight: .regular))
                    .foregroundColor(getPrimaryColor())
                    .background(Color.clear)
                    .focused($isTextFieldFocused)
                    .onChange(of: widget.text) { _ in
                        widget.saveText()
                    }
                    .onTapGesture {
                        isEditing = true
                        isTextFieldFocused = true
                    }
            } else {
                ScrollView {
                    Text(widget.text)
                        .font(.system(size: CGFloat(widget.fontSize), weight: .regular))
                        .foregroundColor(getPrimaryColor())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
            
            // Footer with actions
            if widget.isEditable {
                NotesFooterView(widget: widget)
            }
        }
    }
    
    private func getPrimaryColor() -> Color {
        let theme = themeManager.getThemeForWidget(.notes, themeName: widget.theme)
        return Color(hex: theme?.primaryColor ?? "#000000")
    }
}

// MARK: - Notes Footer View
struct NotesFooterView: View {
    @ObservedObject var widget: NotesWidgetModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text("\(widget.text.count) characters")
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(getAccentColor().opacity(0.7))
            
            Spacer()
            
            Button(action: {
                widget.clearText()
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Rectangle()
                .fill(getAccentColor().opacity(0.05))
        )
    }
    
    private func getAccentColor() -> Color {
        let theme = themeManager.getThemeForWidget(.notes, themeName: widget.theme)
        return Color(hex: theme?.accentColor ?? "#007AFF")
    }
}

