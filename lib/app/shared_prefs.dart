import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

/// The current "search index generation" — bump this by 1 whenever a change to
/// how content is indexed for search requires existing users to rebuild their
/// index (do it in the same release as the change). Users whose last rebuild
/// predates the current generation are prompted once, in the What's New dialog,
/// to rebuild.
///
/// History:
///   1 — markup-stripping of verse text (release 26.6.24+1).
const int kSearchIndexGeneration = 1;

/// The [kSearchIndexGeneration] the user last rebuilt their search index for
/// (absent / 0 means "older than generation 1"). Set to the current generation
/// on a fresh install (born clean) and whenever a rebuild runs, so the prompt
/// re-fires for each future generation but never nags after a rebuild. See
/// [WhatsNewDialog] and `MainShell._checkWhatsNew`.
const String kSearchIndexRebuiltGenKey = 'searchIndexRebuiltGeneration';
