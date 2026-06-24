import 'dart:convert';
import 'package:flutter/services.dart';
import '../data/logging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/audio_bible.dart';
import 'reader_state.dart';
import 'content_providers.dart';
import 'shared_prefs.dart';

// 1. Load all available audio bibles
final audioBiblesProvider = FutureProvider<List<AudioBible>>((ref) async {
  final files = {
    'bsb': 'assets/media/bsb-audio.json',
    'kjv': 'assets/media/kjv-audio.json',
  };

  final List<AudioBible> bibles = [];

  for (final entry in files.entries) {
    try {
      final jsonString = await rootBundle.loadString(entry.value);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      bibles.add(AudioBible.fromJson(entry.key, jsonData));
    } catch (e, stack) {
      logError(e, stack, context: 'loadAudioBibles: ${entry.key}');
    }
  }

  return bibles;
});

// 2. User selected voice actor
class SelectedVoiceNotifier extends Notifier<String?> {
  @override
  String? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('selectedVoice');
  }

  void setVoice(String voice) {
    state = voice;
    ref.read(sharedPreferencesProvider).setString('selectedVoice', voice);
  }
}

final selectedVoiceProvider = NotifierProvider<SelectedVoiceNotifier, String?>(
  () => SelectedVoiceNotifier(),
);

// 4. Current chapter audio data (URL + available voices)
class ChapterAudioData {
  final String url;
  final List<String> availableVoices;
  final String activeVoice;

  ChapterAudioData({
    required this.url,
    required this.availableVoices,
    required this.activeVoice,
  });
}

final chapterAudioProvider = Provider<ChapterAudioData?>((ref) {
  final activeVersions = ref.watch(activeVersionsProvider);
  if (activeVersions.isEmpty) return null;

  final versions = ref.watch(versionsProvider.select((v) => v.value));
  final bibles = ref.watch(audioBiblesProvider.select((v) => v.value));

  if (versions == null || bibles == null) {
    return null; // Equivalent to loading
  }

  final activeId = activeVersions.first;
  final activeBibleVersion = versions
      .where((v) => v.id == activeId)
      .firstOrNull;

  if (activeBibleVersion == null) return null;

  final name = activeBibleVersion.name.toLowerCase();
  final abbrev = activeBibleVersion.abbreviation.toLowerCase();
  final id = activeBibleVersion.id.toLowerCase();

  AudioBible? activeBible;

  // Check for KJV matches
  if (name.contains('kjv') ||
      name.contains('king james') ||
      abbrev.contains('kjv') ||
      id.contains('kjv')) {
    activeBible = bibles.where((b) => b.name == 'kjv').firstOrNull;
  }

  // Check for BSB matches
  if (activeBible == null &&
      (name.contains('bsb') ||
      name.contains('berean') ||
      abbrev.contains('bsb') ||
      id.contains('bsb'))) {
    activeBible = bibles.where((b) => b.name == 'bsb').firstOrNull;
  }

  if (activeBible == null) return null;

  final bookName = ref.watch(selectedBookNameProvider);
  final chapter = ref.watch(selectedChapterProvider);

  final audioMap = activeBible.getAudioForChapter(bookName, chapter);
  if (audioMap == null || audioMap.isEmpty) return null;

  final availableVoices = audioMap.keys.toList()..sort();
  String? selectedVoice = ref.watch(selectedVoiceProvider);

  // If user hasn't selected a voice, or the selected voice isn't available for this chapter, pick the first one
  if (selectedVoice == null || !availableVoices.contains(selectedVoice)) {
    // We don't want to update the provider state during build, so we just use a default
    // We prefer 'gilbert' or 'souer' if available
    if (availableVoices.contains('gilbert')) {
      selectedVoice = 'gilbert';
    } else if (availableVoices.contains('souer')) {
      selectedVoice = 'souer';
    } else {
      selectedVoice = availableVoices.first;
    }
  }

  return ChapterAudioData(
    url: audioMap[selectedVoice]!,
    availableVoices: availableVoices,
    activeVoice: selectedVoice,
  );
});
