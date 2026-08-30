# Yuzu Task List

## Task 1 — Documentation baseline

- [x] Product direction, capability map, module specification, constraints, and implementation plan exist.
- [x] The clean-room boundary is explicit.
- Verify: review the Markdown files; no application code is involved.

## Task 2 — Android toolchain

- [x] Install Flutter stable, Dart, Java, and the Android SDK/tooling.
- [x] `flutter doctor -v` reports no Android blocker.
- [x] An emulator or Android device is detected when the environment supports one.
- Dependencies: Task 1.

## Task 3 — Flutter scaffold

- [x] Create the Android/iOS project scaffold, while configuring and building only Android.
- [x] The formatter, analyzer, template test, and debug APK pass.
- [x] `pubspec.yaml` records the actual versions and dependencies.
- Dependencies: Task 2.

## Task 4 — Media contracts

- [x] Tests fail before implementation for `Track`, `MusicProvider`, and queue state.
- [x] Models are immutable and do not depend on Flutter widgets or a concrete provider.
- [x] Focused tests and the full suite pass.
- Dependencies: Task 3.

## Task 5 — Fake catalog

- [x] The fake provider returns deterministic Home sections and Search results.
- [x] Tests can simulate loading, empty, and error states.
- [x] No network calls occur.
- Dependencies: Task 4.

## Task 6 — Material 3 app shell

- [x] Light/dark themes and semantic tokens exist.
- [x] Home/Search/Library navigation renders correctly.
- [x] Widget tests cover themes and navigation.
- Dependencies: Task 3.

## Task 7 — Catalog vertical slice

- [x] Home and Search use the fake provider through ViewModels and repositories.
- [x] Loading, empty, and error states are present.
- [x] Selecting a track sends a playback command.
- Dependencies: Tasks 5, 6.

## Task 8 — Playback domain

- [x] Queue, current item, play/pause, and next/previous behavior are built with TDD.
- [x] Empty-queue and end-of-queue edge cases are tested.
- [x] The domain has no Android API dependency.
- Dependencies: Task 4.

## Task 9 — Player UI

- [x] The mini-player and full player reflect playback state.
- [x] Controls have semantic labels and appropriate touch targets.
- [x] Widget tests cover the primary interactions.
- Dependencies: Tasks 6, 8.

## Task 10 — Android audio adapter

- [x] Legally generated test audio plays on Android.
- [x] Background playback and notification controls work.
- [x] The plugin and license decision is recorded.
- Dependencies: Tasks 8, 9.

## Task 11 — Verification

- [x] The critical flow has an integration test that passes on an Android emulator.
- [x] Android tap targets, tappable labels, and text contrast pass Flutter accessibility guidelines.
- [x] Format, analyze, tests, and the debug APK pass.
- [x] Coverage and APK-size baselines are recorded in `CONSTRAINTS.md`.
- Dependencies: Tasks 7–10.

## Task 12 — Human checkpoint

- [x] The latest debug APK builds, installs, and launches on the Android emulator.
- [x] The user reviews the UI, architecture, and milestone APK.
- [x] Do not begin the YouTube Music adapter before this checkpoint.
- Dependencies: Task 11.

## Task 13 — YouTube Music adapter spec

- [x] Document the guest-only scope, catalog endpoints, privacy, and clean-room boundary.
- [x] Separate `CatalogProvider` from `StreamResolver`; the UI does not know about Innertube.
- [x] Record a decision about the unofficial integration, stability, and policy risks.
- Verify: review the specification and ADR; do not add a network implementation.
- Dependencies: Task 12.
- Files likely touched: `SPEC-youtube-music-adapter.md`, `docs/decisions/0002-youtube-music-upstream.md`.
- Estimated scope: Small (documentation only).

## Checkpoint — Adapter design

- [ ] The maintainer reviews and approves `SPEC-youtube-music-adapter.md` and ADR 0002.
- [ ] Do not begin Task 14 before this checkpoint.

## Task 14 — Catalog transport contract

- [ ] Write tests first for request/response mapping with self-authored, sanitized fixtures.
- [ ] Define timeouts, cancellation, and an error taxonomy for network, parse, rejection, and unsupported-response failures.
- [ ] Do not store cookies, tokens, credentials, or raw user responses.
- Verify: focused tests, `flutter analyze`, `flutter test`.
- Dependencies: Task 13 and the Adapter design checkpoint.
- Files likely touched: `lib/data/youtube_music/transport.dart`, `lib/data/youtube_music/catalog_error.dart`, focused tests/fixtures.
- Estimated scope: Medium (3–5 files).

## Checkpoint — Upstream policy

- [ ] Task 14 remains network-free and passes its offline contract and mapper tests.
- [ ] The maintainer selects an official API, accepts an unofficial guest experiment, or keeps live access disabled.
- [ ] Do not begin Task 15 before this checkpoint.

## Task 15 — Live Search slice

- [ ] Guest Search returns tracks, albums, and artists through the existing `MusicProvider`.
- [ ] Loading, empty, retry, and upstream-error states render correctly with Material 3.
- [ ] Dependency injection can switch between fake and live providers without modifying feature UI.
- Verify: unit/widget tests and a manual check on a network-connected Android device.
- Dependencies: Task 14 and the Upstream policy checkpoint.
- Files likely touched: live provider/search mapper, DI bootstrap, and focused tests.
- Estimated scope: Medium (3–5 files).

