import SwiftUI
import Cocoa

/// Hlavna aplikacia
@main
struct ClipboardApp: App {
    // Registracia AppDelegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings { EmptyView() } // Prazdne nastavenia, aby aplikácia bežala
    }
}
