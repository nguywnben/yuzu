# Implementation Plan: Yuzu Milestone 0 → Milestone 1

## Overview

Dựng nền tảng Flutter Android và một vertical slice nghe nhạc hoàn chỉnh bằng fake provider/audio kiểm thử, đóng Milestone 0 bằng kiểm thử trên thiết bị, sau đó kiểm chứng catalog YouTube Music không đăng nhập qua một adapter clean-room tách biệt. Playback YouTube thật chỉ bắt đầu sau khi catalog và rủi ro upstream đã được xác nhận.

## Architecture Decisions

- Android-first nhưng giữ domain/UI độc lập nền tảng để không khóa đường iOS.
- MVVM và repository/service separation theo hướng dẫn Flutter.
- Material 3 là design system mặc định; component tùy biến phải dùng semantic tokens.
- Provider và playback là contract-first; upstream YouTube không xuất hiện trong feature UI.
- Catalog provider và stream resolver là hai boundary riêng; catalog thành công không đồng nghĩa playback đã sẵn sàng.
- Clean-room: dự án tham khảo chỉ cung cấp feature inventory, hành vi và failure mode; không port mã, asset, UI, test hoặc cấu trúc implementation.
- MVP không đăng nhập, không đồng bộ tài khoản và không tải nhạc ngoại tuyến.

## Task List

### Phase 1: Foundation

- [x] Task 1: Lưu product one-pager, capability map, spec và constraints.
- [x] Task 2: Cài và xác minh Flutter/Android toolchain.
- [x] Task 3: Tạo Flutter project và baseline format/analyze/test/build.

### Checkpoint: Foundation

- [x] `flutter doctor -v` không có lỗi chặn Android.
- [x] Counter-template replacement build và test sạch.

### Phase 2: Contracts and Design System

- [x] Task 4: Viết test và triển khai media domain/provider contract.
- [x] Task 5: Viết test và triển khai fake catalog repository.
- [x] Task 6: Xây Material 3 theme/tokens và app shell có test.

### Checkpoint: Contracts

- [x] Domain và fake provider tests pass.
- [x] Light/dark app shell render ở kích thước phone và tablet.

### Phase 3: First Vertical Slice

- [x] Task 7: Home và Search với loading/empty/error states.
- [x] Task 8: Playback state, queue và controls theo TDD.
- [x] Task 9: Mini-player và full player Material 3.
- [x] Task 10: Android audio/media-session adapter bằng audio kiểm thử.

### Checkpoint: Vertical Slice

- [x] Luồng Home/Search → Track → Player hoạt động end-to-end.
- [x] Background playback và notification được kiểm tra trên Android.

### Phase 4: Verification

- [x] Task 11: Integration test, accessibility pass và baseline coverage.
- [ ] Task 12: Build debug APK và review milestone.

### Checkpoint: Milestone 0

- [x] Critical flow chạy trên thiết bị Android thật hoặc emulator.
- [ ] Người dùng xác nhận APK, navigation và player UI đủ tốt để chuyển sang dữ liệu thật.

### Phase 5: Live Catalog Feasibility

- [ ] Task 13: Viết spec và decision record cho YouTube Music adapter không đăng nhập.
- [ ] Task 14: Định nghĩa catalog transport, DTO boundary và error taxonomy bằng fixtures clean-room.
- [ ] Task 15: Triển khai live Search theo TDD sau `MusicProvider`, có timeout và lỗi có kiểu.
- [ ] Task 16: Triển khai live Home và continuation theo TDD.
- [ ] Task 17: Triển khai album detail theo TDD.
- [ ] Task 18: Triển khai artist detail theo TDD.
- [ ] Task 19: Triển khai playlist detail theo TDD.

### Checkpoint: Live Catalog

- [ ] Fake provider và live provider thay thế được qua dependency injection mà UI không đổi.
- [ ] Search/Home hoạt động với mạng thật; loading, empty, malformed response, timeout và upstream rejection đều được kiểm thử.
- [ ] Không có cookie, token, credential hoặc JSON người dùng trong source/test fixture.

### Phase 6: Playback Feasibility

- [ ] Task 20: Viết spec riêng cho stream resolver, URL expiry, headers và failure recovery.
- [ ] Task 21: Làm playback spike cho một track công khai, không đăng nhập và không download.
- [ ] Task 22: Nối resolver vào queue/audio adapter hiện tại, giữ fake playback làm fallback phát triển.

### Checkpoint: Live Playback

- [ ] Một track có thể đi từ Search → queue → Media3 và phát trên Android.
- [ ] URL hết hạn, nội dung bị chặn, mạng mất và upstream thay đổi đều tạo lỗi hữu ích, không crash.
- [ ] Format, analyze, unit/widget/integration tests và debug APK đều pass.

### Phase 7: MVP Product Slice

- [ ] Task 23: Hoàn thiện catalog UI với ảnh thật, pagination và retry Material 3.
- [ ] Task 24: Thêm thư viện cục bộ tối thiểu: yêu thích và lịch sử nghe.
- [ ] Task 25: Quality pass cho accessibility, privacy, logging đã làm sạch và APK phân phối thử.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Android toolchain chưa tồn tại | High | Cài trước mọi code và dừng nếu `flutter doctor` còn blocker |
| Audio plugin không ổn định | High | Spike riêng, fake playback trước, dependency audit |
| Innertube là API nội bộ, có thể đổi hoặc chặn | High | Feasibility spike sớm, adapter độc lập, fixtures và error taxonomy; giữ fake provider |
| Playback trực tiếp có rủi ro điều khoản/chính sách | High | Decision record trước implementation, không tuyên bố đây là API chính thức, tách resolver để có thể thay thế |
| PO token/cipher làm playback phức tạp | High | Không trộn vào catalog; spike một track và dừng tại checkpoint nếu không ổn định |
| UI mở rộng thiếu nhất quán | Medium | Material tokens và component gallery từ đầu |
| iOS bị khóa bởi Android code | Medium | Platform adapter boundary, không dùng Android API trong domain/UI |

## Open Questions

- License và application id được chốt trước public release, không chặn debug milestone.
- Trước Task 21 cần chốt mức rủi ro chính sách mà dự án chấp nhận đối với playback YouTube trực tiếp.
