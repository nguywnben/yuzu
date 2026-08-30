# Spec: app-foundation

## Objective

Tạo nền tảng Flutter Android có thể build, test và mở rộng an toàn cho Yuzu. Thành công của milestone là một lát cắt dùng dữ liệu giả: Home/Search → chọn track → phát audio kiểm thử → mini-player → full player → queue.

## Tech Stack

- Flutter 3.47.2 stable và Dart 3.13.2.
- Material Design 3 từ Flutter Material library; không cài một framework UI riêng.
- Kiến trúc MVVM với View, ViewModel, Repository và Service.
- `provider` cho dependency injection và `go_router` cho navigation theo khuyến nghị Flutter.
- `just_audio` 0.10.6 cho playback engine và `audio_service` 0.18.19 cho background media session; quyết định và license được ghi tại `docs/decisions/0001-android-audio-stack.md`.

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
lib/app/                Application bootstrap, DI, router và theme
lib/core/               Primitive dùng chung, không chứa feature logic
lib/domain/media/       Model và repository/provider contract
lib/data/               Provider/service implementation
lib/features/           Home, Search, Library và Player theo vertical slice
lib/platform/           Adapter Android cho audio/media session
test/                   Unit và widget tests
integration_test/       Critical user flows
docs/                   Product và architecture decisions
tasks/                  Plan và task state
```

## Code Style

```dart
abstract interface class MusicProvider {
  Future<List<Track>> search(String query);
}
```

- Tên file `lower_snake_case.dart`; type `UpperCamelCase`; member `lowerCamelCase`.
- Model bất biến; dependency truyền qua constructor; UI không gọi service trực tiếp.
- View chỉ chứa rendering, animation và routing đơn giản; logic nằm ở ViewModel/repository.

## Testing Strategy

- Unit test cho model, repository, provider giả và ViewModel.
- Widget test cho theme, navigation, trạng thái loading/empty/error và player controls.
- Integration test cho luồng Home/Search → Player.
- Không gọi YouTube hoặc dịch vụ mạng thật trong unit/widget test.

## Boundaries

- Always: test behavior mới trước implementation, chạy format/analyze/test, dùng semantic Material components, giữ backend sau interface.
- Ask first: thêm dependency, thay capability map, thay persistence schema, thay license, thêm account/login.
- Never: commit secret/cookie/token, tắt test/lint để lấy màu xanh, hard-code credential, copy code/asset/UI từ dự án tham khảo.

## Success Criteria

- Android debug APK build thành công.
- `flutter analyze` và toàn bộ test không có lỗi.
- Lát cắt cốt lõi chạy với fake provider và audio kiểm thử.
- Light/dark Material 3 hoạt động với text scaling và semantic labels.
- Không có feature code phụ thuộc trực tiếp implementation YouTube Music.

## Open Questions

- Application id chính thức.
- `dev.yuzu.yuzu` hiện là application id phát triển; phải chốt trước public release.
