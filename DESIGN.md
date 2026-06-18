# Study Bible (Flutter) — Design & Roadmap

A clean-slate reimplementation of the Clojure/JavaFX Study Bible as a single
Flutter codebase targeting **Android, iOS, Windows, macOS, and Linux**, with
**first-class cross-device sync** as a new capability.

This doc is the source of truth for *what we're building and why*. Keep entries
terse; record non-obvious decisions (with dates) under "Decisions / open
questions".

---

## 1. Vision & goals

| Goal | What it means |
|---|---|
| **One codebase, five platforms** | Android + iOS + Windows + macOS + Linux from a single Flutter/Dart project. iOS is a build target and simulator-tested; real-device/App-Store distribution ($99/yr) deferred until there's a device. |
| **Cross-device sync** | Highlights, notes, bookmarks, journals, prayers, sermons, reading progress, settings — everything I do on one device shows up on the others. New capability, never shipped before. |
| **Offline-first** | The app is fully usable with no network. Sync reconciles when connectivity returns. |
| **Clean layered architecture** | Pure domain logic, isolated from UI and platform IO, from day one — the discipline the JavaFX version only reached for late (see §2). |
| **Feature parity, then beyond** | Match the JavaFX app's feature set (§3), then add sync, multi-device dashboards, and mobile-native touches. |

Non-goals (for now): multi-*user* collaboration (this is single-user, many
devices), a web build, real-time co-editing.

---

## 2. Lessons learned from the JavaFX/Clojure app

The existing app (~12,500 lines) works and is feature-rich, but the migration
analysis in the old `docs/mobile-port.md` surfaced clear lessons. We bake the
fixes in from the start instead of refactoring toward them.

1. **The UI monolith is the enemy.** `core.clj` was 8,694 lines with business
   logic buried inside event handlers. → *Domain logic lives in plain Dart
   classes with zero Flutter imports. Widgets are thin.*
2. **Platform IO must sit behind interfaces from line one.** The old code spread
   `slurp`/`spit`/JDBC/jsoup everywhere, making it un-portable. → *All IO
   (storage, content DB, HTTP, HTML sanitize) goes through abstract interfaces;
   concrete impls are swappable and testable.*
3. **State as one monolithic blob loses data.** `app-state.edn` was written as a
   single `pr-str` blob, so the last device to save clobbered the others. →
   *Every user object is an addressable record with sync metadata
   (`id`, `updatedAt`, `deleted`). No monolithic save. (§6)*
4. **Never hard-delete in a synced world.** → *Deletions are tombstones so they
   propagate.*
5. **Content and user data are different beasts.** Bibles/commentaries are large,
   read-mostly, queryable; user data is small, mutable, synced. → *Two separate
   stores with different lifecycles (§5).*
6. **Theming via raw stylesheets was powerful but ad hoc.** 16 CSS themes. →
   *A typed `ThemeSpec` model + Flutter `ThemeData`, themes as data.*
7. **Verify UI visually.** A standing lesson from the JavaFX app: layout/render
   claims get screenshotted, not trusted from code. Carries over.

---

## 3. Feature inventory (parity target)

From the JavaFX app's README/feature list. ✅ = parity target, ➕ = new in Flutter.

- **Multi-version Bible reader** — parallel panels, verse selection, version
  swap, verse-by-verse *and* flowing paragraph view, highlight bands. ✅
- **Integrated commentaries** — verse-ref lookup, parallel view. ✅
- **Multi-dictionary search** — case-insensitive across all installed dicts;
  tap-a-word lookup. ✅
- **Progress dashboard** — reading coverage + per-book drill-down, reading pace
  (streaks, projection), achievements/badges, time tracker & analytics. ✅
