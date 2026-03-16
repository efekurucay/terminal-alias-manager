import SwiftUI

/// Form for adding and editing aliases.
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
            // Title
            HStack {
                Text(isEditing ? "Edit Alias" : "New Alias")
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

            // Form fields
            VStack(alignment: .leading, spacing: 16) {
                // Alias Name
                VStack(alignment: .leading, spacing: 6) {
                    Text("Alias Name")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("gs, ll, dev...", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .disabled(isEditing)
                        .opacity(isEditing ? 0.7 : 1.0)

                    if showValidation && !isNameValid {
                        Text("Enter a valid alias name (letters, numbers, _, -)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    if isEditing {
                        Text("Alias name cannot be changed.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Command
                VStack(alignment: .leading, spacing: 6) {
                    Text("Command")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("git status, ls -la, npm run dev...", text: $command)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))

                    if showValidation && !isCommandValid {
                        Text("Command cannot be empty.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                // Description (optional)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description (optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("What does this alias do?", text: $comment)
                        .textFieldStyle(.roundedBorder)
                }

                // Preview
                if !name.isEmpty && !command.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Preview")
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

            // Buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(isEditing ? "Save" : "Add") {
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
