import SwiftUI

/// Hlavné zobrazenie aplikácie zobrazujúce históriu skopírovaných textov.
/// Každá položka v zozname je klikateľná a po prejdení myšou sa mierne stmaví.
struct ContentView: View {
    /// Odkaz na ClipboardManager pre správu histórie a interakcie
    @ObservedObject var clipboardManager = ClipboardManager.shared

    /// ScrollView proxy pre automatické rolovanie hore
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        VStack {
            Text(LocalizedStringResource("clipboard_app_title"))
                .font(.headline)
                .padding()

            ScrollViewReader { proxy in
                ScrollView { // Použitie ScrollView namiesto List na odstránenie oddelovačov
                    VStack(spacing: 10) { // Medzera medzi položkami
                        ForEach(clipboardManager.clipboardHistory, id: \.self) { text in
                            HStack {
                                Text(text)
                                    .padding()
                                    .frame(maxHeight: 100)
                                Spacer() // Rozšíri klikateľnú plochu na celý riadok
                            }
                            .onHover { hovering in
                                withAnimation {
                                    if hovering {
                                        // Pri hoveri stmaví pozadie
                                        self.hoveredItem = text
                                    } else {
                                        self.hoveredItem = nil
                                    }
                                }
                            }
                            .background(self.hoveredItem == text ? Color.white.opacity(0.25) : Color.white.opacity(0.15)) // Použitie hover efektu
                            .cornerRadius(10) // Zaoblené rohy
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1) // Jemný okraj
                            )
                            .contentShape(Rectangle()) // Umožní kliknutie kdekoľvek na riadku
                            .onTapGesture {
                                clipboardManager.printSelectedText(text)
                            }
                            .id(text) // Každý prvok dostane unikátne ID pre správne skrolovanie
                        }
                    }
                    .padding(.horizontal, 15) // Medzera na krajoch zoznamu
                    .padding(.vertical, 5) // Menšia medzera na vrchu a spodku
                }
                .onChange(of: clipboardManager.clipboardHistory) {
                    withAnimation {
                        if let firstItem = clipboardManager.clipboardHistory.first {
                            proxy.scrollTo(firstItem, anchor: .top) // Scroll hore
                        }
                    }
                }
            }
        }
        .frame(width: 300, height: 400)
    }

    /// Premenná na sledovanie, ktorá položka je pod kurzorom
    @State private var hoveredItem: String? = nil
}
