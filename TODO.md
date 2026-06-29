# TODO

Running list of known issues and follow-ups.

## Bugs

## Enhancements

- [x] **Printing.** Print notes, journals, and sermons to a physical printer or
  PDF (cross-platform, via `printing`/`pdf` with an embedded Noto Sans font).
  Reader-chapter and search-results printing were intentionally left out — not
  adding them unless requested.

## Research

- [ ] **Import SWORD modules** (CrossWire format — translations, commentaries,
  dictionaries). Implementation lives in `lib/data/importer/sword/`. Phases
  1, 2, 4, and 5 are **DONE** and verified in the macOS app; **Phase 3 is the
  only remaining work.**
  - **Done so far:** `.conf` parser; `zText`/`RawText`(`4`) Bible readers behind
    a shared `SwordVerseReader`; ZIP + BZIP2 decompression; per-verse OSIS / GBF
    / ThML / TEI source filters via `parseSwordSource`; KJV versification +
    index math; commentary (`zCom`/`RawCom`) and dictionary/lexicon
    (`zLD`/`RawLD`) importers; and a "CrossWire Catalog" download tab (fetches
    the primary repo's `mods.d.tar.gz`, installs freely-distributable unlocked
    Bible/commentary/dictionary modules). Verified end-to-end against real
    CrossWire modules (KJV, GBF/ThML Bibles, MHCC, Easton, AmTract, Scofield).
    LZSS + XZ compression and enumeration of non-primary repos remain
    deliberately unsupported, with clear errors.
  - **Phase 3 — more versifications** (data-heavy, mechanical): Synodal,
    German, Vulgate, LXX, NRSV(A), Catholic/Catholic2, … Same
    `SwordVersification` shape, validated against aggregate totals as KJV was.
    Needed for most non-English and Catholic modules. (Full per-phase research
    notes are in git history — see TODO.md prior to this condensation.)

## Issues

## Archive

- [x] **Gesture navigation using PageView.** Swipe navigation in the Reader to
  change chapters by wrapping the content in a `PageView` with eagerly-loaded
  adjacent chapters for smooth animations (`feat/swipe-navigation`, shipped
  26.6.28+2).

- [x] **Support FTS5 NEAR operator.** Search now allows proximity searches
  (e.g. `NEAR`) instead of forcing exact phrase matches for everything.

- [x] **Delete Notes.**

- [x] **Investigate why Windows can't play audio.**

- [x] **Right-click dictionary lookup returns multiple words instead of the
  exact word.** Right-clicking (or long-pressing) a word in the reader to "Look
  up in Dictionary" showed every entry containing the term as a substring.
  - Fixed: `dictionarySearchQueryProvider` now carries an `exact` flag; the
    reader lookups request an exact (case-insensitive) headword match and show
    "No definitions found" when there's no exact headword (no substring
    fallback). The free-text search box keeps its substring behaviour.

- [x] **Start TTS (read-aloud) from the selected verse, not the chapter
  beginning.** When a verse is selected, read-aloud now begins at the first
  selected verse instead of restarting from verse 1.
  - Fixed: `TtsController.toggle` forwards a `fromVerse` to `start`; the read
    aloud sheet seeds it from the lowest `selectedVersesProvider` entry (0 when
    nothing is selected) and shows "Starts at verse N" while idle. Pause/resume
    still continues where it left off.

- [x] **Prompt existing users to rebuild the search index after the
  markup-stripping fix.** Verse search indexing was changed to strip MyBible
  markup (release 26.6.24+1), but already-installed Bibles keep their old
  polluted index until the user rebuilds it.
  - Done: the What's New dialog shows an amber "Action recommended" caution at
    the top with a one-tap **Rebuild now** button (runs
    `ContentStore.rebuildSearchIndex()`), flipping to a green "All set"
    confirmation. Fresh installs are born clean and never see it.
  - Generalised beyond a one-shot: gated on `kSearchIndexGeneration`
    (`lib/app/shared_prefs.dart`) vs the per-user `searchIndexRebuiltGeneration`
    pref. **To re-prompt after a future indexing change, bump
    `kSearchIndexGeneration` in the same release** — users below it are nudged
    once, then quiet after rebuilding (also resolved by Settings → Rebuild
    search index). A reminder lives on `ContentStore.rebuildSearchIndex()`.

- [x] **Auto check for updates.** Automatically check for updates and display
  a message indicating that a new version is available, along with a link to the
  latest releases page.
  - Done: `updateCheckerProvider` (`lib/app/update_checker.dart`) queries the
    GitHub releases API on desktop only, comparing the latest tag against
    `appVersion`. The dashboard shows a dismissible `MaterialBanner` with a
    "View Release" link when a newer version exists. Result is cached for the
    session (`ref.keepAlive()`); dismissal is keyed to the version so a later
    release re-shows the banner.

