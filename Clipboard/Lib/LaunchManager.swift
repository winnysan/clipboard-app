import Cocoa
import ServiceManagement

/// Správa automatického spúšťania aplikácie pri štarte systému.
class LaunchManager {
    /// Singleton inštancia triedy.
    static let shared = LaunchManager()
    
    /// Identifikátor aplikácie v `LaunchAgents`.
    private let helperBundleID = Bundle.main.bundleIdentifier!

    /// Privátny inicializátor zabraňujúci vytvoreniu ďalších inštancií.
    private init() {}

    /// Zistí, či je aplikácia nastavená na automatické spustenie pri štarte systému.
    /// - Returns: `true`, ak je automatické spustenie povolené, inak `false`.
    func isLaunchAtStartupEnabled() -> Bool {
        return SMAppService.mainApp.status == .enabled
    }

    /// Zapne alebo vypne automatické spúšťanie aplikácie pri štarte systému.
    /// - Parameter enabled: `true`, ak má byť aplikácia spustená pri štarte, inak `false`.
    func setLaunchAtStartup(_ enabled: Bool) {
        if enabled {
            do {
                try SMAppService.mainApp.register()
            } catch {
                print("❌ Chyba pri nastavovaní spustenia pri štarte: \(error.localizedDescription)")
            }
        } else {
            do {
                try SMAppService.mainApp.unregister()
            } catch {
                print("❌ Chyba pri odstraňovaní spustenia pri štarte: \(error.localizedDescription)")
            }
        }
    }

    /// Požiada používateľa o povolenie spustenia aplikácie pri štarte, ak ešte nie je povolené.
    func requestLaunchAtStartup() {
        if !isLaunchAtStartupEnabled() {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("launch_prompt_title", comment: "Názov dialógu pre automatické spustenie")
                alert.informativeText = NSLocalizedString("launch_prompt_message", comment: "Text pre povolenie automatického spustenia")
                alert.alertStyle = .informational
                alert.addButton(withTitle: NSLocalizedString("allow", comment: "Tlačidlo na povolenie"))
                alert.addButton(withTitle: NSLocalizedString("cancel", comment: "Tlačidlo na zrušenie"))

                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    self.setLaunchAtStartup(true)
                    print("✅ Automatické spustenie povolené.")
                } else {
                    print("❌ Používateľ zamietol automatické spustenie.")
                }
            }
        }
    }
}
