import Cocoa
import Combine
import Foundation

/// Trieda zodpovedná za manipuláciu so schránkou.
/// Obsahuje funkcie na získanie označeného textu, správu histórie kopírovania a výpis vybraného textu.
class ClipboardManager: ObservableObject {
    /// Singleton inštancia triedy
    static let shared = ClipboardManager()

    /// Maximálny počet položiek v histórii
    private let maxHistorySize = 100

    /// História skopírovaných položiek (najnovší na začiatku)
    @Published var clipboardHistory: [ClipboardItem] = []
    
    /// Pripnuté položky, ktoré sa uchovajú aj po reštarte aplikácie
    @Published var pinnedItems: Set<ClipboardItem> = []

    /// Sledovanie systémovej schránky
    private var clipboardCheckTimer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var lastWrittenText: String? = nil
    
    /// Hash posledného vloženého obrázka (pre detekciu duplicitného vloženia)
    private var lastWrittenImageHash: String?
    
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
                self.clipboardHistory.removeAll { item in
                    item.type == .text && item.value == copiedText
                }

                // Pridáme ho na začiatok histórie
                self.clipboardHistory.insert(.text(copiedText), at: 0)

                // Ak je pripnutý, ostáva pripnutý a uložíme ho do JSON
                if self.pinnedItems.contains(.text(copiedText)) {
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
    
    /// Vloží prvú položku z histórie podľa jej typu (text alebo obrázok).
    func paste() {
        guard let firstItem = clipboardHistory.first else {
            appLog("⚠️ História je prázdna – nič na vloženie.", level: .warning)
            return
        }

        switch firstItem.type {
        case .text:
            pasteText(firstItem.value)
        case .imageFile:
            pasteImage(named: firstItem.value)
        default:
            appLog("⚠️ Nepodporovaný typ položky na vloženie: \(firstItem.type)", level: .warning)
        }
    }
    
    /// Vloží zadaný text alebo najnovší text z histórie na miesto kurzora.
    /// - Parameter text: Voliteľný parameter. Ak nie je zadaný, použije sa posledný text z histórie.
    func pasteText(_ text: String? = nil) {
         let pasteboard = NSPasteboard.general
 
        // Ak nie je zadaný text, použijeme prvý text z histórie.
        let firstTextFromHistory = clipboardHistory.first(where: { $0.isText })

        let resolvedText: String?
        if let explicitText = text {
            resolvedText = explicitText
        } else {
            resolvedText = firstTextFromHistory?.textValue
        }

        guard let textToPaste = resolvedText else {
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
    
    /// Vloží obrázok (ak je povolená Pro verzia a položka je typu `imageFile`).
    /// - Parameter imageFileName: názov obrázka zo schránky (napr. "XYZ123.png")
    func pasteImage(named imageFileName: String) {
        guard PurchaseManager.shared.isProUnlocked else {
            appLog("🔒 Pokus o vloženie obrázka v bezplatnej verzii", level: .warning)
            return
        }

        guard let imageURL = ImageManager.shared.imageFileURL(for: imageFileName),
              let image = NSImage(contentsOf: imageURL),
              let tiffData = image.tiffRepresentation else {
            appLog("❌ Nepodarilo sa načítať obrázok na vloženie", level: .error)
            return
        }
        
        self.lastWrittenImageHash = ImageManager.shared.hashImageData(tiffData)

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])

        // Simulácia Cmd+V (vloženie)
        let source = CGEventSource(stateID: .hidSystemState)
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        let vDown   = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let vUp     = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        let cmdUp   = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)

        cmdDown?.flags = .maskCommand
        vDown?.flags = .maskCommand

        WindowManager.shared.preserveFocusBeforeOpening()

        cmdDown?.post(tap: .cghidEventTap)
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)

        WindowManager.shared.restorePreviousFocus()

        appLog("🖼️ Vložený obrázok: \(imageFileName)", level: .info)