- **Journals & prayer tracker** — active/archived, tags, edits. ✅
- **Sermon builder & generator** — modular points, HTML/Text/ZIP export. ✅
- **Plan generator** — custom reading schedules, active devotionals. ✅
- **Rich media** — local audio/video, YouTube overlay, image lightbox. ✅
- **Dynamic themes** — port the 16 themes as `ThemeSpec` data. ✅
- **Content manager** — install bibles/commentaries/dictionaries/devotionals
  from ph4.org; OSIS + MyBible import; content bundle download. ✅ (see §7)
- **Auto-update check** — desktop only; mobile uses store updates. ✅ (adapted)
- **Cross-device sync** — ➕ the headline new feature (§6).
- **Multi-device dashboard touches** — e.g. "continue where you left off on
  another device". ➕ (stretch)

---

## 4. Tech stack & key decisions

> These are *recommended defaults*. The three biggest forks (sync model, iOS
> scope, content format) are recorded as decisions in §10 with a default chosen
> so work can start; revisit any of them there.

| Concern | Choice | Why |
|---|---|---|
| Framework / language | **Flutter + Dart** | One UI codebase across all four targets; mature desktop support. |
| State management | **Riverpod** | Compile-safe, testable, no `BuildContext` coupling; fits the "thin widgets, pure logic" rule. |
| Navigation | **go_router** | Declarative, deep-link friendly, works across desktop/mobile. |
| Local database | **Drift (SQLite)** | Typed queries, migrations, FTS5 for search, runs on all four targets. Used for *both* content and user data (separate DBs). |
| Content format | **SQLite, produced by an in-app importer** | Fast queries, low memory, mobile-friendly. No migration of the old EDN; the importer (MyBible/OSIS/ph4.org → SQLite) is the content-creation path. |
| Sync | **File sync behind a `SyncEngine` interface** (default: per-device files + LWW) | Zero hosting cost; transport via the user's own Syncthing/cloud folder. Interface keeps an optional BYO-backend impl possible for real-time push. |
| HTTP | **dio** | Interceptors, retries, download progress (content manager). |
| Audio | **just_audio** + **audio_service** | Background playback, playlists. |
| Video | **video_player** + **youtube_player_iframe** | Local media + YouTube overlay. |
| HTML rendering | **flutter_widget_from_html** (or `flutter_html`) | Commentary/dictionary entries carry HTML; render + sanitize. |
| Packaging | per-OS Flutter desktop builds + Android APK/AAB | Replaces jpackage scripts. |

### Layered architecture

```
┌─────────────────────────────────────────────┐
│ Presentation   Flutter widgets + Riverpod    │  thin; no business logic
├─────────────────────────────────────────────┤
│ Application    use-cases / controllers        │  orchestrates domain + repos
├─────────────────────────────────────────────┤
│ Domain         pure Dart: models, services    │  scripture parsing, search,
│                (NO flutter/IO imports)         │  plan/sermon gen, merge/LWW
├─────────────────────────────────────────────┤
│ Data           repositories + interfaces       │  ContentDb, UserStore,
│                Drift impls, SyncEngine, Http    │  Http, HtmlSanitize
└─────────────────────────────────────────────┘
```

The **domain layer has no Flutter or IO imports** — the single most important
rule, and the one the JavaFX app violated. It is unit-testable in plain Dart.

Proposed package layout:
```
lib/
  domain/        models, scripture refs, search, plan/sermon gen, sync merge
  data/          interfaces + Drift/HTTP/sync implementations
  app/           use-cases, Riverpod providers/controllers
  ui/            screens, widgets, themes
  main.dart
tool/            content converter (EDN/OSIS/MyBible -> SQLite)
test/            domain tests (pure), data tests, widget tests
```

---

## 5. Data model — two stores

### A. Content store (read-mostly, shipped/downloaded, **not** synced)

Bibles, commentaries, dictionaries, cross-references, plans. Large, queryable,
identical across devices. SQLite, one DB (or one per resource type).

