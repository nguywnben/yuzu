# Yuzu

Yuzu là ứng dụng nghe nhạc mã nguồn mở, Android-first, được xây dựng bằng Flutter và Material Design 3.

Hiện dự án đang ở giai đoạn nền tảng. Milestone đầu tiên dùng catalog và playback giả lập để hoàn thiện kiến trúc, giao diện và kiểm thử trước khi kết nối backend YouTube Music.

## Trạng thái hỗ trợ

- Android: nền tảng phát triển và phân phối APK chính.
- iOS: giữ scaffold và code đa nền tảng; cần macOS/Xcode để build, ký và kiểm thử trong tương lai.
- Đăng nhập: không thuộc MVP.

## Toolchain

- Flutter 3.47.2 stable
- Dart 3.13.2
- Android SDK 36

## Kiểm tra dự án

```powershell
flutter analyze
flutter test
flutter test integration_test/critical_flow_test.dart -d <device-id>
flutter build apk --debug
```

Xem [SPEC-app-foundation.md](SPEC-app-foundation.md), [CAPABILITY_MAP.md](CAPABILITY_MAP.md) và [tasks/plan.md](tasks/plan.md) để biết kiến trúc và lộ trình hiện tại.

## Clean-room

Các ứng dụng tương tự chỉ được dùng để tham khảo hành vi và luồng sử dụng. Không sao chép mã nguồn, tài nguyên, chuỗi giao diện, test hoặc cấu trúc triển khai của dự án khác.
