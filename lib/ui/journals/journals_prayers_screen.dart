import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_drawer.dart';
import 'journals_list_panel.dart';
import 'journal_editor_panel.dart';
import 'prayer_tracker_panel.dart';

class JournalsPrayersScreen extends ConsumerStatefulWidget {
  const JournalsPrayersScreen({super.key});

  @override
  ConsumerState<JournalsPrayersScreen> createState() => _JournalsPrayersScreenState();
}

class _JournalsPrayersScreenState extends ConsumerState<JournalsPrayersScreen> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > 800;

    if (isDesktop) {
      return Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: const Text('Journals & Prayers'),
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              width: 300,
              child: Card(
                margin: EdgeInsets.all(8),
                child: JournalsListPanel(),
              ),
            ),
            const Expanded(
              child: Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: JournalEditorPanel(),
              ),
            ),
            const SizedBox(
              width: 350,
              child: Card(
                margin: EdgeInsets.all(8),
                child: PrayerTrackerPanel(),
              ),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: const Text('Journals & Prayers'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Journals'),
              Tab(text: 'Prayers'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            JournalsListPanel(),
            PrayerTrackerPanel(),
          ],
        ),
      ),
    );
  }
}
