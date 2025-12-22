import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

/// Interface chung cho mọi loại đầu cân
abstract class IScaleService {
  /// Stream trọng lượng hiện tại (kg) từ đầu cân.
  Stream<double> watchWeight();

  /// Lệnh trừ bì.
  Future<void> tare();

  /// Lệnh về 0.
  Future<void> zero();

  /// Đóng kết nối (nếu cần)
  Future<void> dispose();
}

/// Implementation dùng MethodChannel + EventChannel.
///
/// Cần native plugin implement:
/// - EventChannel: 'can_heo/scale/weight'
/// - MethodChannel: 'can_heo/scale/methods'
class MethodChannelScaleService implements IScaleService {
  static const EventChannel _weightChannel =
      EventChannel('can_heo/scale/weight');
  static const MethodChannel _methodChannel =
      MethodChannel('can_heo/scale/methods');

  @override
  Stream<double> watchWeight() {
    // Nếu native chưa implement, stream này sẽ bắn MissingPluginException.
    // UI có thể listen với onError để biết trạng thái.
    return _weightChannel
        .receiveBroadcastStream()
        .map<double>((dynamic event) {
          if (event is num) return event.toDouble();
          if (event is String) {
            final parsed = double.tryParse(event);
            if (parsed != null) return parsed;
          }
          return 0;
        })
        .distinct();
  }

  @override
  Future<void> tare() async {
    try {
      await _methodChannel.invokeMethod('tare');
    } on MissingPluginException {
      // Native chưa implement -> bỏ qua để app không crash
    }
  }

  @override
  Future<void> zero() async {
    try {
      await _methodChannel.invokeMethod('zero');
    } on MissingPluginException {
      // Native chưa implement -> bỏ qua để app không crash
    }
  }

  @override
  Future<void> dispose() async {
    // Nothing to dispose for method channel
  }
}

/// Service kết nối với đầu hiển thị ASI 2025 qua Serial Port
/// 
/// Cấu hình:
/// - Baudrate: 9600
/// - Data bits: 8
/// - Stop bits: 1
/// - Parity: None
/// - Protocol: Continuous mode (nhận dữ liệu liên tục)
class ASIScaleService implements IScaleService {
  SerialPort? _port;
  SerialPortReader? _reader;
  final StreamController<double> _weightController = StreamController<double>.broadcast();
  String _buffer = '';
  bool _isConnected = false;

  /// Tự động tìm và kết nối với đầu cân ASI
  Future<bool> connect() async {
    try {
      // Lấy danh sách tất cả các cổng COM
      final availablePorts = SerialPort.availablePorts;
      
      if (availablePorts.isEmpty) {
        return false;
      }

      // Thử kết nối với từng cổng
      for (final portName in availablePorts) {
        try {
          _port = SerialPort(portName);
          
          // Cấu hình cổng cho ASI 2025
          final config = SerialPortConfig();
          config.baudRate = 9600;
          config.bits = 8;
          config.stopBits = 1;
          config.parity = SerialPortParity.none;
          
          _port!.config = config;
          
          // Thử mở cổng
          if (!_port!.openReadWrite()) {
            _port!.dispose();
            _port = null;
            continue;
          }
          
          // Bắt đầu đọc dữ liệu
          _startReading();
          _isConnected = true;
          
          return true;
        } catch (e) {
          _port?.dispose();
          _port = null;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Bắt đầu đọc dữ liệu từ serial port
  void _startReading() {
    if (_port == null) return;

    _reader = SerialPortReader(_port!);
    _reader!.stream.listen(
      (data) {
        _processData(data);
      },
      onError: (error) {
        _isConnected = false;
      },
      onDone: () {
        _isConnected = false;
      },
    );
  }

  /// Xử lý dữ liệu thô từ serial port
  /// 
  /// Đầu ASI 2025 gửi dữ liệu dạng ASCII text:
  /// Ví dụ: "ST,GS,+000123.4" hoặc "US,GS,+000000.0"
  /// - ST = Stable (ổn định), US = Unstable (chưa ổn định)
  /// - GS = Gross weight (cân tổng)
  /// - Số: trọng lượng (có thể có dấu + hoặc -)
  void _processData(Uint8List data) {
    try {
      // Chuyển bytes sang string
      final text = utf8.decode(data, allowMalformed: true);
      _buffer += text;

      // Tách theo dòng (CR LF hoặc chỉ LF)
      final lines = _buffer.split(RegExp(r'\r?\n'));
      
      // Giữ lại phần chưa đủ dòng
      _buffer = lines.last;
      
      // Xử lý các dòng hoàn chỉnh
      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        final weight = _parseWeight(line);
        if (weight != null) {
          _weightController.add(weight);
        }
      }
    } catch (e) {
      // Ignore malformed data
    }
  }

  /// Parse trọng lượng từ dòng dữ liệu ASI
  /// 
  /// Format: "ST,GS,+000123.4" hoặc "US,GS,+000000.0"
  /// Trả về: 123.4 hoặc 0.0
  double? _parseWeight(String line) {
    try {
      // Tách theo dấu phẩy
      final parts = line.split(',');
      
      if (parts.length < 3) {
        return null;
      }

      // Lấy phần số (phần thứ 3)
      final weightStr = parts[2].trim();
      
      // Loại bỏ dấu + ở đầu nếu có
      final cleanStr = weightStr.replaceFirst('+', '');
      
      // Parse sang số
      final weight = double.tryParse(cleanStr);
      
      if (weight != null) {
        // Đầu ASI thường gửi theo đơn vị kg
        return weight;
      }
    } catch (e) {
      // Ignore parse errors
    }
    
    return null;
  }

  @override
  Stream<double> watchWeight() async* {
    // Nếu chưa kết nối, thử kết nối
    if (!_isConnected) {
      await connect();
    }

    // Phát dữ liệu từ stream controller
    yield* _weightController.stream;
  }

  @override
  Future<void> tare() async {
    // Gửi lệnh tare qua serial port
    // Tùy vào protocol của ASI, có thể là "T\r\n" hoặc lệnh khác
    if (_port != null && _isConnected) {
      try {
        _port!.write(Uint8List.fromList(utf8.encode('T\r\n')));
      } catch (e) {
        // Ignore write errors
      }
    }
  }

  @override
  Future<void> zero() async {
    // Gửi lệnh zero qua serial port
    // Tùy vào protocol của ASI, có thể là "Z\r\n" hoặc lệnh khác
    if (_port != null && _isConnected) {
      try {
        _port!.write(Uint8List.fromList(utf8.encode('Z\r\n')));
      } catch (e) {
        // Ignore write errors
      }
    }
  }

  @override
  Future<void> dispose() async {
    await _weightController.close();
    _reader?.close();
    _port?.close();
    _port?.dispose();
    _isConnected = false;
  }

  /// Kiểm tra trạng thái kết nối
  bool get isConnected => _isConnected;

  /// Lấy tên cổng đang kết nối
  String? get portName => _port?.name;
}

/// Service giả dùng trong giai đoạn DEV khi CHƯA có plugin đầu cân.
/// Luôn trả về 0 kg, không kết nối gì với phần cứng.
class DummyScaleService implements IScaleService {
  @override
  Stream<double> watchWeight() {
    // Phát 0kg định kỳ để UI luôn có dữ liệu ổn định.
    return Stream<double>.periodic(
      const Duration(milliseconds: 500),
      (_) => 0.0,
    );
  }

  @override
  Future<void> tare() async {
    // Không làm gì cả
  }

  @override
  Future<void> zero() async {
    // Không làm gì cả
  }

  @override
  Future<void> dispose() async {
    // Không làm gì cả
  }
}
