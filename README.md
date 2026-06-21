# Study Bible (Flutter)

A clean-slate reimplementation of the Clojure/JavaFX Study Bible as a single Flutter codebase targeting **Android, iOS, Windows, macOS, and Linux**, with **first-class cross-device sync** as a new capability.

## Features

- **Multi-version Bible reader** — parallel panels, verse selection, version swap, verse-by-verse and flowing paragraph view, highlight bands.
- **Integrated commentaries & dictionaries** — verse-ref lookup, parallel view, multi-dictionary search, tap-a-word lookup.
- **Study tools** — journals, prayer tracker, sermon builder, plan generator, custom notes, and bookmarks.
- **Progress dashboard** — reading coverage + per-book drill-down, reading pace, achievements/badges, time tracker & analytics.
- **Content manager** — install bibles/commentaries/dictionaries from ph4.org; OSIS + MyBible import.
- **Rich media** — local audio/video, YouTube overlay, image lightbox.
- **Cross-device sync** — highlights, notes, bookmarks, journals, prayers, reading progress, and settings synced across devices (using zero-cost file-based sync like Syncthing or cloud folders).

## Architecture

This project strictly follows a **clean layered architecture**:
- **Presentation:** Flutter widgets + Riverpod (thin, no business logic)
- **Application:** Use-cases / controllers
- **Domain:** Pure Dart models, services, sync merge logic (NO Flutter/IO imports)
- **Data:** Repositories, interfaces, Drift SQLite DBs, SyncEngine, HTTP

### Tech Stack
- **Framework:** Flutter + Dart
- **State Management:** Riverpod
- **Routing:** go_router
- **Local Database:** Drift (SQLite)
- **Sync:** File sync behind a `SyncEngine` interface (LWW merge)
- **Networking:** dio
- **Media:** just_audio, video_player, youtube_player_iframe

## Documentation

- [Design & Roadmap](DESIGN.md) - The source of truth for what we're building and why.
- [Contributing](CONTRIBUTING.md) - Guidelines for contributing to the project.

## Acknowledgments

This project is made possible thanks to several upstream resources and formats:
- **[ph4.org](https://ph4.org/)**: For providing the extensive catalog of Bible modules, commentaries, and dictionaries.
- **[MyBible](https://mybible.zone/)**: For their excellent SQLite-based module format which this app imports and utilizes.
- **OSIS (Open Scriptural Information Standard)**: For the standard XML schema used in representing scriptural texts.
- **Clojure/JavaFX Study Bible**: The original desktop application that inspired and provided the feature foundation for this Flutter reimplementation.

## Getting Started

1. Install [Flutter](https://docs.flutter.dev/get-started/install).
2. Clone the repository and fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run code generation for Drift and Riverpod:
   ```bash
   dart run build_runner build -d
   ```
4. Run the app:
   ```bash
   flutter run
   ```
