# Wave 6A Live Discovery Verification

Date: 2026-08-31

## Scope

- Guest-only, read-only Search for tracks, albums, and artists.
- Guest Home discovery shelves containing albums and playlists/mixes.
- Opaque Home continuation handling with deduplication and loop prevention.
- Anonymous browse context retained only in transport memory; it is never persisted, logged, or exposed through domain models.

## Automated checks

- `dart format --output=none --set-exit-if-changed .`: passed.
- `flutter analyze`: passed with no findings.
- `flutter test --coverage`: 101 tests passed.
- `flutter build apk --debug`: passed for version 0.2.0+3.
- `flutter build apk --release --split-per-abi`: passed for ARMv7, ARM64, and x86-64.
- Line coverage: 93.1% (1408/1513).
- Guest Home smoke: first page mapped 2 sections and 9 items.
- Guest Home continuation smoke: next page mapped 2 sections and 12 items.

Smoke output contains only aggregate counts and failure categories. It does not contain response bodies, catalog titles, IDs, continuation values, or anonymous context values.

## Device status

- The maintainer confirmed live Search results on a physical Android device.
- Android Studio AVD execution remains unavailable because emulator hardware acceleration is not installed on the host.
- Physical-device verification of the new live Home UI is pending installation of the Wave 6A APK.

The split APKs are 15.6–19.5 MiB and are signed with the existing Android debug certificate for trial installation only. A dedicated release key remains a Wave 8 release task.

## Boundary

Wave 6A displays discovery entities but does not open album or playlist track lists. Those detail flows belong to Wave 6B. Live stream resolution and audio playback belong to Wave 7.
