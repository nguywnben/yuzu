# ADR 0001: Android audio stack

- Status: Accepted
- Date: 2026-08-30

## Context

Milestone 0 cần phát audio hợp pháp trên Android, tiếp tục khi ứng dụng ở nền và nhận lệnh từ media notification/headset. UI và domain phải giữ độc lập nền tảng để không khóa đường triển khai iOS sau này.

Yuzu chưa tích hợp YouTube Music ở milestone này. Audio dùng để kiểm chứng pipeline không được lấy từ dự án tham khảo hoặc một bản ghi có bản quyền không rõ ràng.

## Decision

- Dùng [`just_audio` 0.10.6](https://pub.dev/packages/just_audio) làm playback engine.
- Dùng [`audio_service` 0.18.19](https://pub.dev/packages/audio_service) làm media session, foreground service và notification controls.
- Khởi tạo `AudioService` đúng một lần ở application startup. `YuzuAudioHandler` là adapter duy nhất biết hai plugin; UI chỉ phụ thuộc `PlaybackDriver`.
- Android khai báo foreground service loại `mediaPlayback`, media-button receiver và wake lock theo hướng dẫn của `audio_service`.
- Test audio là WAV PCM 16-bit dài 30 giây do mã Yuzu tự tổng hợp và ghi vào system cache lúc chạy. Repository không chứa hay tải media asset của bên thứ ba.
- Giữ cấu hình iOS `UIBackgroundModes/audio` trong scaffold, nhưng iOS chưa được tuyên bố hỗ trợ cho tới khi build và kiểm thử trên macOS/thiết bị iOS.

## License review

- [`just_audio` license](https://pub.dev/packages/just_audio/license): Apache-2.0 và MIT.
- [`audio_service` license](https://pub.dev/packages/audio_service/license): MIT.
- Các giấy phép này cho phép dùng trong dự án mã nguồn mở; attribution/license notices của dependency phải được giữ trong bản phân phối theo điều khoản tương ứng.
- WAV kiểm thử được tạo hoàn toàn từ thuật toán của Yuzu, không có license media bên ngoài.

## Alternatives considered

- `just_audio_background`: cấu hình đơn giản hơn nhưng còn ở trạng thái beta và ít quyền kiểm soát queue/media session hơn yêu cầu production của Yuzu.
- Tự viết Android Media3/native player: tăng đáng kể mã nền tảng và khiến đường iOS phải nhân đôi sớm, không phù hợp milestone đầu.
- Đóng gói một bài nhạc mẫu: thêm rủi ro nguồn gốc và license không cần thiết.

## Consequences

- Android có playback thật, background service và notification controls qua một adapter được cô lập.
- Domain/widget tests dùng `MemoryPlaybackDriver`, không khởi tạo MethodChannel.
- Mapper giữa plugin và domain được unit test; lifecycle plugin được kiểm chứng bằng build và Android runtime.
- Trước khi hỗ trợ iOS cần có máy Mac để build/sign, kiểm tra audio session/interruption, lock-screen controls và background lifecycle.
