# Hướng dẫn sử dụng hệ thống License

## 📋 Tổng quan

Hệ thống license bảo vệ phần mềm của bạn bằng cách:
1. Tạo **Machine ID** duy nhất cho mỗi máy tính
2. Cấp **License Key** có thời hạn cho từng khách
3. Kiểm tra license mỗi khi khởi động app

---

## 🔧 Cách hoạt động

### Quy trình kích hoạt cho khách hàng:

```
Khách mở app → Hiển thị Machine ID → Gửi cho bạn
      ↓
Bạn tạo License Key → Gửi cho khách
      ↓
Khách nhập License Key → Kích hoạt thành công
```

---

## 👨‍💼 ADMIN: Cách tạo License Key

### Cách 1: Dùng License Generator Tool

1. Chạy tool riêng:
```bash
cd can_heo
flutter run -t lib/tools/license_generator.dart
```

2. Nhập thông tin:
   - Machine ID của khách
   - Tên khách hàng
   - Số ngày sử dụng
   - Loại license

3. Copy License Key và gửi cho khách

### Cách 2: Tạo License bằng code

```dart
import 'core/services/license_service.dart';

// Tạo license 30 ngày
final licenseKey = LicenseService.generateLicenseKey(
  machineId: 'ABCD-1234-EFGH-5678',  // Machine ID của khách
  expiryDate: DateTime.now().add(Duration(days: 30)),
  customerName: 'Trại heo ABC',
  type: LicenseType.trial,
);

print(licenseKey);
```

---

## 👤 KHÁCH HÀNG: Cách kích hoạt

1. Mở phần mềm
2. Copy **Machine ID** (hiển thị trên màn hình)
3. Gửi Machine ID cho nhà cung cấp qua Zalo/Email
4. Nhận **License Key** từ nhà cung cấp
5. Paste License Key vào ô và nhấn "Kích hoạt"

---

## ⚙️ Cấu hình

### Thay đổi Secret Key (QUAN TRỌNG!)

Mở file `lib/core/services/license_service.dart` và thay đổi:

```dart
static const String _secretKey = 'CAN_HEO_2025_SECRET_KEY_CHANGE_THIS';
```

Thành một chuỗi ngẫu nhiên dài hơn, ví dụ:
```dart
static const String _secretKey = 'MyCompany_SecretKey_2025_AbCdEfGh12345!@#';
```

**⚠️ LƯU Ý:** 
- Phải thay đổi ở CẢ 2 file: `license_service.dart` và `license_generator.dart`
- KHÔNG được thay đổi sau khi đã cấp license cho khách

### Thay đổi thông tin liên hệ

Mở file `lib/presentation/features/license/license_activation_screen.dart`:

```dart
Text(
  'Hotline: 0xxx.xxx.xxx\nZalo: 0xxx.xxx.xxx\nEmail: support@example.com',
  ...
),
```

---

## 🔒 Các loại License

| Loại | Mô tả |
|------|-------|
| `trial` | Dùng thử (giới hạn thời gian) |
| `standard` | Bản tiêu chuẩn |
| `premium` | Bản cao cấp (có thể thêm tính năng) |
| `lifetime` | Vĩnh viễn (đặt ngày hết hạn xa) |

---

## 📦 Build và phân phối

### Build bản Release:
```bash
flutter build windows --release
```

### Tạo Installer với Inno Setup:

File `can_heo.exe` sẽ nằm tại:
```
build/windows/x64/runner/Release/
```

**⚠️ QUAN TRỌNG:** KHÔNG bao gồm file `license_generator.dart` hoặc thư mục `tools` trong bản build gửi khách!

---

## 🚫 Đóng băng phần mềm

Khi khách không thanh toán:

1. **Không gia hạn license** - Phần mềm tự động khóa khi hết hạn
2. **Thu hồi license** - Khách phải có license mới
3. **Cấp license ngắn hạn** - Dùng thử 7 ngày, sau đó phải thanh toán

---

## 🔍 Kiểm tra trạng thái License

Các trạng thái có thể:

| Status | Mô tả |
|--------|-------|
| `valid` | License hợp lệ |
| `notFound` | Chưa kích hoạt |
| `invalid` | License sai định dạng |
| `expired` | Đã hết hạn |
| `wrongMachine` | License không dành cho máy này |
| `tampered` | License đã bị chỉnh sửa |
| `error` | Lỗi hệ thống |

---

## ❓ FAQ

### Q: Khách đổi máy tính?
A: Cần cấp license mới với Machine ID của máy mới.

### Q: License bị lộ?
A: Mỗi license chỉ dùng được trên 1 máy (theo Machine ID), nên không lo bị copy.

### Q: Muốn cho nhiều máy dùng chung?
A: Tạo nhiều license với cùng thông tin nhưng khác Machine ID.

---

## 📞 Hỗ trợ

Nếu cần hỗ trợ thêm về hệ thống license, liên hệ developer.
