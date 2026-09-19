# Kế hoạch chi tiết hoàn thiện bản Beta cho Yuzu (Music Player)

> **Mục tiêu:** Xây dựng Yuzu thành một ứng dụng nghe nhạc Android mã nguồn mở hoàn chỉnh, mượt mà, chuẩn Material Design 3, stream nhạc trực tiếp từ YouTube Music ổn định (Guest mode & hỗ trợ nâng cao), có Lyric đồng bộ, quản lý Playlist/Favorites cục bộ và tối ưu hóa trải nghiệm người dùng đạt tiêu chuẩn Beta release.
> **Phương pháp tiếp cận:** Clean-room implementation, tuân thủ TDD (Test-Driven Development), kiến trúc MVVM tách bạch tầng dữ liệu và playback engine. Học hỏi toàn diện danh mục tính năng (Feature Inventory) và xử lý ngoại lệ từ **ArchiveTune**.

---

## I. Phân tích chuyên sâu đối chuẩn: ArchiveTune vs Yuzu

Qua phân tích cấu trúc mã nguồn thực tế của [ArchiveTune](https://github.com/rukamori/ArchiveTune) (Kotlin/Jetpack Compose, Room DB, Media3/ExoPlayer):

| Thành phần | ArchiveTune (Thực trạng đối chuẩn) | Yuzu (Hiện trạng) | Mục tiêu Yuzu Beta |
| :--- | :--- | :--- | :--- |
| **Tech Stack** | Kotlin + Jetpack Compose + Room | Flutter 3.47.5 + Dart 3.13.4 | Giữ vững Flutter (cross-platform ready, build APK tối ưu) |
| **Audio Core** | Android Media3 + ExoPlayer tùy biến | `just_audio` + `audio_service` | Tối ưu buffer, dynamic audio session, crossfade, sleep timer |
| **Dữ liệu trực tuyến** | Innertube (Guest & Auth, Token rotation) | Clean-room Innertube Adapter (Guest Search & Home) | Hoàn thiện Detail (Album, Artist, Playlist) + Resolve Audio Stream |
| **Dữ liệu cục bộ** | Room Database (Songs, Albums, History, TopMix) | In-memory queues & Fake providers | SQLite (`sqflite`) lưu trữ Favorites, History, Offline Cache, Playlist |
| **Lyrics** | Multi-provider (LrcLib, Musixmatch, Kugou, Paxsenix) | Chưa có | LrcLib + YouTube Synced Subtitles (hỗ trợ lyrics cuộn thời gian thực) |
| **Giao diện (UI)** | Material 3 + Dynamic Color theo bìa bài hát | Material 3 cơ bản (ThemeTokens, Mini/Full Player) | Dynamic Palette từ Artwork, Player Gestures, Queue Reorder |

---

## II. Các giai đoạn triển khai (Roadmap to Beta)

```
[Phase 1: Catalog Details] ➔ [Phase 2: Live Stream Engine] ➔ [Phase 3: Local Library & DB]
                                                                        ↓
[Beta Polish & Release]   ←   [Phase 5: Player UI & Theme]   ←   [Phase 4: Synced Lyrics]
```

---

### Giai đoạn 1: Hoàn thiện danh mục trực tuyến (Live Catalog Details)
*Hoàn thành nốt nhánh Wave 6B theo kế hoạch kỹ thuật của Yuzu.*

1. **Album Details (`Task 17`):**
   * Xây dựng request Innertube browse endpoint cho Album (`browseId` bắt đầu bằng `MPREb_`).
   * Mapper dữ liệu: Tracklist, nghệ sĩ, năm phát hành, thời lượng, thumbnail chất lượng cao.
   * Viết TDD tests và xử lý trạng thái tải/lỗi/timeout.

2. **Artist Details (`Task 18`):**
   * Endpoint browse Artist (`browseId` bắt đầu bằng `UC...` hoặc `FEmusic_library_privately_owned_artist_detail...`).
   * Mapper phân mục: Top bài hát (Top Songs), Albums, Singles & EPs, Nghệ sĩ liên quan.
   * Giao diện Artist Profile chuẩn Material 3 SliverAppBar mở rộng.

3. **Playlist Details (`Task 19`):**
   * Hỗ trợ nạp Community/Official Playlists (`VL...` / `RDAMPL...`).
   * Phân trang liên tục (Continuation token) cho playlist dài trên 100 bài hát.

---

### Giai đoạn 2: Trình giải mã luồng âm thanh trực tiếp (Live Playback Engine)
*Học hỏi kiến trúc `ResolveAudioStreamUseCase` và `YoutubeiStreamRepository` của ArchiveTune.*

1. **Stream Resolution Pipeline:**
   * Tạo adapter gọi endpoint `player` của YouTube Music với payload guest context.
   * Lọc và chọn luồng audio thích hợp:
     * Ưu tiên Opus/WebM (ít tốn băng thông, chất lượng cao 160kbps).
     * Fallback m4a/aac (tương thích rộng).
   * Xử lý giải mã chữ ký (Signature decipher / throttling parameter nếu gặp phải).
2. **Quản lý Vòng đời Luồng phát (Stream Lease & Expiry):**
   * Cơ chế cache URL có thời hạn (YouTube stream URLs thường hết hạn sau 6 tiếng).
   * Tự động renew stream khi người dùng bấm Resume sau một thời gian dài tạm dừng.
   * Pre-fetch luồng của bài tiếp theo trong hàng đợi (Next track preloading) giúp chuyển bài không có độ trễ (Gapless playback).
3. **Bộ đệm & Kết nối mạng gián đoạn (Resilience):**
   * Cấu hình buffer trước 30-60 giây.
   * Retry logic theo Exponential Backoff khi mất mạng tạm thời.

---

### Giai đoạn 3: Thư viện cá nhân & Cơ sở dữ liệu cục bộ (Local Persistence)
*Thiết kế bảng dữ liệu tối giản nhưng mạnh mẽ bằng `sqflite`.*

1. **Database Schema:**
   * `songs`: Lưu metadata bài hát đã từng nghe/thích (id, title, artist, album, duration, thumbnail_url, stream_cache_path).
   * `playlists`: Danh sách phát người dùng tự tạo.
   * `playlist_songs`: Quan hệ n-n có thứ tự sắp xếp (`position`).
   * `playback_history`: Nhật ký nghe nhạc (timestamp, song_id, play_duration) phục vụ tính năng Nghe gần đây.
   * `favorites`: Đánh dấu yêu thích nhanh.
2. **Tính năng Quản lý Playlist:**
   * Tạo playlist mới, đổi tên, thêm/xóa bài hát, kéo thả sắp xếp bài hát trong danh sách.
   * Nút bấm "Thích" (Heart toggle) tức thì ngay trên Mini-player và Notification.

---

### Giai đoạn 4: Lời bài hát đồng bộ (Live Synced Lyrics)
*ArchiveTune tích hợp rất mạnh phần này nhờ LrcLib & Subtitles.*

1. **Lyrics Service Architecture:**
   * Khởi tạo `LyricsRepository` hỗ trợ nhiều nguồn (Fallback-chain):
     * **Ưu tiên 1 (LrcLib API):** Nguồn mở miễn phí, hỗ trợ lời bài hát đồng bộ theo từng mili-giây (format `.lrc`).
     * **Ưu tiên 2 (YouTube Music Captions):** Trích xuất subtitle có sẵn từ video ID.
2. **Trải nghiệm hiển thị (Lyrics UI):**
   * Giao diện cuộn tự động theo thời gian phát hiện tại (`currentPosition`).
   * Cho phép bấm vào một câu bất kỳ để tua nhạc (Seek on tap).
   * Chế độ Plain Lyrics (khi bài hát chỉ có lời thô không có mốc thời gian).

---

### Giai đoạn 5: Tối ưu UI/UX, Player Styles & Material Design 3
1. **Dynamic Color Palette:**
   * Tự động trích xuất màu chủ đạo từ Artwork bài hát (`palette_generator`).
   * Đổi màu gradient nền của Full Player theo bìa album như các app hiện đại (ArchiveTune/Apple Music).
2. **Full Player hoàn chỉnh:**
   * Vuốt cử chỉ xuống để thu nhỏ thành Mini Player (Draggable/Sliding Panel).
   * Các nút chức năng phụ: Sleep Timer (Hẹn giờ tắt), Tốc độ phát (0.5x - 2.0x), Equalizer tích hợp.
   * Bottom Sheet xem hàng đợi (Playing Queue) có thể kéo thả đổi vị trí hoặc vuốt để xóa.
3. **Android Media Integration (Notification & Lockscreen):**
   * Đảm bảo notification hiển thị đầy đủ: Artwork, nút Next/Previous, SeekBar tương tác trực tiếp trên Android 13+.
   * Xử lý Headset events: Rút tai nghe tự dừng nhạc, bấm nút tai nghe để Next/Pause.

---

### Giai đoạn 6: Tối ưu hoá, Kiểm thử tự động & Đóng gói Beta APK
1. **Kiểm thử chất lượng (TDD & Quality Gates):**
   * Unit tests cho toàn bộ luồng Resolver & DB.
   * Integration test trên thiết bị thật: Tìm kiếm → Thêm hàng đợi → Chuyển bài → Tắt màn hình nghe liên tục.
2. **Tối ưu hiệu năng ứng dụng:**
   * Nén file APK (ProGuard / R8 rules, tách ABI nếu cần).
   * Giảm thiểu rò rỉ bộ nhớ khi load ảnh thumbnail liên tục.
3. **Bản phát hành Beta 1.0.0:**
   * Tạo Github Release workflow tự động build file APK có gắn chữ ký debug/release.
   * Cập nhật tài liệu hướng dẫn người dùng trong `README.md`.

---

## III. Bảng phân chia công việc chi tiết (Tasks Execution)

| STT | Nhiệm vụ | Đầu ra bàn giao | Độ ưu tiên |
| :---: | :--- | :--- | :---: |
| **T1** | Implement Album/Artist/Playlist Fetchers | Bộ Adapter live data + Unit Tests | 🟢 High |
| **T2** | Build Audio Stream Resolver (YouTube Engine) | Phát được nhạc online từ YouTube Music | 🔴 Critical |
| **T3** | Implement Local DB (`sqflite`) | Lưu lịch sử, bài hát yêu thích, playlist riêng | 🟢 High |
| **T4** | Tích hợp LrcLib Synced Lyrics | Tab Lyric cuộn mượt mà theo bài hát | 🟡 Medium |
| **T5** | Dynamic Theme & Draggable Player UI | Giao diện Full Player sang trọng, đổi màu theo bìa | 🟡 Medium |
| **T6** | Sleep Timer & Audio Controls | Tính năng hẹn giờ ngủ, loop/shuffle hoàn chỉnh | 🔵 Normal |
| **T7** | Release Build & GitHub CI/CD | File `yuzu-beta-v0.3.0.apk` sẵn sàng tải về | 🟢 High |

---
*Tài liệu này được lưu trực tiếp tại `yuzu/docs/plans/beta_plan.md` để theo dõi tiến độ.*
