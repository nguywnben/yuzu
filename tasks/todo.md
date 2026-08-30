# Yuzu Task List

## Task 1 — Documentation baseline

- [x] Product direction, capability map, module spec, constraints và implementation plan tồn tại.
- [x] Clean-room boundary được ghi rõ.
- Verify: review các file markdown; không có code application.

## Task 2 — Android toolchain

- [x] Cài Flutter stable, Dart, Java và Android SDK/tooling.
- [x] `flutter doctor -v` không có Android blocker.
- [x] Có emulator hoặc thiết bị Android được nhận diện, nếu môi trường hỗ trợ.
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

- [x] Home và Search dùng fake provider qua ViewModel/repository.
- [x] Có loading, empty và error states.
- [x] Chọn track phát một playback command.
- Dependencies: Tasks 5, 6.

## Task 8 — Playback domain

- [x] Queue, current item, play/pause, next/previous được viết theo TDD.
- [x] Edge cases queue rỗng và cuối queue được kiểm thử.
- [x] Không phụ thuộc Android API.
- Dependencies: Task 4.

## Task 9 — Player UI

- [x] Mini-player và full player phản ánh playback state.
- [x] Controls có semantic labels và touch target phù hợp.
- [x] Widget tests kiểm tra thao tác chính.
- Dependencies: Tasks 6, 8.

## Task 10 — Android audio adapter

- [x] Audio kiểm thử hợp pháp phát được trên Android.
- [x] Background playback và notification controls hoạt động.
- [x] Plugin/license decision được ghi lại.
- Dependencies: Tasks 8, 9.

## Task 11 — Verification

- [x] Critical flow có integration test và đã pass trên Android emulator.
- [x] Android tap targets, tappable labels và text contrast pass Flutter accessibility guidelines.
- [x] Format, analyze, tests và debug APK pass.
- [x] Coverage/APK-size baseline được ghi vào `CONSTRAINTS.md`.
- Dependencies: Tasks 7–10.

## Task 12 — Human checkpoint

- [x] Debug APK mới đã build, cài và khởi chạy trên Android emulator.
- [ ] Người dùng review UI, kiến trúc và APK milestone.
- [ ] Không bắt đầu YouTube Music adapter trước checkpoint này.
- Dependencies: Task 11.

## Task 13 — YouTube Music adapter spec

- [ ] Ghi rõ phạm vi guest-only, catalog endpoints, privacy và clean-room boundary.
- [ ] Tách `CatalogProvider` khỏi `StreamResolver`; UI không biết Innertube.
- [ ] Ghi decision record về tính không chính thức, độ ổn định và rủi ro chính sách.
- Verify: review spec/ADR; không thêm network implementation.
- Dependencies: Task 12.
- Files likely touched: `SPEC-youtube-music-adapter.md`, `docs/decisions/0002-youtube-music-upstream.md`.
- Estimated scope: Small (documentation only).

## Task 14 — Catalog transport contract

- [ ] Viết test trước cho request/response mapping bằng fixture tự tạo và đã loại dữ liệu nhạy cảm.
- [ ] Có timeout, cancellation và error taxonomy cho network, parse, rejection và unsupported response.
- [ ] Không lưu cookie, token, credential hoặc raw response của người dùng.
- Verify: focused tests, `flutter analyze`, `flutter test`.
- Dependencies: Task 13.
- Files likely touched: `lib/data/youtube_music/transport.dart`, `lib/data/youtube_music/catalog_error.dart`, focused tests/fixtures.
- Estimated scope: Medium (3–5 files).

## Task 15 — Live Search slice

- [ ] Search không đăng nhập trả track/album/artist qua `MusicProvider` hiện có.
- [ ] Loading, empty, retry và lỗi upstream hiển thị đúng bằng Material 3.
- [ ] Có thể chuyển fake/live provider bằng dependency injection mà không sửa feature UI.
- Verify: unit/widget tests và kiểm tra thủ công trên Android có mạng.
- Dependencies: Task 14.
- Files likely touched: live provider/search mapper, DI bootstrap và focused tests.
- Estimated scope: Medium (3–5 files).

## Task 16 — Live Home slice

- [ ] Home không đăng nhập trả các section qua provider contract.
- [ ] Continuation không tạo item trùng hoặc vòng lặp request.
- [ ] Empty/malformed/timeout có typed failure và retry hữu hạn.
- Verify: focused tests, full suite và manual Home flow.
- Dependencies: Task 15.
- Files likely touched: Home mapper/provider, ViewModel integration và focused tests.
- Estimated scope: Medium (3–5 files).

## Task 17 — Album detail slice

