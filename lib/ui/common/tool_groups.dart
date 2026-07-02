import 'package:flutter/material.dart';

import '../../app/app_state.dart';

/// One reader-tool destination, shared by the desktop tools rail and the
/// mobile tools drawer so both surfaces present the same tools in the same
/// order.
class ToolItem {
  final ActiveTool tool;
  final IconData icon;

  /// Full label, used where horizontal space allows (drawer list tiles).
  final String label;

  /// Short label for the narrow desktop rail; defaults to [label].
  final String railLabel;

  const ToolItem(this.tool, this.icon, this.label, {String? railLabel})
      : railLabel = railLabel ?? label;
}

class ToolGroup {
  final String label;
  final List<ToolItem> items;

  const ToolGroup(this.label, this.items);
}

/// The reader's side tools, grouped so 14 destinations scan as four short
/// sections instead of one long list: reference works you consult, content
/// you author, scheduled reading, and browsable extras.
const List<ToolGroup> toolGroups = [
  ToolGroup('Study', [
    ToolItem(ActiveTool.crossReference, Icons.compare_arrows,
        'Cross-References',
        railLabel: 'Cross-Ref'),
    ToolItem(ActiveTool.commentaries, Icons.menu_book, 'Commentaries',
        railLabel: 'Commentary'),
    ToolItem(ActiveTool.dictionary, Icons.import_contacts, 'Dictionary'),
    ToolItem(ActiveTool.search, Icons.search, 'Search'),
  ]),
  ToolGroup('My Work', [
    ToolItem(ActiveTool.notes, Icons.note, 'Notes'),
    ToolItem(ActiveTool.highlights, Icons.format_color_fill, 'My Highlights',
        railLabel: 'Highlights'),
    ToolItem(ActiveTool.scratch, Icons.edit_note, 'Scratch'),
    ToolItem(ActiveTool.sermons, Icons.co_present, 'Sermons'),
  ]),
  ToolGroup('Plans', [
    ToolItem(ActiveTool.readingPlans, Icons.event_note, 'Reading Plans',
        railLabel: 'Plans'),
    ToolItem(ActiveTool.devotionals, Icons.calendar_today, 'Devotionals'),
  ]),
  ToolGroup('Explore', [
    ToolItem(ActiveTool.topics, Icons.topic, 'Topics'),
    ToolItem(ActiveTool.harmony, Icons.auto_stories, 'Gospel Harmony',
        railLabel: 'Harmony'),
    ToolItem(ActiveTool.places, Icons.map, 'Places'),
    ToolItem(ActiveTool.media, Icons.video_library, 'Media'),
  ]),
];
