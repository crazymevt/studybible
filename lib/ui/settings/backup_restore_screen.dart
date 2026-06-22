import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/backup_providers.dart';
import '../../data/backup/backup_restore_service.dart';
import '../app_drawer.dart';
import '../common/global_search_bar.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _includeContent = false;
  bool _isWorking = false;
  String? _statusMessage;

  Future<void> _createBackup() async {
    setState(() {
      _isWorking = true;
      _statusMessage = 'Preparing backup...';
    });

    try {
      final service = ref.read(backupRestoreServiceProvider);
      final backupFile = await service.createBackup(
        includeContent: _includeContent,
        onProgress: (status) {
          if (mounted) setState(() => _statusMessage = status);
        },
      );

      if (!mounted) return;

      // Mobile has no "Save As" dialog via file_selector (getSaveLocation is
      // desktop/web only).
      if (Platform.isAndroid) {
        // Android: pick a destination folder through the Storage Access
        // Framework (which includes local storage) and copy the backup into
        // it — no storage permission, and unlike a share sheet it can target a
        // plain local folder.
        final dir = await SafUtil().pickDirectory(
          writePermission: true,
          persistablePermission: false,
          initialUri: '',
        );
        if (dir != null) {
          await SafStream().pasteLocalFile(
            backupFile.path,
            dir.uri,
            service.defaultFilename,
            'application/octet-stream',
            overwrite: true,
          );
        }
        await backupFile.delete();
        if (mounted) {
          setState(
            () => _statusMessage = dir != null
                ? 'Backup saved successfully!'
                : 'Backup cancelled.',
          );
        }
        return;
      }

      if (Platform.isIOS) {
        // iOS: the system share sheet offers "Save to Files" for local folders.
        final shareResult = await SharePlus.instance.share(
          ShareParams(
            files: [XFile(backupFile.path, name: service.defaultFilename)],
          ),
        );
        await backupFile.delete();
        if (mounted) {
          final saved = shareResult.status == ShareResultStatus.success;
          setState(
            () => _statusMessage =
                saved ? 'Backup saved successfully!' : 'Backup cancelled.',
          );
        }
        return;
      }

      // Desktop: let the user pick where to save.
      final saveLocation = await getSaveLocation(
        suggestedName: service.defaultFilename,
      );
      final result = saveLocation?.path;

      if (result != null) {
        // Copy the temp backup to the chosen location
        await backupFile.copy(result);
        await backupFile.delete(); // Clean up temp
        if (mounted) {
          setState(() => _statusMessage = 'Backup saved successfully!');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Backup saved to ${p.basename(result)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // User cancelled
        await backupFile.delete();
        if (mounted) setState(() => _statusMessage = 'Backup cancelled.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _restoreBackup() async {
    // 1. Pick a file
    String? pickedFileUri;
    Stream<List<int>>? readStream;
    String? pickedFilePath;

    if (Platform.isAndroid) {
      final doc = await SafUtil().pickFile(
        mimeTypes: ['application/octet-stream', '*/*'],
      );
      if (doc == null) return;
      pickedFileUri = doc.uri;
    } else {
      final picked = await openFile();

      if (picked == null) return;
      pickedFilePath = picked.path;
    }

    final service = ref.read(backupRestoreServiceProvider);

    setState(() {
      _isWorking = true;
      _statusMessage = 'Preparing backup...';
    });

    File backupFile;
    File? tempFile;
    try {
      if (pickedFilePath != null) {
        // Desktop/iOS: the picker returns a real file path, so read it
        // directly — no need to copy the (potentially large) backup.
        backupFile = File(pickedFilePath);
      } else {
        // Android SAF: we only have a content:// URI, so stream it to a
        // temp file rather than loading the whole backup into memory.
        if (Platform.isAndroid && pickedFileUri != null) {
          readStream = await SafStream().readFileStream(pickedFileUri);
        }
        if (readStream == null) {
          throw Exception('Could not read picked file');
        }
        final tempDir = await getTemporaryDirectory();
        tempFile = File(
          p.join(
            tempDir.path,
            'temp_restore_${DateTime.now().microsecondsSinceEpoch}.studybible',
          ),
        );
        final sink = tempFile.openWrite();
        await for (final chunk in readStream) {
          sink.add(chunk);
        }
        await sink.close();
        backupFile = tempFile;
      }

      // 2. Inspect the backup
      BackupInfo info;
      try {
        info = await service.inspectBackup(backupFile);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid backup file: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      // 3. Show confirmation dialog with backup details
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _RestoreConfirmDialog(info: info),
      );

      if (confirmed != true || !mounted) return;

      // 4. Perform restore
      setState(() => _statusMessage = 'Restoring...');

      await service.restoreBackup(
        backupFile,
        onProgress: (status) {
          if (mounted) setState(() => _statusMessage = status);
        },
      );

      if (mounted) {
        setState(
          () => _statusMessage = 'Restore complete! Please restart the app.',
        );
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: const Text('Restore Complete'),
            content: const Text(
              'Your data has been restored successfully.\n\n'
              'Please close and reopen the app for changes to take effect.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
      
      // Clean up temp file if we created one
      try {
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        centerTitle: true,
        title: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Icon(Icons.search, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const Expanded(
                  child: GlobalSearchBar(),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // ── Backup Section ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.backup,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Create Backup',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Save your highlights, notes, bookmarks, journals, prayers, and reading progress to a file.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Include downloaded content'),
                        subtitle: const Text(
                          'Bible translations, commentaries, and dictionaries. '
                          'This can significantly increase the backup size.',
                        ),
                        value: _includeContent,
                        onChanged: _isWorking
                            ? null
                            : (val) => setState(() => _includeContent = val),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isWorking ? null : _createBackup,
                          icon: const Icon(Icons.save),
                          label: const Text('Create Backup'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Restore Section ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.restore,
                            color: theme.colorScheme.secondary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Restore from Backup',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Restore your data from a previously created backup file. '
                        'This will replace all current data.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Restoring will overwrite your current data. If you use sync, run a sync first to preserve any recent changes.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isWorking ? null : _restoreBackup,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Select Backup File'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Status Area ──
              if (_statusMessage != null || _isWorking) ...[
                const SizedBox(height: 24),
                Card(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        if (_isWorking)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(
                            _statusMessage?.startsWith('Error') == true
                                ? Icons.error_outline
                                : Icons.check_circle_outline,
                            color: _statusMessage?.startsWith('Error') == true
                                ? theme.colorScheme.error
                                : Colors.green,
                            size: 20,
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _statusMessage ?? '',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirmation dialog shown before a restore, displaying backup details.
class _RestoreConfirmDialog extends StatelessWidget {
  final BackupInfo info;

  const _RestoreConfirmDialog({required this.info});

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(Icons.restore, color: theme.colorScheme.primary, size: 40),
      title: const Text('Restore Backup?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This will replace all current data with the backup contents.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _InfoRow(
            label: 'Created',
            value: _formatDate(info.manifest.createdAt),
          ),
          _InfoRow(label: 'Size', value: _formatBytes(info.fileSizeBytes)),
          _InfoRow(
            label: 'User data',
            value: info.hasUserDb ? 'Included' : 'Not included',
          ),
          _InfoRow(
            label: 'Downloaded content',
            value: info.hasContentDb ? 'Included' : 'Not included',
          ),
          if (info.manifest.deviceId != null)
            _InfoRow(
              label: 'Source device',
              value: info.manifest.deviceId!.substring(0, 8),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This action cannot be undone.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Restore'),
        ),
      ],
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
