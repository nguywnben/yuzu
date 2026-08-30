# Yuzu

## Problem Statement

Làm thế nào để xây dựng một trình nghe nhạc YouTube Music mã nguồn mở cho Android có chất lượng production, giao diện Material Design 3 chỉnh chu và kiến trúc đủ độc lập để backend không chính thức có thể được thay thế khi thay đổi?

## Recommended Direction

Yuzu là ứng dụng Flutter Android-first, phát hành dưới dạng APK ngoài store. MVP hoạt động không cần tài khoản và ưu tiên một trải nghiệm nghe nhạc cốt lõi ổn định: khám phá, tìm kiếm, phát nhạc, hàng đợi và thư viện cục bộ.

Phần giao diện, domain và playback không được biết chi tiết YouTube Music. Mọi nguồn dữ liệu phải đi qua `MusicProvider`; milestone đầu dùng provider giả và audio kiểm thử hợp pháp, sau đó mới thêm adapter YouTube Music ẩn danh.

## Key Assumptions to Validate

- [ ] Nguồn YouTube Music ẩn danh đủ ổn định cho Home, Search và metadata.
- [ ] Audio stack Flutter đáp ứng phát nền, notification và khôi phục queue trên Android.
- [ ] Kiến trúc provider độc lập giữ phần lớn ứng dụng hoạt động khi upstream thay đổi.

## MVP Scope

- Android APK, không đăng nhập.
- Home, Search và trang chi tiết cơ bản.
- Mini-player, full player, queue và media controls Android.
- Library cục bộ: yêu thích, playlist và lịch sử.
- Material Design 3 sáng/tối, accessibility và responsive layout.
- Kiểm thử unit, widget và integration cho luồng cốt lõi.

## Not Doing

- iOS trong MVP: chưa có macOS/Xcode để build và kiểm thử.
- Đăng nhập Google: tăng đáng kể rủi ro bảo mật và độ phức tạp.
- Tải nhạc ngoại tuyến, lyrics nâng cao, equalizer, casting và Android Auto: không cần để chứng minh lát cắt đầu tiên.
- Sao chép mã, asset, UI hoặc cấu trúc từ Metrolist/ArchiveTune: Yuzu được thiết kế độc lập từ tài liệu nền tảng và hành vi người dùng.

## Open Questions

- Chọn giấy phép nguồn mở trước bản phát hành công khai đầu tiên.
- Chọn application id và namespace chính thức trước khi tạo bản release.
