import SwiftUI

/// Hlavné zobrazenie aplikácie zobrazujúce históriu skopírovaných textov a obrázkov.
/// Každá položka v zozname je klikateľná a umožňuje rýchle vloženie.
struct ContentView: View {
    /// Odkaz na `ClipboardManager` pre správu histórie a interakcie so schránkou.
    @ObservedObject var clipboardManager = ClipboardManager.shared

    /// Odkaz na `SystemPermissionManager` pre kontrolu oprávnení.
    @ObservedObject private var permissionManager = SystemPermissionManager.shared

    /// Premenná na sledovanie, ktorá položka je pod kurzorom myši.
    @State private var hoveredItem: ClipboardItem? = nil

    var body: some View {
        VStack {
            /// Názov aplikácie zobrazený v hlavičke.
            HStack(spacing: 8) {
                Text(LocalizedStringResource("clipboard_app_title"))
                    .font(.headline)
                
                if PurchaseManager.shared.isProUnlocked {
                    Text(LocalizedStringResource("pro"))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                }
            }
            .padding()

            /// Ak chýbajú oprávnenia, zobrazí sa upozornenie s odkazom na ich povolenie.
            if !permissionManager.hasPermission {
                VStack {
                    Text(LocalizedStringResource("application_has_no_permissions"))
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 4)
                    
                    Button(action: {
                        permissionManager.openAccessibilitySettings()
                    }) {
                        Text(LocalizedStringResource("open_settings"))
                            .font(.system(size: 14, weight: .bold))
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 12)
            }

            /// Zabezpečenie správneho skrolovania pri zmene histórie.
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 8) { // Menšie medzery medzi položkami
                        ForEach(clipboardManager.clipboardHistory, id: \.self) { item in
                            let isHovered = hoveredItem == item
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .padding(.leading, 4)
                                
                                HStack(alignment: .top) {
                                    Button(action: {
                                        if let text = item.textValue {
                                            clipboardManager.pasteText(text)
                                        } else if let imageName = item.imageFileName {
                                            clipboardManager.pasteImage(named: imageName)
                                        } else {
                                            appLog("⚠️ Neznámy typ položky na kliknutie", level: .warning)
                                        }
                                    }) {
                                        HStack {
                                            // Zobrazenie textu alebo typ položky
                                            if let text = item.textValue {
                                                Text(text)
                                                    .padding(.vertical, 8)
                                                    .padding(.horizontal, 12)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .lineLimit(3)
                                            } else if let imageName = item.imageFileName,
                                                      let imageURL = ImageManager.shared.imageFileURL(for: imageName),
                                                      let nsImage = NSImage(contentsOf: imageURL) {
                                                
                                                HStack {
                                                    Image(nsImage: nsImage)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                        .frame(maxHeight: 60) // výška obmedzená, šírka sa prispôsobí
                                                        .cornerRadius(4)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 4)
                                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                        )
                                                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
                                                }
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(12)
                                            }
                                            Spacer()
                                        }
                                        .background(isHovered ? Color.white.opacity(0.25) : Color.white.opacity(0.15)) // Efekt hoveru
                                        .cornerRadius(10)
                                        .contentShape(Rectangle()) // Klikateľná celá plocha
                                        .onHover { hovering in
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                hoveredItem = hovering ? item : nil
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain) // Odstránenie defaultného tlačidlového štýlu
                                    .id(item) // Unikátne ID pre skrolovanie
                                    
                                    /// VStack na umiestnenie tlačidiel mimo záznamu vpravo
                                    VStack(alignment: .trailing, spacing: 4) {
                                        /// Tlačidlo na pripnutie položky
                                        Button(action: {
                                            clipboardManager.togglePin(item)
                                        }) {
                                            Image(systemName: clipboardManager.pinnedItems.contains(item) ? "pin.fill" : "pin")
                                        }
                                        .buttonStyle(.borderless) // Odstránenie rámu tlačidla
                                        
                                        /// Tlačidlo na odstránenie položky (Trash)
                                        Button(action: {
                                            clipboardManager.removeItem(item)
                                        }) {
                                            Image(systemName: "trash")
                                        }
                                        .buttonStyle(.borderless) // Odstránenie rámu tlačidla
                                    }
                                    .padding(.leading, 4) // Pridanie medzery pred VStack
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12) // Jemná medzera na krajoch zoznamu
                    .padding(.vertical, 5)
                }
                /// Automatické skrolovanie hore pri zmene histórie.
                .onChange(of: clipboardManager.clipboardHistory) {
                    withAnimation {
                        if let firstItem = clipboardManager.clipboardHistory.first {
                            proxy.scrollTo(firstItem, anchor: .top)
                        }
                    }
                }
            }
        }
        .frame(width: 300, height: 400)
    }
}
