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

- [x] **Start TTS (read-aloud) from the selected verse, not the chapter
  beginning.** When a verse is selected, read-aloud now begins at the first
  selected verse instead of restarting from verse 1.
  - Fixed: `TtsController.toggle` forwards a `fromVerse` to `start`; the read
    aloud sheet seeds it from the lowest `selectedVersesProvider` entry (0 when
    nothing is selected) and shows "Starts at verse N" while idle. Pause/resume
    still continues where it left off.

- [ ] **Prompt existing users to rebuild the search index after the
  markup-stripping fix.** Verse search indexing was changed to strip MyBible
  markup (release 26.6.24+1), but already-installed Bibles keep their old
  polluted index until the user rebuilds it. We need to tell users to do this
  and make it one tap.
  - Surface a clear, friendly note at the **top of the "What's New" dialog**
    recommending a rebuild, with an inline action button that runs
    `ContentStore.rebuildSearchIndex()` (today it's buried in
    Settings → "Rebuild search index", `lib/ui/settings/settings_screen.dart`).
  - Consider only showing the note for users upgrading *into* this version (not
    fresh installs, which already index cleanly), and marking it done once the
    rebuild has been run so it doesn't nag.
  - Changelog renders from `assets/changelog.json`
    (`scripts/update_version.dart`); the dialog lives near the app's
    "What's New" / version display.

- [x] **Auto check for updates.** Automatically check for updates and display
  a message indicating that a new version is available, along with a link to the
  latest releases page.
  - Done: `updateCheckerProvider` (`lib/app/update_checker.dart`) queries the
    GitHub releases API on desktop only, comparing the latest tag against
    `appVersion`. The dashboard shows a dismissible `MaterialBanner` with a
    "View Release" link when a newer version exists. Result is cached for the
    session (`ref.keepAlive()`); dismissal is keyed to the version so a later
    release re-shows the banner.

## Research

- [ ] **Investigate importing SWORD modules.** SWORD is the CrossWire module
  format used by many open Bible apps — a large library of translations,
  commentaries, and dictionaries. Scope out what it would take to import them:
  the on-disk module layout (conf + compressed `ztext`/`zld`/`zcom` data),
  the compression/encoding (LZSS/zlib, versification), and how it maps onto our
  existing `verses`/`commentary`/`dictionary` tables. We already import OSIS
  XML, and many SWORD modules are OSIS-encoded internally, so the existing
  `OsisImporter` (now milestone-aware) may be reusable for the text once a
  module is unpacked.

## Issues

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
