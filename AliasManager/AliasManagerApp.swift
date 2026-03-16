import SwiftUI

/// AliasManager — A native macOS app to manage your terminal aliases.
@main
struct AliasManagerApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 800, height: 550)
        .commands {
            // File menu commands
            CommandGroup(after: .newItem) {
                Button("Refresh") {
                    NotificationCenter.default.post(name: .refreshAliases, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }

            // Help menu
            CommandGroup(replacing: .help) {
                Button("About AliasManager") {
                    NSWorkspace.shared.open(
                        URL(string: "https://github.com/efekurucay/terminal-alias-manager")!
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
