import SwiftUI

/// Alias ekleme ve düzenleme formu.
struct AliasFormView: View {
    @Environment(\.dismiss) private var dismiss

    let isEditing: Bool
    let existingAlias: AliasItem?
    let onSave: (String, String, String) -> Void

    @State private var name: String = ""
    @State private var command: String = ""
    @State private var comment: String = ""
    @State private var showValidation: Bool = false

    init(
        isEditing: Bool = false,
        existingAlias: AliasItem? = nil,
        onSave: @escaping (String, String, String) -> Void
    ) {
        self.isEditing = isEditing
        self.existingAlias = existingAlias
        self.onSave = onSave

        if let alias = existingAlias {
            _name = State(initialValue: alias.name)
            _command = State(initialValue: alias.command)
            _comment = State(initialValue: alias.comment)
        }
    }

    // MARK: - Validation

    private var isNameValid: Bool {
        let pattern = #"^[a-zA-Z_][a-zA-Z0-9_-]*$"#
        return !name.isEmpty && name.range(of: pattern, options: .regularExpression) != nil
    }

    private var isCommandValid: Bool {
        !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isFormValid: Bool {
        isNameValid && isCommandValid
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Başlık
            HStack {
                Text(isEditing ? "Alias Düzenle" : "Yeni Alias")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider()

            // Form alanları
            VStack(alignment: .leading, spacing: 16) {
                // Alias Adı
                VStack(alignment: .leading, spacing: 6) {
                    Text("Alias Adı")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("gs, ll, dev...", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .disabled(isEditing)
                        .opacity(isEditing ? 0.7 : 1.0)

                    if showValidation && !isNameValid {
                        Text("Geçerli bir alias adı girin (harf, rakam, _, -)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    if isEditing {
                        Text("Alias adı düzenlenemez.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Komut
                VStack(alignment: .leading, spacing: 6) {
                    Text("Komut")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("git status, ls -la, npm run dev...", text: $command)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))

                    if showValidation && !isCommandValid {
                        Text("Komut boş olamaz.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                // Açıklama (opsiyonel)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Açıklama (opsiyonel)")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("Bu alias ne işe yarar?", text: $comment)
                        .textFieldStyle(.roundedBorder)
                }

                // Önizleme
                if !name.isEmpty && !command.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Önizleme")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        Text("alias \(name)='\(command)'")
                            .font(.system(.caption, design: .monospaced))
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            .padding(20)

            Spacer()

            Divider()

            // Butonlar
            HStack {
                Button("İptal") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(isEditing ? "Kaydet" : "Ekle") {
                    showValidation = true
                    if isFormValid {
                        onSave(name, command, comment)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isFormValid && showValidation)
            }
            .padding(20)
        }
        .frame(width: 420, height: 480)
    }
}
