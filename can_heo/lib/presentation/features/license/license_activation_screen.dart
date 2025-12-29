import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/license_service.dart';

/// Màn hình kích hoạt License
class LicenseActivationScreen extends StatefulWidget {
  final VoidCallback onActivated;
  final bool allowClose;
  
  const LicenseActivationScreen({
    super.key,
    required this.onActivated,
    this.allowClose = false,
  });

  @override
  State<LicenseActivationScreen> createState() => _LicenseActivationScreenState();
}

class _LicenseActivationScreenState extends State<LicenseActivationScreen> {
  final _licenseController = TextEditingController();
  final _licenseService = LicenseService.instance;
  
  String _machineId = 'Đang tải...';
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  LicenseResult? _currentStatus;

  @override
  void initState() {
    super.initState();
    _loadMachineId();
    _checkCurrentLicense();
  }

  Future<void> _loadMachineId() async {
    final machineId = await _licenseService.getMachineId();
    setState(() => _machineId = machineId);
  }

  Future<void> _checkCurrentLicense() async {
    final result = await _licenseService.validateLicense();
    setState(() => _currentStatus = result);
  }

  Future<void> _activateLicense() async {
    final licenseKey = _licenseController.text.trim();
    
    if (licenseKey.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập License Key');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    // Lưu license key
    final saved = await _licenseService.saveLicenseKey(licenseKey);
    if (!saved) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể lưu License Key';
      });
      return;
    }
    
    // Validate license
    final result = await _licenseService.validateLicense();
    
    setState(() {
      _isLoading = false;
      _currentStatus = result;
    });
    
    if (result.isValid) {
      setState(() => _successMessage = 'Kích hoạt thành công!');
      await Future.delayed(const Duration(seconds: 1));
      widget.onActivated();
    } else {
      setState(() => _errorMessage = result.message);
      // Xóa license không hợp lệ
      await _licenseService.removeLicense();
    }
  }

  void _copyMachineId() {
    Clipboard.setData(ClipboardData(text: _machineId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã copy Machine ID'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 500,
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo/Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security,
                      size: 48,
                      color: Color(0xFF667eea),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  const Text(
                    'Kích hoạt phần mềm',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vui lòng liên hệ để nhận License Key',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Machine ID section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.computer, size: 20, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'Machine ID (Gửi mã này cho nhà cung cấp)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF667eea)),
                                ),
                                child: SelectableText(
                                  _machineId,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                    color: Color(0xFF667eea),
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _copyMachineId,
                              icon: const Icon(Icons.copy),
                              tooltip: 'Copy Machine ID',
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF667eea),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // License Key input
                  TextField(
                    controller: _licenseController,
                    decoration: InputDecoration(
                      labelText: 'License Key',
                      hintText: 'Nhập License Key được cấp...',
                      prefixIcon: const Icon(Icons.vpn_key),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
                      ),
                    ),
                    maxLines: 3,
                    minLines: 2,
                  ),
                  const SizedBox(height: 16),
                  
                  // Error message
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Success message
                  if (_successMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Activate button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _activateLicense,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Kích hoạt License',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  
                  if (widget.allowClose) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Đóng'),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Contact info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.support_agent, size: 18, color: Colors.blue.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'Liên hệ hỗ trợ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hotline: 0xxx.xxx.xxx\nZalo: 0xxx.xxx.xxx\nEmail: support@example.com',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Current license status
                  if (_currentStatus != null && _currentStatus!.info != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Thông tin License hiện tại',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLicenseInfoRow('Khách hàng', _currentStatus!.info!.customerName),
                    _buildLicenseInfoRow('Loại', _currentStatus!.info!.typeDisplayName),
                    _buildLicenseInfoRow(
                      'Hết hạn',
                      '${_currentStatus!.info!.expiryDate.day}/${_currentStatus!.info!.expiryDate.month}/${_currentStatus!.info!.expiryDate.year}',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLicenseInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }
}
