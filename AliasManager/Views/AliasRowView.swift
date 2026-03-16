import SwiftUI

/// Liste içinde her bir alias satırının görünümü.
struct AliasRowView: View {
    let alias: AliasItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Durum göstergesi
            Circle()
                .fill(alias.isEnabled ? Color.green : Color.gray.opacity(0.4))
                .frame(width: 8, height: 8)

            // Alias bilgileri
            VStack(alignment: .leading, spacing: 2) {
                Text(alias.name)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(alias.isEnabled ? .primary : .secondary)

                Text(alias.command)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Yorum varsa ikon göster
            if !alias.comment.isEmpty {
                Image(systemName: "text.bubble")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .help(alias.comment)
            }
        }
        .padding(.vertical, 4)
        .opacity(alias.isEnabled ? 1.0 : 0.6)
        .contextMenu {
            Button {
                onToggle()
            } label: {
                Label(
                    alias.isEnabled ? "Devre Dışı Bırak" : "Etkinleştir",
                    systemImage: alias.isEnabled ? "pause.circle" : "play.circle"
                )
            }

            Button {
                onDuplicate()
            } label: {
                Label("Kopyala", systemImage: "doc.on.doc")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Sil", systemImage: "trash")
            }
        }
    }
}
