# Hướng Dẫn Triển Khai Auto-Update cho Can Heo

## Tổng Quan Quy Trình

```
[App khởi động] → [Check version.json] → [So sánh version]
                                              ↓
                          [Có bản mới] → [Tải .msix] → [Cài đặt] → [Tắt app]
```

## 1. Cấu Trúc Server

Bạn cần host 2 file trên server (GitHub Releases, AWS S3, hoặc web hosting):

### a) `version.json` - File kiểm tra version
```json
{
  "version": "1.0.1",
  "build_number": 2,
  "download_url": "https://your-server.com/updates/can_heo_1.0.1.msix",
  "release_notes": "- Cải thiện giao diện\n- Sửa lỗi",
  "file_size": 52428800,
  "release_date": "2024-12-22",
  "force_update": false
}
```

### b) `can_heo_x.x.x.msix` - File cài đặt

---

## 2. Build MSIX cho Windows

### Bước 1: Cấu hình pubspec.yaml

Đảm bảo có config msix:
```yaml
msix_config:
  display_name: Cân Heo
  publisher_display_name: Your Company
  identity_name: com.yourcompany.canheo
  msix_version: 1.0.1.0
  logo_path: assets/icon.png
  capabilities: internetClient
```

### Bước 2: Build MSIX

```powershell
# Build release
flutter build windows --release

# Tạo MSIX
dart run msix:create
```

File MSIX sẽ được tạo tại:
```
build\windows\x64\runner\Release\can_heo.msix
```

### Bước 3: Đổi tên file theo version
```powershell
# Đổi tên: can_heo_1.0.1.msix
Rename-Item "build\windows\x64\runner\Release\can_heo.msix" "can_heo_1.0.1.msix"
```

---

## 3. Upload lên Server

### Option A: GitHub Releases (Miễn phí)

1. Tạo Release mới trên GitHub
2. Upload file `can_heo_1.0.1.msix`
3. Copy URL download (dạng: `https://github.com/user/repo/releases/download/v1.0.1/can_heo_1.0.1.msix`)
4. Tạo `version.json` trong repo hoặc GitHub Pages

### Option B: AWS S3 / Google Cloud Storage

1. Tạo bucket public
2. Upload `version.json` và `can_heo_1.0.1.msix`
3. Lấy public URL

### Option C: Web Hosting thông thường

Upload 2 file vào folder `/updates/` trên hosting

---

## 4. Cấu Hình App

### Cập nhật URL trong UpdateService

File: `lib/core/services/update_service.dart`

```dart
/// URL tới file version.json trên server
static const String versionUrl = 'https://your-server.com/updates/version.json';

/// Version hiện tại (phải khớp với pubspec.yaml)
static const String currentVersion = '1.0.0';
static const int currentBuildNumber = 1;
```

---

## 5. Quy Trình Phát Hành Bản Mới

### Checklist mỗi lần release:

1. ☐ Cập nhật `version` trong `pubspec.yaml`
2. ☐ Cập nhật `currentVersion` và `currentBuildNumber` trong `update_service.dart`
3. ☐ Build MSIX: `dart run msix:create`
4. ☐ Đổi tên file theo version: `can_heo_x.x.x.msix`
5. ☐ Upload file MSIX lên server
6. ☐ Cập nhật `version.json` trên server:
   - `version`: version mới
   - `build_number`: tăng lên
   - `download_url`: URL file MSIX mới
   - `release_notes`: mô tả thay đổi
   - `file_size`: kích thước file MSIX (bytes)
   - `release_date`: ngày phát hành

---

## 6. Cách Khách Hàng Cập Nhật

### Tự động:
1. Vào **Cài đặt** → **Kiểm tra cập nhật**
2. Nếu có bản mới, nhấn **Cập nhật ngay**
3. Đợi tải xong → App tự động đóng và cài đặt

### Thủ công (nếu tự động không hoạt động):
1. Tải file `.msix` từ link
2. Double-click để cài đặt
3. Nhấn **Install** / **Update**

---

## 7. Ví Dụ GitHub Releases

### Cấu trúc version.json cho GitHub:
```json
{
  "version": "1.0.1",
  "build_number": 2,
  "download_url": "https://github.com/tranminhieu10/can_heo/releases/download/v1.0.1/can_heo_1.0.1.msix",
  "release_notes": "Bản cập nhật 1.0.1:\n- Cải thiện responsive\n- Thêm đăng nhập\n- Sửa lỗi tồn kho",
  "file_size": 52428800,
  "release_date": "2024-12-22",
  "force_update": false
}
```

### Host version.json trên GitHub Pages:
1. Tạo branch `gh-pages`
2. Đặt `version.json` ở root
3. URL: `https://tranminhieu10.github.io/can_heo/version.json`

---

## 8. Troubleshooting

### Lỗi "App package signature validation failed"
- MSIX chưa được sign. Cần certificate hoặc dùng sideloading

### Lỗi "File in use"
- App cần tắt trước khi cài. Code đã xử lý bằng `exit(0)`

### Không tải được file
- Kiểm tra URL trong version.json
- Đảm bảo file MSIX đã public
- Kiểm tra kết nối internet

---

## 9. Script Tự Động Build & Upload

Tạo file `release.ps1`:

```powershell
param (
    [string]$Version = "1.0.0"
)

Write-Host "🚀 Building version $Version..."

# Build Flutter
flutter build windows --release

# Create MSIX
dart run msix:create

# Rename
$msixPath = "build\windows\x64\runner\Release\can_heo.msix"
$newName = "can_heo_$Version.msix"
Copy-Item $msixPath $newName

Write-Host "✅ Build complete: $newName"
Write-Host "📤 Upload file này lên server và cập nhật version.json"
```

Chạy: `.\release.ps1 -Version "1.0.1"`
