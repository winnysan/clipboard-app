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
    
    /// Sledovanie systémovej schránky
    private var clipboardCheckTimer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var lastWrittenText: String? = nil
    
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

        let filePath = appDirectory.appendingPathComponent("clipboard_history.json")

        // Logovanie kompletnej cesty v terminálovom formáte
        appLog("📂 Súbor histórie: \"\(filePath.path)\"", level: .info)

        return filePath
    }()

    /// Privátny inicializátor zabraňujúci vytvoreniu ďalších inštancií.
    private init() {
        loadHistory()
    }

    /// Skopíruje alebo vystrihne označený text zo systému, uloží ho do histórie a zobrazí okno aplikácie.
    /// - Parameter cut: Ak je true, vykoná vystrihnutie (Cmd + X). Inak kopírovanie (Cmd + C).
    func copySelectedText(cut: Bool = false) {
        let pasteboard = NSPasteboard.general

        if cut {
            KeyboardManager.simulateCmdX()
        } else {
            KeyboardManager.simulateCmdC()
        }

        // Po krátkom čase prečítame obsah schránky a spracujeme ho
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let copiedText = pasteboard.string(forType: .string), !copiedText.isEmpty {
                if cut {
                    appLog("📋 Vystrihnutý text: \(copiedText)", level: .info)
                } else {
                    appLog("📋 Skopírovaný text: \(copiedText)", level: .info)
                }

                // Skontrolujeme, či už existuje v histórii a odstránime ho
                self.clipboardHistory.removeAll { $0 == copiedText }

                // Pridáme ho na začiatok histórie
                self.clipboardHistory.insert(copiedText, at: 0)

                // Ak je pripnutý, ostáva pripnutý a uložíme ho do JSON
                if self.pinnedItems.contains(copiedText) {
                    self.saveHistory()
                }

                // Zabezpečíme, že história nepresiahne maximálny limit
                if self.clipboardHistory.count > self.maxHistorySize {
                    self.clipboardHistory.removeLast()
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
        lastWrittenText = textToPaste

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
    
    /// Odstráni položku zo zoznamu aj z pripnutých
    func removeItem(_ text: String) {
        clipboardHistory.removeAll { $0 == text } // Odstráni z histórie
        pinnedItems.remove(text) // Odstráni z pripnutých
        saveHistory() // Uložíme len pripnuté položky
    }
    
    /// Spustí sledovanie zmien v systémovej schránke
    func startMonitoringClipboard() {
        clipboardCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            let pasteboard = NSPasteboard.general
            let currentChangeCount = pasteboard.changeCount

            if currentChangeCount != self.lastChangeCount {
                self.lastChangeCount = currentChangeCount

                if let newText = pasteboard.string(forType: .string), !newText.isEmpty {
                    if newText == self.lastWrittenText {
                        appLog("🔁 Preskočené: vložený text je náš vlastný", level: .debug)
                        self.lastWrittenText = nil
                        return
                    }

                    appLog("📥 Zistená nová položka v schránke: \(newText)", level: .info)
                    self.clipboardHistory.removeAll { $0 == newText }
                    self.clipboardHistory.insert(newText, at: 0)

                    if self.pinnedItems.contains(newText) {
                        self.saveHistory()
                    }

                    if self.clipboardHistory.count > self.maxHistorySize {
                        self.clipboardHistory.removeLast()
                    }

                    if StatusBarManager.shared.openWindowOnCopy {
                        WindowManager.shared.openWindow()
                    }
                }
            }
        }

        RunLoop.main.add(clipboardCheckTimer!, forMode: .common)
        appLog("🔄 Spustené sledovanie systémovej schránky", level: .info)
    }
    
    /// Zastaví sledovanie zmien v systémovej schránke.
    func stopMonitoringClipboard() {
        clipboardCheckTimer?.invalidate()
        clipboardCheckTimer = nil
        appLog("🛑 Sledovanie systémovej schránky bolo zastavené", level: .info)
    }
}
