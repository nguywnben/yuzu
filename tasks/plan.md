# Implementation Plan: Yuzu Milestone 0

## Overview

Dựng nền tảng Flutter Android và một vertical slice nghe nhạc hoàn chỉnh bằng fake provider/audio kiểm thử trước khi tích hợp YouTube Music thật.

## Architecture Decisions

- Android-first nhưng giữ domain/UI độc lập nền tảng để không khóa đường iOS.
- MVVM và repository/service separation theo hướng dẫn Flutter.
- Material 3 là design system mặc định; component tùy biến phải dùng semantic tokens.
- Provider và playback là contract-first; upstream YouTube không xuất hiện trong feature UI.
- Clean-room: không đọc để port mã dự án tham khảo.

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
- [ ] Task 10: Android audio/media-session adapter bằng audio kiểm thử.

### Checkpoint: Vertical Slice

- [ ] Luồng Home/Search → Track → Player hoạt động end-to-end.
- [ ] Background playback và notification được kiểm tra trên Android.

### Phase 4: Verification

- [ ] Task 11: Integration test, accessibility pass và baseline coverage.
- [ ] Task 12: Build debug APK và review milestone.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Android toolchain chưa tồn tại | High | Cài trước mọi code và dừng nếu `flutter doctor` còn blocker |
| Audio plugin không ổn định | High | Spike riêng, fake playback trước, dependency audit |
| Upstream YouTube thay đổi | High | Adapter độc lập và contract tests |
| UI mở rộng thiếu nhất quán | Medium | Material tokens và component gallery từ đầu |
| iOS bị khóa bởi Android code | Medium | Platform adapter boundary, không dùng Android API trong domain/UI |

## Open Questions

- License và application id được chốt trước public release, không chặn debug milestone.
