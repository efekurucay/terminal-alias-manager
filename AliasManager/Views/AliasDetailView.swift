import SwiftUI

/// Seçili alias'ın detay paneli (sağ taraf).
struct AliasDetailView: View {
    let alias: AliasItem
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void

    @State private var isCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Üst başlık alanı
            headerSection

            Divider()

            // İçerik
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    commandSection
                    if !alias.comment.isEmpty {
                        commentSection
                    }
                    previewSection
                }
                .padding(24)
            }

            Divider()

            // Alt buton alanı
            actionBar
        }
        .frame(minWidth: 350)
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(alias.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .fontDesign(.monospaced)

                    // Durum etiketi
                    Text(alias.isEnabled ? "Aktif" : "Devre Dışı")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            alias.isEnabled
                                ? Color.green.opacity(0.15)
                                : Color.gray.opacity(0.15)
                        )
                        .foregroundColor(alias.isEnabled ? .green : .secondary)
                        .clipShape(Capsule())
                }
            }

            Spacer()

            // Düzenle butonu
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .help("Düzenle")
        }
        .padding(20)
    }

    private var commandSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Komut", systemImage: "terminal")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack {
                Text(alias.command)
                    .font(.system(.body, design: .monospaced))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(alias.command, forType: .string)
                    withAnimation {
                        isCopied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            isCopied = false
                        }
                    }
                } label: {
                    Image(systemName: isCopied ? "checkmark" : "doc.on.clipboard")
                        .foregroundColor(isCopied ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .help("Komutu Kopyala")
            }
        }
    }

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Açıklama", systemImage: "text.bubble")
                .font(.headline)
                .foregroundColor(.secondary)

            Text(alias.comment)
                .font(.body)
                .foregroundColor(.primary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(".zshrc Satırı", systemImage: "doc.text")
                .font(.headline)
                .foregroundColor(.secondary)

            Text(alias.zshrcLine)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
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

            Spacer()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Sil", systemImage: "trash")
            }
        }
        .padding(16)
    }
}
