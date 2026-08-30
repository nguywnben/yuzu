# Yuzu

Yuzu is an open-source, Android-first music player built with Flutter and Material Design 3.

The project is currently in its foundation phase. The first milestone uses a fake catalog and test playback to establish the architecture, interface, and test coverage before connecting a YouTube Music backend.

## Platform Support

- Android: the primary development platform and APK distribution target.
- iOS: the scaffold and cross-platform code are retained; macOS and Xcode will be required to build, sign, and test it in the future.
- Sign-in: not included in the MVP.

## Toolchain

- Flutter 3.47.2 stable
- Dart 3.13.2
- Android SDK 36

## Project Checks

```powershell
flutter analyze
flutter test
flutter test integration_test/critical_flow_test.dart -d <device-id>
flutter build apk --debug
```

See [SPEC-app-foundation.md](SPEC-app-foundation.md), [CAPABILITY_MAP.md](CAPABILITY_MAP.md), and [tasks/plan.md](tasks/plan.md) for the current architecture and roadmap.

## Clean-room

Similar applications may only be used to study behavior and user flows. Do not copy source code, assets, interface text, tests, or implementation structures from other projects.

## License

Yuzu is released under the [GNU General Public License v3.0](LICENSE).
