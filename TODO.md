# TODO

Running list of known issues and follow-ups.

## Bugs

- [ ] **Right-click dictionary lookup returns multiple words instead of the
  exact word.** Right-clicking (or long-pressing) a word in the reader to "Look
  up in Dictionary" shows several entries rather than the single exact word
  that was tapped. The lookup likely runs a prefix/substring match where it
  should resolve (or at least prioritize) the exact term.
  - Entry point: `_openDictionary` in the reader views
    (`lib/ui/reader/flowing_paragraph_view.dart`, `verse_list_view.dart`,
    `parallel_view.dart`) sets `dictionarySearchQueryProvider` to the tapped
    word; the `DictionaryPanel` search then resolves the matches.

## Enhancements

- [ ] **Start TTS (read-aloud) from the selected verse, not the chapter
  beginning.** When a verse is selected, read-aloud should begin at that verse
  instead of always restarting from verse 1 of the chapter.
  - Look at `TtsService` and `lib/app/tts_providers.dart`; the play action
    should seed the starting verse from the current verse selection.
