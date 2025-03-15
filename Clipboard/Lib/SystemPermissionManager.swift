import Cocoa

/// Trieda na správu systémových oprávnení pre aplikáciu.
/// Obsahuje funkciu na otvorenie nastavení pre Accessibility.
class SystemPermissionManager {
    /// Skontroluje, či má aplikácia povolenie na sledovanie klávesnice.
    /// - Returns: `true`, ak má aplikácia povolenie, inak `false`.
    func hasAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    /// Otvorí systémové nastavenia pre udelenie oprávnenia v **Privacy & Security > Accessibility**.
    func requestAccessibilityPermission() {
        appLog("🔓 Kontrola oprávnenia na sledovanie klávesnice...", level: .info)

        if hasAccessibilityPermission() {
            appLog("✅ Aplikácia už má požadované oprávnenie.", level: .info)
            return
        }
        
        if !hasAccessibilityPermission() {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("accessibility_permission_required", comment: "Oprávnenie požadované")
            alert.informativeText = NSLocalizedString("accessibility_permission_message", comment: "Aplikácia potrebuje oprávnenie na sledovanie klávesových skratiek.")
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }

        appLog("⚠️ Aplikácia nemá oprávnenie. Otváram systémové nastavenia...", level: .warning)

        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        } else {
            appLog("❌ Nepodarilo sa otvoriť systémové nastavenia. Skontrolujte oprávnenia manuálne.", level: .error)
        }
        
        // Požiada o oprávnenie a začne sledovať zmeny v povoleniach
        DispatchQueue.global(qos: .background).async {
            self.monitorPermissionChanges()
        }
    }
    
    /// Sleduje, či bolo oprávnenie udelené, a po jeho získaní reštartuje aplikáciu.
    private func monitorPermissionChanges() {
        while !hasAccessibilityPermission() {
            sleep(1) // Čaká jednu sekundu a znova kontroluje
        }

        appLog("🔄 Oprávnenie udelené! Reštartujem aplikáciu...", level: .info)
        restartApplication()
    }

    /// Reštartuje aplikáciu.
    private func restartApplication() {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-n", Bundle.main.bundlePath]
        task.launch()

        // Ukončí aktuálnu inštanciu aplikácie
        DispatchQueue.main.async {
            NSApp.terminate(nil)
        }
    }
}
