import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'scale_service.dart';

/// Service kết nối với cân điện tử NHB300 qua Serial Port (RS232/USB)
/// 
/// Cân NHB300 thường gửi dữ liệu theo format:
/// - Baud rate: 9600 (hoặc 4800)
/// - Data bits: 8
/// - Stop bits: 1
/// - Parity: None
/// - Format dữ liệu: "ST,GS,+000.00 kg\r\n" hoặc tương tự
class NHB300ScaleService implements IScaleService {
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamController<double>? _weightController;
  Timer? _reconnectTimer;
  Timer? _periodicTimer;
  
  String? _currentPortName;
  bool _isConnected = false;
  bool _isDisposed = false;
  double _lastWeight = 0.0;

  // Cấu hình mặc định cho cân NHB300
  static const int defaultBaudRate = 9600;
  static const int dataBits = 8;
  static const int stopBits = 1;
  static const int parity = 0; // None

  /// Stream thông báo trạng thái kết nối
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;
  String? get currentPortName => _currentPortName;

  /// Lấy danh sách các cổng COM khả dụng
  static List<String> getAvailablePorts() {
    try {
      return SerialPort.availablePorts;
    } catch (e) {
      return [];
    }
  }

  /// Lấy thông tin chi tiết của một cổng
  static Map<String, dynamic>? getPortInfo(String portName) {
    try {
      final port = SerialPort(portName);
      final info = {
        'name': portName,
        'description': port.description,
        'manufacturer': port.manufacturer,
        'productId': port.productId,
        'vendorId': port.vendorId,
        'serialNumber': port.serialNumber,
      };
      port.dispose();
      return info;
    } catch (e) {
      return null;
    }
  }

  /// Kết nối với cổng serial
  Future<bool> connect(String portName, {int baudRate = defaultBaudRate}) async {
    try {
      await disconnect();
      
      _port = SerialPort(portName);
      
      // Mở cổng với chế độ đọc
      if (!_port!.openReadWrite()) {
        final error = SerialPort.lastError;
        throw Exception('Không thể mở cổng $portName: $error');
      }

      // Cấu hình cổng
      final config = SerialPortConfig();
      config.baudRate = baudRate;
      config.bits = dataBits;
      config.stopBits = stopBits;
      config.parity = parity;
      config.setFlowControl(SerialPortFlowControl.none);
      _port!.config = config;

      _currentPortName = portName;
      _isConnected = true;
      _connectionController.add(true);

      // Bắt đầu đọc dữ liệu
      _startReading();

      return true;
    } catch (e) {
      _isConnected = false;
      _connectionController.add(false);
      rethrow;
    }
  }

  /// Ngắt kết nối
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    try {
      _reader?.close();
      _reader = null;
    } catch (_) {}

    try {
      if (_port?.isOpen == true) {
        _port?.close();
      }
      _port?.dispose();
      _port = null;
    } catch (_) {}