        if StatusBarManager.shared.closeWindowOnPaste {
            WindowManager.shared.closeWindow()
        }
    }
    
    /// Uloží **iba pripnuté položky** do JSON súboru
    private func saveHistory() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let jsonData = try encoder.encode(Array(pinnedItems)) // Uložíme len pripnuté položky
            try jsonData.write(to: historyFileURL)
            appLog("💾 Pripnuté položky boli uložené: \(pinnedItems.count)", level: .info)
        } catch {
            appLog("❌ Chyba pri ukladaní histórie: \(error.localizedDescription)", level: .error)
        }
    }

    /// Načíta históriu, **ale iba pripnuté položky**
    private func loadHistory() {
        guard FileManager.default.fileExists(atPath: historyFileURL.path) else { return }
        do {
            let jsonData = try Data(contentsOf: historyFileURL)
            let decoder = JSONDecoder()
            let allItems = try decoder.decode([ClipboardItem].self, from: jsonData)

            // Filtrovanie len platných položiek
            let validItems = allItems.filter { $0.textValue != nil || $0.imageFileName != nil }
            let removedCount = allItems.count - validItems.count

            pinnedItems = Set(validItems)
            clipboardHistory = validItems

            appLog("📥 Načítaných pripnutých položiek: \(validItems.count)", level: .info)
            if removedCount > 0 {
                appLog("⚠️ Ignorovaných neplatných položiek v histórii: \(removedCount)", level: .warning)
            }
        } catch {
            appLog("❌ Chyba pri načítaní histórie: \(error.localizedDescription)", level: .error)
        }
    }
    
    /// Označí alebo odznačí text ako pripnutý
    func togglePin(_ item: ClipboardItem) {
        if pinnedItems.contains(item) {
            pinnedItems.remove(item) // Odstránime z pripnutých
        } else {
            pinnedItems.insert(item) // Pridáme medzi pripnuté
        }

        saveHistory() // Uložíme nové pripnuté položky
    }
    
    /// Odstráni položku zo zoznamu aj z pripnutých
    func removeItem(_ item: ClipboardItem) {
        clipboardHistory.removeAll { $0 == item } // Odstráni z histórie
        pinnedItems.remove(item)                  // Odstráni z pripnutých
        saveHistory()                             // Uložíme len pripnuté položky
    }
    
    /// Spustí sledovanie zmien v systémovej schránke
    func startMonitoringClipboard() {
        clipboardCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            let pasteboard = NSPasteboard.general
            let currentChangeCount = pasteboard.changeCount

            if currentChangeCount != self.lastChangeCount {
                self.lastChangeCount = currentChangeCount

                // Text v schránke
                if let newText = pasteboard.string(forType: .string), !newText.isEmpty {
                    if newText == self.lastWrittenText {
                        appLog("🔁 Preskočené: vložený text je náš vlastný", level: .debug)
                        self.lastWrittenText = nil
                        return
                    }

                    appLog("📥 Zistená nová položka v schránke: \(newText)", level: .info)
                    self.clipboardHistory.removeAll { item in
                        item.type == .text && item.value == newText
                    }
                    self.clipboardHistory.insert(.text(newText), at: 0)

                    if self.pinnedItems.contains(.text(newText)) {
                        self.saveHistory()
                    }

                    if self.clipboardHistory.count > self.maxHistorySize {
                        self.clipboardHistory.removeLast()
                    }

                    if StatusBarManager.shared.openWindowOnCopy {
                        WindowManager.shared.openWindow()
                    }
                }
                
                // Obrázok v schránke
                else if let imageData = pasteboard.data(forType: .tiff) {
                    let readableTypes = pasteboard.types?.map { $0.rawValue } ?? []
                    appLog("🖼️ Schránka obsahuje obrázok. Dostupné typy:", level: .info)
                    readableTypes.forEach { appLog("🔸 \($0)", level: .info) }

                    if PurchaseManager.shared.isProUnlocked {
                        let newImageHash = ImageManager.shared.hashImageData(imageData)

                        // Preskočenie, ak ide o náš vlastný obrázok
                        if newImageHash == self.lastWrittenImageHash {
                            appLog("🔁 Preskočené: vložený obrázok je náš vlastný (hash match)", level: .debug)
                            self.lastWrittenImageHash = nil
                            return
                        }

                        if let filename = ImageManager.shared.saveImage(imageData) {
                            let item = ClipboardItem.imageFile(filename)
                            self.clipboardHistory.removeAll { $0 == item }
                            self.clipboardHistory.insert(item, at: 0)

                            self.lastWrittenImageHash = newImageHash

                            appLog("💾 Obrázok pridaný do histórie: \(filename)", level: .info)

                            if self.pinnedItems.contains(item) {
                                self.saveHistory()
                            }

                            if self.clipboardHistory.count > self.maxHistorySize {
                                self.clipboardHistory.removeLast()
                            }

                            if StatusBarManager.shared.openWindowOnCopy {
                                WindowManager.shared.openWindow()
                            }
                        } else {
                            appLog("❌ Ukladanie obrázka zlyhalo", level: .error)
                        }
                    } else {
                        appLog("🔒 Obrázky nie sú povolené v bezplatnej verzii.", level: .warning)
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

// MARK: - Typ reprezentujúci položku v schránke

/// Položka v histórii schránky – text alebo obrázok (base64 alebo odkaz na súbor).
struct ClipboardItem: Codable, Hashable {
    enum ItemType: String, Codable {
        case text, imageBase64, imageFile
    }

    let type: ItemType
    let value: String
    let timestamp: Date

    init(type: ItemType, value: String, timestamp: Date = Date()) {
        self.type = type
        self.value = value
        self.timestamp = timestamp
    }

    // Pôvodné enum príklady nahradíme statickými továrenskými metódami:
    static func text(_ value: String) -> ClipboardItem {
        ClipboardItem(type: .text, value: value)
    }

    static func imageBase64(_ base64: String) -> ClipboardItem {
        ClipboardItem(type: .imageBase64, value: base64)
    }

    static func imageFile(_ fileName: String) -> ClipboardItem {
        ClipboardItem(type: .imageFile, value: fileName)
    }

    var isText: Bool { type == .text }

    var textValue: String? {
        type == .text ? value : nil
    }

    var imageFileName: String? {
        type == .imageFile ? value : nil
    }

    var imageBase64: String? {
        type == .imageBase64 ? value : nil
    }
}


//enum ClipboardItem: Codable, Hashable {
//    case text(String)
//    case imageBase64(String)
//    case imageFile(String)
//
//    enum CodingKeys: String, CodingKey {
//        case type, value
//    }
//
//    enum ItemType: String, Codable {
//        case text, imageBase64, imageFile
//    }
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let type = try container.decode(ItemType.self, forKey: .type)
//
//        switch type {
//        case .text:
//            self = .text(try container.decode(String.self, forKey: .value))
//        case .imageBase64:
//            self = .imageBase64(try container.decode(String.self, forKey: .value))
//        case .imageFile:
//            self = .imageFile(try container.decode(String.self, forKey: .value))
//        }
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//
//        switch self {
//        case .text(let value):
//            try container.encode(ItemType.text, forKey: .type)
//            try container.encode(value, forKey: .value)
//        case .imageBase64(let value):
//            try container.encode(ItemType.imageBase64, forKey: .type)
//            try container.encode(value, forKey: .value)
//        case .imageFile(let value):
//            try container.encode(ItemType.imageFile, forKey: .type)
//            try container.encode(value, forKey: .value)
//        }
//    }
//
//    var isText: Bool {
//        if case .text = self { return true }
//        return false
//    }
//
//    var textValue: String? {
//        if case .text(let value) = self { return value }
//        return nil
//    }
//
//    var imageFileName: String? {
//        if case .imageFile(let name) = self { return name }
//        return nil
//    }
//
//    var imageBase64: String? {
//        if case .imageBase64(let base64) = self { return base64 }
//        return nil
//    }
//}
