import AppKit

import SwiftUI

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

    /// Kľúč pre nastavenie "Zatvoriť okno pri vložení".
    private let closeWindowOnPasteKey = "closeWindowOnPaste"

    /// Kľúč pre nastavenie "Sledovanie systémovej schránky".
    private let monitorClipboardKey = "monitorClipboard"

    /// Kľúč pre nastavenie "Klávesové skratky"
    private let enableKeyboardShortcutsKey = "enableKeyboardShortcuts"

    /// Hodnota pre "Otvoriť okno pri kopírovaní"
    var openWindowOnCopy: Bool {
        get { defaults.bool(forKey: openWindowOnCopyKey) }
        set { defaults.set(newValue, forKey: openWindowOnCopyKey) }
    }

    /// Hodnota pre "Zatvoriť okno pri vložení".
    var closeWindowOnPaste: Bool {
        get { defaults.bool(forKey: closeWindowOnPasteKey) }
        set { defaults.set(newValue, forKey: closeWindowOnPasteKey) }
    }

    /// Hodnota pre "Sledovanie systémovej schránky".
    var monitorClipboard: Bool {
        get { defaults.bool(forKey: monitorClipboardKey) }
        set { defaults.set(newValue, forKey: monitorClipboardKey) }
    }

    /// Hodnota pre "Klávesové skratky".
    var enableKeyboardShortcuts: Bool {
        get { defaults.bool(forKey: enableKeyboardShortcutsKey) }
        set { defaults.set(newValue, forKey: enableKeyboardShortcutsKey) }
    }

    /// Registrovanie predvolených hodnôt pri prvom spustení aplikácie.
    func registerDefaultPreferences() {
        let defaultValues: [String: Any] = [
            openWindowOnCopyKey: false, // Predvolene vypnuté
            closeWindowOnPasteKey: true, // Predvolene zapnuté
            monitorClipboardKey: true, // Predvolene zapnuté
            enableKeyboardShortcutsKey: true, // Predvolene zapnuté
        ]
        defaults.register(defaults: defaultValues)
    }

    /// Privátny inicializátor zabraňujúci vytvoreniu ďalších inštancií.
    private init() {}

    /// Inicializuje ikonku v stavovej lište a nastaví akcie.
    func setupStatusBar() {
        registerDefaultPreferences() // Zavolanie metódy na registráciu predvolených hodnôt

        // Spustí sledovanie po štarte
        if monitorClipboard {
            ClipboardManager.shared.startMonitoringClipboard()
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Clipboard")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp]) // Povolenie akcií na ľavé aj pravé tlačidlo
        }
    }

    /// Aktualizuje ikonku podľa stavu oprávnenia.
    func updateIcon(authorized: Bool) {
        let iconName = authorized ? "clipboard" : "exclamationmark.triangle.fill"
        statusItem?.button?.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Permission Status")
    }

    /// Akcia pri kliknutí na ikonku stavovej lišty - zobrazí alebo skryje okno aplikácie.
    @objc private func statusBarButtonClicked(_: NSStatusBarButton) {
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

        // Položka "Sledovať systémovú schránku"
        let monitorClipboardItem = NSMenuItem(
            title: NSLocalizedString("monitor_clipboard", comment: "Sledovať systémovú schránku"),
            action: #selector(toggleMonitorClipboard),
            keyEquivalent: ""
        )
        monitorClipboardItem.target = self
        monitorClipboardItem.state = monitorClipboard ? .on : .off

        // Položka "Povoliť klávesové skratky"
        let keyboardShortcutsItem = NSMenuItem(
            title: NSLocalizedString("enable_keyboard_shortcuts", comment: "Povoliť klávesové skratky"),
            action: #selector(toggleKeyboardShortcuts),
            keyEquivalent: ""
        )
        keyboardShortcutsItem.target = self
        keyboardShortcutsItem.state = enableKeyboardShortcuts ? .on : .off

        // Položka "Otvoriť okno pri kopírovaní"
        let openWindowItem = NSMenuItem(
            title: NSLocalizedString("open_window_on_copy", comment: "Otvoriť okno pri kopírovaní"),
            action: #selector(toggleOpenWindowOnCopy),
            keyEquivalent: ""
        )
        openWindowItem.target = self
        openWindowItem.state = openWindowOnCopy ? .on : .off

        // Položka "Zatvoriť okno pri vložení"
        let closeWindowItem = NSMenuItem(
            title: NSLocalizedString("close_window_on_paste", comment: "Zatvoriť okno pri vložení"),
            action: #selector(toggleCloseWindowOnPaste),
            keyEquivalent: ""
        )
        closeWindowItem.target = self
        closeWindowItem.state = closeWindowOnPaste ? .on : .off

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
        menu.addItem(monitorClipboardItem)
        menu.addItem(keyboardShortcutsItem)
        menu.addItem(openWindowItem)
        menu.addItem(closeWindowItem)
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

    /// Zapne alebo vypne možnosť sledovania systémovej schránky.
    @objc private func toggleMonitorClipboard() {
        monitorClipboard.toggle()
        defaults.set(monitorClipboard, forKey: monitorClipboardKey)

        if monitorClipboard {
            ClipboardManager.shared.startMonitoringClipboard()
            appLog("🟢 Zapnuté sledovanie systémovej schránky", level: .info)
        } else {
            ClipboardManager.shared.stopMonitoringClipboard()
            appLog("🔴 Vypnuté sledovanie systémovej schránky", level: .info)
        }
    }

    /// Prepne stav "Povoliť klávesové skratky"
    @objc private func toggleKeyboardShortcuts() {
        enableKeyboardShortcuts.toggle()
        appLog("🔄 Klávesové skratky: \(enableKeyboardShortcuts ? "Zapnuté" : "Vypnuté")", level: .info)
    }

    /// Prepne stav "Otvoriť okno pri kopírovaní"
    @objc private func toggleOpenWindowOnCopy() {
        openWindowOnCopy.toggle()
        appLog("🔄 Otvoriť okno pri kopírovaní: \(openWindowOnCopy ? "Zapnuté" : "Vypnuté")", level: .info)
    }

    /// Prepne stav "Zatvoriť okno pri vložení".
    @objc private func toggleCloseWindowOnPaste() {
        closeWindowOnPaste.toggle()
        appLog("🔄 Zatvoriť okno pri vložení: \(closeWindowOnPaste ? "Zapnuté" : "Vypnuté")", level: .info)
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
        AboutWindowManager.shared.openWindow()
    }
}
