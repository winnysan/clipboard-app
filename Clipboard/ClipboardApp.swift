import SwiftUI
import Cocoa

/// Hlavná aplikácia,
@main
struct ClipboardApp: App {
    /// Registrácia `AppDelegate`
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        /// Aplikácia beží na pozadí bez GUI
        Settings { EmptyView() }
    }
}
