import SwiftUI

/// SwiftUI zobrazenie pre okno „O aplikácii“.
struct AboutView: View {
    /// Verzia aplikácie, zvyčajne získaná z Info.plist.
    var version: String

    /// Pomocná funkcia na vykreslenie jedného riadku s funkciou a ikonou.
    /// - Parameters:
    ///   - icon: Systémový SF symbol názov ikony.
    ///   - text: Lokalizačný kľúč s popisom funkcie.
    @ViewBuilder
    private func featureRow(icon: String, text: String) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: icon)
                .frame(width: 24, height: 24)
                .foregroundColor(.accentColor)
                .imageScale(.medium)
                .alignmentGuide(.firstTextBaseline) { d in d[VerticalAlignment.center] }

            Text(LocalizedStringKey(text))
        }
    }

    /// Telo pohľadu AboutView.
    var body: some View {
        VStack(spacing: 28) {
            // Horný panel s ikonou a názvom/verziou
            HStack(alignment: .center, spacing: 28) {
                if let icon = NSApp.applicationIconImage {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .cornerRadius(18)
                        .shadow(radius: 5)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedStringKey("clipboard_app_title"))
                        .font(.system(size: 22, weight: .bold))
                    Text(String(format: NSLocalizedString("v%@", comment: ""), version))
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 32)

            Divider()
                .padding(.horizontal)

            // Popis a zoznam funkcií vedľa seba
            HStack(alignment: .top, spacing: 32) {
                Text(LocalizedStringKey("clipboard_about_description"))
                    .font(.system(size: 15))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 12) {
                    featureRow(icon: "clipboard", text: "feature_history")
                    featureRow(icon: "photo", text: "feature_images")
                    featureRow(icon: "pin.fill", text: "feature_pin")
                    featureRow(icon: "keyboard", text: "feature_shortcuts")
                    featureRow(icon: "bolt.fill", text: "feature_autostart")
                }
                .font(.system(size: 15, weight: .medium))
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.quaternaryLabelColor).opacity(0.2))
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 32)

            Divider()
                .padding(.horizontal)

            // Tlačidlá odkazu na projekt a podporu
            HStack(spacing: 20) {
                Link(destination: URL(string: "https://winnysan.github.io/clipboard-app")!) {
                    Label(LocalizedStringKey("about_project"), systemImage: "house.fill")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                }
                .font(.system(size: 15, weight: .medium))
                .buttonStyle(.bordered)

                Link(destination: URL(string: "https://buymeacoffee.com/winnysan")!) {
                    Label(LocalizedStringKey("support_development"), systemImage: "cup.and.saucer.fill")
                        .padding(.horizontal, 18)
                        .padding(.vertical, 7)
                }
                .font(.system(size: 15, weight: .medium))
                .buttonStyle(.borderedProminent)
            }

            // Upozornenie na oprávnenie prístupnosti
            VStack(spacing: 8) {
                Text(LocalizedStringKey("accessibility_permission_notice"))
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)

                Text(LocalizedStringKey("accessibility_permission_location"))
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Copyright
            Text(LocalizedStringKey("copyright_notice"))
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 28)
    }
}
