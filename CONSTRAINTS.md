# Constraints

Last reviewed: 2026-08-30

## Floor

- Không thêm suppression để che lỗi analyzer hoặc compiler.
- Không có stub chưa triển khai, empty catch hoặc debug output trong code bàn giao.
- Không skip, xóa test hoặc làm yếu assertion để lấy màu xanh.
- Không đưa secret, cookie, token hoặc credential vào source.
- Không làm yếu file này để một thay đổi vượt qua kiểm tra.
- Không copy mã, asset, UI hoặc chuỗi văn bản từ Metrolist, ArchiveTune hay dự án tham khảo khác.

## Enforced

| Dimension | Rule | Checked by | Runs at |
|---|---|---|---|
| Format | Không có file Dart lệch formatter | `dart format --output=none --set-exit-if-changed .` | task end |
| Static analysis | Không có analyzer finding | `flutter analyze` | task end |
| Tests | Không có test thất bại hoặc bị skip | `flutter test` | task end |
| Android build | Debug APK phải build được | `flutter build apk --debug` | checkpoint |

## Measured, Not Yet Enforced

| Metric | Baseline | Direction |
|---|---|---|
| Test coverage | Đo sau vertical slice đầu | Không được giảm sau khi có baseline |
| APK size | Đo sau debug/release build đầu | Theo dõi trước khi đặt budget |

## Exceptions

Không có. Mọi exception mới phải có lý do, owner và ngày hết hạn trước khi được thêm.
