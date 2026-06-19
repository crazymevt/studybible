import 'package:flutter/material.dart';
import '../../data/user_store.dart';

class TimeAnalyticsDialog extends StatefulWidget {
  final List<TimeTracker> trackers;

  const TimeAnalyticsDialog({super.key, required this.trackers});

  @override
  State<TimeAnalyticsDialog> createState() => _TimeAnalyticsDialogState();
}

enum TimeRange { pastMonth, past3Months, pastYear }

class _TimeAnalyticsDialogState extends State<TimeAnalyticsDialog> {
  TimeRange _selectedRange = TimeRange.pastMonth;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Time Analytics', style: Theme.of(context).textTheme.headlineSmall),
                DropdownButton<TimeRange>(
                  value: _selectedRange,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRange = val);
                  },
                  items: const [
                    DropdownMenuItem(value: TimeRange.pastMonth, child: Text('Past Month')),
                    DropdownMenuItem(value: TimeRange.past3Months, child: Text('Past 3 Months')),
                    DropdownMenuItem(value: TimeRange.pastYear, child: Text('Past Year')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: _buildBarChart(),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int numBuckets = 0;
    Duration bucketSize;
    DateTime startDate;

    switch (_selectedRange) {
      case TimeRange.pastMonth:
        numBuckets = 30;
        bucketSize = const Duration(days: 1);
        startDate = today.subtract(const Duration(days: 29));
        break;
      case TimeRange.past3Months:
        numBuckets = 12; // 12 weeks
        bucketSize = const Duration(days: 7);
        startDate = today.subtract(const Duration(days: 12 * 7 - 1));
        break;
      case TimeRange.pastYear:
        numBuckets = 12; // 12 months
        bucketSize = const Duration(days: 30); // Approximate
        startDate = DateTime(today.year - 1, today.month, 1);
        break;
    }

    final buckets = List.filled(numBuckets, 0);

    for (final t in widget.trackers) {
      final d = DateTime.fromMillisecondsSinceEpoch(t.endTime).toLocal();
      if (d.isBefore(startDate)) continue;
      
      if (_selectedRange == TimeRange.pastYear) {
        // Precise month matching for past year
        int monthDiff = (today.year - d.year) * 12 + today.month - d.month;
        int bucketIndex = 11 - monthDiff;
        if (bucketIndex >= 0 && bucketIndex < 12) {
          buckets[bucketIndex] += t.durationMs;
        }
      } else {
        final diff = d.difference(startDate).inDays;
        int bucketIndex = diff ~/ bucketSize.inDays;
        if (bucketIndex >= 0 && bucketIndex < numBuckets) {
          buckets[bucketIndex] += t.durationMs;
        }
      }
    }

    int maxMs = buckets.reduce((a, b) => a > b ? a : b);
    if (maxMs == 0) maxMs = 60000; // default 1 min max for empty chart

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(numBuckets, (index) {
        final heightPct = buckets[index] / maxMs;
        final minutes = buckets[index] ~/ 60000;
        
        String label = '';
        if (_selectedRange == TimeRange.pastMonth && index % 5 == 0) {
          label = '${index + 1}';
        } else if (_selectedRange == TimeRange.past3Months) {
          label = 'W${index + 1}';
        } else if (_selectedRange == TimeRange.pastYear) {
          final m = DateTime(startDate.year, startDate.month + index, 1);
          final monthStr = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m.month - 1];
          label = monthStr;
        }

        return Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (minutes > 0 && numBuckets <= 12) 
                Text('${minutes}m', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 4),
              Expanded(
                child: FractionallySizedBox(
                  heightFactor: heightPct,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (label.isNotEmpty)
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              if (label.isEmpty && numBuckets <= 30) // placeholder for spacing
                 const Text('', style: TextStyle(fontSize: 10)),
            ],
          ),
        );
      }),
    );
  }
}
