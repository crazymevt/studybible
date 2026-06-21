import 'package:flutter/material.dart';
import '../../data/user_store.dart' show Achievement;
import '../../data/models/achievement_def.dart';
import 'package:intl/intl.dart';

class AchievementsDialog extends StatelessWidget {
  final List<Achievement> unlockedAchievements;

  const AchievementsDialog({super.key, required this.unlockedAchievements});

  @override
  Widget build(BuildContext context) {
    // Map unlocked achievements by their ID for easy lookup
    final unlockedMap = {for (var a in unlockedAchievements) a.id: a};

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Achievements',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${unlockedAchievements.length} of ${allAchievements.length} Completed',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: allAchievements.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final def = allAchievements[index];
                  final unlockedInfo = unlockedMap[def.id];
                  final isUnlocked = unlockedInfo != null;

                  return Opacity(
                    opacity: isUnlocked ? 1.0 : 0.5,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isUnlocked
                            ? def.color.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.2),
                        child: Icon(
                          isUnlocked ? def.icon : Icons.lock,
                          color: isUnlocked ? def.color : Colors.grey,
                        ),
                      ),
                      title: Text(
                        def.name,
                        style: TextStyle(
                          fontWeight: isUnlocked
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(def.description),
                          if (isUnlocked)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Unlocked on ${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(unlockedInfo.unlockedAt))}',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: isUnlocked
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const SizedBox.shrink(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
