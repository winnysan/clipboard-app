import SwiftUI

/// Správca pre okno s nákupom PRO verzie.
class PurchaseWindowManager {
    static let shared = PurchaseWindowManager()

    private let windowSize = NSSize(width: 300, height: 400)
    private var window: NSWindow?

    private init() {}

    /// Zobrazí okno "Prejsť na PRO"
    func showWindow() {
        // Ak už okno existuje, iba ho zaktivuj
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Vytvor okno bez titlebaru, ktoré vie byť aktívne
        let window = CustomWindow(
            contentRect: NSRect(origin: .zero, size: windowSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // Vlastnosti okna
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = .floating
        window.center()

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

        // Obsah SwiftUI
        let contentView = PurchaseView(onClose: { [weak self] in
            self?.closeWindow()
        })

        // HostingView cez vizuálny efekt
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(x: 10, y: 10, width: windowSize.width - 20, height: windowSize.height - 40)
        hostingView.autoresizingMask = [.width, .height]

        containerView.addSubview(hostingView)

        // Nastavenie obsahu okna
        window.contentView = containerView

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Zavrie okno
    func closeWindow() {
        window?.orderOut(nil)
        window = nil
    }
}

/// Vlastná trieda `NSWindow`, ktorá definuje správanie plávajúceho okna.
private final class CustomWindow: NSWindow {
    /// Zabraňuje, aby sa okno stalo hlavným (`key window`).
    override var canBecomeKey: Bool {
        return true
    }

    /// Umožňuje, aby sa okno stalo hlavné (`main window`).
    override var canBecomeMain: Bool {
        return true
    }
}
