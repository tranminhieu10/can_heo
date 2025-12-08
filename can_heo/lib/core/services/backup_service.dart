import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BackupService {
  static const String _dbFileName = 'pig_scale.sqlite';

  /// Sao lưu file DB ra thư mục do người dùng chọn
  static Future<void> backupDatabase() async {
    // 1. Lấy đường dẫn file DB hiện tại
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDir.path, _dbFileName);
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      throw Exception('Không tìm thấy file dữ liệu ($_dbFileName).');
    }

    // 2. Cho user chọn thư mục lưu
    final directoryPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Chọn thư mục để lưu file sao lưu',
    );
    if (directoryPath == null) return; // user bấm Hủy

    final backupFileName =
        'backup_${DateTime.now().millisecondsSinceEpoch}.sqlite';
    final backupPath = p.join(directoryPath, backupFileName);

    await dbFile.copy(backupPath);
  }

  /// Khôi phục DB từ file .sqlite mà user chọn
  static Future<void> restoreDatabase() async {
    // 1. Chọn file .sqlite
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Chọn file .sqlite để khôi phục',
      type: FileType.custom,
      allowedExtensions: ['sqlite'],
    );

    if (result == null || result.files.single.path == null) return;

    final backupFile = File(result.files.single.path!);

    // 2. Ghi đè vào file DB hiện tại
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDir.path, _dbFileName);
    final dbFile = File(dbPath);

    if (await dbFile.exists()) {
      await dbFile.delete();
    }

    await backupFile.copy(dbPath);
  }
}
