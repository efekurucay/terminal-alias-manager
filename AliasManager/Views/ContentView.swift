import SwiftUI

/// Ana uygulama görünümü — NavigationSplitView ile Finder tarzı arayüz.
struct ContentView: View {
    @StateObject private var viewModel = AliasViewModel()
    @State private var showDeleteConfirm = false
    @State private var aliasToDelete: AliasItem?

    var body: some View {
        NavigationSplitView {
            // Sol panel: Alias listesi
            sidebarContent
                .navigationSplitViewColumnWidth(min: 250, ideal: 300)
        } detail: {
            // Sağ panel: Detay
            detailContent
        }
        .navigationTitle("AliasManager")
        .searchable(text: $viewModel.searchText, prompt: "Alias ara...")
        .onAppear {
            viewModel.loadAliases()
        }
        .alert("Bilgi", isPresented: $viewModel.showAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
        .alert("Alias'ı Sil", isPresented: $showDeleteConfirm) {
            Button("İptal", role: .cancel) {}
            Button("Sil", role: .destructive) {
                if let alias = aliasToDelete {
                    viewModel.deleteAlias(alias)
                }
            }
        } message: {
            if let alias = aliasToDelete {
                Text("'\(alias.name)' alias'ını silmek istediğinize emin misiniz?")
            }
        }
        .sheet(isPresented: $viewModel.isShowingAddForm) {
            AliasFormView(isEditing: false) { name, command, comment in
                viewModel.addAlias(name: name, command: command, comment: comment)
            }
        }
        .sheet(isPresented: $viewModel.isShowingEditForm) {
            if let editing = viewModel.editingAlias {
                AliasFormView(isEditing: true, existingAlias: editing) { name, command, comment in
                    viewModel.updateAlias(editing, name: name, command: command, comment: comment)
                }
            }
        }
        .toolbar {
            toolbarContent
        }
    }

    // MARK: - Sidebar

    @ViewBuilder
    private var sidebarContent: some View {
        if viewModel.isLoading {
            ProgressView("Yükleniyor...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.filteredAliases.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: viewModel.searchText.isEmpty ? "terminal" : "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)

                if viewModel.searchText.isEmpty {
                    Text("Henüz alias yok")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Yeni bir alias eklemek için\n+ butonuna tıklayın.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Sonuç bulunamadı")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("'\(viewModel.searchText)' ile eşleşen alias yok.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(viewModel.filteredAliases, selection: $viewModel.selectedAlias) { alias in
                AliasRowView(
                    alias: alias,
                    onToggle: { viewModel.toggleAlias(alias) },
                    onDelete: {
                        aliasToDelete = alias
                        showDeleteConfirm = true
                    },
                    onDuplicate: { viewModel.duplicateAlias(alias) }
                )
                .tag(alias)
            }
            .listStyle(.sidebar)
            .safeAreaInset(edge: .bottom) {
                statusBar
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailContent: some View {
        if let selected = viewModel.selectedAlias {
            AliasDetailView(
                alias: selected,
                onEdit: {
                    viewModel.editingAlias = selected
                    viewModel.isShowingEditForm = true
                },
                onToggle: { viewModel.toggleAlias(selected) },
                onDelete: {
                    aliasToDelete = selected
                    showDeleteConfirm = true
                },
                onDuplicate: { viewModel.duplicateAlias(selected) }
            )
        } else {
            VStack(spacing: 16) {
                Image(systemName: "arrow.left.circle")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                Text("Listeden bir alias seçin")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            Text("\(viewModel.activeCount) aktif")
                .foregroundColor(.green)
            Text("•")
                .foregroundColor(.secondary)
            Text("\(viewModel.disabledCount) devre dışı")
                .foregroundColor(.secondary)
            Text("•")
                .foregroundColor(.secondary)
            Text("\(viewModel.aliases.count) toplam")
                .foregroundColor(.secondary)
        }
        .font(.caption)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            // Sıralama menüsü
            Menu {
                ForEach(AliasViewModel.SortOrder.allCases, id: \.self) { order in
                    Button {
                        viewModel.sortOrder = order
                    } label: {
                        HStack {
                            Text(order.rawValue)
                            if viewModel.sortOrder == order {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
            .help("Sırala")

            // Yenile
            Button {
                viewModel.loadAliases()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("Yenile")
            .keyboardShortcut("r", modifiers: .command)

            // Yeni alias ekle
            Button {
                viewModel.isShowingAddForm = true
            } label: {
                Image(systemName: "plus")
            }
            .help("Yeni Alias Ekle")
            .keyboardShortcut("n", modifiers: .command)
        }

        ToolbarItemGroup(placement: .secondaryAction) {
            // Yedekle
            Button {
                if let path = viewModel.createBackup() {
                    viewModel.alertMessage = "Yedek oluşturuldu: \(path)"
                    viewModel.showAlert = true
                }
            } label: {
                Label("Yedekle", systemImage: "externaldrive.badge.plus")
            }

            // JSON Dışa Aktar
            Button {
                if let data = viewModel.exportToJSON() {
                    let panel = NSSavePanel()
                    panel.allowedContentTypes = [.json]
                    panel.nameFieldStringValue = "aliases.json"
                    panel.begin { response in
                        if response == .OK, let url = panel.url {
                            try? data.write(to: url)
                        }
                    }
                }
            } label: {
                Label("JSON Dışa Aktar", systemImage: "square.and.arrow.up")
            }

            // JSON İçe Aktar
            Button {
                let panel = NSOpenPanel()
                panel.allowedContentTypes = [.json]
                panel.begin { response in
                    if response == .OK, let url = panel.url,
                       let data = try? Data(contentsOf: url) {
                        viewModel.importFromJSON(data)
                    }
                }
            } label: {
                Label("JSON İçe Aktar", systemImage: "square.and.arrow.down")
            }
        }
    }
}

#Preview {
    ContentView()
}
