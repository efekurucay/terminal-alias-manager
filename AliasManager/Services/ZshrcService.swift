import Foundation

/// Service for reading, writing, and parsing the ~/.zshrc file.
final class ZshrcService {

    // MARK: - Properties

    /// Full path to the zshrc file
    private let zshrcPath: String

    /// Preserves non-alias lines in the file
    private var nonAliasLines: [(index: Int, content: String)] = []

    // MARK: - Init

    init(zshrcPath: String? = nil) {
        if let path = zshrcPath {
            self.zshrcPath = path
        } else {
            self.zshrcPath = NSHomeDirectory() + "/.zshrc"
        }
    }

    // MARK: - Read

    /// Reads and parses aliases from the .zshrc file.
    func loadAliases() throws -> [AliasItem] {
        let fileURL = URL(fileURLWithPath: zshrcPath)

        guard FileManager.default.fileExists(atPath: zshrcPath) else {
            // Return empty list if .zshrc doesn't exist
            return []
        }

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        var aliases: [AliasItem] = []
        nonAliasLines = []

        var pendingComment = ""

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Check for commented-out (disabled) alias
            if let disabledAlias = parseDisabledAlias(trimmed) {
                var alias = disabledAlias
                alias = AliasItem(
                    name: alias.name,
                    command: alias.command,
                    isEnabled: false,
                    comment: pendingComment
                )
                aliases.append(alias)
                pendingComment = ""
                continue
            }

            // Check for active alias line
            if let alias = parseAliasLine(trimmed) {
                var item = alias
                item = AliasItem(
                    name: item.name,
                    command: item.command,
                    isEnabled: true,
                    comment: pendingComment
                )
                aliases.append(item)
                pendingComment = ""
                continue
            }

            // Capture comment line immediately before an alias
            if trimmed.hasPrefix("#") && !trimmed.hasPrefix("#!") {
                let commentText = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                pendingComment = commentText
                continue
            }

            // Not an alias — previous comment wasn't alias-related either
            if !pendingComment.isEmpty {
                nonAliasLines.append((index: index - 1, content: "# \(pendingComment)"))
                pendingComment = ""
            }

            // Non-alias line
            nonAliasLines.append((index: index, content: line))
        }

        // Remaining comment at end of file
        if !pendingComment.isEmpty {
            nonAliasLines.append((index: lines.count, content: "# \(pendingComment)"))
        }

        return aliases
    }

    // MARK: - Write

    /// Writes the alias list back to the .zshrc file.
    /// Preserves non-alias lines.
    func saveAliases(_ aliases: [AliasItem]) throws {
        let fileURL = URL(fileURLWithPath: zshrcPath)

        // Read existing file
        var existingContent = ""
        if FileManager.default.fileExists(atPath: zshrcPath) {
            existingContent = try String(contentsOf: fileURL, encoding: .utf8)
        }

        // Extract non-alias lines
        let existingLines = existingContent.components(separatedBy: .newlines)
        var preservedLines: [String] = []
        var skipNextComment = false

        for (index, line) in existingLines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip comment line before alias (will be rewritten)
            if skipNextComment {
                skipNextComment = false
                continue
            }

            // Is this an active or disabled alias line?
            if parseAliasLine(trimmed) != nil || parseDisabledAlias(trimmed) != nil {
                // Previous line might be this alias's comment
                if index > 0 {
                    let prevTrimmed = existingLines[index - 1].trimmingCharacters(in: .whitespaces)
                    if prevTrimmed.hasPrefix("#") && !prevTrimmed.hasPrefix("#!") && !preservedLines.isEmpty {
                        preservedLines.removeLast()
                    }
                }
                continue
            }

            preservedLines.append(line)
        }

        // Trim trailing blank lines
        while preservedLines.last?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            preservedLines.removeLast()
        }

        // Build the alias block
        var aliasBlock: [String] = []
        if !aliases.isEmpty {
            aliasBlock.append("")
            aliasBlock.append("# ═══════════════════════════════════════════")
            aliasBlock.append("# 🚀 Aliases (Managed by AliasManager)")
            aliasBlock.append("# ═══════════════════════════════════════════")
            for alias in aliases {
                aliasBlock.append(alias.zshrcLine)
            }
            aliasBlock.append("# ═══════════════════════════════════════════")
            aliasBlock.append("")
        }

        // Merge and write
        let finalContent = (preservedLines + aliasBlock).joined(separator: "\n")
        try finalContent.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    // MARK: - Source

    /// Runs `source ~/.zshrc` in the terminal.
    @discardableResult
    func sourceZshrc() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-c", "source \(zshrcPath)"]

        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            print("Failed to run source ~/.zshrc: \(error)")
            return false
        }
    }

    // MARK: - Backup

    /// Creates a backup of the .zshrc file.
    func createBackup() throws -> String {
        let backupPath = zshrcPath + ".backup_\(dateString())"
        try FileManager.default.copyItem(atPath: zshrcPath, toPath: backupPath)
        return backupPath
    }

    /// Restores from a backup file.
    func restoreFromBackup(_ backupPath: String) throws {
        try FileManager.default.removeItem(atPath: zshrcPath)
        try FileManager.default.copyItem(atPath: backupPath, toPath: zshrcPath)
    }

    // MARK: - Private Parse Helpers

    /// Parses a line in "alias name='command'" format.
    private func parseAliasLine(_ line: String) -> AliasItem? {
        let pattern = #"^alias\s+(\S+?)=(['\"])(.*)\2\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: line,
                range: NSRange(line.startIndex..., in: line)
              ) else {
            return parseUnquotedAlias(line)
        }

        guard let nameRange = Range(match.range(at: 1), in: line),
              let commandRange = Range(match.range(at: 3), in: line) else {
            return nil
        }

        let name = String(line[nameRange])
        let command = String(line[commandRange])
            .replacingOccurrences(of: "'\\''", with: "'")

        return AliasItem(name: name, command: command)
    }

    /// Parses an unquoted alias: alias name=command
    private func parseUnquotedAlias(_ line: String) -> AliasItem? {
        let pattern = #"^alias\s+(\S+?)=(\S+)\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: line,
                range: NSRange(line.startIndex..., in: line)
              ) else {
            return nil
        }

        guard let nameRange = Range(match.range(at: 1), in: line),
              let commandRange = Range(match.range(at: 2), in: line) else {
            return nil
        }

        return AliasItem(
            name: String(line[nameRange]),
            command: String(line[commandRange])
        )
    }

    /// Parses a commented-out (disabled) alias: "# alias name='command'"
    private func parseDisabledAlias(_ line: String) -> AliasItem? {
        guard line.hasPrefix("#") else { return nil }
        let uncommented = String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
        guard uncommented.hasPrefix("alias ") else { return nil }
        return parseAliasLine(uncommented)
    }

    // MARK: - Helpers

    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
}
