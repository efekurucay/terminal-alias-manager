import Foundation
import SwiftUI

/// Alias listesi için iş mantığını yöneten ViewModel.
@MainActor
final class AliasViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var aliases: [AliasItem] = []
    @Published var searchText: String = ""
    @Published var selectedAlias: AliasItem?
    @Published var isShowingAddForm: Bool = false
    @Published var isShowingEditForm: Bool = false
    @Published var editingAlias: AliasItem?
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var sortOrder: SortOrder = .name
    @Published var isLoading: Bool = false

    // MARK: - Enums

    enum SortOrder: String, CaseIterable {
        case name = "İsim"
        case command = "Komut"
        case status = "Durum"
    }

    // MARK: - Private

    private let service: ZshrcService

    // MARK: - Computed

    /// Arama ve sıralama filtresi uygulanmış alias listesi
    var filteredAliases: [AliasItem] {
        var result = aliases

        // Arama filtresi
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { alias in
                alias.name.lowercased().contains(query) ||
                alias.command.lowercased().contains(query) ||
                alias.comment.lowercased().contains(query)
            }
        }

        // Sıralama
        switch sortOrder {
        case .name:
            result.sort { $0.name.lowercased() < $1.name.lowercased() }
        case .command:
            result.sort { $0.command.lowercased() < $1.command.lowercased() }
        case .status:
            result.sort { ($0.isEnabled ? 0 : 1) < ($1.isEnabled ? 0 : 1) }
        }

        return result
    }

    /// Aktif alias sayısı
    var activeCount: Int {
        aliases.filter(\.isEnabled).count
    }

    /// Devre dışı alias sayısı
    var disabledCount: Int {
        aliases.filter { !$0.isEnabled }.count
    }

    // MARK: - Init

    init(service: ZshrcService = ZshrcService()) {
        self.service = service
    }

    // MARK: - CRUD Operations

    /// Alias'ları .zshrc'den yükler.
    func loadAliases() {
        isLoading = true
        do {
            aliases = try service.loadAliases()
        } catch {
            showError("Alias'lar yüklenemedi: \(error.localizedDescription)")
        }
        isLoading = false
    }

    /// Alias'ları .zshrc'ye kaydeder.
    func saveAliases() {
        do {
            try service.saveAliases(aliases)
            service.sourceZshrc()
        } catch {
            showError("Alias'lar kaydedilemedi: \(error.localizedDescription)")
        }
    }

    /// Yeni alias ekler.
    func addAlias(name: String, command: String, comment: String = "") {
        // İsim kontrolü
        guard !name.isEmpty else {
            showError("Alias adı boş olamaz.")
            return
        }

        guard !command.isEmpty else {
            showError("Komut boş olamaz.")
            return
        }

        // Alias adı zaten var mı?
        if aliases.contains(where: { $0.name == name }) {
            showError("'\(name)' adında bir alias zaten mevcut.")
            return
        }

        // İsimde boşluk veya özel karakter kontrolü
        let validNamePattern = #"^[a-zA-Z_][a-zA-Z0-9_-]*$"#
        guard name.range(of: validNamePattern, options: .regularExpression) != nil else {
            showError("Alias adı sadece harf, rakam, alt çizgi ve tire içerebilir.")
            return
        }

        let newAlias = AliasItem(
            name: name,
            command: command,
            isEnabled: true,
            comment: comment
        )

        aliases.append(newAlias)
        saveAliases()
        selectedAlias = newAlias
    }

    /// Var olan alias'ı günceller.
    func updateAlias(_ alias: AliasItem, name: String, command: String, comment: String) {
        guard let index = aliases.firstIndex(where: { $0.id == alias.id }) else { return }

        // Yeni isim başka bir alias'ta var mı?
        if name != alias.name && aliases.contains(where: { $0.name == name }) {
            showError("'\(name)' adında bir alias zaten mevcut.")
            return
        }

        aliases[index].name = name
        aliases[index].command = command
        aliases[index].comment = comment
        saveAliases()

        // Seçili alias'ı güncelle
        if selectedAlias?.id == alias.id {
            selectedAlias = aliases[index]
        }
    }

    /// Alias siler.
    func deleteAlias(_ alias: AliasItem) {
        aliases.removeAll { $0.id == alias.id }
        if selectedAlias?.id == alias.id {
            selectedAlias = nil
        }
        saveAliases()
    }

    /// Birden fazla alias siler.
    func deleteAliases(_ aliasIDs: Set<UUID>) {
        aliases.removeAll { aliasIDs.contains($0.id) }
        if let sel = selectedAlias, aliasIDs.contains(sel.id) {
            selectedAlias = nil
        }
        saveAliases()
    }

    /// Alias'ı etkinleştir / devre dışı bırak.
    func toggleAlias(_ alias: AliasItem) {
        guard let index = aliases.firstIndex(where: { $0.id == alias.id }) else { return }
        aliases[index].isEnabled.toggle()
        saveAliases()

        if selectedAlias?.id == alias.id {
            selectedAlias = aliases[index]
        }
    }

    /// Alias'ı kopyalar (duplicate).
    func duplicateAlias(_ alias: AliasItem) {
        var newName = alias.name + "_copy"
        var counter = 1
        while aliases.contains(where: { $0.name == newName }) {
            counter += 1
            newName = alias.name + "_copy\(counter)"
        }

        let duplicate = AliasItem(
            name: newName,
            command: alias.command,
            isEnabled: alias.isEnabled,
            comment: alias.comment
        )

        aliases.append(duplicate)
        saveAliases()
        selectedAlias = duplicate
    }

    // MARK: - Backup

    /// .zshrc yedeği oluşturur.
    func createBackup() -> String? {
        do {
            let path = try service.createBackup()
            return path
        } catch {
            showError("Yedek oluşturulamadı: \(error.localizedDescription)")
            return nil
        }
    }

    /// Yedekten geri yükler.
    func restoreFromBackup(_ path: String) {
        do {
            try service.restoreFromBackup(path)
            loadAliases()
        } catch {
            showError("Geri yükleme başarısız: \(error.localizedDescription)")
        }
    }

    // MARK: - Export / Import

    /// Alias'ları JSON olarak dışa aktarır.
    func exportToJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(aliases)
    }

    /// JSON'dan alias'ları içe aktarır.
    func importFromJSON(_ data: Data) {
        let decoder = JSONDecoder()
        guard let imported = try? decoder.decode([AliasItem].self, from: data) else {
            showError("JSON dosyası okunamadı.")
            return
        }

        // Çakışan isimleri atla
        var added = 0
        for alias in imported {
            if !aliases.contains(where: { $0.name == alias.name }) {
                aliases.append(alias)
                added += 1
            }
        }

        if added > 0 {
            saveAliases()
        }

        showInfo("\(added) alias içe aktarıldı. \(imported.count - added) tanesi zaten mevcut olduğu için atlandı.")
    }

    // MARK: - Helpers

    private func showError(_ message: String) {
        alertMessage = message
        showAlert = true
    }

    private func showInfo(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