    _currentPortName = null;
    _isConnected = false;
    if (!_connectionController.isClosed) {
      _connectionController.add(false);
    }
  }

  void _startReading() {
    if (_port == null || !_port!.isOpen) return;

    _weightController?.close();
    _weightController = StreamController<double>.broadcast();

    _reader = SerialPortReader(_port!);
    
    String buffer = '';
    
    _reader!.stream.listen(
      (Uint8List data) {
        try {
          // Chuyển bytes thành string
          buffer += String.fromCharCodes(data);
          
          // Xử lý từng dòng hoàn chỉnh
          while (buffer.contains('\n') || buffer.contains('\r')) {
            int endIndex = buffer.indexOf('\n');
            if (endIndex == -1) endIndex = buffer.indexOf('\r');
            
            if (endIndex != -1) {
              String line = buffer.substring(0, endIndex).trim();
              buffer = buffer.substring(endIndex + 1);
              
              if (line.isNotEmpty) {
                final weight = _parseWeight(line);
                if (weight != null) {
                  _lastWeight = weight;
                  if (_weightController != null && !_weightController!.isClosed) {
                    _weightController!.add(weight);
                  }
                }
              }
            }
          }
          
          // Giới hạn buffer để tránh memory leak
          if (buffer.length > 1000) {
            buffer = buffer.substring(buffer.length - 100);
          }
        } catch (e) {
          // Lỗi parse, bỏ qua
        }
      },
      onError: (error) {
        _isConnected = false;
        if (!_connectionController.isClosed) {
          _connectionController.add(false);
        }
        _scheduleReconnect();
      },
      onDone: () {
        _isConnected = false;
        if (!_connectionController.isClosed) {
          _connectionController.add(false);
        }
        _scheduleReconnect();
      },
    );
  }

  /// Parse trọng lượng từ chuỗi dữ liệu cân NHB300
  /// 
  /// Các format phổ biến:
  /// - "ST,GS,+000.00 kg"
  /// - "ST,NT,+000.00 kg"
  /// - "+000.00"
  /// - "000.00 kg"
  double? _parseWeight(String data) {
    try {
      // Loại bỏ các ký tự không cần thiết
      String cleaned = data
          .replaceAll(RegExp(r'[^\d\.\-\+]'), ' ')
          .trim();
      
      // Tìm số trong chuỗi
      final match = RegExp(r'[\+\-]?\d+\.?\d*').firstMatch(cleaned);
      if (match != null) {
        final value = double.tryParse(match.group(0)!);
        if (value != null && value >= 0 && value < 10000) {
          return value;
        }
      }
      
      // Thử parse trực tiếp từ dữ liệu gốc
      final directMatch = RegExp(r'[\+\-]?\d+\.?\d*').firstMatch(data);
      if (directMatch != null) {
        final value = double.tryParse(directMatch.group(0)!);
        if (value != null && value >= 0 && value < 10000) {
          return value;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  void _scheduleReconnect() {
    if (_currentPortName == null || _isDisposed) return;
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_isDisposed && _currentPortName != null && !_isConnected) {
        connect(_currentPortName!);
      }
    });
  }

  @override
  Stream<double> watchWeight() {
    if (_isDisposed) {
      return Stream<double>.empty();
    }
    if (_weightController == null || _weightController!.isClosed) {
      _weightController = StreamController<double>.broadcast();
      // Nếu chưa kết nối, trả về stream rỗng với giá trị mặc định
      if (!_isConnected) {
        _periodicTimer?.cancel();
        _periodicTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
          if (_isDisposed || _weightController == null || _weightController!.isClosed) {
            timer.cancel();
            return;
          }
          _weightController!.add(_lastWeight);
        });
      }
    }
    return _weightController!.stream;
  }

  @override
  Future<void> tare() async {
    if (_port == null || !_port!.isOpen) return;
    
    try {
      // Lệnh trừ bì cho cân NHB300 (có thể khác tùy model)
      // Thường là: T\r\n hoặc TARE\r\n
      _port!.write(Uint8List.fromList('T\r\n'.codeUnits));
    } catch (e) {
      // Lỗi gửi lệnh
    }
  }

  @override
  Future<void> zero() async {
    if (_port == null || !_port!.isOpen) return;
    
    try {
      // Lệnh về 0 cho cân NHB300 (có thể khác tùy model)
      // Thường là: Z\r\n hoặc ZERO\r\n
      _port!.write(Uint8List.fromList('Z\r\n'.codeUnits));
    } catch (e) {
      // Lỗi gửi lệnh
    }
  }

  /// Gửi lệnh tùy chỉnh đến cân
  Future<void> sendCommand(String command) async {
    if (_port == null || !_port!.isOpen) return;
    
    try {
      _port!.write(Uint8List.fromList('$command\r\n'.codeUnits));
    } catch (e) {
      // Lỗi gửi lệnh
    }
  }

  /// Giải phóng tài nguyên
  @override
  Future<void> dispose() async {
    _isDisposed = true;
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    disconnect();
    _weightController?.close();
    _connectionController.close();
  }
}
