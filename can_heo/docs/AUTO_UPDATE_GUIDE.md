# Hướng Dẫn Auto-Update từ GitHub Releases

## Tổng Quan Quy Trình

```
[App khởi động] → [Check GitHub Releases API] → [So sánh version]
                                                      ↓
                              [Có bản mới] → [Tải Setup.exe] → [Cài đặt] → [Restart app]
```

## 1. Cách Hoạt Động

App sử dụng **GitHub Releases API** để kiểm tra và tải bản cập nhật:

1. Gọi API: `https://api.github.com/repos/tranminhieu10/can_heo/releases/latest`
2. So sánh version trong tag_name với version hiện tại
3. Nếu có bản mới → Tìm file `.exe` trong assets
4. Tải file installer và chạy với `/SILENT`

---

## 2. Tạo Release Mới

### Bước 1: Cập nhật version trong code

**File `lib/core/services/update_service.dart`:**
```dart
static const String currentVersion = '1.0.1';  // Tăng version
```

**File `pubspec.yaml`:**
```yaml
version: 1.0.1+2  # format: major.minor.patch+build
```

### Bước 2: Build Release

```powershell
cd can_heo
flutter clean
flutter pub get
flutter build windows --release
```

### Bước 3: Build Installer (Inno Setup)

```powershell
# Compile Inno Setup
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" "installer\can_heo_setup.iss"
```

File installer: `installer\Output\CanHeo_Setup_1.0.1.exe`

### Bước 4: Tạo GitHub Release

1. Vào GitHub repo → **Releases** → **Draft a new release**
2. **Tag**: `v1.0.1` (phải có prefix `v`)
3. **Title**: `Version 1.0.1`
4. **Description**: Ghi nội dung cập nhật
5. **Upload file**: `CanHeo_Setup_1.0.1.exe`
6. **Publish release**

---

## 3. Quy Tắc Đặt Tên

| Item | Format | Ví dụ |
|------|--------|-------|
| Tag | `v{major}.{minor}.{patch}` | `v1.0.1` |
| Installer | `CanHeo_Setup_{version}.exe` | `CanHeo_Setup_1.0.1.exe` |
| pubspec.yaml | `{version}+{build}` | `1.0.1+2` |

---

## 4. Sử Dụng Trong App

### Kiểm tra cập nhật thủ công (Settings)

```dart
import 'presentation/features/settings/update_dialog.dart';

// Hiển thị dialog kiểm tra cập nhật
ElevatedButton(
  onPressed: () => UpdateDialog.show(context),
  child: Text('Kiểm tra cập nhật'),
)
```

### Kiểm tra tự động khi khởi động

```dart
// Trong initState của màn hình chính
@override
void initState() {
  super.initState();
  // Kiểm tra cập nhật sau 3 giây
  Future.delayed(Duration(seconds: 3), () {
    UpdateDialog.checkOnStartup(context);
  });
}
```

---

## 5. Force Update

Để bắt buộc người dùng cập nhật, thêm `[force]` vào Release notes:

```
[force] Bản cập nhật bảo mật quan trọng!
- Sửa lỗi bảo mật
- Cải thiện hiệu năng
```

---

## 6. Cấu Hình Repository

Thay đổi thông tin repo trong `update_service.dart`:

```dart
static const String githubOwner = 'tranminhieu10';  // Username GitHub
static const String githubRepo = 'can_heo';          // Tên repo
```

---

## 7. Quy Trình Phát Hành Version Mới (Checklist)

```
□ 1. Sửa code, test kỹ
□ 2. Tăng version trong:
     - pubspec.yaml
     - update_service.dart (currentVersion)
     - can_heo_setup.iss (MyAppVersion)
□ 3. flutter build windows --release
□ 4. Build Inno Setup installer
□ 5. Tạo GitHub Release:
     - Tag: vX.X.X
     - Upload: CanHeo_Setup_X.X.X.exe
□ 6. Publish release
□ 7. Test cập nhật từ app cũ
```

---

## 8. Cập Nhật Version trong Inno Setup

Mở file `installer/can_heo_setup.iss`:

```iss
#define MyAppVersion "1.0.1"  ; Thay đổi version ở đây
```

---

## 9. Lưu Ý Quan Trọng

- ⚠️ **Tag phải có prefix `v`**: `v1.0.0`, `v1.0.1`...
- ⚠️ **File installer phải chứa "Setup" và đuôi ".exe"**
- ⚠️ **GitHub API có rate limit**: 60 requests/hour (không auth)
- ⚠️ **Version trong code phải khớp với tag** (không có prefix `v`)

---

## 10. Troubleshooting

### Không tìm thấy bản cập nhật
- Kiểm tra tag có đúng format `vX.X.X` không
- Kiểm tra file upload có chứa "Setup" và đuôi ".exe" không
- Kiểm tra version trong code có thấp hơn tag không

### Lỗi tải file
- Kiểm tra kết nối mạng
- Kiểm tra GitHub API rate limit
- File có thể quá lớn, thử compress installer

### Lỗi cài đặt
- Chạy installer với quyền Admin
- Kiểm tra antivirus có chặn không
- Đóng app trước khi cài đặt
