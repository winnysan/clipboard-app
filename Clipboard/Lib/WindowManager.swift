import AppKit
import SwiftUI

/// Singleton trieda na správu hlavného okna aplikácie.
class WindowManager: BaseWindowManager {
    /// Zdieľaná inštancia triedy (Singleton).
    static let shared = WindowManager()

    /// Predchádzajúca aktívna aplikácia (pre zachovanie fokusu).
    private var previousApp: NSRunningApplication?

    /// Timer na sledovanie zmeny aktívnej aplikácie.
    private var focusTrackingTimer: Timer?

    /// Privátny inicializátor zabraňujúci vytvoreniu ďalších inštancií.
    private init() {
        super.init(size: NSSize(width: 300, height: 400))
    }

    /// Konfiguruje hlavné okno aplikácie s vizuálnymi vlastnosťami a rozložením.
    func configureWindow() {
        show { _ in
            ContentView()
        }
        close() // Skryť okno po vytvorení
    }

    /// Zobrazí alebo skryje okno aplikácie a spustí sledovanie fokusu.
    func toggleWindow() {
        guard let window = window else { return }

        if window.isVisible {
            closeWindow()
        } else {
            preserveFocusBeforeOpening()
            window.makeKeyAndOrderFront(nil) // Zobraziť okno
            startFocusTracking() // Začať sledovanie aktívnej aplikácie
        }
    }

    /// Otvorí okno aplikácie a spustí sledovanie fokusu.
    func openWindow() {
        guard let window = window, !window.isVisible else { return }

        preserveFocusBeforeOpening()
        window.makeKeyAndOrderFront(nil) // Zobraziť okno
        startFocusTracking()
    }

    /// Zatvorí okno aplikácie a zastaví sledovanie fokusu.
    func closeWindow() {
        close() // Zavrie okno
        stopFocusTracking()
    }

    /// Uloží aktuálnu aktívnu aplikáciu pred otvorením okna aplikácie.
    func preserveFocusBeforeOpening() {
        guard let currentApp = NSWorkspace.shared.frontmostApplication,
              currentApp.bundleIdentifier != Bundle.main.bundleIdentifier
        else {
            appLog("⚠️ Fokus nebol uložený, aktuálne sme už v aplikácii Clipboard.", level: .warning)
            return
        }

        previousApp = currentApp
        appLog("🔹 Pôvodná aktívna aplikácia: \(previousApp?.localizedName ?? "Neznáma aplikácia")", level: .info)
    }

    /// Obnoví predchádzajúcu aplikáciu ako aktívnu.
    func restorePreviousFocus() {
        guard let app = previousApp else { return }
        let success = app.activate(options: [])
        appLog(success ? "✅ Fokus obnovený na: \(app.localizedName ?? "Neznáma aplikácia")" : "❌ Nepodarilo sa obnoviť fokus.", level: success ? .info : .error)
    }

    /// Spustí sledovanie aktuálnej aktívnej aplikácie na pozadí.
    private func startFocusTracking() {
        focusTrackingTimer?.invalidate() // Zruší predchádzajúci timer, ak existuje

        focusTrackingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            guard let currentApp = NSWorkspace.shared.frontmostApplication else { return }
            if currentApp.bundleIdentifier != Bundle.main.bundleIdentifier {
                self.previousApp = currentApp
                appLog("🔄 Aktualizovaný fokus na: \(currentApp.localizedName ?? "Neznáma aplikácia")", level: .debug)
            }
        }
    }

    /// Zastaví sledovanie aktívnej aplikácie.
    private func stopFocusTracking() {
        focusTrackingTimer?.invalidate()
        focusTrackingTimer = nil
    }
}
