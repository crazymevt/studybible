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

## Research

- [ ] **Investigate importing SWORD modules.** SWORD is the CrossWire module
  format used by many open Bible apps — a large library of translations,
  commentaries, and dictionaries.
  - **Researched (2026-06-24).** A module is a `.conf` metadata file (`mods.d/`)
    plus binary data files (`modules/…/`). The `.conf` is INI-like and drives
    everything: `ModDrv` (`zText`/`RawText` Bibles, `zCom`/`RawCom`
    commentaries, `zLD`/`RawLD` dictionaries, `RawGenBook` trees); `SourceType`
    (the per-verse markup: `OSIS`/`GBF`/`ThML`/`TEI`/plain); `CompressType`
    (`ZIP`=zlib, `BZIP2`, `LZSS`, `XZ`); `Versification`; plus `Encoding`,
    `Lang`, `Description`, `About`.
  - **`zText` layout** (compressed Bibles, common case): per testament
    (`ot`/`nt`) three files — `.bzz` (concatenated compressed text blocks),
    `.bzs` (block index: `[fileOffset(4), compSize(4), uncompSize(4)]`), `.bzv`
    (verse index, one record **per verse slot in the versification**:
    `[blockNum(4), offsetInBlock(4), length(2)]`). Read a verse = `.bzv` lookup
    by positional index → block#/offset/length → `.bzs` → seek/decompress
    `.bzz` block → slice. `RawText` has no block layer (`ot` + `ot.vss`).
  - **Schema fit is clean, no migrations needed:** `zText`/`RawText` →
    `Versions`/`Books`/`Verses` (+ `content_search` FTS); `zCom` →
    `Commentaries`/`CommentaryEntries`; `zLD` →
    `Dictionaries`/`DictionaryEntries`. SWORD inline markup maps onto our
    `VerseSegment`/footnote model.
  - **Reusable:** `extractOsisBookVerses` ([osis_importer.dart](lib/data/importer/osis_importer.dart),
    already milestone-aware) for OSIS modules — but SWORD stores an OSIS
    *fragment per verse*, not a whole document, so it needs adapting to
    per-verse fragments. Decompression: `package:archive` (already a dep) has
    `ZLibDecoder` + `BZip2Decoder`, and `dart:io` has zlib built in, so ZIP and
    BZIP2 are free. The download→extract→pick-driver→import→invalidate flow in
    [content_manager_providers.dart](lib/app/content_manager_providers.dart)
    drops straight in.
  - **Hard part = versification.** The `.bzv` index is *positional*: entry N is
    the Nth verse slot in the module's v11n, uninterpretable without the full
    ordered canon (per-chapter verse counts + testament/book intro "verse 0"
    slots). SWORD hardcodes ~20 of these in C++ (`canon_*.h`); we'd port **KJV**
    first, then Synodal/LXX/etc. as needed. An off-by-one shifts every verse —
    this is the line item to budget for, *not* the compression.
  - **Other new work:** `.conf` parser (INI-ish, has continuation lines +
    repeated keys like `GlobalOptionFilter`); GBF/ThML filters for older
    non-OSIS modules; LZSS decoder (SWORD's own variant, ~100 lines to port, no
    Dart package); `zLD` dictionary index (`.dat/.idx/.zdt/.zdx`). XZ + LZSS
    can be rejected with a clear message initially.
  - **Phased plan:** (1) `.conf` parser + `zText`/`RawText` with ZIP + OSIS +
    KJV versification only — covers KJV/ASV/WEB and proves the binary-index +
    versification machinery end-to-end. (2) BZIP2, then GBF/ThML, then more
    versifications. (3) commentaries (`zCom`) and dictionaries (`zLD`).
  - **Phase 1 DONE** (branch `feat/sword-import`, `lib/data/importer/sword/`):
    `.conf` parser, KJV versification + index math, `zText` ZIP reader,
    per-verse OSIS fragment parser, and `SwordBibleImporter` →
    `versions`/`books`/`verses`, all unit-tested. Wired into the Content
    Manager via a local-file "Import SWORD module (.zip)" action.
    **Verified end-to-end** against the real CrossWire KJV module (all 31,102
    verses, correct text + Strong's + footnotes + FTS) and confirmed working
    in the macOS app. Phase-1 caveat fixed along the way: SWORD reserves two
    leading index slots (module + testament heading), so book offsets start at
    2 — an off-by-one that shifted every verse.
  - **Roadmap for the remaining phases** (planned order: 2 → 4 → 3 → 5):
    - **Phase 2 DONE — broaden format coverage** (2026-06-24).
      `RawText`/`RawText4` uncompressed Bibles via a new `SwordRawTextReader`
      (flat `ot`/`nt` text + `ot.vss`/`nt.vss` positional index, no block
      layer); both readers now share a `SwordVerseReader` interface so
      `SwordBibleImporter` walks the versification reader-agnostically and
      accepts any Bible driver. **BZIP2** decompression added to
      `SwordZTextReader` via `package:archive`'s `BZip2Decoder`. Per-verse
      source filters `parseGbfFragment` (token-based GBF) and `parseThmlFragment`
      (XML via `package:xml`) join `parseOsisFragment`, dispatched by
      `SourceType`; both share a `VerseSegmentBuilder` that attaches the
      trailing Strong's codes GBF/ThML emit *after* each word, captures
      footnotes out of the search text, and marks italic/Jesus words. The shared
      parse result is now `ParsedVerseEntry` (renamed from `ParsedOsisEntry`).
      LZSS and XZ compression, and `TEI` source, still throw a clear
      unsupported-format error. All unit-tested (readers, both filters,
      end-to-end RawText import), and **verified in the macOS app** against real
      CrossWire **GBF** and **ThML** modules — download → install → text and
      footnotes rendering correctly in the reader. Not yet exercised against a
      real module: **BZIP2** (none in the CrossWire repo) and GBF/ThML
      **Strong's** attachment (no available GBF/ThML Bible ships Strong's) —
      both remain synthetic-tested only.
    - **Phase 4 DONE — CrossWire download manager** (2026-06-24).
      New "CrossWire Catalog" tab beside ph4.org/OSIS: fetches
      [`masterRepoList.conf`](https://crosswire.org/ftpmirror/pub/sword/masterRepoList.conf)
      to locate the **primary CrossWire repo**, fetches that repo's
      `mods.d.tar.gz` → parses confs into a catalog (Description + license);
      downloads `packages/rawzip/<NAME>.zip` → existing SWORD importer.
      (Enumerating the *other* repos in the master list is deferred — see the
      Phase-1 note's "single primary repo" caveat; revisit when broader coverage
      is wanted.) **Unlocked** only — confs with a `CipherKey` are skipped
      outright. Remaining modules stay visible but are **greyed out with the
      reason** unless they are both supported (a Bible driver — `zText`/`RawText`)
      and **freely distributable** (`SwordConfig.isFreelyDistributable` accepts
      only `DistributionLicense` values that explicitly grant redistribution —
      public domain, Creative Commons, the GNU licenses, and the "Free …/
      Permission … to distribute" grants — and fails closed on a bare
      `Copyrighted`/absent license). The info dialog preserves and displays each
      module's `DistributionLicense`, full `Copyright`, and `ShortCopyright`.
      Sets a proper `User-Agent` (incl. app version) and uses HTTPS throughout.
    - **Phase 3 — more versifications** (data-heavy, mechanical): Synodal,
      German, Vulgate, LXX, NRSV(A), Catholic/Catholic2, … Same
      `SwordVersification` shape, validated against aggregate totals as KJV was.
      Needed for most non-English and Catholic modules.
    - **Phase 5 DONE — other content types** (2026-06-24).
      - **Commentaries** (`zCom`/`zCom4`/`RawCom`/`RawCom4` →
        `commentaries`/`commentary_entries`). A commentary uses the same
        verse-keyed `zVerse`/`RawVerse` backend as a Bible, so
        `SwordCommentaryImporter` reuses the existing verse readers and walks
        the versification just like the Bible importer. Verified against the
        real CrossWire **MHCC** module (28,718 entries).
      - **Dictionaries/lexicons** (`zLD`/`RawLD`/`RawLD4` →
        `dictionaries`/`dictionary_entries`) via a new key-based
        `SwordLdReader`. The on-disk format was reverse-engineered and verified:
        `.idx` (`offset` + `size`; **8-byte for zLD/RawLD4, 6-byte for RawLD**,
        auto-detected by bounds-checking) → `.dat`, whose record is
        `KEY\r\n<body>` (RawLD) or `KEY\r\n` + `blockNum(u32)` +
        `entryInBlock(u32)` (zLD). For zLD the body lives in a `.zdt` zlib block
        located via `.zdx` (`offset` + `compSize`); each decompressed block is
        `count(u32)` + `count×(offset,size)` directory + bodies. Verified against
        real CrossWire **Easton** (zLD/TEI, 3,963 entries) and **AmTract**
        (RawLD/ThML, 2,286).
      - Added a **TEI** per-source filter (`parseTeiFragment`) — most lexicons
        are TEI — and a shared `parseSwordSource` dispatcher + `segmentsToHtml`
        serialiser feeding both new importers (their panels render with
        `HtmlWidget`). The CrossWire catalog now installs Bible, commentary, and
        dictionary modules; book/chapter intro ("verse 0") commentary entries
        are not yet mapped.
      - **Verified in the macOS app**: a commentary and a dictionary downloaded
        from the CrossWire catalog install and render correctly in the
        commentary/dictionary panels (formatted HTML, no raw markup).

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
