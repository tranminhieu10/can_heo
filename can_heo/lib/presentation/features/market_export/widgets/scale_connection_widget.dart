import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/services/nhb300_scale_service.dart';

/// Widget để chọn và kết nối với cân NHB300 qua Serial Port
class ScaleConnectionWidget extends StatefulWidget {
  final NHB300ScaleService scaleService;
  final ValueChanged<double>? onWeightChanged;
  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;

  const ScaleConnectionWidget({
    super.key,
    required this.scaleService,
    this.onWeightChanged,
    this.onConnected,
    this.onDisconnected,
  });

  @override
  State<ScaleConnectionWidget> createState() => _ScaleConnectionWidgetState();
}

class _ScaleConnectionWidgetState extends State<ScaleConnectionWidget> {
  List<String> _availablePorts = [];
  String? _selectedPort;
  int _selectedBaudRate = 9600;
  bool _isConnecting = false;
  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<double>? _weightSub;
  double _currentWeight = 0.0;

  final List<int> _baudRates = [4800, 9600, 19200, 38400, 57600, 115200];

  @override
  void initState() {
    super.initState();
    _refreshPorts();
    _setupListeners();
  }

  void _setupListeners() {
    _connectionSub = widget.scaleService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {});
        if (connected) {
          widget.onConnected?.call();
          _startWeightListening();
        } else {
          widget.onDisconnected?.call();
        }
      }
    });
  }

  void _startWeightListening() {
    _weightSub?.cancel();
    _weightSub = widget.scaleService.watchWeight().listen((weight) {
      if (mounted) {
        setState(() => _currentWeight = weight);
        widget.onWeightChanged?.call(weight);
      }
    });
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    _weightSub?.cancel();
    super.dispose();
  }

  void _refreshPorts() {
    setState(() {
      _availablePorts = NHB300ScaleService.getAvailablePorts();
      if (_availablePorts.isNotEmpty && _selectedPort == null) {
        _selectedPort = _availablePorts.first;
      }
    });
  }

  Future<void> _connect() async {
    if (_selectedPort == null) return;
    
    setState(() => _isConnecting = true);
    
    try {
      await widget.scaleService.connect(
        _selectedPort!,
        baudRate: _selectedBaudRate,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã kết nối với cân tại $_selectedPort'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi kết nối: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _disconnect() async {
    await widget.scaleService.disconnect();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã ngắt kết nối cân')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.scaleService.isConnected;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  isConnected ? Icons.usb : Icons.usb_off,
                  color: isConnected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'KẾT NỐI CÂN NHB300',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _refreshPorts,
                  tooltip: 'Làm mới danh sách cổng',
                ),
              ],
            ),
            const Divider(),
            
            // Connection controls
            if (!isConnected) ...[
              Row(
                children: [
                  // Port selection
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedPort,
                      decoration: const InputDecoration(
                        labelText: 'Cổng COM',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _availablePorts.map((port) {
                        return DropdownMenuItem(
                          value: port,
                          child: Text(port, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedPort = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Baud rate selection
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedBaudRate,
                      decoration: const InputDecoration(
                        labelText: 'Baud',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      items: _baudRates.map((rate) {
                        return DropdownMenuItem(
                          value: rate,
                          child: Text('$rate', style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedBaudRate = value ?? 9600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Connect button
                  FilledButton.icon(
                    onPressed: _isConnecting || _selectedPort == null ? null : _connect,
                    icon: _isConnecting 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.link, size: 18),
                    label: Text(_isConnecting ? 'Đang kết nối...' : 'Kết nối'),
                  ),
                ],
              ),
              
              if (_availablePorts.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '⚠️ Không tìm thấy cổng COM. Hãy kiểm tra cáp kết nối.',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
            ] else ...[
              // Connected state
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đã kết nối: ${widget.scaleService.currentPortName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Trọng lượng: ${_currentWeight.toStringAsFixed(2)} kg',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        OutlinedButton.icon(
                          onPressed: widget.scaleService.tare,
                          icon: const Icon(Icons.exposure_zero, size: 16),
                          label: const Text('Trừ bì'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextButton.icon(
                          onPressed: _disconnect,
                          icon: const Icon(Icons.link_off, size: 16),
                          label: const Text('Ngắt'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dialog để hiển thị thông tin chi tiết các cổng COM
class PortInfoDialog extends StatelessWidget {
  const PortInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final ports = NHB300ScaleService.getAvailablePorts();
    
    return AlertDialog(
      title: const Text('Thông tin cổng COM'),
      content: SizedBox(
        width: 400,
        child: ports.isEmpty
            ? const Text('Không tìm thấy cổng COM nào.')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: ports.length,
                itemBuilder: (context, index) {
                  final portName = ports[index];
                  final info = NHB300ScaleService.getPortInfo(portName);
                  
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.usb),
                      title: Text(portName),
                      subtitle: info != null
                          ? Text(
                              'Mô tả: ${info['description'] ?? 'N/A'}\n'
                              'Nhà SX: ${info['manufacturer'] ?? 'N/A'}',
                            )
                          : const Text('Không lấy được thông tin'),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ĐÓNG'),
        ),
      ],
    );
  }
}
