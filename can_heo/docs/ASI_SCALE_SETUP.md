# Hướng Dẫn Kết Nối Đầu Hiển Thị ASI 2025

## Tổng Quan

App đã được cấu hình để kết nối với **Đầu Hiển Thị ASI 2025 (Amcells)** qua cổng **Serial RS232/USB**.

## Cấu Hình Phần Cứng

### 1. Kết Nối Vật Lý

```
[Cân điện tử] ----RS232----> [Đầu hiển thị ASI 2025] ----USB/RS232----> [Máy tính]
```

**Các bước kết nối:**

1. Kết nối cân điện tử với đầu hiển thị ASI qua cáp RS232
2. Kết nối đầu hiển thị ASI với máy tính qua:
   - **USB-to-Serial adapter** (phổ biến nhất), hoặc
   - Cổng COM trực tiếp (nếu máy có)

### 2. Cài Đặt Driver

Nếu dùng USB-to-Serial adapter:

1. Tải driver cho adapter (thường là CH340, FTDI, hoặc PL2303)
2. Cài đặt driver
3. Khởi động lại máy tính
4. Kiểm tra trong Device Manager → Ports (COM & LPT)
5. Ghi nhớ số cổng COM (ví dụ: COM3, COM4...)

## Cấu Hình Đầu ASI 2025

### Thông Số Serial Port

- **Baudrate**: 9600
- **Data bits**: 8
- **Stop bits**: 1
- **Parity**: None
- **Flow control**: None

### Chế Độ Truyền Dữ Liệu

Đầu ASI cần cấu hình ở chế độ **Continuous Mode** (gửi dữ liệu liên tục).

**Cách cấu hình trên ASI 2025:**

1. Nhấn nút **MENU** trên đầu hiển thị
2. Chọn **COMMUNICATION** hoặc **COM SETUP**
3. Thiết lập:
   - Mode: **Continuous** (hoặc **Auto**)
   - Baudrate: **9600**
   - Format: **GS** (Gross weight)
4. Lưu cấu hình và thoát

### Format Dữ Liệu

Đầu ASI sẽ gửi dữ liệu theo format:

```
ST,GS,+000123.4\r\n
```

Trong đó:
- `ST` = Stable (ổn định) hoặc `US` = Unstable (chưa ổn định)
- `GS` = Gross weight (cân tổng)
- `+000123.4` = Trọng lượng (kg), có dấu +/- ở đầu
- `\r\n` = Ký tự kết thúc dòng

## Sử Dụng Trong App

### 1. Khởi Động App

Khi app khởi động, nó sẽ **tự động quét** và kết nối với đầu ASI:

```
🔍 Đang quét cổng COM...
✅ Đã kết nối với COM3
```

### 2. Kiểm Tra Kết Nối

Tại màn hình **Nhập Chợ**, trên AppBar sẽ hiển thị trạng thái:

- ✅ **ASI (COM3)** = Đã kết nối
- ⚠️ **Chưa kết nối cân** = Chưa tìm thấy đầu cân

### 3. Kết Nối Lại

Nếu mất kết nối, nhấn nút **"Kết nối lại"** trên AppBar.

### 4. Lệnh Điều Khiển

- **Trừ bì (Tare)**: App gửi lệnh `T\r\n`
- **Về 0 (Zero)**: App gửi lệnh `Z\r\n`

> **Lưu ý**: Một số đầu ASI có thể dùng lệnh khác. Kiểm tra manual của thiết bị.

## Troubleshooting

### Không Tìm Thấy Cổng COM

**Nguyên nhân:**
- Driver chưa cài đặt
- USB chưa cắm chặt
- Cổng COM bị disable

**Giải pháp:**
1. Kiểm tra Device Manager
2. Cài đặt/cập nhật driver
3. Thử cắm lại USB vào cổng khác

### Kết Nối Nhưng Không Nhận Dữ Liệu

**Nguyên nhân:**
- Đầu ASI chưa bật chế độ Continuous
- Baudrate không đúng
- Cân chưa bật

**Giải pháp:**
1. Kiểm tra LED trên đầu ASI (phải nhấp nháy khi có dữ liệu)
2. Kiểm tra cấu hình COM trên ASI
3. Đảm bảo cân đã bật và hoạt động

### Dữ Liệu Lỗi/Loạn

**Nguyên nhân:**
- Baudrate sai
- Nhiễu tín hiệu
- Cáp quá dài hoặc kém chất lượng

**Giải pháp:**
1. Kiểm tra lại baudrate (phải là 9600)
2. Dùng cáp ngắn hơn, tốt hơn
3. Tránh xa nguồn nhiễu (động cơ, máy hàn...)

### Test Thủ Công

Nếu muốn test kết nối serial trước khi chạy app:

1. Dùng **PuTTY** hoặc **RealTerm**:
   - Port: COM3 (hoặc cổng của bạn)
   - Speed: 9600
   - Data bits: 8
   - Stop bits: 1
   - Parity: None

2. Khi cân hoạt động, bạn sẽ thấy dữ liệu dạng:
   ```
   ST,GS,+000000.0
   ST,GS,+000123.4
   US,GS,+000125.1
   ST,GS,+000125.0
   ```

## Chuyển Đổi Giữa ASI và Dummy

### Sử Dụng ASI (Thực Tế)

File: `lib/injection_container.dart`

```dart
// Sử dụng ASIScaleService
final asiScale = ASIScaleService();
await asiScale.connect();
sl.registerLazySingleton<IScaleService>(() => asiScale);
```

### Sử Dụng Dummy (Test Không Có Cân)

```dart
// Dùng DummyScaleService (luôn trả về 0)
sl.registerLazySingleton<IScaleService>(() => DummyScaleService());
```

## Thông Số Kỹ Thuật ASI 2025

- **Nguồn**: AC 110-220V hoặc DC 12-24V
- **Giao tiếp**: RS232, RS485, USB (tùy model)
- **Độ phân giải**: 1/30,000
- **Tốc độ đọc**: 10-20 lần/giây
- **Nhiệt độ hoạt động**: -10°C ~ 40°C

## Liên Hệ Hỗ Trợ

Nếu gặp vấn đề với đầu cân ASI:

1. Kiểm tra manual thiết bị
2. Liên hệ nhà phân phối Amcells
3. Hotline: 0397154084