## Task 16 — Live Home slice

- [ ] Guest Home returns sections through the provider contract.
- [ ] Continuations do not create duplicate items or request loops.
- [ ] Empty, malformed, and timeout responses produce typed failures and bounded retries.
- Verify: focused tests, the full suite, and a manual Home flow.
- Dependencies: Task 15.
- Files likely touched: Home mapper/provider, ViewModel integration, and focused tests.
- Estimated scope: Medium (3–5 files).

## Task 17 — Album detail slice

- [ ] Album metadata and track lists map to Yuzu-owned domain models.
- [ ] Unavailable albums or missing fields do not crash the UI.
- [ ] Selecting a track creates the correct existing playback command.
- Verify: mapper/provider tests and a widget flow test.
- Dependencies: Task 16.
- Files likely touched: album model/mapper, album ViewModel/screen, and focused tests.
- Estimated scope: Medium (3–5 files).

## Task 18 — Artist detail slice

- [ ] Artist metadata, top tracks, and releases map to domain models.
- [ ] Continuations and optional fields are handled safely.
- [ ] Navigation from Search/Home to an artist works.
- Verify: mapper/provider tests and a widget navigation test.
- Dependencies: Task 17.
- Files likely touched: artist model/mapper, artist ViewModel/screen, and focused tests.
- Estimated scope: Medium (3–5 files).

## Task 19 — Playlist detail slice

- [ ] Guest playlist metadata and track lists are displayed.
- [ ] Private or unavailable playlists return typed errors instead of pretending to be empty lists.
- [ ] Pagination does not duplicate tracks and can be retried.
- Verify: mapper/provider tests and a widget flow test.
- Dependencies: Task 18.
- Files likely touched: playlist model/mapper, playlist ViewModel/screen, and focused tests.
- Estimated scope: Medium (3–5 files).

## Checkpoint — Live catalog

- [ ] Search/Home run with live data on Android.
- [ ] The fake provider still supports the complete offline test suite.
- [ ] The user reviews the catalog before live playback begins.

## Task 20 — Stream resolver spec

- [ ] Define inputs/outputs, required headers, URL expiry, and typed failures.
- [ ] The playback contract does not depend on Innertube DTOs or Android APIs.
- [ ] Explicitly document that the MVP has no sign-in, downloads, or account sync.
- Verify: review the specification and contract tests.
- Dependencies: Task 19 and the Live catalog checkpoint.
- Files likely touched: `SPEC-playback-resolver.md`, provider contracts, and contract tests.
- Estimated scope: Small–Medium (2–4 files).

## Task 21 — One-track playback spike

- [ ] One public track can be resolved and played on Android through the existing audio adapter.
- [ ] Expired URLs, unavailable content, region restrictions, and bot rejection do not crash the application.
- [ ] Do not commit cookies, tokens, or temporary stream URLs.
- Verify: unit tests with fixtures, an Android integration check, and the debug APK.
- Dependencies: Task 20.
- Files likely touched: resolver implementation, transport adapter, and focused tests.
- Estimated scope: Medium (3–5 files).

## Task 22 — Live playback integration

- [ ] Search → queue → mini-player → full player uses the live resolver.
- [ ] Next/previous and background media controls work with live tracks.
- [ ] Fake playback remains available for tests and offline development.
- Verify: the critical integration flow, format, analyze, tests, and the debug APK.
- Dependencies: Task 21.
- Files likely touched: playback controller/driver integration, DI bootstrap, and the integration test.
- Estimated scope: Medium (3–5 files).

## Checkpoint — Live playback

- [ ] The user confirms playback on an Android device.
- [ ] Failure states provide useful messages and bounded retries.
- [ ] Do not begin sign-in or download work.

## Task 23 — Catalog UI polish

- [ ] Artwork loading, placeholders, pagination, and retry states meet Material 3 standards.
- [ ] Text scaling, semantics, and touch targets are tested.
- Verify: appropriate widget/golden checks and a manual device review.
- Dependencies: Task 22.
- Files likely touched: shared catalog widgets, theme tokens and widget tests.
- Estimated scope: Medium (3–5 files).

## Task 24 — Minimal local library

- [ ] Favorites and listening history are stored locally through a repository contract.
- [ ] The schema and migration have tests before they are connected to the UI.
- Verify: persistence tests, widget tests, and the full suite.
- Dependencies: Task 23; persistence-schema changes require prior user approval.
- Files likely touched: library repository/storage adapter, screen/ViewModel, and tests.
- Estimated scope: Medium per approved persistence slice.

## Task 25 — MVP quality pass

- [ ] Privacy disclosure, redacted logging, and open-source notices are complete.
- [ ] Release split APKs are built and measured.
- [ ] The critical flow passes on at least one physical Android device.
- Verify: format, analyze, all tests, a release build, and a manual smoke test.
- Dependencies: Tasks 22–24.
- Files likely touched: privacy/notices, release configuration, and verification docs/tests.
- Estimated scope: Medium (3–5 files per quality slice).
