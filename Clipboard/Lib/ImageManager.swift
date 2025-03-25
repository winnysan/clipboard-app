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
        self.imageDirectoryURL = baseDirectory.appendingPathComponent("Clipboard/images", isDirectory: true)

        // Vytvorenie adresára, ak ešte neexistuje.
        if !FileManager.default.fileExists(atPath: imageDirectoryURL.path) {
            try? FileManager.default.createDirectory(at: imageDirectoryURL, withIntermediateDirectories: true)
        }
    }
}
