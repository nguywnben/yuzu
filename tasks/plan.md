# Implementation Plan: Yuzu Milestone 0 → Milestone 1

## Overview

Build the Flutter Android foundation and a complete music-listening vertical slice with a fake provider and test audio. Close Milestone 0 with on-device verification, then validate a guest YouTube Music catalog through an isolated clean-room adapter. Real YouTube playback begins only after the catalog and upstream risks have been validated.

## Architecture Decisions

- Android-first, while keeping the domain and UI platform-independent so the iOS path remains open.
- MVVM with repository/service separation, following Flutter guidance.
- Material 3 is the default design system; custom components must use semantic tokens.
- Providers and playback are contract-first; upstream YouTube details do not appear in feature UI.
- The catalog provider and stream resolver are separate boundaries; a working catalog does not mean playback is ready.
- Clean-room: reference projects provide only feature inventories, behavior, and failure modes; do not port code, assets, UI, tests, or implementation structures.
- The MVP has no sign-in, account sync, or offline downloads.

## Task List

### Phase 1: Foundation

- [x] Task 1: Record the product one-pager, capability map, specification, and constraints.
- [x] Task 2: Install and verify the Flutter/Android toolchain.
- [x] Task 3: Create the Flutter project and establish the format/analyze/test/build baseline.

### Checkpoint: Foundation

- [x] `flutter doctor -v` reports no Android blockers.
- [x] The counter-template replacement builds and tests cleanly.

### Phase 2: Contracts and Design System

- [x] Task 4: Test and implement the media domain/provider contract.
- [x] Task 5: Test and implement the fake catalog repository.
- [x] Task 6: Build Material 3 themes/tokens and a tested application shell.

### Checkpoint: Contracts

- [x] Domain and fake-provider tests pass.
- [x] The light/dark application shell renders at phone and tablet sizes.

### Phase 3: First Vertical Slice

- [x] Task 7: Build Home and Search with loading, empty, and error states.
- [x] Task 8: Build playback state, queue, and controls with TDD.
- [x] Task 9: Build Material 3 mini-player and full-player interfaces.
- [x] Task 10: Build the Android audio/media-session adapter with test audio.

### Checkpoint: Vertical Slice

- [x] The Home/Search → Track → Player flow works end to end.
- [x] Background playback and notifications are verified on Android.

### Phase 4: Verification

- [x] Task 11: Add integration tests, pass accessibility checks, and establish baseline coverage.
- [x] Task 12: Build the debug APK and review the milestone.

### Checkpoint: Milestone 0

- [x] The critical flow runs on a physical Android device or emulator.
- [x] The user confirms that the APK, navigation, and player UI are ready to move to live data.

### Phase 5: Live Catalog Feasibility

- [x] Task 13: Write the specification and decision record for a guest YouTube Music adapter.

### Checkpoint: Adapter Design

- [x] The maintainer reviews `SPEC-youtube-music-adapter.md` and ADR 0002 before Task 14 begins.

- [x] Task 14: Define the catalog transport, DTO boundary, and error taxonomy with clean-room fixtures.

### Checkpoint: Upstream Policy

- [x] Task 14 remains network-free and passes its offline contract/mapper tests.
- [ ] Before Task 15, the maintainer selects an official API, accepts an unofficial guest experiment, or keeps live access disabled.

- [ ] Task 15: Implement live Search behind `MusicProvider` with TDD, timeouts, and typed errors.
- [ ] Task 16: Implement live Home and continuation handling with TDD.
- [ ] Task 17: Implement album details with TDD.
- [ ] Task 18: Implement artist details with TDD.
- [ ] Task 19: Implement playlist details with TDD.

### Checkpoint: Live Catalog

- [ ] Fake and live providers can be swapped through dependency injection without changing the UI.
- [ ] Search and Home work against the live network; loading, empty, malformed-response, timeout, and upstream-rejection states are tested.
- [ ] Source and test fixtures contain no cookies, tokens, credentials, or user JSON.

### Phase 6: Playback Feasibility

- [ ] Task 20: Write a dedicated specification for the stream resolver, URL expiry, headers, and failure recovery.
- [ ] Task 21: Build a playback spike for one public track without sign-in or downloads.
- [ ] Task 22: Connect the resolver to the existing queue/audio adapter while retaining fake playback as a development fallback.

### Checkpoint: Live Playback

- [ ] A track can travel from Search → queue → Media3 and play on Android.
- [ ] Expired URLs, blocked content, network loss, and upstream changes produce useful errors without crashing.
- [ ] Format, analyze, unit/widget/integration tests, and the debug APK all pass.

### Phase 7: MVP Product Slice

- [ ] Task 23: Polish the catalog UI with live artwork, pagination, and Material 3 retry states.
- [ ] Task 24: Add a minimal local library with favorites and listening history.
- [ ] Task 25: Complete the quality pass for accessibility, privacy, redacted logging, and a trial-distribution APK.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Android toolchain is unavailable | High | Install it before writing code and stop if `flutter doctor` still reports a blocker |
| Audio plugin is unstable | High | Run an isolated spike, build fake playback first, and audit dependencies |
| Innertube is an internal API that may change or block access | High | Run an early feasibility spike, isolate the adapter, use fixtures and an error taxonomy, and retain the fake provider |
| Direct playback carries terms-of-service and policy risk | High | Record the decision before implementation, do not present it as an official API, and isolate the replaceable resolver |
| PO tokens or ciphers complicate playback | High | Keep them out of the catalog, spike one track, and stop at the checkpoint if the result is unstable |
| Unofficial automated access may conflict with YouTube's Terms | High | Keep Task 14 offline and require an explicit policy decision before the first live request |
| UI becomes inconsistent as it grows | Medium | Establish Material tokens and a component gallery early |
| Android code blocks the iOS path | Medium | Maintain a platform-adapter boundary and keep Android APIs out of the domain and UI layers |

## Open Questions

- Finalize the application ID before the public release; it does not block the debug milestone. The license is already GNU GPL v3.0.
- Before Task 15, select the approved catalog upstream path documented in ADR 0002.
- Before Task 21, make a separate decision about the additional policy and technical risk of direct YouTube playback.
