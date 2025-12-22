import 'package:flutter/material.dart';
import '../../../core/services/scale_service.dart';
import '../../../injection_container.dart';

/// Widget hiển thị trạng thái kết nối với đầu cân ASI
class ScaleConnectionStatus extends StatefulWidget {
  const ScaleConnectionStatus({super.key});

  @override
  State<ScaleConnectionStatus> createState() => _ScaleConnectionStatusState();
}

class _ScaleConnectionStatusState extends State<ScaleConnectionStatus> {
  bool _isConnected = false;
  String? _portName;
  bool _isReconnecting = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  void _checkConnection() {
    final scaleService = sl<IScaleService>();
    if (scaleService is ASIScaleService) {
      setState(() {
        _isConnected = scaleService.isConnected;
        _portName = scaleService.portName;
      });
    }
  }

  Future<void> _reconnect() async {
    setState(() => _isReconnecting = true);
    
    final scaleService = sl<IScaleService>();
    if (scaleService is ASIScaleService) {
      await scaleService.dispose();
      final success = await scaleService.connect();
      
      if (mounted) {
        setState(() {
          _isConnected = success;
          _portName = scaleService.portName;
          _isReconnecting = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã kết nối lại với $_portName'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Không thể kết nối lại với đầu cân'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      setState(() => _isReconnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isConnected ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isConnected ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isConnected ? Icons.check_circle : Icons.warning,
            size: 16,
            color: _isConnected ? Colors.green.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            _isConnected 
                ? 'ASI ($_portName)' 
                : 'Chưa kết nối cân',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _isConnected ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
          if (!_isConnected) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: _isReconnecting ? null : _reconnect,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _isReconnecting
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Kết nối lại',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
