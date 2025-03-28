import AppKit
import CryptoKit
import Foundation

/// Správca pre prácu s obrázkami.
/// Zodpovedá za ukladanie, načítanie a mazanie obrázkov používaných v histórii.
class ImageManager {
    /// Zdieľaná singleton inštancia.
    static let shared = ImageManager()

    /// Cesta k adresáru, kde sa ukladajú obrázky.
    private let imageDirectoryURL: URL

    /// Privátny inicializátor – nastaví cestu k adresáru.
    private init() {
        let baseDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        imageDirectoryURL = baseDirectory.appendingPathComponent("Clipboard/images", isDirectory: true)

        // Výpis cesty pri inicializácii
        appLog("📂 Adresár pre obrázky: \(imageDirectoryURL.path)", level: .info)

        if !FileManager.default.fileExists(atPath: imageDirectoryURL.path) {
            do {
                try FileManager.default.createDirectory(at: imageDirectoryURL, withIntermediateDirectories: true)
                appLog("📁 Vytvorený adresár: \(imageDirectoryURL.path)", level: .info)
            } catch {
                appLog("❌ Chyba pri vytváraní adresára: \(error.localizedDescription)", level: .error)
            }
        }
    }

    /// Uloží obrázok (ako PNG) na disk a vráti názov súboru.
    /// - Parameter data: Dáta obrázka (napr. TIFF z NSPasteboard).
    /// - Returns: Názov súboru (napr. `ABCD1234.png`) alebo `nil` pri chybe.
    func saveImage(_ data: Data) -> String? {
        guard let imageRep = NSBitmapImageRep(data: data),
              let pngData = imageRep.representation(using: .png, properties: [:])
        else {
            appLog("❌ Obrázok sa nepodarilo konvertovať na PNG.", level: .error)
            return nil
        }

        let filename = UUID().uuidString + ".png"
        let fileURL = imageDirectoryURL.appendingPathComponent(filename)

        // Výpis celej cesty pred uložením
        appLog("📤 Ukladám obrázok do súboru: \(fileURL.path)", level: .debug)

        do {
            try pngData.write(to: fileURL)
            appLog("💾 Obrázok uložený ako: \(filename)", level: .info)
            return filename
        } catch {
            appLog("❌ Chyba pri ukladaní obrázka: \(error.localizedDescription)", level: .error)
            return nil
        }
    }

    /// Vráti úplnú cestu k obrázku uloženému v adresári obrázkov, ak súbor existuje.
    /// - Parameter name: Názov súboru obrázka (napr. „1234.png”).
    /// - Returns: URL adresa obrázka, ak súbor existuje, inak `nil`.
    func imageFileURL(for name: String) -> URL? {
        let url = imageDirectoryURL.appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Vypočíta SHA256 hash z dát.
    /// - Parameter data: Dáta obrázka.
    /// - Returns: Hexadecimálny reťazec s hashom.
    func hashImageData(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02hhx", $0) }.joined()
    }

    /// Vymaže všetky súbory, ktoré nie sú v histórii ani medzi pripnutými položkami.
    /// - Parameters:
    ///   - history: Všetky položky histórie.
    ///   - pinnedItems: Pripnuté položky (ostávajú zachované).
    func cleanupUnusedImages(history: [ClipboardItem], pinnedItems: Set<ClipboardItem>) {
        let relevantNames = Set(
            history.filter { item in
                item.type != .imageFile || pinnedItems.contains(item)
            }.compactMap { $0.imageFileName } +
                pinnedItems.compactMap { $0.imageFileName }
        )

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: imageDirectoryURL, includingPropertiesForKeys: nil)

            for url in fileURLs {
                let fileName = url.lastPathComponent
                if !relevantNames.contains(fileName) {
                    try FileManager.default.removeItem(at: url)
                    appLog("🧹 Vymazaný nepoužívaný obrázok: \(fileName)", level: .info)
                }
            }
        } catch {
            appLog("❌ Chyba pri čistení obrázkov: \(error.localizedDescription)", level: .error)
        }
    }
}
