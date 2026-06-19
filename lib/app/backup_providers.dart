import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/backup/backup_restore_service.dart';

final backupRestoreServiceProvider = Provider<BackupRestoreService>((ref) {
  return BackupRestoreService();
});
