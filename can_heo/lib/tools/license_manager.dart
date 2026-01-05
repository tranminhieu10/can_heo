import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';

/// License Manager - Công cụ quản lý tất cả license đã cấp
/// 
/// Chạy: flutter run -t lib/tools/license_manager.dart

void main() {
  runApp(const LicenseManagerApp());
}

class LicenseManagerApp extends StatelessWidget {
  const LicenseManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'License Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const LicenseManagerScreen(),
    );
  }
}

class LicenseManagerScreen extends StatefulWidget {
  const LicenseManagerScreen({super.key});

  @override
  State<LicenseManagerScreen> createState() => _LicenseManagerScreenState();
}

class _LicenseManagerScreenState extends State<LicenseManagerScreen> {
  final LicenseDatabase _db = LicenseDatabase();
  List<LicenseRecord> _licenses = [];
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, active, expired, revoked

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  Future<void> _loadLicenses() async {
    final licenses = await _db.getAllLicenses();
    setState(() {
      _licenses = licenses;
    });
  }

  List<LicenseRecord> get _filteredLicenses {
    return _licenses.where((license) {
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!license.customerName.toLowerCase().contains(query) &&
            !license.machineId.toLowerCase().contains(query) &&
            !license.phone.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Filter by status
      switch (_filterStatus) {
        case 'active':
          return license.isActive && !license.isExpired;
        case 'expired':
          return license.isExpired;
        case 'revoked':
          return !license.isActive;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔐 License Manager - Cân Heo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLicenses,
            tooltip: 'Làm mới',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateLicenseDialog,
            tooltip: 'Tạo license mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics
          _buildStatistics(),
          
          // Search and Filter
          _buildSearchAndFilter(),
          
          // License List
          Expanded(
            child: _buildLicenseList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final total = _licenses.length;
    final active = _licenses.where((l) => l.isActive && !l.isExpired).length;
    final expired = _licenses.where((l) => l.isExpired).length;
    final revoked = _licenses.where((l) => !l.isActive).length;
    final expiringIn7Days = _licenses.where((l) => 
      l.isActive && !l.isExpired && l.daysRemaining <= 7
    ).length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Tổng', total, Colors.blue),
          _buildStatCard('Đang hoạt động', active, Colors.green),
          _buildStatCard('Hết hạn', expired, Colors.orange),
          _buildStatCard('Đã thu hồi', revoked, Colors.red),
          _buildStatCard('Sắp hết hạn (7 ngày)', expiringIn7Days, Colors.amber),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm theo tên, Machine ID, SĐT...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _filterStatus,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tất cả')),
              DropdownMenuItem(value: 'active', child: Text('Đang hoạt động')),
              DropdownMenuItem(value: 'expired', child: Text('Hết hạn')),
              DropdownMenuItem(value: 'revoked', child: Text('Đã thu hồi')),
            ],
            onChanged: (value) {
              setState(() {
                _filterStatus = value ?? 'all';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseList() {
    final licenses = _filteredLicenses;
    
    if (licenses.isEmpty) {
      return const Center(
        child: Text('Không có license nào'),
      );
    }

    return ListView.builder(
      itemCount: licenses.length,
      itemBuilder: (context, index) {
        final license = licenses[index];
        return _buildLicenseCard(license);
      },
    );
  }

  Widget _buildLicenseCard(LicenseRecord license) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!license.isActive) {
      statusColor = Colors.red;
      statusText = 'Đã thu hồi';
      statusIcon = Icons.block;
    } else if (license.isExpired) {
      statusColor = Colors.orange;
      statusText = 'Hết hạn';
      statusIcon = Icons.timer_off;
    } else if (license.daysRemaining <= 7) {
      statusColor = Colors.amber;
      statusText = 'Còn ${license.daysRemaining} ngày';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.green;
      statusText = 'Hoạt động';
      statusIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(
          license.customerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Machine ID: ${license.machineId}\n'
          'SĐT: ${license.phone}',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            statusText,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Loại license', license.type),
                _buildInfoRow('Ngày tạo', _formatDate(license.createdDate)),
                _buildInfoRow('Ngày hết hạn', _formatDate(license.expiryDate)),
                _buildInfoRow('Còn lại', '${license.daysRemaining} ngày'),
                _buildInfoRow('Ghi chú', license.notes),
                const SizedBox(height: 16),
                
                // License Key (có thể copy)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          license.licenseKey,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: license.licenseKey));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã copy License Key')),
                          );
                        },
                        tooltip: 'Copy License Key',
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (license.isActive && !license.isExpired)
                      TextButton.icon(
                        icon: const Icon(Icons.block, color: Colors.red),
                        label: const Text('Thu hồi', style: TextStyle(color: Colors.red)),
                        onPressed: () => _revokeLicense(license),
                      ),
                    if (!license.isActive)
                      TextButton.icon(
                        icon: const Icon(Icons.restore, color: Colors.green),
                        label: const Text('Khôi phục', style: TextStyle(color: Colors.green)),
                        onPressed: () => _restoreLicense(license),
                      ),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Gia hạn'),
                      onPressed: () => _showRenewDialog(license),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                      onPressed: () => _deleteLicense(license),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _showCreateLicenseDialog() async {
    final formKey = GlobalKey<FormState>();
    String machineId = '';
    String customerName = '';
    String phone = '';
    String notes = '';
    int days = 30;
    String licenseType = 'trial';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo License Mới'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Machine ID *',
                      hintText: 'XXXX-XXXX-XXXX-XXXX',
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Bắt buộc' : null,
                    onSaved: (v) => machineId = v ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Tên khách hàng *',
                      hintText: 'VD: Trại heo ABC',
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Bắt buộc' : null,
                    onSaved: (v) => customerName = v ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      hintText: 'VD: 0901234567',
                    ),
                    onSaved: (v) => phone = v ?? '',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: days,
                    decoration: const InputDecoration(labelText: 'Thời hạn'),
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('7 ngày (dùng thử)')),
                      DropdownMenuItem(value: 30, child: Text('30 ngày')),
                      DropdownMenuItem(value: 90, child: Text('90 ngày')),
                      DropdownMenuItem(value: 180, child: Text('180 ngày')),
                      DropdownMenuItem(value: 365, child: Text('1 năm')),
                      DropdownMenuItem(value: 3650, child: Text('10 năm (lifetime)')),
                    ],
                    onChanged: (v) => days = v ?? 30,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: licenseType,
                    decoration: const InputDecoration(labelText: 'Loại license'),
                    items: const [
                      DropdownMenuItem(value: 'trial', child: Text('Trial (dùng thử)')),
                      DropdownMenuItem(value: 'standard', child: Text('Standard')),
                      DropdownMenuItem(value: 'premium', child: Text('Premium')),
                      DropdownMenuItem(value: 'lifetime', child: Text('Lifetime')),
                    ],
                    onChanged: (v) => licenseType = v ?? 'trial',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú',
                      hintText: 'VD: Đã thanh toán 50%',
                    ),
                    maxLines: 2,
                    onSaved: (v) => notes = v ?? '',
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();
                Navigator.pop(context, true);
              }
            },
            child: const Text('Tạo License'),
          ),
        ],
      ),
    );

    if (result == true) {
      final expiryDate = DateTime.now().add(Duration(days: days));
      final licenseKey = _generateLicenseKey(
        machineId: machineId,
        expiryDate: expiryDate,
        customerName: customerName,
        type: licenseType,
      );

      final record = LicenseRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        machineId: machineId,
        customerName: customerName,
        phone: phone,
        type: licenseType,
        createdDate: DateTime.now(),
        expiryDate: expiryDate,
        licenseKey: licenseKey,
        notes: notes,
        isActive: true,
      );

      await _db.addLicense(record);
      await _loadLicenses();

      // Copy license key to clipboard
      await Clipboard.setData(ClipboardData(text: licenseKey));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã tạo license và copy vào clipboard!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _showRenewDialog(LicenseRecord license) async {
    int days = 30;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Gia hạn license cho ${license.customerName}'),
        content: DropdownButtonFormField<int>(
          initialValue: days,
          decoration: const InputDecoration(labelText: 'Thêm thời gian'),
          items: const [
            DropdownMenuItem(value: 7, child: Text('7 ngày')),
            DropdownMenuItem(value: 30, child: Text('30 ngày')),
            DropdownMenuItem(value: 90, child: Text('90 ngày')),
            DropdownMenuItem(value: 180, child: Text('180 ngày')),
            DropdownMenuItem(value: 365, child: Text('1 năm')),
          ],
          onChanged: (v) => days = v ?? 30,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, days),
            child: const Text('Gia hạn'),
          ),
        ],
      ),
    );

    if (result != null) {
      final newExpiry = license.expiryDate.add(Duration(days: result));
      final newLicenseKey = _generateLicenseKey(
        machineId: license.machineId,
        expiryDate: newExpiry,
        customerName: license.customerName,
        type: license.type,
      );

      license.expiryDate = newExpiry;
      license.licenseKey = newLicenseKey;
      license.notes += '\n[${_formatDate(DateTime.now())}] Gia hạn thêm $result ngày';

      await _db.updateLicense(license);
      await _loadLicenses();

      await Clipboard.setData(ClipboardData(text: newLicenseKey));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã gia hạn và copy license key mới!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _revokeLicense(LicenseRecord license) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thu hồi license?'),
        content: Text('Bạn có chắc muốn thu hồi license của ${license.customerName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      license.isActive = false;
      license.notes += '\n[${_formatDate(DateTime.now())}] Thu hồi license';
      await _db.updateLicense(license);
      await _loadLicenses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thu hồi license'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _restoreLicense(LicenseRecord license) async {
    license.isActive = true;
    license.notes += '\n[${_formatDate(DateTime.now())}] Khôi phục license';
    await _db.updateLicense(license);
    await _loadLicenses();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã khôi phục license'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteLicense(LicenseRecord license) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa license?'),
        content: Text('Bạn có chắc muốn xóa vĩnh viễn license của ${license.customerName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteLicense(license.id);
      await _loadLicenses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa license'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _generateLicenseKey({
    required String machineId,
    required DateTime expiryDate,
    required String customerName,
    required String type,
  }) {
    const secretKey = 'CAN_HEO_2025_SECRET_KEY_CHANGE_THIS';
    
    final typeIndex = ['trial', 'standard', 'premium', 'lifetime'].indexOf(type);
    
    final data = {
      'mid': machineId,
      'exp': expiryDate.toIso8601String(),
      'name': customerName,
      'type': typeIndex >= 0 ? typeIndex : 0,
      'created': DateTime.now().toIso8601String(),
    };

    final jsonStr = jsonEncode(data);
    final bytes = utf8.encode(jsonStr);
    final base64Str = base64Encode(bytes);

    final signatureBytes = utf8.encode(base64Str + secretKey);
    final signature = sha256.convert(signatureBytes).toString().substring(0, 8).toUpperCase();

    return '$base64Str.$signature';
  }
}

