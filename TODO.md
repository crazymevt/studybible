# TODO

Running list of known issues and follow-ups.

## Bugs

- [x] **Right-click dictionary lookup returns multiple words instead of the
  exact word.** Right-clicking (or long-pressing) a word in the reader to "Look
  up in Dictionary" showed every entry containing the term as a substring.
  - Fixed: `dictionarySearchQueryProvider` now carries an `exact` flag; the
    reader lookups request an exact (case-insensitive) headword match and show
    "No definitions found" when there's no exact headword (no substring
    fallback). The free-text search box keeps its substring behaviour.

## Enhancements

- [ ] **Start TTS (read-aloud) from the selected verse, not the chapter
  beginning.** When a verse is selected, read-aloud should begin at that verse
  instead of always restarting from verse 1 of the chapter.
  - Look at `TtsService` and `lib/app/tts_providers.dart`; the play action
    should seed the starting verse from the current verse selection.
