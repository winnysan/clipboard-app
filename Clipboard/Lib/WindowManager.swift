import AppKit
import SwiftUI

/// Singleton trieda na správu hlavného okna aplikácie.
class WindowManager {
    /// Zdieľaná inštancia triedy (Singleton).
    static let shared = WindowManager()
    
    /// Hlavné okno aplikácie.
    private var window: NSWindow?
    
    /// Veľkosť okna aplikácie.
    private let windowSize = NSSize(width: 300, height: 400)
    
    /// Privátny inicializátor zabraňujúci vytvoreniu ďalších inštancií.
    private init() {}

    /// Konfiguruje okno aplikácie.
    func configureWindow() {
        let window = CustomWindow(
            contentRect: NSRect(origin: .zero, size: windowSize),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Vlastnosti okna
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary] // Okno ostane aktívne
        window.ignoresMouseEvents = false
        
        // Hlavný kontajner pre obsah okna
        let containerView = NSView(frame: NSRect(origin: .zero, size: windowSize))
        
        // Efekt rozmazania pozadia
        let visualEffectView = NSVisualEffectView(frame: window.contentView!.bounds)
        visualEffectView.autoresizingMask = [.width, .height]
        visualEffectView.material = .underWindowBackground
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        
        // Zaoblené rohy, tieň a orámovanie okna
        visualEffectView.wantsLayer = true
        if let layer = visualEffectView.layer {
            layer.cornerRadius = 18
            layer.masksToBounds = true
            layer.borderWidth = 1
            layer.borderColor = NSColor.separatorColor.cgColor
            layer.shadowColor = NSColor.black.cgColor
            layer.shadowOpacity = 0.2
            layer.shadowOffset = CGSize(width: 0, height: -2)
            layer.shadowRadius = 10
        }
        
        containerView.addSubview(visualEffectView)
        
        // Pridanie tlačidla na zatvorenie okna
        let closeButton = NSButton(frame: NSRect(x: window.frame.width - 35, y: window.frame.height - 35, width: 20, height: 20))
        closeButton.bezelStyle = .regularSquare
        closeButton.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close")
        closeButton.isBordered = false
        closeButton.refusesFirstResponder = true
        closeButton.target = self
        closeButton.action = #selector(closeButtonClicked)
        
        containerView.addSubview(closeButton)
        
        // Vloženie SwiftUI obsahu do NSHostingView
        let contentView = ContentView()
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(x: 10, y: 10, width: windowSize.width - 20, height: windowSize.height - 40)
        hostingView.autoresizingMask = [.width, .height]
        
        containerView.addSubview(hostingView)
        
        // Nastavenie obsahu okna
        window.contentView = containerView
        window.orderOut(nil) // Skryť okno pri štarte
        
        self.window = window
        positionWindowInBottomRight()
    }
    
    /// Nastaví pozíciu okna v pravom dolnom rohu obrazovky.
    private func positionWindowInBottomRight() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        
        let windowWidth: CGFloat = 300
        let windowHeight: CGFloat = 400
        let margin: CGFloat = 20
        
        let x = screenFrame.maxX - windowWidth - margin
        let y = screenFrame.minY + margin
        
        window?.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
    }
    
    /// Zobrazí alebo skryje okno aplikácie.
    func toggleWindow() {
        guard let window = window else { return }
        
        if window.isVisible {
            window.orderOut(nil) // Skryť okno
        } else {
            window.makeKeyAndOrderFront(nil) // Zobraziť okno
            NSApp.activate(ignoringOtherApps: true) // Aktivovať aplikáciu
        }
    }
    
    /// Otvorí okno aplikácie, ak ešte nie je viditeľné.
    func openWindow() {
        guard let window = window, !window.isVisible else { return }
        
        window.makeKeyAndOrderFront(nil) // Zobraziť okno
        NSApp.activate(ignoringOtherApps: true) // Aktivovať aplikáciu
    }
    
    /// Zatvorí okno aplikácie.
    func closeWindow() {
        guard let window = window else { return }
        window.orderOut(nil)
    }
    
    /// Handler pre stlačenie tlačidla na zatvorenie okna.
    @objc private func closeButtonClicked() {
        closeWindow()
    }
}

