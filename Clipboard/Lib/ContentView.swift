import SwiftUI

/// Hlavné zobrazenie aplikácie zobrazujúce históriu skopírovaných textov.
/// Každá položka v zozname je klikateľná a umožňuje rýchle vloženie vybraného textu.
struct ContentView: View {
    /// Odkaz na `ClipboardManager` pre správu histórie a interakcie so schránkou.
    @ObservedObject var clipboardManager = ClipboardManager.shared

    /// Premenná na sledovanie, ktorá položka je pod kurzorom myši.
    @State private var hoveredItem: String? = nil

    var body: some View {
        VStack {
            /// Názov aplikácie zobrazený v hlavičke.
            Text(LocalizedStringResource("clipboard_app_title"))
                .font(.headline)
                .padding()

            /// Zabezpečenie správneho skrolovania pri zmene histórie.
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 8) { // Menšie medzery medzi položkami
                        ForEach(clipboardManager.clipboardHistory, id: \.self) { text in
                            HStack(alignment: .top) {
                                Button(action: {
                                    clipboardManager.pasteText(text)
                                }) {
                                    HStack {
                                        /// Zobrazenie skopírovaného textu s obmedzením na 3 riadky.
                                        Text(text)
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading) // Zarovnanie vľavo
                                            .lineLimit(3) // Obmedzenie počtu riadkov
                                        Spacer()
                                    }
                                    .background(hoveredItem == text ? Color.white.opacity(0.25) : Color.white.opacity(0.15)) // Efekt hoveru
                                    .cornerRadius(10)
                                    .contentShape(Rectangle()) // Klikateľná celá plocha
                                    .onHover { hovering in
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            hoveredItem = hovering ? text : nil
                                        }
                                    }
                                }
                                .buttonStyle(.plain) // Odstránenie defaultného tlačidlového štýlu
                                .id(text) // Unikátne ID pre skrolovanie

                                /// VStack na umiestnenie tlačidiel mimo záznamu vpravo
                                VStack(alignment: .trailing, spacing: 4) {
                                    /// Tlačidlo na pripnutie položky
                                    Button(action: {
                                        clipboardManager.togglePin(text)
                                    }) {
                                        Image(systemName: clipboardManager.pinnedItems.contains(text) ? "pin.fill" : "pin")
                                    }
                                    .buttonStyle(.borderless) // Odstránenie rámu tlačidla

                                    /// Tlačidlo na odstránenie položky (Trash)
                                    Button(action: {
                                        clipboardManager.removeItem(text)
                                    }) {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.borderless) // Odstránenie rámu tlačidla
                                }
                                .padding(.leading, 4) // Pridanie medzery pred VStack
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
