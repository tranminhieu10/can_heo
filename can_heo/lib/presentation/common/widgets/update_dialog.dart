import 'package:flutter/material.dart';
import '../../../core/services/update_service.dart';

/// Dialog kiểm tra và cài đặt cập nhật
class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key});

  /// Hiển thị dialog kiểm tra cập nhật
  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UpdateDialog(),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  final _updateService = UpdateService();
  UpdateCheckResult? _checkResult;
  bool _isChecking = true;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    setState(() => _isChecking = true);
    
    final result = await _updateService.checkForUpdates();
    
    if (mounted) {
      setState(() {
        _checkResult = result;
        _isChecking = false;
      });
    }
  }

  Future<void> _startDownload() async {
    setState(() => _isDownloading = true);
    await _updateService.downloadAndInstall();
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes == 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.system_update, color: Colors.green.shade700),
          const SizedBox(width: 12),
          const Text('Kiểm tra cập nhật'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: _buildContent(),
      ),
      actions: _buildActions(),
    );
  }

  Widget _buildContent() {
    // Đang kiểm tra
    if (_isChecking) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang kiểm tra phiên bản...'),
        ],
      );
    }

    // Có lỗi
    if (_checkResult?.error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Không thể kiểm tra cập nhật',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _checkResult!.error!,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    // Đang tải
    if (_isDownloading) {
      return ValueListenableBuilder<double>(
        valueListenable: _updateService.downloadProgress,
        builder: (context, progress, _) {
          return ValueListenableBuilder<UpdateStatus>(
            valueListenable: _updateService.status,
            builder: (context, status, _) {
              String statusText;
              switch (status) {
                case UpdateStatus.downloading:
                  statusText = 'Đang tải... ${(progress * 100).toStringAsFixed(0)}%';
                  break;
                case UpdateStatus.installing:
                  statusText = 'Đang cài đặt...';
                  break;
                case UpdateStatus.completed:
                  statusText = 'Hoàn tất! Đang khởi động lại...';
                  break;
                case UpdateStatus.error:
                  statusText = 'Lỗi: ${_updateService.errorMessage.value}';
                  break;
                default:
                  statusText = 'Đang xử lý...';
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status == UpdateStatus.downloading) ...[
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 16),
                  ] else if (status != UpdateStatus.error) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 14,
                      color: status == UpdateStatus.error
                          ? Colors.red
                          : Colors.grey[700],
                    ),
                  ),
                  if (status == UpdateStatus.installing) ...[
                    const SizedBox(height: 8),
                    Text(
                      '⚠️ Vui lòng không tắt ứng dụng',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      );
    }

    // Có bản cập nhật mới
    if (_checkResult?.hasUpdate == true) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.new_releases,
                    color: Colors.green.shade700,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Có bản cập nhật mới!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'v${_checkResult!.currentVersion} → v${_checkResult!.newVersion}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_checkResult!.downloadSize != null &&
                          _checkResult!.downloadSize! > 0)
                        Text(
                          'Dung lượng: ${_formatFileSize(_checkResult!.downloadSize)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_checkResult!.releaseNotes != null &&
              _checkResult!.releaseNotes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Có gì mới:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: Text(
                  _checkResult!.releaseNotes!,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      );
    }

    // Đã là phiên bản mới nhất
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: 48,
            color: Colors.blue.shade600,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Bạn đang dùng phiên bản mới nhất!',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Phiên bản: v${_checkResult?.currentVersion ?? UpdateService.currentVersion}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions() {
    // Đang kiểm tra hoặc đang tải
    if (_isChecking || _isDownloading) {
      if (_updateService.status.value == UpdateStatus.error) {
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ];
      }
      return [];
    }

    // Có bản cập nhật
    if (_checkResult?.hasUpdate == true) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Để sau'),
        ),
        FilledButton.icon(
          onPressed: _startDownload,
          icon: const Icon(Icons.download),
          label: const Text('Cập nhật ngay'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green.shade600,
          ),
        ),
      ];
    }

    // Không có cập nhật hoặc lỗi
    return [
      if (_checkResult?.error != null)
        TextButton(
          onPressed: _checkForUpdates,
          child: const Text('Thử lại'),
        ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Đóng'),
      ),
    ];
  }
}

/// Widget hiển thị thông tin phiên bản và nút kiểm tra cập nhật
class UpdateCheckerTile extends StatelessWidget {
  const UpdateCheckerTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.system_update, color: Colors.green.shade700),
      ),
      title: const Text('Kiểm tra cập nhật'),
      subtitle: Text(
        'Phiên bản hiện tại: v${UpdateService.currentVersion}',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => UpdateDialog.show(context),
    );
  }
}
