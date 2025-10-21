import SwiftUI

struct DesktopView: View {
    @EnvironmentObject var widgetManager: WidgetManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var draggedWidget: WidgetModel?
    
    var body: some View {
        ZStack {
            // Desktop background
            Color.clear
                .ignoresSafeArea()
            
            // Widgets
            ForEach(widgetManager.widgets) { widget in
                if widget.isVisible {
                    WidgetContainerView(widget: widget)
                        .position(widget.position)
                        .frame(width: widget.size.width, height: widget.size.height)
                        .scaleEffect(widgetManager.selectedWidget?.id == widget.id ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: widgetManager.selectedWidget?.id)
                        .onTapGesture {
                            if widgetManager.isEditMode {
                                widgetManager.selectWidget(widget)
                            }
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if widgetManager.isEditMode {
                                        isDragging = true
                                        draggedWidget = widget
                                        dragOffset = value.translation
                                    }
                                }
                                .onEnded { value in
                                    if widgetManager.isEditMode {
                                        let newPosition = CGPoint(
                                            x: widget.position.x + value.translation.x,
                                            y: widget.position.y + value.translation.y
                                        )
                                        widgetManager.moveWidget(widget, to: newPosition)
                                    }
                                    isDragging = false
                                    draggedWidget = nil
                                    dragOffset = .zero
                                }
                        )
                }
            }
            
            // Edit mode overlay
            if widgetManager.isEditMode {
                EditModeOverlay()
            }
            
            // Widget menu
            if widgetManager.showWidgetMenu {
                WidgetMenuView()
                    .position(x: 200, y: 100)
            }
        }
        .onKeyPress(.init("e")) {
            widgetManager.toggleEditMode()
            return .handled
        }
        .onKeyPress(.init("a")) {
            widgetManager.showWidgetMenu = true
            return .handled
        }
        .onKeyPress(.init("h")) {
            widgetManager.toggleAllWidgets()
            return .handled
        }
    }
}

struct WidgetContainerView: View {
    let widget: WidgetModel
    @EnvironmentObject var widgetManager: WidgetManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingEditor = false
    
    var body: some View {
        ZStack {
            // Widget content
            widget.render()
                .environmentObject(widgetManager)
                .environmentObject(themeManager)
            
            // Edit mode controls
            if widgetManager.isEditMode && widgetManager.selectedWidget?.id == widget.id {
                EditControlsOverlay(widget: widget, showingEditor: $showingEditor)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .opacity(widgetManager.isEditMode ? 0.1 : 0)
        )
        .sheet(isPresented: $showingEditor) {
            WidgetEditorView(widget: widget)
                .environmentObject(widgetManager)
                .environmentObject(themeManager)
        }
    }
}

struct EditControlsOverlay: View {
    let widget: WidgetModel
    @Binding var showingEditor: Bool
    @EnvironmentObject var widgetManager: WidgetManager
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                // Settings button
                Button(action: {
                    showingEditor = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.blue)
                        .background(Color.white, in: Circle())
                }
                .buttonStyle(.plain)
                
                // Close button
                Button(action: {
                    widgetManager.removeWidget(widget)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .background(Color.white, in: Circle())
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            HStack {
                // Resize handles
                ResizeHandle(direction: .topLeading)
                Spacer()
                ResizeHandle(direction: .topTrailing)
            }
            
            Spacer()
            
            HStack {
                ResizeHandle(direction: .bottomLeading)
                Spacer()
                ResizeHandle(direction: .bottomTrailing)
            }
        }
        .padding(4)
    }
}

struct ResizeHandle: View {
    let direction: ResizeDirection
    @EnvironmentObject var widgetManager: WidgetManager
    
    enum ResizeDirection {
        case topLeading, topTrailing, bottomLeading, bottomTrailing
    }
    
    var body: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 12, height: 12)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Handle resize logic here
                    }
            )
    }
}

struct EditModeOverlay: View {
    @EnvironmentObject var widgetManager: WidgetManager
    
    var body: some View {
        VStack {
            HStack {
                Text("Edit Mode")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                
                Spacer()
                
                Button("Done") {
                    widgetManager.toggleEditMode()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Spacer()
        }
    }
}

// MARK: - Keyboard Extension
extension View {
    func onKeyPress(_ key: KeyEquivalent, action: @escaping () -> KeyPress.Result) -> some View {
        self.onKeyPress(key, modifiers: [], action: action)
    }
    
    func onKeyPress(_ key: KeyEquivalent, modifiers: EventModifiers, action: @escaping () -> KeyPress.Result) -> some View {
        self.background(
            KeyPressHandlingView(key: key, modifiers: modifiers, action: action)
        )
    }
}

struct KeyPressHandlingView: NSViewRepresentable {
    let key: KeyEquivalent
    let modifiers: EventModifiers
    let action: () -> KeyPress.Result
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyPressView()
        view.key = key
        view.modifiers = modifiers
        view.action = action
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // No updates needed
    }
}

class KeyPressView: NSView {
    var key: KeyEquivalent = .init("")
    var modifiers: EventModifiers = []
    var action: (() -> KeyPress.Result)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        if event.characters == key.character && event.modifierFlags.rawValue == modifiers.rawValue {
            if let result = action?(), result == .handled {
                return
            }
        }
        super.keyDown(with: event)
    }
}
