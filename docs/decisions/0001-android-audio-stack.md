# ADR 0001: Android audio stack

- Status: Accepted
- Date: 2026-08-30

## Context

Milestone 0 requires legally sourced audio playback on Android that continues while the application is in the background and responds to media-notification and headset commands. The UI and domain layers must remain platform-independent so they do not block a future iOS implementation.

Yuzu does not integrate YouTube Music in this milestone. Audio used to verify the pipeline must not come from a reference project or a recording with unclear copyright status.

## Decision

- Use [`just_audio` 0.10.6](https://pub.dev/packages/just_audio) as the playback engine.
- Use [`audio_service` 0.18.19](https://pub.dev/packages/audio_service) for the media session, foreground service, and notification controls.
- Initialize `AudioService` exactly once at application startup. `YuzuAudioHandler` is the only adapter that knows about both plugins; the UI depends only on `PlaybackDriver`.
- Declare an Android foreground service with the `mediaPlayback` type, a media-button receiver, and a wake lock as directed by `audio_service`.
- Generate a 30-second, 16-bit PCM WAV test tone entirely with Yuzu code and write it to the system cache at runtime. The repository neither contains nor downloads third-party media assets.
- Retain the iOS `UIBackgroundModes/audio` configuration in the scaffold, but do not claim iOS support until the application has been built and tested on macOS and an iOS device.

## License review

- [`just_audio` license](https://pub.dev/packages/just_audio/license): Apache-2.0 and MIT.
- [`audio_service` license](https://pub.dev/packages/audio_service/license): MIT.
- These licenses permit use in an open-source project; dependency attribution and license notices must be preserved in distributions according to their respective terms.
- The test WAV is generated entirely by a Yuzu algorithm and carries no external media license.

## Alternatives considered

- `just_audio_background`: simpler configuration, but it remains in beta and offers less control over the queue and media session than Yuzu's production target requires.
- A custom Android Media3/native player: substantially increases platform code and prematurely duplicates the future iOS path, making it unsuitable for the first milestone.
- A bundled sample song: introduces unnecessary provenance and licensing risks.

## Consequences

- Android has real playback, a background service, and notification controls behind an isolated adapter.
- Domain and widget tests use `MemoryPlaybackDriver` and do not initialize a `MethodChannel`.
- Unit tests cover plugin-to-domain mapping; builds and Android runtime checks verify the plugin lifecycle.
- Supporting iOS will require a Mac for building and signing, plus validation of the audio session, interruptions, lock-screen controls, and background lifecycle.
