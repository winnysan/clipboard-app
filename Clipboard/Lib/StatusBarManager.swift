import AppKit

/// Správa ikonky na stavovej lište aplikácie.
/// Umožňuje interakciu s aplikáciou cez ikonku v `NSStatusBar`.
class StatusBarManager {
    /// Singleton inštancia pre správu stavovej lišty.
    static let shared = StatusBarManager()
    
    /// Referencia na položku stavovej lišty.
    private var statusItem: NSStatusItem?

    /// Ukladanie preferencií používateľa
    private let defaults = UserDefaults.standard

    /// Kľúč pre nastavenie "Otvoriť okno pri kopírovaní"
    private let openWindowOnCopyKey = "openWindowOnCopy"

    /// Hodnota pre "Otvoriť okno pri kopírovaní"
    var openWindowOnCopy: Bool {
        get { defaults.bool(forKey: openWindowOnCopyKey) }
        set { defaults.set(newValue, forKey: openWindowOnCopyKey) }
    }

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
        
        // Položka "O aplikácii"
        let aboutItem = NSMenuItem(
            title: NSLocalizedString("about_app", comment: "O aplikácii"),
            action: #selector(showAboutWindow),
            keyEquivalent: ""
        )
        aboutItem.target = self

        // Položka "Otvoriť okno pri kopírovaní"
        let openWindowItem = NSMenuItem(
            title: NSLocalizedString("open_window_on_copy", comment: "Otvoriť okno pri kopírovaní"),
            action: #selector(toggleOpenWindowOnCopy),
            keyEquivalent: ""
        )
        openWindowItem.target = self
        openWindowItem.state = openWindowOnCopy ? .on : .off

        // Položka "Spustiť pri štarte"
        let launchAtStartupItem = NSMenuItem(
            title: NSLocalizedString("start_at_login", comment: "Tlačidlo na povolenie spustenia aplikácie pri prihlasení"),
            action: #selector(toggleLaunchAtStartup),
            keyEquivalent: ""
        )
        launchAtStartupItem.target = self
        launchAtStartupItem.state = LaunchManager.shared.isLaunchAtStartupEnabled() ? .on : .off

        menu.addItem(aboutItem)
        menu.addItem(.separator()) // Oddelovač
        menu.addItem(openWindowItem)
        menu.addItem(launchAtStartupItem)
        menu.addItem(.separator()) // Oddelovač

        // Položka "Ukončiť aplikáciu"
        let quitItem = NSMenuItem(
            title: NSLocalizedString("quit", comment: "Tlačidlo na ukončenie aplikácie"),
            action: #selector(quitApp),
            keyEquivalent: ""
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil) // Simuluje kliknutie na ikonu pre zobrazenie menu
        statusItem?.menu = nil // Po kliknutí na položku menu resetuje menu, aby neboli vizuálne chyby
    }

    /// Prepne stav "Otvoriť okno pri kopírovaní"
    @objc private func toggleOpenWindowOnCopy() {
        openWindowOnCopy.toggle()
        appLog("🔄 Otvoriť okno pri kopírovaní: \(openWindowOnCopy ? "Zapnuté" : "Vypnuté")", level: .info)
    }
    
    /// Prepne stav automatického spúšťania aplikácie pri štarte systému.
    @objc private func toggleLaunchAtStartup() {
        let isEnabled = LaunchManager.shared.isLaunchAtStartupEnabled()
        LaunchManager.shared.setLaunchAtStartup(!isEnabled)
    }
    
    /// Ukončí aplikáciu.
    @objc private func quitApp() {
        appLog("🚪 Aplikácia bola ukončená.", level: .info)
        NSApp.terminate(nil)
    }
    
    /// Zobrazí okno "O aplikácii"
    @objc private func showAboutWindow() {
         let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
         let informativeText = String(format: NSLocalizedString("informative_text", comment: "Informácie o aplikácii"), appVersion)
         
         let alert = NSAlert()
         alert.messageText = NSLocalizedString("clipboard_app_title", comment: "Nadpis aplikácie")
         alert.informativeText = informativeText
         alert.alertStyle = .informational
         alert.addButton(withTitle: "OK")
         alert.runModal()
    }
}
