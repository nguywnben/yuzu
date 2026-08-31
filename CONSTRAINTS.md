# Constraints

Last reviewed: 2026-08-30

## Floor

- Do not add suppressions to hide analyzer or compiler errors.
- Do not deliver unimplemented stubs, empty catch blocks, or debug output.
- Do not skip or delete tests, or weaken assertions to make checks pass.
- Do not commit secrets, cookies, tokens, or credentials to source control.
- Do not weaken this file to make a change pass its checks.
- Do not copy code, assets, UI, or text from Metrolist, ArchiveTune, or any other reference project.

## Enforced

| Dimension | Rule | Checked by | Runs at |
|---|---|---|---|
| Format | All Dart files match the formatter | `dart format --output=none --set-exit-if-changed .` | task end |
| Static analysis | No analyzer findings | `flutter analyze` | task end |
| Tests | No failed or skipped tests | `flutter test` | task end |
| Android build | The debug APK must build successfully | `flutter build apk --debug` | checkpoint |

## Measured, Not Yet Enforced

| Metric | Baseline | Direction |
|---|---|---|
| Test coverage | 93.4% line coverage (1077/1153), 2026-08-31 | Keep above 90%; tighten gradually after CI is added |
| APK size | 174.4 MiB debug universal APK, 2026-08-31 | Track only for now; set a budget using release split APKs later |

## Exceptions

None. Every new exception must include a rationale, an owner, and an expiration date before it is added.