- [x] **Investigate ScriptureParser.** `ScriptureParser` currently does not support parsing references with multi-word book names, but it also appears to be unused outside of its own tests (the app uses `ReferenceParser`). Investigate if this is dead code that can be safely removed.
- [x] **Outdated dependencies.** `flutter pub get` reports that 24 packages have newer versions incompatible with current dependency constraints. Need to review `flutter pub outdated` and update constraints in `pubspec.yaml`.
  - Investigated (2026-06-24): the only freely-resolvable bump was
    `path_provider_linux` 2.2.1 → 2.2.2 — applied via `flutter pub upgrade`.
  - The other 24 are all major-version bumps blocked at the resolver level:
    even `flutter pub upgrade --major-versions` reports "No changes would be
    made." Their newer majors (analyzer 14, win32 6, package_info_plus 10,
    vector_math 2.4, `latlong2` 0.10 via flutter_map, `share_plus` 13, etc.)
    depend on transitive packages pinned by the Flutter SDK.
  - We're already on the latest stable **Flutter 3.44.3** (2026-06-18), so the
    tree is as current as the SDK allows. These will become reachable only when
    a future Flutter release bumps its pins — nothing actionable until then.
    Tests green after the bump.
- [x] **Investigate silent failures on network and IO operations.** Many `catch` blocks (e.g. cross-reference import in `content_providers.dart`, audio loading in `audio_player_widget.dart`, and network calls in `content_manager_api.dart`) swallow exceptions with a simple `debugPrint` and return empty states. In release builds, this means features fail completely silently without logging to a crash reporter or showing a UI error to the user.
  - Done (2026-06-24): added `lib/data/logging.dart` `logError(error, stack,
    {context})` as the single sink for *caught* errors, mirroring the
    uncaught/framework path in `main.dart` (which now also routes through it).
    This is the one hook to wire a crash reporter (Sentry/Crashlytics — neither
    installed yet) into later.
  - Routed every genuine error-swallow site (data/app/ui) through `logError`
    with a `context` label and a stack trace. Deliberately *left* intentional
    control-flow catches (platform no-op `catch(_)`, FTS-vocab migration
    fallbacks, "table not migrated yet" search guards, delta/date parse
    fallbacks) so they don't become log noise.
  - UX: `ContentManagerApi.fetch*` now **rethrow** instead of returning `[]`,
    so the content browser and onboarding show the real connection error via
    their existing `AsyncValue.error` branches instead of a misleading "nothing
    available" empty state. Audio load failures already drive a `_loadFailed`
    retry UI; sync/backup/export already showed SnackBars — those now log too.
  - analyze + domain lint + 104 tests all green.
- [x] **FutureBuilder inside build method.** `WhatsNewDialog` creates its future (`_loadChangelog()`) directly inside its `build` method. This causes the app to re-read and re-parse the JSON asset on every single widget rebuild, which is a common Flutter anti-pattern that can lead to flickering or performance hits. It should be converted to a `StatefulWidget` and initialized in `initState`.
  - Done (2026-06-24): converted to a `StatefulWidget`; the changelog future is
    created once in `initState` and held in `_changelogFuture`, so the asset is
    read/parsed a single time per dialog instead of on every rebuild. The
    `const WhatsNewDialog()` call sites are unchanged. analyze + 104 tests green.
- [x] **TextEditingController memory leaks.** Several dialogs create `TextEditingController` instances but fail to dispose them. For example, `_NoteEditorDialogState` (in `note_editor.dart`) lacks a `dispose()` method entirely, while methods like `_showNewSermonDialog` (in `sermons_panel.dart`) and `_showOutlineGeneratorDialog` (in `sermon_editor_screen.dart`) instantiate controllers before calling `showDialog` but never call `.dispose()` after the dialog completes. This causes compounding memory leaks as users open and close dialogs.
  - Done (2026-06-24): added the missing `dispose()` to `_NoteEditorDialogState`.
    For the dialog-local controllers, dispose after the dialog future resolves:
    `_showNewSermonDialog` / `_showOutlineGeneratorDialog` (both `await
    showDialog`) dispose post-await; `_showAddPrayerDialog` in
    `prayer_tracker_panel.dart` (a non-awaited `showDialog`, found during the
    sweep) disposes via `.then()`. A full `lib/ui` scan confirmed every other
    `TextEditingController` is a State field already disposed in `dispose()`.
    analyze + 104 tests green.
