import SwiftUI

struct PurchaseView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text("Clipboard PRO")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Získajte viac funkcií a lepší zážitok")
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Budúce funkcie bez ďalšieho poplatku")
                }
                HStack {
                    Image(systemName: "sparkles")
                    Text("Budúce funkcie bez ďalšieho poplatku")
                }
                HStack {
                    Image(systemName: "sparkles")
                    Text("Budúce funkcie bez ďalšieho poplatku")
                }
                HStack {
                    Image(systemName: "sparkles")
                    Text("Budúce funkcie bez ďalšieho poplatku")
                }
                HStack {
                    Image(systemName: "sparkles")
                    Text("Budúce funkcie bez ďalšieho poplatku")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)

            Button(action: {
                //
            }) {
                Text("Prejsť na PRO")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
                .cornerRadius(10)
                .focusable(false)

            Button("Zavrieť") {
                dismiss()
            }
            .foregroundColor(.secondary)
            .focusable(false)
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .frame(width: 300)
    }
}

