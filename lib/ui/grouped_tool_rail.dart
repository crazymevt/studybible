import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_state.dart';
import 'common/tool_groups.dart';

/// The desktop tools rail: the reader's side tools in sections separated by
/// dividers (see [toolGroups]). Hand-rolled to Material 3 rail metrics
/// because [NavigationRail] has no notion of sections, which is what keeps
/// 14 destinations scannable.
class GroupedToolRail extends ConsumerWidget {
  const GroupedToolRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTool = ref.watch(activeToolProvider);

    // Deliberately denser than NavigationRail's 72px-per-destination: 14
    // tools plus the group breaks must still fit a typical laptop window
    // without scrolling.
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          const SizedBox(height: 6),
          for (var i = 0; i < toolGroups.length; i++) ...[
            if (i > 0)
              const Divider(height: 17, indent: 16, endIndent: 16),
            for (final item in toolGroups[i].items)
              _RailItem(item: item, selected: activeTool == item.tool),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _RailItem extends ConsumerWidget {
  final ToolItem item;
  final bool selected;

  const _RailItem({required this.item, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final iconColor = selected
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onSurfaceVariant;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: selected
          ? theme.colorScheme.onSurface
          : theme.colorScheme.onSurfaceVariant,
      fontWeight: selected ? FontWeight.w600 : null,
      height: 1.1,
    );

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // setTool toggles: tapping the active tool closes its panel, same as
        // the NavigationRail behaved.
        onTap: () => ref.read(activeToolProvider.notifier).setTool(item.tool),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? theme.colorScheme.secondaryContainer : null,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(item.icon, color: iconColor),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  item.railLabel,
                  style: labelStyle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