Verse model preserves the existing rich structure (text segments + Strong's
numbers + attrs), e.g. from `kjv.edn`:
```
verse(version, book, chapter, verse) -> segments[ {text, strong?, attrs[]} ]
```
Tables (sketch): `versions`, `books`, `verses` (+ FTS5 mirror for search),
`commentaries`, `commentary_entries`, `dictionaries`, `dictionary_entries`,
`cross_references`, `plans`.

### B. User store (small, mutable, **synced**)

Highlights, notes, bookmarks, reading progress, journals, prayers, sermons,
settings, time-tracker entries, achievements. Every record carries sync
metadata (§6). Separate SQLite DB so it can be backed up/synced independently of
the multi-gigabyte content.

---

## 6. Cross-device sync (the headline feature)

**Scope:** single user, multiple devices. This makes **last-write-wins (LWW) per
record** sufficient — no CRDTs, no real-time co-editing.

**Record shape** (every synced user object):
```dart
{ id: Uuid, updatedAt: int /*epoch ms*/, deviceId: String,
  deleted: bool /*tombstone*/, ...payload }
```

**Merge rule** (pure function, fully unit-tested, in `domain/sync`):
> For a given `id`, keep the record with the newest `updatedAt`; a tombstone
> wins ties toward deletion. Deterministic and identical on every device.

Clock caveat: LWW trusts `updatedAt`. Fine for one user. If clock skew bites,
add a per-device **Lamport counter** alongside wall-clock and tie-break on it.

**`SyncEngine` interface** decouples the merge policy from the transport, so the
default file impl and an optional backend impl are drop-in swappable:
```dart
abstract class SyncEngine {
  Future<void> push(List<SyncRecord> localChanges);
  Future<List<SyncRecord>> pull(int sinceCursor);
  Stream<List<SyncRecord>> changes(); // realtime, if the transport supports it
}
```

### Default transport — per-device files + LWW (zero hosting cost)

Chosen because this is a no-funds open-source project: a maintainer-hosted
backend scales its cost with user count, not income, and makes the maintainer
responsible for everyone's personal data. The file model avoids both.

- Each device owns **its own** file: `state-<deviceId>.db` (or `.json`). Devices
  **never write the same file**, so even a dumb file-syncer cannot create a
  write-conflict.
- On load, read all `state-*.db`, run the pure **LWW merge** above, and project
  the result into the local read model. The merge doesn't care how the files
  arrived.
- **Transport = storage the user already has — $0 to maintainer and user:**
  - Desktop (Win/Mac/Linux): a folder inside Dropbox / Google Drive / iCloud /
    OneDrive that the OS already syncs.
  - Cross-platform incl. Android: **Syncthing** (open-source, free,
    peer-to-peer, no cloud account) — the folder simply appears on every device.
- Bonus: the user's journals/prayers never touch our servers — a privacy win.
- Tradeoff: no instant push — changes land when the folder syncs (seconds to
  minutes), and Android needs one-time Syncthing setup. Acceptable for a
  personal study app.
