import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// ADMIN TOOL - Tạo License Key cho khách hàng
/// 
/// HƯỚNG DẪN SỬ DỤNG:
/// 1. Chạy file này riêng: dart run lib/tools/license_generator.dart
/// 2. Hoặc tích hợp vào app admin của bạn
/// 
/// LƯU Ý: KHÔNG bao gồm file này trong bản build cho khách!

void main() {
  runApp(const LicenseGeneratorApp());
}

class LicenseGeneratorApp extends StatelessWidget {
  const LicenseGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'License Generator - Admin Tool',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF667eea),
        useMaterial3: true,
      ),
      home: const LicenseGeneratorScreen(),
    );
  }
}

class LicenseGeneratorScreen extends StatefulWidget {
  const LicenseGeneratorScreen({super.key});

  @override
  State<LicenseGeneratorScreen> createState() => _LicenseGeneratorScreenState();
}

class _LicenseGeneratorScreenState extends State<LicenseGeneratorScreen> {
  final _machineIdController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _daysController = TextEditingController(text: '30');
  
  String _generatedLicense = '';
  int _selectedLicenseType = 0;
  
  // QUAN TRỌNG: Phải giống với key trong license_service.dart
  static const String _secretKey = 'CAN_HEO_2025_SECRET_KEY_CHANGE_THIS';

  void _generateLicense() {
    final machineId = _machineIdController.text.trim();
    final customerName = _customerNameController.text.trim();
    final days = int.tryParse(_daysController.text) ?? 30;
    
    if (machineId.isEmpty) {
      _showError('Vui lòng nhập Machine ID');
      return;
    }
    
    if (customerName.isEmpty) {
      _showError('Vui lòng nhập tên khách hàng');
      return;
    }
    
    final expiryDate = DateTime.now().add(Duration(days: days));
    
    final data = {
      'mid': machineId,
      'exp': expiryDate.toIso8601String(),
      'name': customerName,
      'type': _selectedLicenseType,
      'created': DateTime.now().toIso8601String(),
    };
    
    final jsonStr = jsonEncode(data);
    final bytes = utf8.encode(jsonStr);
    final base64Str = base64Encode(bytes);
    
    // Tạo signature
    final signatureBytes = utf8.encode(base64Str + _secretKey);
    final signature = sha256.convert(signatureBytes).toString().substring(0, 8).toUpperCase();
    
    setState(() {
      _generatedLicense = '$base64Str.$signature';
    });
    
    _showSuccess('Đã tạo License Key thành công!');
  }

  void _copyLicense() {
    if (_generatedLicense.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _generatedLicense));
      _showSuccess('Đã copy License Key');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('License Generator - Admin Tool'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Warning banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '⚠️ ADMIN ONLY - Không bao gồm tool này trong bản build cho khách!',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Machine ID input
                TextField(
                  controller: _machineIdController,
                  decoration: InputDecoration(
                    labelText: 'Machine ID của khách',
                    hintText: 'VD: ABCD-1234-EFGH-5678',
                    prefixIcon: const Icon(Icons.computer),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Customer name input
                TextField(
                  controller: _customerNameController,
                  decoration: InputDecoration(
                    labelText: 'Tên khách hàng',
                    hintText: 'VD: Trại heo ABC',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Days input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _daysController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Số ngày sử dụng',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Quick buttons
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildQuickDaysButton(7, '7 ngày'),
                        _buildQuickDaysButton(30, '30 ngày'),
                        _buildQuickDaysButton(90, '90 ngày'),
                        _buildQuickDaysButton(365, '1 năm'),
                        _buildQuickDaysButton(3650, '10 năm'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // License type
                DropdownButtonFormField<int>(
                  initialValue: _selectedLicenseType,
                  decoration: InputDecoration(
                    labelText: 'Loại License',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Trial - Dùng thử')),
                    DropdownMenuItem(value: 1, child: Text('Standard - Tiêu chuẩn')),
                    DropdownMenuItem(value: 2, child: Text('Premium - Cao cấp')),
                    DropdownMenuItem(value: 3, child: Text('Lifetime - Vĩnh viễn')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedLicenseType = value ?? 0);
                  },
                ),
                const SizedBox(height: 24),
                
                // Generate button
                ElevatedButton.icon(
                  onPressed: _generateLicense,
                  icon: const Icon(Icons.vpn_key),
                  label: const Text('Tạo License Key'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Generated license
                if (_generatedLicense.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'License Key đã tạo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _copyLicense,
                              icon: const Icon(Icons.copy),
                              tooltip: 'Copy',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: SelectableText(
                            _generatedLicense,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Gửi License Key này cho khách hàng để kích hoạt phần mềm.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Hướng dẫn sử dụng',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '1. Khách hàng mở phần mềm → Copy Machine ID\n'
                        '2. Khách gửi Machine ID cho bạn\n'
                        '3. Bạn nhập Machine ID vào tool này\n'
                        '4. Chọn số ngày và loại license\n'
                        '5. Nhấn "Tạo License Key"\n'
                        '6. Gửi License Key cho khách\n'
                        '7. Khách nhập License Key để kích hoạt',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuickDaysButton(int days, String label) {
    return OutlinedButton(
      onPressed: () {
        _daysController.text = days.toString();
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  @override
  void dispose() {
    _machineIdController.dispose();
    _customerNameController.dispose();
    _daysController.dispose();
    super.dispose();
  }
}
