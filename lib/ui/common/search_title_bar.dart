import 'package:flutter/material.dart';
import 'global_search_bar.dart';

/// The rounded search "pill" used as the AppBar title across the dashboard,
/// reader, journals and backup screens.
///
/// Clips its contents so it degrades gracefully — rather than throwing a
/// RenderFlex overflow — when many AppBar actions squeeze the centered title
/// down to a few pixels on narrow screens.
class SearchTitleBar extends StatelessWidget {
  const SearchTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Container(
        height: 40,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        // The search icon is the field's prefixIcon, so there's no fixed-width
        // sibling that could overflow the title Row on narrow screens.
        child: const GlobalSearchBar(),
      ),
    );
  }
}
