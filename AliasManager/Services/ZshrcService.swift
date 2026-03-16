import Foundation

/// ~/.zshrc dosyasını okuma, yazma ve parse etme servisi.
final class ZshrcService {

    // MARK: - Properties

    /// Zshrc dosyasının tam yolu
    private let zshrcPath: String

    /// Dosyadaki alias olmayan satırları korumak için
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

    /// .zshrc dosyasını okuyup alias'ları parse eder.
    func loadAliases() throws -> [AliasItem] {
        let fileURL = URL(fileURLWithPath: zshrcPath)

        guard FileManager.default.fileExists(atPath: zshrcPath) else {
            // .zshrc yoksa boş liste döndür
            return []
        }

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        var aliases: [AliasItem] = []
        nonAliasLines = []

        var pendingComment = ""

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Yorum satırı olan devre dışı alias kontrolü
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

            // Aktif alias satırı kontrolü
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

            // Alias'tan hemen önceki yorum satırını yakala
            if trimmed.hasPrefix("#") && !trimmed.hasPrefix("#!") {
                let commentText = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                // Bir sonraki satırda alias var mı kontrol edip
                // şimdilik yorum olarak sakla
                pendingComment = commentText
                // Ama bu yorum alias'a ait olmayabilir, nonAliasLines'a da ekle
                // Eğer bir sonraki iterasyonda alias bulunursa pendingComment kullanılacak
                // Bulamazsa nonAliasLines'a eklenecek
                continue
            }

            // Alias değilse, önceki yorum da alias'a ait değildi
            if !pendingComment.isEmpty {
                nonAliasLines.append((index: index - 1, content: "# \(pendingComment)"))
                pendingComment = ""
            }

            // Alias olmayan satır
            nonAliasLines.append((index: index, content: line))
        }

        // Son satırda kalan yorum
        if !pendingComment.isEmpty {
            nonAliasLines.append((index: lines.count, content: "# \(pendingComment)"))
        }

        return aliases
    }

    // MARK: - Write

    /// Alias listesini .zshrc dosyasına yazar.
    /// Alias olmayan satırları korur.
    func saveAliases(_ aliases: [AliasItem]) throws {
        let fileURL = URL(fileURLWithPath: zshrcPath)

        // Mevcut dosyayı oku
        var existingContent = ""
        if FileManager.default.fileExists(atPath: zshrcPath) {
            existingContent = try String(contentsOf: fileURL, encoding: .utf8)
        }

        // Alias olmayan satırları ayıkla
        let existingLines = existingContent.components(separatedBy: .newlines)
        var preservedLines: [String] = []
        var skipNextComment = false

        for (index, line) in existingLines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Alias'tan önceki yorum satırını atla (yeni halini yazacağız)
            if skipNextComment {
                skipNextComment = false
                continue
            }

            // Aktif veya devre dışı alias satırı mı?
            if parseAliasLine(trimmed) != nil || parseDisabledAlias(trimmed) != nil {
                // Bir önceki satır bu alias'ın yorumu olabilir
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

        // Sondaki boş satırları temizle
        while preservedLines.last?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            preservedLines.removeLast()
        }

        // Alias bloğunu oluştur
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

        // Birleştir ve yaz
        let finalContent = (preservedLines + aliasBlock).joined(separator: "\n")
        try finalContent.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    // MARK: - Source

    /// `source ~/.zshrc` komutunu terminalde çalıştırır.
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
            print("source ~/.zshrc çalıştırılamadı: \(error)")
            return false
        }
    }

    // MARK: - Backup

    /// .zshrc dosyasının yedeğini oluşturur.
    func createBackup() throws -> String {
        let backupPath = zshrcPath + ".backup_\(dateString())"
        try FileManager.default.copyItem(atPath: zshrcPath, toPath: backupPath)
        return backupPath
    }

    /// Yedekten geri yükler.
    func restoreFromBackup(_ backupPath: String) throws {
        try FileManager.default.removeItem(atPath: zshrcPath)
        try FileManager.default.copyItem(atPath: backupPath, toPath: zshrcPath)
    }

    // MARK: - Private Parse Helpers

    /// "alias name='command'" formatındaki satırı parse eder.
    private func parseAliasLine(_ line: String) -> AliasItem? {
        // Regex: alias name='command' veya alias name="command"
        let pattern = #"^alias\s+(\S+?)=(['\"])(.*)\2\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: line,
                range: NSRange(line.startIndex..., in: line)
              ) else {
            // Tırnak olmadan da dene: alias name=command
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

    /// Tırnak işareti olmayan alias: alias name=command
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

    /// "# alias name='command'" formatındaki devre dışı alias'ı parse eder.
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
