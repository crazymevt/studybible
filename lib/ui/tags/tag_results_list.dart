import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/tag_providers.dart';
import '../reader/search_panel.dart';
import '../common/empty_state.dart';
import '../common/skeleton.dart';

class TagResultsList extends ConsumerWidget {
  final String tagId;
  final String tagName;

  const TagResultsList({required this.tagId, required this.tagName, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(entitiesForTagProvider(tagId));

    return resultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return EmptyState(
            icon: Icons.label_off_outlined,
            title: 'Nothing tagged yet',
            message: 'Nothing is tagged with #$tagName yet.',
          );
        }

        final verses = results.where((r) => r.type == 'verse').toList();
        final notes = results.where((r) => r.type == 'note').toList();
        final sermons = results.where((r) => r.type == 'sermon').toList();
        final journals = results.where((r) => r.type == 'journal').toList();
        final prayers = results.where((r) => r.type == 'prayer').toList();

        final tabs = <Widget>[];
        final views = <Widget>[];

        if (verses.isNotEmpty) {
          tabs.add(Tab(text: 'Verses (${verses.length})'));
          views.add(SearchResultsList(results: verses));
        }
        if (notes.isNotEmpty) {
          tabs.add(Tab(text: 'Notes (${notes.length})'));
          views.add(SearchResultsList(results: notes));
        }
        if (sermons.isNotEmpty) {
          tabs.add(Tab(text: 'Sermons (${sermons.length})'));
          views.add(SearchResultsList(results: sermons));
        }
        if (journals.isNotEmpty) {
          tabs.add(Tab(text: 'Journals (${journals.length})'));
          views.add(SearchResultsList(results: journals));
        }
        if (prayers.isNotEmpty) {
          tabs.add(Tab(text: 'Prayers (${prayers.length})'));
          views.add(SearchResultsList(results: prayers));
        }

        if (tabs.isEmpty) {
          return const EmptyState(
            icon: Icons.label_off_outlined,
            title: 'Nothing to show',
            message: 'No supported entities found for this tag.',
          );
        }

        return DefaultTabController(
          length: tabs.length,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TabBar(
                isScrollable: true,
                tabs: tabs,
              ),
              Expanded(
                child: TabBarView(
                  children: views,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SkeletonList(),
      error: (e, _) => const EmptyState(
        icon: Icons.error_outline,
        title: 'Couldn\'t load tagged items',
      ),
    );
  }
}
