import Foundation

/// Tek bir terminal alias'ını temsil eden model.
/// Örneğin: alias gs='git status'
struct AliasItem: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String       // Alias adı, örn: "gs"
    var command: String    // Alias komutu, örn: "git status"
    var isEnabled: Bool    // Alias aktif mi?
    var comment: String    // Opsiyonel açıklama

    init(
        id: UUID = UUID(),
        name: String,
        command: String,
        isEnabled: Bool = true,
        comment: String = ""
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.isEnabled = isEnabled
        self.comment = comment
    }

    /// Alias'ın .zshrc'ye yazılacak tam satırını döndürür.
    var zshrcLine: String {
        var lines: [String] = []
        if !comment.isEmpty {
            lines.append("# \(comment)")
        }
        let escapedCommand = command.replacingOccurrences(of: "'", with: "'\\''")
        if isEnabled {
            lines.append("alias \(name)='\(escapedCommand)'")
        } else {
            lines.append("# alias \(name)='\(escapedCommand)'")
        }
        return lines.joined(separator: "\n")
    }

    /// Alias satırının kısa önizlemesi
    var preview: String {
        "alias \(name)='\(command)'"
    }
}
