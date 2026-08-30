# Spec: app-foundation

## Objective

Create a Flutter Android foundation that Yuzu can build, test, and extend safely. The milestone succeeds when a fake-data vertical slice works end to end: Home/Search → select a track → play test audio → mini-player → full player → queue.

## Tech Stack

- Flutter 3.47.2 stable and Dart 3.13.2.
- Material Design 3 from Flutter's Material library; no separate UI framework is installed.
- MVVM architecture with View, ViewModel, Repository, and Service layers.
- `provider` for dependency injection and `go_router` for navigation, following Flutter guidance.
- `just_audio` 0.10.6 for the playback engine and `audio_service` 0.18.19 for the background media session; the decision and license review are recorded in `docs/decisions/0001-android-audio-stack.md`.

## Commands

```powershell
flutter doctor -v
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test integration_test/critical_flow_test.dart -d <device-id>
flutter test --coverage
flutter build apk --debug
```

## Project Structure

```text
lib/app/                Application bootstrap, DI, router, and theme
lib/core/               Shared primitives with no feature logic
lib/domain/media/       Models and repository/provider contracts
lib/data/               Provider/service implementation
lib/features/           Home, Search, Library, and Player vertical slices
lib/platform/           Android audio/media-session adapter
test/                   Unit and widget tests
integration_test/       Critical user flows
docs/                   Product and architecture decisions
tasks/                  Plans and task state
```

## Code Style

```dart
abstract interface class MusicProvider {
  Future<List<Track>> search(String query);
}
```

- File names use `lower_snake_case.dart`; types use `UpperCamelCase`; members use `lowerCamelCase`.
- Models are immutable; dependencies are passed through constructors; the UI does not call services directly.
- Views contain only rendering, animation, and simple routing; logic belongs in ViewModels or repositories.

## Testing Strategy

- Unit tests cover models, repositories, fake providers, and ViewModels.
- Widget tests cover themes, navigation, loading/empty/error states, and player controls.
- Integration tests cover the Home/Search → Player flow.
- Unit and widget tests do not call YouTube or any live network service.

## Boundaries

- Always: test new behavior before implementation, run format/analyze/test, use semantic Material components, and keep backends behind interfaces.
- Ask first: add dependencies, change the capability map, change the persistence schema, change the license, or add accounts/sign-in.
- Never: commit secrets/cookies/tokens, disable tests or lint rules to make checks pass, hard-code credentials, or copy code/assets/UI from reference projects.

## Success Criteria

- The Android debug APK builds successfully.
- `flutter analyze` and the full test suite pass without errors.
- The core vertical slice works with the fake provider and test audio.
- Light and dark Material 3 themes work with text scaling and semantic labels.
- No feature code depends directly on a YouTube Music implementation.

## Open Questions

- Official application ID.
- `dev.yuzu.yuzu` is the current development application ID and must be finalized before the public release.
