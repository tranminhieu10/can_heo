import 'dart:async';
import 'package:flutter/services.dart';

/// Interface chung cho mọi loại đầu cân
abstract class IScaleService {
  /// Stream trọng lượng hiện tại (kg) từ đầu cân.
  Stream<double> watchWeight();

  /// Lệnh trừ bì.
  Future<void> tare();

  /// Lệnh về 0.
  Future<void> zero();
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
}
