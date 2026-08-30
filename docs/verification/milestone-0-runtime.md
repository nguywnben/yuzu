# Milestone 0 Runtime Verification

Date: 2026-08-30

## Environment

- Flutter 3.47.2 stable / Dart 3.13.2
- Android emulator `NomNom_Test_API_35`
- App id `dev.yuzu.yuzu` (development identifier)
- Debug universal APK

## Verified

- APK installs and launches on Android.
- Splash transitions to Home without a Flutter or Android fatal error.
- Home renders both deterministic catalog sections.
- Selecting `Sunrise Drive` opens the mini-player.
- Mini-player opens the full Material 3 player.
- Queue displays `1 of 4`; Previous is disabled at the first item.
- Layout has no visible overflow at 1080×2400.
- WAV PCM 16-bit dài 30 giây do Yuzu tự tổng hợp được decoder tải đủ và media session phát ở trạng thái `PLAYING`.
- Playback tiếp tục qua foreground service loại `mediaPlayback` khi Home launcher là activity foreground.
- Media notification hiển thị metadata và ba control Previous/Pause/Next.
- Android media keys Pause, Play và Next điều khiển session khi ứng dụng ở nền.
- Khi mở lại ứng dụng, mini-player phản ánh track và trạng thái mới từ media session.

## Automated Evidence

- `flutter analyze`: no findings.
- `flutter test`: 47 tests passed.
- `flutter test --coverage`: 96.2% line coverage (641/666).
- `flutter build apk --debug`: passed; 168.0 MiB universal debug APK.
- Android `dumpsys`: active Yuzu media session, `PLAYING`/`PAUSED` transitions, queue metadata updates và foreground notification service đều được xác nhận.

## Not Yet Verified

- Physical loudspeaker output (emulator được chạy với audio output tắt; decoder, buffer và media pipeline đã được xác nhận).
- Lock-screen layout trên thiết bị vật lý.
- Release signing and release split APK size.
- iOS build or runtime behavior.
