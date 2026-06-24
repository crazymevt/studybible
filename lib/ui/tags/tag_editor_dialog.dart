import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/tag_providers.dart';
import '../../data/logging.dart';

class TagEditorDialog extends ConsumerStatefulWidget {
  final String entityId;
  final String entityType;

  const TagEditorDialog({
    super.key,
    required this.entityId,
    required this.entityType,
  });

  @override
  ConsumerState<TagEditorDialog> createState() => _TagEditorDialogState();
}

class _TagEditorDialogState extends ConsumerState<TagEditorDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addTag(String tagName) async {
    final cleanName = tagName.trim().replaceAll(RegExp(r'^#'), '');
    if (cleanName.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(tagControllerProvider).addTagToEntity(
            entityId: widget.entityId,
            entityType: widget.entityType,
            tagName: cleanName,
          );
      if (mounted) {
        _controller.clear();
        _focusNode.requestFocus();
      }
    } catch (e, stack) {
      logError(e, stack, context: 'TagEditorDialog.addTag');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding tag: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entityTagsAsync = ref.watch(tagsForEntityProvider(widget.entityId));
    final allTagsAsync = ref.watch(allTagsProvider);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.label, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Manage Tags',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Current Tags
            entityTagsAsync.when(
              data: (tags) {
                if (tags.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text('No tags yet.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((et) {
                      return InputChip(
                        label: Text('#${et.tag.name}'),
                        onDeleted: () async {
                          await ref.read(tagControllerProvider).removeTagFromEntity(et.id);
                        },
                        deleteIconColor: theme.colorScheme.onSurfaceVariant,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Error: $e'),
            ),

            // Input Field
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: !_isSaving,
              decoration: InputDecoration(
                hintText: 'Add a new tag...',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _isSaving ? null : () => _addTag(_controller.text),
                ),
              ),
              onSubmitted: _isSaving ? null : _addTag,
            ),

            const SizedBox(height: 24),
            Text(
              'Existing Tags',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Existing Tags Cloud
            Expanded(
              child: allTagsAsync.when(
                data: (allTags) {
                  // Filter out tags already applied
                  final appliedTagIds = entityTagsAsync.value?.map((e) => e.tagId).toSet() ?? {};
                  final availableTags = allTags.where((t) => !appliedTagIds.contains(t.id)).toList();

                  if (availableTags.isEmpty) {
                    return Text('No other tags available.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant));
                  }

                  return SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableTags.map((t) {
                        return ActionChip(
                          label: Text('#${t.name}'),
                          backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          onPressed: () => _addTag(t.name),
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
