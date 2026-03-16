# AliasManager

macOS için native terminal alias yönetim uygulaması. `~/.zshrc` dosyasındaki alias'larınızı görsel bir arayüzden kolayca yönetin.

## Özellikler

- **Alias Listeleme** — `~/.zshrc` dosyasından alias'ları otomatik parse eder
- **Ekleme / Düzenleme / Silme** — Tam CRUD desteği
- **Etkinleştirme / Devre Dışı Bırakma** — Alias'ları silmeden geçici olarak kapatın
- **Arama** — Alias adı, komut veya açıklamaya göre arayın
- **Sıralama** — İsim, komut veya duruma göre sıralama
- **Kopyalama (Duplicate)** — Mevcut alias'ı hızlıca kopyalayın
- **Otomatik Source** — Değişiklik sonrası `source ~/.zshrc` otomatik çalışır
- **Yedekleme** — `.zshrc` dosyasının yedeğini oluşturun
- **JSON Import/Export** — Alias'larınızı JSON olarak dışa/içe aktarın
- **macOS Native** — SwiftUI + NavigationSplitView ile Finder tarzı arayüz

## Gereksinimler

- macOS 14.0 (Sonoma) veya üzeri
- Xcode 15.2 veya üzeri
- Swift 5.9

## Kurulum

1. Bu projeyi indirin
2. `AliasManager.xcodeproj` dosyasını Xcode ile açın
3. `Cmd + R` ile çalıştırın

## Proje Yapısı

```
AliasManager/
├── AliasManagerApp.swift           ← Uygulama giriş noktası
├── AliasManager.entitlements       ← Dosya erişim izinleri
├── Assets.xcassets/                ← Uygulama ikonu ve renkler
├── Models/
│   └── AliasItem.swift             ← Alias veri modeli
├── Services/
│   └── ZshrcService.swift          ← ~/.zshrc okuma/yazma servisi
├── ViewModels/
│   └── AliasViewModel.swift        ← İş mantığı, arama, CRUD
└── Views/
    ├── ContentView.swift           ← Ana ekran (NavigationSplitView)
    ├── AliasRowView.swift          ← Liste satırı görünümü
    ├── AliasDetailView.swift       ← Detay paneli (sağ taraf)
    └── AliasFormView.swift         ← Ekle / Düzenle formu
```

## Mimari

- **MVVM** (Model-View-ViewModel) pattern
- **SwiftUI** deklaratif UI framework
- **NavigationSplitView** — macOS'a özgü Finder tarzı iki panelli arayüz
- Sandbox kapalı (`com.apple.security.app-sandbox = false`) — `~/.zshrc` dosyasına doğrudan erişim için

## Klavye Kısayolları

| Kısayol | İşlem |
|---------|-------|
| `Cmd + N` | Yeni alias ekle |
| `Cmd + R` | Alias listesini yenile |

## Notlar

- Uygulama varsayılan olarak `~/.zshrc` dosyasını kullanır (Zsh — macOS Catalina ve sonrası varsayılan shell)
- Alias olmayan satırlar korunur, sadece alias bölümü yönetilir
- Değişiklikler `# Aliases (Managed by AliasManager)` bloğu altında yazılır

## Lisans

MIT License
