# Capability Map: Yuzu

| Module id | Responsibility | Depends on |
|---|---|---|
| `app-foundation` | Toolchain, cấu hình, dependency injection, routing và quality gates | — |
| `design-system` | Material 3 theme, tokens, component dùng chung và accessibility | `app-foundation` |
| `media-core` | Domain model, queue state và các provider contract | `app-foundation` |
| `catalog` | Home, Search, album, artist và playlist | `media-core` |
| `playback` | Audio engine, queue, mini/full player và Android media session | `media-core` |
| `library` | Yêu thích, playlist và lịch sử cục bộ | `media-core` |
| `account-sync` | Đăng nhập và đồng bộ provider trong giai đoạn sau | `catalog`, `library` |
| `offline-media` | Cache/download khi được đưa vào phạm vi | `playback`, `library` |
| `release-quality` | Test, CI, privacy, observability và đóng gói APK | tất cả module |

Build order: `app-foundation` → `design-system`, `media-core` → `catalog`, `playback` → vertical slice → `library` → `account-sync`, `offline-media` → `release-quality`.

Các module id là ổn định. Interface giữa các module thuộc về module cung cấp contract; dependency không được tạo chu trình.
