import SwiftUI
import MediaPlayer
import Foundation
import AppKit

// MARK: - Music Widget Model
class MusicWidgetModel: WidgetModel {
    @Published var nowPlayingInfo: MPMediaItem?
    @Published var playbackState: MPMusicPlaybackState = .stopped
    @Published var showControls: Bool = true
    @Published var showAlbumArt: Bool = true
    
    private let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    private var cancellables = Set<AnyCancellable>()
    
    override init(type: WidgetType = .music, position: CGPoint, size: CGSize? = nil) {
        super.init(type: type, position: position, size: size)
        setupMusicPlayer()
        loadCustomProperties()
    }
    
    override func updateData() {
        updateNowPlayingInfo()
    }
    
    override func render() -> AnyView {
        return AnyView(MusicWidgetView(widget: self))
    }
    
    override func getDefaultSize() -> CGSize {
        return CGSize(width: 300, height: 100)
    }
    
    private func setupMusicPlayer() {
        // Request authorization for media library access
        MPMediaLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                if status == .authorized {
                    self?.updateNowPlayingInfo()
                }
            }
        }
        
        // Listen for playback state changes
        NotificationCenter.default.publisher(for: .MPMusicPlayerControllerPlaybackStateDidChange)
            .sink { [weak self] _ in
                self?.updatePlaybackState()
            }
            .store(in: &cancellables)
        
        // Listen for now playing item changes
        NotificationCenter.default.publisher(for: .MPMusicPlayerControllerNowPlayingItemDidChange)
            .sink { [weak self] _ in
                self?.updateNowPlayingInfo()
            }
            .store(in: &cancellables)
    }
    
    private func updateNowPlayingInfo() {
        nowPlayingInfo = musicPlayer.nowPlayingItem
    }
    
    private func updatePlaybackState() {
        playbackState = musicPlayer.playbackState
    }
    
    private func loadCustomProperties() {
        if let showControls = customProperties["showControls"] as? Bool {
            self.showControls = showControls
        }
        if let showAlbumArt = customProperties["showAlbumArt"] as? Bool {
            self.showAlbumArt = showAlbumArt
        }
    }
    
    // MARK: - Playback Controls
    func togglePlayPause() {
        if playbackState == .playing {
            musicPlayer.pause()
        } else {
            musicPlayer.play()
        }
    }
    
    func skipToNext() {
        musicPlayer.skipToNextItem()
    }
    
    func skipToPrevious() {
        musicPlayer.skipToPreviousItem()
    }
}

// MARK: - Music Widget View
struct MusicWidgetView: View {
    @ObservedObject var widget: MusicWidgetModel
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
            
            // Music content
            if let nowPlaying = widget.nowPlayingInfo {
                MusicContentView(nowPlaying: nowPlaying, widget: widget, animationPhase: animationPhase)
            } else {
                NoMusicView()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                animationPhase = 1
            }
        }
    }
    
    // MARK: - Theme Helpers
    private func getTheme() -> ThemeModel? {
        return themeManager.getThemeForWidget(.music, themeName: widget.theme)
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

// MARK: - Music Content View
struct MusicContentView: View {
    let nowPlaying: MPMediaItem
    @ObservedObject var widget: MusicWidgetModel
    let animationPhase: Double
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Album artwork
            if widget.showAlbumArt {
                AlbumArtworkView(artwork: nowPlaying.artwork, animationPhase: animationPhase)
            }
            
            // Track info
            VStack(alignment: .leading, spacing: 4) {
                Text(nowPlaying.title ?? "Unknown Title")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(getPrimaryColor())
                    .lineLimit(1)
                    .shadow(color: .black.opacity(getTextShadowOpacity()), radius: 1, x: 0.5, y: 0.5)
                
                Text(nowPlaying.artist ?? "Unknown Artist")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(getAccentColor())
                    .lineLimit(1)
                
                if let album = nowPlaying.albumTitle {
                    Text(album)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(getPrimaryColor().opacity(0.7))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Playback controls
            if widget.showControls {
                PlaybackControlsView(widget: widget)
            }
        }
        .padding()
    }
    
    private func getPrimaryColor() -> Color {
        let theme = themeManager.getThemeForWidget(.music, themeName: widget.theme)
        return Color(hex: theme?.primaryColor ?? "#FFFFFF")
    }
    
    private func getAccentColor() -> Color {
        let theme = themeManager.getThemeForWidget(.music, themeName: widget.theme)
        return Color(hex: theme?.accentColor ?? "#FF3B30")
    }
    
    private func getTextShadowOpacity() -> Double {
        let theme = themeManager.getThemeForWidget(.music, themeName: widget.theme)
        return theme?.textShadow == true ? 0.5 : 0
    }
}

// MARK: - Album Artwork View
struct AlbumArtworkView: View {
    let artwork: MPMediaItemArtwork?
    let animationPhase: Double
    
    var body: some View {
        Group {
            if let artwork = artwork, let image = artwork.image(at: CGSize(width: 60, height: 60)) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .scaleEffect(1.0 + (animationPhase * 0.05))
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animationPhase)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    )
            }
        }
    }
}

// MARK: - Playback Controls View
struct PlaybackControlsView: View {
    @ObservedObject var widget: MusicWidgetModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 8) {
            // Previous button
            Button(action: {
                widget.skipToPrevious()
            }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 16))
                    .foregroundColor(getAccentColor())
            }
            .buttonStyle(.plain)
            
            // Play/Pause button
            Button(action: {
                widget.togglePlayPause()
            }) {
                Image(systemName: widget.playbackState == .playing ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(getAccentColor())
            }
            .buttonStyle(.plain)
            
            // Next button
            Button(action: {
                widget.skipToNext()
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 16))
                    .foregroundColor(getAccentColor())
            }
            .buttonStyle(.plain)
        }
    }
    
    private func getAccentColor() -> Color {
        let theme = themeManager.getThemeForWidget(.music, themeName: widget.theme)
        return Color(hex: theme?.accentColor ?? "#FF3B30")
    }
}

// MARK: - No Music View
struct NoMusicView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("No Music Playing")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Start playing music to see info here")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
}
