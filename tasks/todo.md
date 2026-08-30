# Yuzu Task List

## Task 1 — Documentation baseline

- [x] Product direction, capability map, module spec, constraints và implementation plan tồn tại.
- [x] Clean-room boundary được ghi rõ.
- Verify: review các file markdown; không có code application.

## Task 2 — Android toolchain

- [x] Cài Flutter stable, Dart, Java và Android SDK/tooling.
- [x] `flutter doctor -v` không có Android blocker.
- [ ] Có emulator hoặc thiết bị Android được nhận diện, nếu môi trường hỗ trợ.
- Dependencies: Task 1.

## Task 3 — Flutter scaffold

- [x] Tạo project Android/iOS scaffold nhưng chỉ cấu hình/build Android.
- [x] Formatter, analyzer, template test và debug APK pass.
- [x] `pubspec.yaml` ghi nhận phiên bản/dependency thực tế.
- Dependencies: Task 2.

## Task 4 — Media contracts

- [x] Test thất bại trước implementation cho `Track`, `MusicProvider` và queue state.
- [x] Model bất biến, không phụ thuộc Flutter widget hay provider cụ thể.
- [x] Focused tests và full suite pass.
- Dependencies: Task 3.

## Task 5 — Fake catalog

- [x] Fake provider trả Home sections và kết quả Search xác định.
- [x] Loading/empty/error đều mô phỏng được trong test.
- [x] Không có network call.
- Dependencies: Task 4.

## Task 6 — Material 3 app shell

- [x] Light/dark theme và semantic tokens tồn tại.
- [x] Navigation Home/Search/Library render đúng.
- [x] Widget tests bao phủ theme và navigation.
- Dependencies: Task 3.

## Task 7 — Catalog vertical slice

- [ ] Home và Search dùng fake provider qua ViewModel/repository.
- [ ] Có loading, empty và error states.
- [ ] Chọn track phát một playback command.
- Dependencies: Tasks 5, 6.

## Task 8 — Playback domain

- [ ] Queue, current item, play/pause, next/previous được viết theo TDD.
- [ ] Edge cases queue rỗng và cuối queue được kiểm thử.
- [ ] Không phụ thuộc Android API.
- Dependencies: Task 4.

## Task 9 — Player UI

- [ ] Mini-player và full player phản ánh playback state.
- [ ] Controls có semantic labels và touch target phù hợp.
- [ ] Widget tests kiểm tra thao tác chính.
- Dependencies: Tasks 6, 8.

## Task 10 — Android audio adapter

- [ ] Audio kiểm thử hợp pháp phát được trên Android.
- [ ] Background playback và notification controls hoạt động.
- [ ] Plugin/license decision được ghi lại.
- Dependencies: Tasks 8, 9.

## Task 11 — Verification

- [ ] Critical flow có integration test.
- [ ] Format, analyze, tests và debug APK pass.
- [ ] Coverage/APK-size baseline được ghi vào `CONSTRAINTS.md`.
- Dependencies: Tasks 7–10.

## Task 12 — Human checkpoint

- [ ] Người dùng review UI, kiến trúc và APK milestone.
- [ ] Không bắt đầu YouTube Music adapter trước checkpoint này.
- Dependencies: Task 11.