- **iOS exception:** Syncthing/arbitrary-folder sync doesn't work under the iOS
  sandbox. On iOS the file transport would have to ride **iCloud Drive**
  (Apple-only, won't bridge cleanly to Windows/Linux/Android), so iOS sync in
  practice uses the **BYO-backend path** below. Desktop+Android keep the file
  default.

### Optional transport — bring-your-own backend (still $0 to maintainer)

For users who want real-time push, let them paste **their own** free-tier
Supabase URL + key in settings. A single user's tiny text data stays well within
the free tier, and **each user pays their own $0** — never the maintainer. Same
`SyncEngine` interface; adds an **outbox queue** in the local DB (offline-first)
plus a realtime subscription. We never host a central instance.

**Escalation path (not built now):** op-log for cross-device undo/history;
CRDTs only if genuine concurrent multi-user editing ever appears.

---

## 7. Content pipeline

We are **not migrating the old `data/*.edn` files** — no EDN→SQLite converter.
Instead we reimplement the JavaFX app's *importer* so the app can create its own
content in the new format, from the same upstream sources (ph4.org catalog,
MyBible SQLite modules, public-domain OSIS XML). The importer's **output is the
Content SQLite schema (§5A)** directly.

- **Importer rewritten in Dart, runs in-app** — so import works on every
  platform (incl. mobile), not just desktop. The old importer was a desktop-only
  Clojure tool using SQLite JDBC + zip + jsoup; the Dart equivalents are
  `sqlite3` (read MyBible modules), `archive` (reading-plan zips), and an HTML
  parser + allowlist sanitizer (replacing jsoup's HTML cleanup). The verse model
  it emits keeps the rich structure — text segments + Strong's numbers + attrs
  (§5A).
- **Source-format handlers:**
  - *MyBible* (already SQLite) → transform tables/XML-tagged verses into our
    schema (SQLite → SQLite).
  - *OSIS* (XML) → parse and map to our schema.
  - *Reading-plan zips* → extract plan + thumbnail assets.
- **In-app Content Manager** — browse the ph4.org catalog, download a module, run
  it through the importer, and write into the Content DB at runtime.
- **Bundled starter content** — ship one small bible (e.g. KJV/BSB), already in
  SQLite, so the app is useful before any download.

---

## 8. Roadmap (phased, each phase independently shippable-ish)

Status legend: ☐ todo · ◐ in progress · ☑ done

### Phase 0 — Project setup
- ☑ 0.1 `flutter create` all five targets (incl. iOS); confirm each builds & runs an empty app (iOS on the simulator).
- ☑ 0.2 Add deps (Riverpod, go_router, Drift, dio, just_audio, etc.); CI lint/test.
- ☑ 0.3 Establish package layout (§4) and the "domain has no Flutter/IO imports" lint rule.

### Phase 1 — Content store + reader (the core value)
- ☑ 1.1 Define Content DB schema (§5A) + Drift tables.
- ☑ 1.2 Build the Dart importer → emits Content SQLite; produce a small bundled starter bible. (Full MyBible/OSIS/ph4.org importer lands in Phase 5.3.)
- ☑ 1.3 Domain: scripture reference model + parsing/normalization (port `scripture`).
- ☑ 1.4 Single-version reader screen (verse-by-verse view) reading from Content DB.
- ☑ 1.5 Flowing paragraph view + verse selection + highlight bands.
- ☑ 1.6 Multi-version parallel panels + version swap.

### Phase 2 — User store + sync foundation
- ☑ 2.1 Define User DB schema with sync metadata on every record (§6).
- ☑ 2.2 Domain: pure LWW `merge` + tombstones; exhaustive unit tests.
- ☑ 2.3 Local-only highlights, notes, bookmarks against the User store.
- ☑ 2.4 `SyncEngine` interface; per-device file impl (`state-<deviceId>.db`).
- ☑ 2.5 Point the file transport at a user-chosen synced folder (Syncthing / cloud folder); load = read all `state-*.db` + LWW merge.
- ☐ 2.6 End-to-end: two devices share a folder, edits + tombstones converge regardless of sync order.
- ☐ 2.7 *(optional/later)* BYO-backend impl: user-supplied Supabase URL+key, outbox queue, realtime.

### Phase 3 — Study features
- ☐ 3.1 Commentaries (verse-ref lookup + parallel view) + HTML render/sanitize.
- ☐ 3.2 Multi-dictionary search + tap-a-word lookup.
- ☐ 3.3 In-bible + global search (FTS5; port `search` semantics).
- ☐ 3.4 Cross-references.
- ☐ 3.5 Tags across notes/prayers/journals/sermons (port `tags`, pass state in).

### Phase 4 — Personal study / tracking
- ☐ 4.1 Journals + prayer tracker (synced records).
- ☐ 4.2 Reading progress capture + coverage drill-down.
- ☐ 4.3 Reading pace (streaks, projection) + achievements engine.
- ☐ 4.4 Time tracker + analytics graphs.
- ☐ 4.5 Sermon builder + generator + HTML/Text/ZIP export (port `sermon-generator`).
- ☐ 4.6 Plan generator + active devotionals (port `plan-generator`).

### Phase 5 — Media, theming, content manager
- ☐ 5.1 Theme engine: port 16 themes as `ThemeSpec` data → `ThemeData`.
- ☐ 5.2 Local audio/video players; YouTube overlay; image lightbox.
- ☐ 5.3 In-app Content Manager (ph4.org catalog, download, import).
- ☐ 5.4 Backup/restore (zip of user data) — adapt `backup`.

### Phase 6 — Release
- ☐ 6.1 Per-OS desktop packaging + Android AAB; icons/metadata. iOS: simulator builds now; real-device/App-Store deferred (needs $99/yr Apple Developer + a device).
- ☐ 6.2 Desktop auto-update check; store-based updates on Android (and iOS if/when shipped).
- ☐ 6.3 Onboarding (sign-in / device pairing for sync).

---

## 9. Testing & verification strategy

- **Domain layer** — pure Dart unit tests, high coverage; especially the LWW
  `merge` (the data-integrity keystone) and scripture-reference parsing.
- **Data layer** — Drift in-memory DB tests; `SyncEngine` against a local fake.
- **Sync** — a multi-device simulation test: interleave edits + tombstones,
  assert convergence regardless of order.
- **UI** — widget tests for key screens; **visual verification** (run + screenshot)
  for any layout/alignment/render claim, per the standing lesson.

---

## 10. Decisions / open questions

Defaults chosen so work can start; revisit explicitly.

- **Sync model** — *Default: per-device files + LWW behind a `SyncEngine`
  interface*, transport via the user's own Syncthing/cloud folder. **Chosen for
  zero hosting cost** — this is a no-funds open-source project, and a
  maintainer-hosted backend scales cost with users and creates a data-privacy
  liability. BYO-backend (user supplies their own free Supabase) is an optional
  impl behind the same interface; we never host a central instance. Alternatives
  rejected: maintainer-hosted Supabase/Firebase (cost + liability), self-hosted
  CouchDB/PouchDB (heavier to operate). (2026-06-18)
- **iOS scope** — *In scope as a build target, simulator-tested.* The Flutter
  UI code is free across iOS; what isn't free: (a) **real-device/App-Store
  distribution needs the $99/yr Apple Developer Program** — deferred until
  there's a device + reason; (b) the zero-cost file-sync default doesn't work in
  the iOS sandbox, so **iOS sync uses the BYO-backend path** (see §6). Build it,
  simulator-test it, ship it later. (2026-06-18)
- **Content format** — *SQLite, read via Drift.* Not migrating the old
  `data/*.edn`; an in-app **Dart importer** (MyBible/OSIS/ph4.org → SQLite) is
  the content-creation path (§7). (2026-06-18)
- **State management** — Riverpod (vs Bloc/Provider). (2026-06-18)
- **Auth for sync** — the default file transport needs **no auth** (the synced
  folder *is* the boundary); each device just needs a stable `deviceId`. Auth
  only applies to the optional BYO-backend path (user's own Supabase
  credentials). TBD in Phase 2.7.
- **jsoup replacement** — Dart HTML parser + allowlist sanitizer for
  commentary/dictionary HTML. Pick exact package in Phase 3.1.
- **Importer language** — *Resolved: rewrite in Dart, run in-app* so import works
  on mobile too (not the desktop-only Clojure tool). (2026-06-18)

---

## 11. How to use this doc

Update status boxes (☐/◐/☑) as work lands. Keep entries one line. Record any
non-obvious decision under §10 with a date. The companion to this doc is the
JavaFX app's `docs/mobile-port.md`, which holds the original
namespace-by-namespace migration analysis worth consulting when porting a
specific module.
