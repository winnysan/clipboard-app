import AppKit
import SwiftUI

/// Základná trieda pre správu jednotného SwiftUI okna.
/// Obsahuje štandardný vzhľad (blur, zaoblenie, tieň), ovládacie prvky (zatváracie tlačidlo)
/// a predvolené umiestnenie v pravom dolnom rohu obrazovky.
/// Dediace triedy definujú len obsah okna a špecifickú logiku.
class BaseWindowManager {
    /// Referencia na aktuálne otvorené okno (ak existuje).
    fileprivate(set) var window: NSWindow?

    /// Pevná veľkosť okna.
    let windowSize: NSSize

    /// Inicializácia so zvolenou veľkosťou okna.
    /// - Parameter size: Veľkosť okna v bodoch.
    init(size: NSSize) {
        windowSize = size
    }

    /// Zobrazí okno s jednotným vzhľadom a zadaným obsahom.
    /// - Parameter content: ViewBuilder, ktorý poskytuje SwiftUI obsah.
    ///   Funkcia `close()` je odovzdaná ako callback pre zavretie okna.
    func show<Content: View>(@ViewBuilder content: @escaping (_ close: @escaping () -> Void) -> Content) {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = CustomWindow(
            contentRect: NSRect(origin: .zero, size: windowSize),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Vizuálne vlastnosti okna
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.ignoresMouseEvents = false
        window.isReleasedWhenClosed = false

        // Kontajnerový NSView (root)
        let containerView = NSView(frame: NSRect(origin: .zero, size: windowSize))

        // Efekt rozmazania pozadia
        let effectView = NSVisualEffectView(frame: containerView.bounds)
        effectView.autoresizingMask = [.width, .height]
        effectView.material = .underWindowBackground
        effectView.blendingMode = .behindWindow
        effectView.state = .active

        // Zaoblené rohy, tieň, orámovanie
        effectView.wantsLayer = true
        if let layer = effectView.layer {
            layer.cornerRadius = 18
            layer.masksToBounds = true
            layer.borderWidth = 1
            layer.borderColor = NSColor.separatorColor.cgColor
            layer.shadowColor = NSColor.black.cgColor
            layer.shadowOpacity = 0.2
            layer.shadowOffset = CGSize(width: 0, height: -2)
            layer.shadowRadius = 10
        }

        containerView.addSubview(effectView)

        // Zatváracie tlačidlo v pravom hornom rohu
        let closeButton = NSButton(frame: NSRect(x: windowSize.width - 35, y: windowSize.height - 35, width: 20, height: 20))
        closeButton.bezelStyle = .regularSquare
        closeButton.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close")
        closeButton.isBordered = false
        closeButton.refusesFirstResponder = true
        closeButton.target = self
        closeButton.action = #selector(closeWindow)

        containerView.addSubview(closeButton)

        // SwiftUI obsah
        let hostingView = NSHostingView(rootView: content { [weak self] in self?.close() })
        hostingView.frame = NSRect(x: 10, y: 10, width: windowSize.width - 20, height: windowSize.height - 40)
        hostingView.autoresizingMask = [.width, .height]

        containerView.addSubview(hostingView)

        // Nastavenie obsahu okna a jeho zobrazenie
        window.contentView = containerView
        self.window = window

        // Umiestnenie v pravom dolnom rohu obrazovky
        positionWindowInBottomRight()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Zavrie okno a uvoľní referenciu.
    func close() {
        window?.orderOut(nil)
    }

    /// Zavrie okno a nastaví `window = nil`.
    /// Volaj túto metódu, ak chceš úplne ukončiť správu okna.
    func forceClose() {
        close()
        window = nil
    }

    /// Handler pre zatváracie tlačidlo.
    @objc private func closeWindow() {
        close()
    }

    /// Nastaví pozíciu okna v pravom dolnom rohu obrazovky.
    func positionWindowInBottomRight() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let margin: CGFloat = 20

        let x = screenFrame.maxX - windowSize.width - margin
        let y = screenFrame.minY + margin

        window?.setFrame(NSRect(x: x, y: y, width: windowSize.width, height: windowSize.height), display: true)
    }

    /// Vlastná trieda `NSWindow`, ktorá definuje správanie plávajúceho okna bez preberania fokusu.
    private class CustomWindow: NSWindow {
        /// Zabraňuje, aby sa okno stalo hlavným (`key window`).
        override var canBecomeKey: Bool { false }

        /// Umožňuje, aby sa okno stalo hlavné (`main window`).
        override var canBecomeMain: Bool { false }

        /// Zobrazenie okna bez jeho aktivácie ako hlavného.
        override func makeKeyAndOrderFront(_ sender: Any?) {
            appLog("📂 Zobrazenie CustomWindow bez aktivácie fokusu", level: .debug)
            super.orderFront(sender)
        }
    }
}
