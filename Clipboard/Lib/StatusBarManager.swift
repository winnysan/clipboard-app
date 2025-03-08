import AppKit

/// Správa ikonky na stavovej lište aplikácie.
/// Umožňuje interakciu s aplikáciou cez ikonku v `NSStatusBar`.
class StatusBarManager {
    /// Singleton inštancia pre správu stavovej lišty.
    static let shared = StatusBarManager()
    
    /// Referencia na položku stavovej lišty.
    private var statusItem: NSStatusItem?

    /// Privátny inicializátor zabraňujúci vytvoreniu ďalších inštancií.
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

        // Položka "Spustiť pri štarte"
        let launchAtStartupItem = NSMenuItem(
            title: "Spustiť pri štarte",
            action: #selector(toggleLaunchAtStartup),
            keyEquivalent: ""
        )
        launchAtStartupItem.target = self
        launchAtStartupItem.state = LaunchManager.shared.isLaunchAtStartupEnabled() ? .on : .off

        menu.addItem(launchAtStartupItem)
        menu.addItem(.separator()) // Oddelovač

        // Položka "Ukončiť aplikáciu"
        let quitItem = NSMenuItem(
            title: "Ukončiť aplikáciu",
            action: #selector(quitApp),
            keyEquivalent: ""
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil) // Simuluje kliknutie na ikonu pre zobrazenie menu
        statusItem?.menu = nil // Po kliknutí na položku menu resetuje menu, aby neboli vizuálne chyby
    }
    
    /// Prepne stav automatického spúšťania aplikácie pri štarte systému.
    @objc private func toggleLaunchAtStartup() {
        let isEnabled = LaunchManager.shared.isLaunchAtStartupEnabled()
        LaunchManager.shared.setLaunchAtStartup(!isEnabled)
    }
    
    /// Ukončí aplikáciu.
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
