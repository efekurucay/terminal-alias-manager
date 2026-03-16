import SwiftUI

/// AliasManager — macOS Terminal Alias Yönetim Uygulaması
/// ~/.zshrc dosyasındaki alias'ları görsel olarak yönetin.
@main
struct AliasManagerApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 800, height: 550)
        .commands {
            // Dosya menüsü komutları
            CommandGroup(after: .newItem) {
                Button("Yenile") {
                    NotificationCenter.default.post(name: .refreshAliases, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }

            // Yardım menüsü
            CommandGroup(replacing: .help) {
                Button("AliasManager Hakkında") {
                    NSWorkspace.shared.open(
                        URL(string: "https://github.com")!
                    )
                }
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let refreshAliases = Notification.Name("refreshAliases")
}
