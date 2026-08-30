# Capability Map: Yuzu

| Module id | Responsibility | Depends on |
|---|---|---|
| `app-foundation` | Toolchain, configuration, dependency injection, routing, and quality gates | — |
| `design-system` | Material 3 theme, tokens, shared components, and accessibility | `app-foundation` |
| `media-core` | Domain models, queue state, and provider contracts | `app-foundation` |
| `catalog` | Home, Search, albums, artists, and playlists | `media-core` |
| `playback` | Audio engine, queue, mini/full player, and Android media session | `media-core` |
| `library` | Local favorites, playlists, and history | `media-core` |
| `account-sync` | Account sign-in and provider sync in a later phase | `catalog`, `library` |
| `offline-media` | Caching and downloads when brought into scope | `playback`, `library` |
| `release-quality` | Testing, CI, privacy, observability, and APK packaging | all modules |

Build order: `app-foundation` → `design-system`, `media-core` → `catalog`, `playback` → vertical slice → `library` → `account-sync`, `offline-media` → `release-quality`.

Module IDs are stable. An interface between modules belongs to the module that provides the contract; dependencies must not form cycles.
