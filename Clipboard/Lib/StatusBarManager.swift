import AppKit

/// Správa ikonky na stavovej lište aplikácie.
/// Umožňuje interakciu s aplikáciou cez ikonku v `NSStatusBar`.
class StatusBarManager {
    /// Singleton inštancia pre správu stavovej lišty.
    static let shared = StatusBarManager()
    
    /// Referencia na položku stavovej lišty.
    private var statusItem: NSStatusItem?

    /// Privátny inicializátor zabraňujúci vytvoreniu ďalších instancií.
    private init() {}

    /// Inicializuje ikonku v stavovej lište a nastaví akcie.
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Clipboard")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp]) // Povolenie akcií na ľavé aj pravé tlačidlo
        }
    }
    
    /// Akcia pri kliknutí na ikonku stavovej lišty - zobrazí alebo skryje okno aplikácie.
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent

        if event?.type == .rightMouseUp {
            showContextMenu() // Kliknutie pravým tlačidlom → zobrazí menu
        } else {
            WindowManager.shared.toggleWindow() // Kliknutie ľavým tlačidlom → otvorí/zatvorí okno
        }
    }
    
    /// Zobrazí kontextové menu pri kliknutí pravým tlačidlom na ikonku stavovej lišty.
    private func showContextMenu() {
        let menu = NSMenu()

        let quitItem = NSMenuItem(title: "Ukončiť aplikáciu", action: #selector(quitApp), keyEquivalent: "")
        quitItem.target = self

        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil) // Simuluje kliknutie na ikonu pre zobrazenie menu
        statusItem?.menu = nil // Po kliknutí na položku menu resetuje menu, aby neboli vizuálne chyby
    }
    
    /// Ukončí aplikáciu.
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
