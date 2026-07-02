import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/scripture_nav_providers.dart';

/// Compact bar shown under the reader's breadcrumb while scripture navigation
/// is active: previous/next steppers, the current stop (tappable to jump
/// anywhere in the route), and a close button that ends the mode.
class ScriptureNavBar extends ConsumerWidget {
  const ScriptureNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(scriptureNavProvider);
    if (nav == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final notifier = ref.read(scriptureNavProvider.notifier);

    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        child: Row(
          children: [
            Icon(
              Icons.route_outlined,
              size: 18,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous passage',
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              onPressed: nav.hasPrevious ? notifier.previous : null,
            ),
            Text(
              '${nav.index + 1}/${nav.stops.length}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next passage',
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              onPressed: nav.hasNext ? notifier.next : null,
            ),
            const SizedBox(width: 4),
            // The current reference doubles as a jump list over the whole
            // route, so a stop can be revisited without stepping one by one.
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: PopupMenuButton<int>(
                  tooltip: 'Jump to passage',
                  onSelected: notifier.jumpTo,
                  itemBuilder: (context) => [
                    for (var i = 0; i < nav.stops.length; i++)
                      CheckedPopupMenuItem(
                        value: i,
                        checked: i == nav.index,
                        child: Text(nav.stops[i].label),
                      ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      '${nav.current.label} — ${nav.sermonTitle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'End scripture navigation',
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              onPressed: notifier.exit,
            ),
          ],
        ),
      ),
    );
  }
}
