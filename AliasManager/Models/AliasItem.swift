import Foundation

/// Represents a single terminal alias.
/// Example: alias gs='git status'
struct AliasItem: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String       // Alias name, e.g. "gs"
    var command: String    // Alias command, e.g. "git status"
    var isEnabled: Bool    // Whether the alias is active
    var comment: String    // Optional description

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

    /// Returns the full line to be written to .zshrc.
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

    /// Short preview of the alias line
    var preview: String {
        "alias \(name)='\(command)'"
    }
}