- [ ] Album metadata và track list được map sang domain model riêng của Yuzu.
- [ ] Album unavailable hoặc thiếu trường không làm UI crash.
- [ ] Chọn track tạo đúng playback command hiện có.
- Verify: mapper/provider tests và widget flow test.
- Dependencies: Task 16.
- Files likely touched: album model/mapper, album view model/screen và focused tests.
- Estimated scope: Medium (3–5 files).

## Task 18 — Artist detail slice

- [ ] Artist metadata, top tracks và releases được map sang domain model.
- [ ] Continuation và trường dữ liệu tùy chọn được xử lý an toàn.
- [ ] Navigation từ Search/Home sang artist hoạt động.
- Verify: mapper/provider tests và widget navigation test.
- Dependencies: Task 17.
- Files likely touched: artist model/mapper, artist view model/screen và focused tests.
- Estimated scope: Medium (3–5 files).

## Task 19 — Playlist detail slice

- [ ] Playlist metadata và track list không đăng nhập được hiển thị.
- [ ] Playlist private/unavailable trả lỗi có kiểu, không giả vờ là danh sách rỗng.
- [ ] Pagination không trùng track và có thể retry.
- Verify: mapper/provider tests và widget flow test.
- Dependencies: Task 18.
- Files likely touched: playlist model/mapper, playlist view model/screen và focused tests.
- Estimated scope: Medium (3–5 files).

## Checkpoint — Live catalog

- [ ] Search/Home chạy với dữ liệu thật trên Android.
- [ ] Fake provider vẫn chạy toàn bộ test offline.
- [ ] Người dùng review catalog trước playback thật.

## Task 20 — Stream resolver spec

- [ ] Định nghĩa input/output, required headers, URL expiry và typed failures.
- [ ] Playback contract không phụ thuộc DTO Innertube hoặc Android API.
- [ ] Ghi rõ không đăng nhập, không download và không account sync trong MVP.
- Verify: spec và contract tests được review.
- Dependencies: Task 19 và checkpoint Live catalog.
- Files likely touched: `SPEC-playback-resolver.md`, provider contract và contract tests.
- Estimated scope: Small–Medium (2–4 files).

## Task 21 — One-track playback spike

- [ ] Một track công khai có thể được resolve và phát trên Android bằng audio adapter hiện tại.
- [ ] URL hết hạn, unavailable, region restriction và bot rejection không làm app crash.
- [ ] Không commit cookie, token hoặc URL stream tạm thời.
- Verify: unit tests với fixtures, integration check trên Android và debug APK.
- Dependencies: Task 20.
- Files likely touched: resolver implementation, transport adapter và focused tests.
- Estimated scope: Medium (3–5 files).

## Task 22 — Live playback integration

- [ ] Search → queue → mini-player → full player dùng live resolver.
- [ ] Next/previous và background media controls hoạt động với track thật.
- [ ] Fake playback vẫn dùng được cho test và phát triển offline.
- Verify: critical integration flow, format, analyze, tests và debug APK.
- Dependencies: Task 21.
- Files likely touched: playback controller/driver integration, DI bootstrap và integration test.
- Estimated scope: Medium (3–5 files).

## Checkpoint — Live playback

- [ ] Người dùng xác nhận playback trên thiết bị Android.
- [ ] Failure states có thông báo hữu ích và retry có giới hạn.
- [ ] Không bắt đầu login hoặc download.

## Task 23 — Catalog UI polish

- [ ] Artwork loading, placeholder, pagination và retry đạt chuẩn Material 3.
- [ ] Text scaling, semantics và touch targets được kiểm thử.
- Verify: widget/golden checks phù hợp và manual device review.
- Dependencies: Task 22.
- Files likely touched: shared catalog widgets, theme tokens and widget tests.
- Estimated scope: Medium (3–5 files).

## Task 24 — Minimal local library

- [ ] Yêu thích và lịch sử nghe được lưu cục bộ qua repository contract.
- [ ] Schema/migration có test trước khi nối UI.
- Verify: persistence tests, widget tests và full suite.
- Dependencies: Task 23; thay đổi persistence schema cần người dùng duyệt trước.
- Files likely touched: library repository/storage adapter, screen/view model và tests.
- Estimated scope: Medium per approved persistence slice.

## Task 25 — MVP quality pass

- [ ] Privacy disclosure, redacted logging và open-source notices đầy đủ.
- [ ] Release split APK được build và đo kích thước.
- [ ] Critical flow pass trên ít nhất một thiết bị Android thật.
- Verify: format, analyze, all tests, release build và manual smoke test.
- Dependencies: Tasks 22–24.
- Files likely touched: privacy/notices, release configuration and verification docs/tests.
- Estimated scope: Medium (3–5 files per quality slice).
