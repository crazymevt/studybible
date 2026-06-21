// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../domain/export/sermon_exporter.dart';
import '../../data/user_store.dart';

class ExportDialog extends StatefulWidget {
  final List<Sermon> sermons;
  
  const ExportDialog({super.key, required this.sermons});

  static Future<void> show(BuildContext context, List<Sermon> sermons) {
    return showDialog(
      context: context,
      builder: (context) => ExportDialog(sermons: sermons),
    );
  }

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  bool _isExporting = false;
  ExportFormat _selectedFormat = ExportFormat.pdf;

  Future<void> _export(ExportAction action) async {
    setState(() => _isExporting = true);
    try {
      await SermonExporter.exportSermons(context, widget.sermons, _selectedFormat, action);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Export ${widget.sermons.length == 1 ? 'Sermon' : 'All Sermons'}'),
      content: _isExporting
          ? const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ExportFormat>(
                  title: const Text('Export as PDF'),
                  subtitle: const Text('Plain text layout'),
                  value: ExportFormat.pdf,
                  groupValue: _selectedFormat,
                  onChanged: (val) => setState(() => _selectedFormat = val!),
                ),
                RadioListTile<ExportFormat>(
                  title: const Text('Export as HTML'),
                  subtitle: const Text('Retains all rich formatting'),
                  value: ExportFormat.html,
                  groupValue: _selectedFormat,
                  onChanged: (val) => setState(() => _selectedFormat = val!),
                ),
                RadioListTile<ExportFormat>(
                  title: const Text('Export as Plain Text'),
                  subtitle: const Text('Raw unformatted text'),
                  value: ExportFormat.text,
                  groupValue: _selectedFormat,
                  onChanged: (val) => setState(() => _selectedFormat = val!),
                ),
              ],
            ),
      actions: [
        if (!_isExporting) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _export(ExportAction.save),
            child: const Text('Save to Folder'),
          ),
          ElevatedButton(
            onPressed: () => _export(ExportAction.share),
            child: const Text('Share'),
          ),
        ]
      ],
    );
  }
}