/// Database để lưu trữ license
class LicenseDatabase {
  static const String _fileName = 'licenses_db.json';
  
  Future<File> _getFile() async {
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
    final appDir = Directory('$localAppData\\can_heo_admin');
    
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    
    return File('${appDir.path}\\$_fileName');
  }

  Future<List<LicenseRecord>> getAllLicenses() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return [];
      }

      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((json) => LicenseRecord.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveAll(List<LicenseRecord> licenses) async {
    final file = await _getFile();
    final jsonList = licenses.map((l) => l.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  Future<void> addLicense(LicenseRecord license) async {
    final licenses = await getAllLicenses();
    licenses.add(license);
    await _saveAll(licenses);
  }

  Future<void> updateLicense(LicenseRecord license) async {
    final licenses = await getAllLicenses();
    final index = licenses.indexWhere((l) => l.id == license.id);
    if (index >= 0) {
      licenses[index] = license;
      await _saveAll(licenses);
    }
  }

  Future<void> deleteLicense(String id) async {
    final licenses = await getAllLicenses();
    licenses.removeWhere((l) => l.id == id);
    await _saveAll(licenses);
  }
}

/// Model cho license record
class LicenseRecord {
  final String id;
  final String machineId;
  final String customerName;
  final String phone;
  final String type;
  final DateTime createdDate;
  DateTime expiryDate;
  String licenseKey;
  String notes;
  bool isActive;

  LicenseRecord({
    required this.id,
    required this.machineId,
    required this.customerName,
    required this.phone,
    required this.type,
    required this.createdDate,
    required this.expiryDate,
    required this.licenseKey,
    required this.notes,
    required this.isActive,
  });

  bool get isExpired => DateTime.now().isAfter(expiryDate);
  
  int get daysRemaining {
    if (isExpired) return 0;
    return expiryDate.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'machineId': machineId,
    'customerName': customerName,
    'phone': phone,
    'type': type,
    'createdDate': createdDate.toIso8601String(),
    'expiryDate': expiryDate.toIso8601String(),
    'licenseKey': licenseKey,
    'notes': notes,
    'isActive': isActive,
  };

  factory LicenseRecord.fromJson(Map<String, dynamic> json) => LicenseRecord(
    id: json['id'],
    machineId: json['machineId'],
    customerName: json['customerName'],
    phone: json['phone'] ?? '',
    type: json['type'],
    createdDate: DateTime.parse(json['createdDate']),
    expiryDate: DateTime.parse(json['expiryDate']),
    licenseKey: json['licenseKey'],
    notes: json['notes'] ?? '',
    isActive: json['isActive'] ?? true,
  );
}
