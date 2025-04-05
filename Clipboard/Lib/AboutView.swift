import SwiftUI

/// SwiftUI pohľad zobrazujúci informácie o aplikácii.
/// Tento pohľad sa používa v okne "O aplikácii" spravovanom cez `AboutWindowManager`.
struct AboutView: View {
    /// Verzia aplikácie
    var version: String

    var body: some View {
        VStack(spacing: 16) {
            // Ikonka aplikácie
            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .cornerRadius(12)
            }

            // Názov aplikácie
            Text(LocalizedStringKey("clipboard_app_title"))
                .font(.title2)
                .bold()

            // Lokalizovaný text s verziou aplikácie
            Text(verbatim: String(format: NSLocalizedString("informative_text", comment: ""), version))
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

