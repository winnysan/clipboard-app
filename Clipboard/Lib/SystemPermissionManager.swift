import Cocoa
import Combine

/// Trieda na správu systémových oprávnení pre aplikáciu.
/// Obsahuje funkcie na kontrolu oprávnení a aktualizáciu ikonky stavovej lišty.
class SystemPermissionManager: ObservableObject {
    static let shared = SystemPermissionManager()
    
    /// Oznamuje UI, či má aplikácia povolenie na ovládanie klávesnice.
    @Published var hasPermission: Bool = AXIsProcessTrusted()
    
    private var permissionCheckTimer: AnyCancellable?
    private var lastPermissionState: Bool = AXIsProcessTrusted() // Ukladá posledný stav oprávnenia

    /// Privátny inicializátor, aby bola trieda Singleton.
    private init() {}

    /// Spustí nepretržité sledovanie oprávnenia a aktualizuje ikonku stavovej lišty.
    func startMonitoringPermission() {
        permissionCheckTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let newState = AXIsProcessTrusted()
                if newState != self.lastPermissionState {
                    self.lastPermissionState = newState
                    self.hasPermission = newState
                    StatusBarManager.shared.updateIcon(authorized: newState)

                    if !newState {
                        appLog("⚠️ Oprávnenie stratene! Prosím, povoľte ho v nastaveniach.", level: .warning)
                    }
                }
            }
    }

    /// Ukončí sledovanie oprávnenia.
    func stopMonitoringPermission() {
        permissionCheckTimer?.cancel()
        permissionCheckTimer = nil
        appLog("🛑 Sledovanie oprávnenia bolo zastavené.", level: .info)
    }

    /// Otvorí systémové nastavenia pre udelenie oprávnenia v **Privacy & Security > Accessibility**.
    func requestAccessibilityPermission() {
        appLog("🔓 Kontrola oprávnenia na sledovanie klávesnice...", level: .info)

        if hasPermission {
            appLog("✅ Aplikácia už má požadované oprávnenie.", level: .info)
            return
        }

        let alert = NSAlert()
        alert.messageText = NSLocalizedString("accessibility_permission_required", comment: "Oprávnenie požadované")
        alert.informativeText = NSLocalizedString("accessibility_permission_message", comment: "Aplikácia potrebuje oprávnenie na sledovanie klávesových skratiek.")
        alert.addButton(withTitle: "OK")
        alert.runModal()

        appLog("⚠️ Aplikácia nemá oprávnenie. Otváram systémové nastavenia...", level: .warning)
        openAccessibilitySettings()
    }

    /// Otvorí systémové nastavenia pre udelenie oprávnenia v **Privacy & Security > Accessibility**.
    func openAccessibilitySettings() {
        appLog("🔓 Otváram systémové nastavenia pre oprávnenia...", level: .info)

        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        } else {
            appLog("❌ Nepodarilo sa otvoriť systémové nastavenia. Skontrolujte oprávnenia manuálne.", level: .error)
        }
    }
}
