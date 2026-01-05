import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/services/nhb300_scale_service.dart';

/// Màn hình test kết nối cân qua Serial Port
class ScaleTestScreen extends StatefulWidget {
  const ScaleTestScreen({super.key});

  @override
  State<ScaleTestScreen> createState() => _ScaleTestScreenState();
}

class _ScaleTestScreenState extends State<ScaleTestScreen> {
  final NHB300ScaleService _scaleService = NHB300ScaleService();
  
  List<String> _availablePorts = [];
  String? _selectedPort;
  int _selectedBaudRate = 9600;
  bool _isConnecting = false;
  
  double _currentWeight = 0.0;
  final List<String> _logs = [];
  
  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<double>? _weightSub;
  
  final ScrollController _logScrollController = ScrollController();

  final List<int> _baudRates = [2400, 4800, 9600, 19200, 38400, 57600, 115200];

  @override
  void initState() {
    super.initState();
    _refreshPorts();
    _setupListeners();
    _addLog('🚀 Khởi động màn hình test cân');
  }

  void _setupListeners() {
    _connectionSub = _scaleService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {});
        if (connected) {
          _addLog('✅ Đã kết nối thành công!');
          _startWeightListening();
        } else {
          _addLog('❌ Mất kết nối');
        }
      }
    });
  }

  void _startWeightListening() {
    _weightSub?.cancel();
    _weightSub = _scaleService.watchWeight().listen((weight) {
      if (mounted) {
        setState(() => _currentWeight = weight);
        _addLog('📊 Trọng lượng: ${weight.toStringAsFixed(2)} kg');
      }
    });
  }

  void _addLog(String message) {
    final time = DateTime.now();
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
    setState(() {
      _logs.add('[$timeStr] $message');
      // Giới hạn 100 dòng log
      if (_logs.length > 100) {
        _logs.removeAt(0);
      }
    });
    
    // Auto scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    _weightSub?.cancel();
    _scaleService.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  void _refreshPorts() {
    setState(() {
      _availablePorts = NHB300ScaleService.getAvailablePorts();
    });
    _addLog('🔄 Tìm thấy ${_availablePorts.length} cổng: ${_availablePorts.join(', ')}');
    
    if (_availablePorts.isNotEmpty && _selectedPort == null) {
      _selectedPort = _availablePorts.first;
    }
  }

  Future<void> _connect() async {
    if (_selectedPort == null) {
      _addLog('⚠️ Chưa chọn cổng COM');
      return;
    }
    
    setState(() => _isConnecting = true);
    _addLog('🔌 Đang kết nối $_selectedPort @ $_selectedBaudRate baud...');
    
    try {
      await _scaleService.connect(
        _selectedPort!,
        baudRate: _selectedBaudRate,
      );
    } catch (e) {
      _addLog('❌ Lỗi: $e');
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _disconnect() async {
    _addLog('🔌 Đang ngắt kết nối...');
    await _scaleService.disconnect();
  }

  void _sendTare() {
    _addLog('📤 Gửi lệnh TRỪ BÌ (T)');
    _scaleService.tare();
  }

  void _sendZero() {
    _addLog('📤 Gửi lệnh VỀ 0 (Z)');
    _scaleService.zero();
  }

  void _clearLogs() {
    setState(() => _logs.clear());
    _addLog('🗑️ Đã xóa log');
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _scaleService.isConnected;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Kết Nối Cân'),
        backgroundColor: Colors.blue[100],
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showPortInfo(),
            tooltip: 'Thông tin cổng',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Panel
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isConnected ? Icons.usb : Icons.usb_off,
                          color: isConnected ? Colors.green : Colors.grey,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isConnected ? 'ĐÃ KẾT NỐI' : 'CHƯA KẾT NỐI',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isConnected ? Colors.green : Colors.grey,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _refreshPorts,
                          tooltip: 'Làm mới cổng',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Port & Baud selection
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedPort,
                            decoration: const InputDecoration(
                              labelText: 'Cổng COM',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: _availablePorts.map((port) {
                              return DropdownMenuItem(value: port, child: Text(port));
                            }).toList(),
                            onChanged: isConnected ? null : (v) => setState(() => _selectedPort = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedBaudRate,
                            decoration: const InputDecoration(
                              labelText: 'Baud Rate',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: _baudRates.map((rate) {
                              return DropdownMenuItem(value: rate, child: Text('$rate'));
                            }).toList(),
                            onChanged: isConnected ? null : (v) => setState(() => _selectedBaudRate = v ?? 9600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Connect/Disconnect buttons
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: isConnected || _isConnecting || _selectedPort == null
                                ? null
                                : _connect,
                            icon: _isConnecting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.link),
                            label: Text(_isConnecting ? 'Đang kết nối...' : 'KẾT NỐI'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isConnected ? _disconnect : null,
                            icon: const Icon(Icons.link_off),
                            label: const Text('NGẮT KẾT NỐI'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Weight Display
            Card(
              elevation: 2,
              color: isConnected ? Colors.green.shade50 : Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'TRỌNG LƯỢNG',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_currentWeight.toStringAsFixed(2)} kg',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: isConnected ? Colors.green.shade700 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: isConnected ? _sendTare : null,
                          icon: const Icon(Icons.exposure_zero),
                          label: const Text('TRỪ BÌ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: isConnected ? _sendZero : null,
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('VỀ 0'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Log Panel
            Expanded(
              child: Card(
                elevation: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.terminal, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'LOG DỮ LIỆU',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _clearLogs,
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Xóa'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.black87,
                        child: ListView.builder(
                          controller: _logScrollController,
                          padding: const EdgeInsets.all(8),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return Text(
                              _logs[index],
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPortInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thông tin cổng COM'),
        content: SizedBox(
          width: 400,
          child: _availablePorts.isEmpty
              ? const Text('Không tìm thấy cổng COM nào.\n\nHãy kiểm tra:\n• Cáp USB đã cắm chưa\n• Driver đã cài chưa\n• Cân đã bật nguồn chưa')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availablePorts.length,
                  itemBuilder: (context, index) {
                    final portName = _availablePorts[index];
                    final info = NHB300ScaleService.getPortInfo(portName);
                    
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.usb, color: Colors.blue),
                        title: Text(portName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: info != null
                            ? Text(
                                'Mô tả: ${info['description'] ?? 'N/A'}\n'
                                'Nhà SX: ${info['manufacturer'] ?? 'N/A'}\n'
                                'VID: ${info['vendorId']} | PID: ${info['productId']}',
                              )
                            : const Text('Không lấy được thông tin'),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ĐÓNG'),
          ),
        ],
      ),
    );
  }
}
