# Yuzu

## Problem Statement

How can we build a production-quality, open-source YouTube Music player for Android with a polished Material Design 3 interface and an architecture independent enough to replace the unofficial backend when it changes?

## Recommended Direction

Yuzu is an Android-first Flutter application distributed as an APK outside app stores. The MVP works without an account and prioritizes a stable core listening experience: discovery, search, playback, queue management, and a local library.

The UI, domain, and playback layers must not know YouTube Music implementation details. Every data source must go through `MusicProvider`; the first milestone uses a fake provider and legally generated test audio before adding an anonymous YouTube Music adapter.

## Key Assumptions to Validate

- [ ] Anonymous YouTube Music access is stable enough for Home, Search, and metadata.
- [ ] The Flutter audio stack supports background playback, notifications, and queue restoration on Android.
- [ ] The provider-independent architecture keeps most of the application working when the upstream service changes.

## MVP Scope

- Android APK with no sign-in.
- Home, Search, and basic detail pages.
- Mini-player, full player, queue, and Android media controls.
- Local library: favorites, playlists, and history.
- Light and dark Material Design 3 themes, accessibility, and responsive layouts.
- Unit, widget, and integration tests for core flows.

## Not Doing

- iOS in the MVP: macOS and Xcode are not currently available for building and testing.
- Google sign-in: it substantially increases security risk and complexity.
- Offline downloads, advanced lyrics, an equalizer, casting, and Android Auto: none are required to validate the first vertical slice.
- Copying code, assets, UI, or structure from Metrolist or ArchiveTune: Yuzu is designed independently from platform documentation and observed user behavior.

## Open Questions

- Choose the official application ID and namespace before producing a release build.
