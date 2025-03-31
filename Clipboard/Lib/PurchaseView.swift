import SwiftUI

struct PurchaseView: View {
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text(LocalizedStringResource("clipboard-pro"))
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(LocalizedStringResource("upgrade-to-pro"))
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "sparkles")
                    Text(LocalizedStringResource("upgrade-to-pro"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)

            Button(action: {
                PurchaseManager.shared.simulatePurchase()
                onClose()
            }) {
                Text(LocalizedStringResource("upgrade-to-pro"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            .background(Color.accentColor)
            .cornerRadius(10)
            .focusable(false)

            Button("close") {
                onClose()
            }
            .padding(.bottom, 16)
            .foregroundColor(.secondary)
            .focusable(false)
        }
        .padding(.horizontal, 24)
        .frame(width: 300)
    }
}
