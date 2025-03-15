import Cocoa
import Combine

/// Trieda zodpovedná za manipuláciu so schránkou.
/// Obsahuje funkcie na získanie označeného textu, správu histórie kopírovania a výpis vybraného textu.
class ClipboardManager: ObservableObject {
    /// Singleton inštancia triedy
    static let shared = ClipboardManager()

    /// Maximálny počet položiek v histórii
    private let maxHistorySize = 100

    /// História skopírovaných textov (najnovší na začiatku)
    @Published var clipboardHistory: [String] = []
    
    /// Pripnuté položky, ktoré sa uchovajú aj po reštarte aplikácie
    @Published var pinnedItems: Set<String> = []
    
    /// Cesta k súboru, kde sa bude ukladať história
    private let historyFileURL: URL = {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        
        // Vytvoríme vlastný priečinok pre aplikáciu
        let appDirectory = directory.appendingPathComponent("MyClipboardApp", isDirectory: true)

        if !FileManager.default.fileExists(atPath: appDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                appLog("❌ Chyba pri vytváraní priečinka: \(error.localizedDescription)", level: .error)
            }
        }

        return appDirectory.appendingPathComponent("clipboard_history.json")
    }()


    /// Privátny inicializátor zabraňujúci vytvoreniu ďalších inštancií.
    private init() {
        loadHistory()
    }

    /// Skopíruje označený text zo systému, uloží ho do histórie a zobrazí okno aplikácie.
    func copySelectedText() {
        let pasteboard = NSPasteboard.general

        // Simulácia stlačenia Cmd + C na skopírovanie označeného textu
        let source = CGEventSource(stateID: .hidSystemState)
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true) // Command
        let cDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true) // C
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        let cUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)

        cmdDown?.flags = .maskCommand
        cDown?.flags = .maskCommand

        cmdDown?.post(tap: .cghidEventTap)
        cDown?.post(tap: .cghidEventTap)
        cUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)

        // Po krátkom čase prečítame obsah schránky a spracujeme ho
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let copiedText = pasteboard.string(forType: .string), !copiedText.isEmpty {
                appLog("📋 Skopírovaný text: \(copiedText)", level: .info)

                // Pridáme do histórie iba ak už nie je uložený
                if !self.clipboardHistory.contains(copiedText) {
                    self.clipboardHistory.insert(copiedText, at: 0)

                    // Zachováme iba pripnuté položky v histórii po reštarte
                    if self.pinnedItems.contains(copiedText) {
                        self.saveHistory()
                    }

                    // Zabezpečíme, že história nepresiahne maximálny limit
                    if self.clipboardHistory.count > self.maxHistorySize {
                        self.clipboardHistory.removeLast()
                    }
                }

                // Ak je povolené "Otvoriť okno pri kopírovaní", zobrazíme ho
                if StatusBarManager.shared.openWindowOnCopy {
                    WindowManager.shared.openWindow()
                }
            } else {
                appLog("⚠️ Nepodarilo sa získať text.", level: .warning)
            }
        }
    }
    
    /// Vloží zadaný text alebo najnovší text z histórie na miesto kurzora.
    /// - Parameter text: Voliteľný parameter. Ak nie je zadaný, použije sa posledný text z histórie.
    func pasteText(_ text: String? = nil) {
         let pasteboard = NSPasteboard.general
 
         // Ak nie je zadaný text, použijeme posledný text z histórie.
         guard let textToPaste = text ?? clipboardHistory.first else {
            appLog("⚠️ Nie je k dispozícii žiadny text na vloženie.", level: .warning)
            return
        }

        pasteboard.clearContents()
        pasteboard.setString(textToPaste, forType: .string)

        // Simulácia Cmd + V na vloženie textu
        let source = CGEventSource(stateID: .hidSystemState)
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true) // Command
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // V
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)

        cmdDown?.flags = .maskCommand
        vDown?.flags = .maskCommand
        
        // Uchovanie pôvodného fokusu pred vložením textu.
        WindowManager.shared.preserveFocusBeforeOpening()

        cmdDown?.post(tap: .cghidEventTap)
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
        
        // Obnovenie pôvodného fokusu po vložení textu.
        WindowManager.shared.restorePreviousFocus()

        appLog("📋 Vložený text: \(textToPaste)", level: .info)
        
        // Ak je povolené "Zatvoriť okno pri vložení", zatvoríme ho
        if StatusBarManager.shared.closeWindowOnPaste {
            WindowManager.shared.closeWindow()
        }
    }
    
    /// Uloží **iba pripnuté položky** do JSON súboru
    private func saveHistory() {
        let data: [String: Any] = [
            "pinnedItems": Array(pinnedItems) // Ukladáme len pripnuté položky
        ]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            try jsonData.write(to: historyFileURL)
        } catch {
            appLog("❌ Chyba pri ukladaní histórie: \(error.localizedDescription)", level: .error)
        }
    }

    /// Načíta históriu, **ale iba pripnuté položky**
    private func loadHistory() {
        guard FileManager.default.fileExists(atPath: historyFileURL.path) else { return }
        do {
            let jsonData = try Data(contentsOf: historyFileURL)
            if let data = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                if let savedPinnedItems = data["pinnedItems"] as? [String] {
                    pinnedItems = Set(savedPinnedItems)
                    clipboardHistory = savedPinnedItems // Načítame len pripnuté
                }
            }
        } catch {
            appLog("❌ Chyba pri načítaní histórie: \(error.localizedDescription)", level: .error)
        }
    }
    
    /// Označí alebo odznačí text ako pripnutý
    func togglePin(_ text: String) {
        if pinnedItems.contains(text) {
            pinnedItems.remove(text) // Odstránime z pripnutých
        } else {
            pinnedItems.insert(text) // Pridáme medzi pripnuté
        }

        // Uložíme len pripnuté položky do JSON-u, ale `clipboardHistory` ostane nezmenené
        saveHistory()
    }
}
