# Study Bible (Flutter)

A clean-slate reimplementation of the Clojure/JavaFX Study Bible as a single Flutter codebase targeting **Android, iOS, Windows, macOS, and Linux**, with **first-class cross-device sync** as a new capability.

## Download

### ⬇ [Download the latest release](https://github.com/crazymevt/StudyBible/releases/latest)

Always points to the newest version — Android (APK), Windows, macOS, and Linux builds. (Use this link rather than browsing the releases list, which may not show the newest build first.)

**Linux** ships in two forms: a portable bundle (`StudyBible-Linux.tar.gz`) and a Flatpak (`StudyBible-Linux.flatpak`):

```bash
flatpak install --user StudyBible-Linux.flatpak
flatpak run io.github.crazymevt.StudyBible
```

Flathub distribution is planned (see [flatpak/README.md](flatpak/README.md)).

> iOS is supported in the codebase but isn't distributed as a signed build yet — build it from source (see [Getting Started](#getting-started)).

## Screenshots

_Click any image to view it full size._

|                                                          |                                                  |
| :------------------------------------------------------: | :----------------------------------------------: |
| [![Reader](docs/screenshots/thumbs/reader.png)](docs/screenshots/reader.png)<br>**Multi-version reader** | [![Search](docs/screenshots/thumbs/search.png)](docs/screenshots/search.png)<br>**Search** |
| [![Dashboard](docs/screenshots/thumbs/dashboard.png)](docs/screenshots/dashboard.png)<br>**Progress dashboard** | [![Content manager](docs/screenshots/thumbs/content-manager.png)](docs/screenshots/content-manager.png)<br>**Content manager** |

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
- **[BibleProject](https://bibleproject.com/)**: Incredible animated videos and resources for exploring the Bible.
- **[Lumo Project](https://lumoproject.com/)**: Visual translations of the four Gospels.
- **[Jesus Film Project](https://www.jesusfilm.org/)**: Sharing the story of Jesus through film.
- **[OpenBible.info](https://www.openbible.info/)**: Crowdsourced cross-reference dataset (licensed under CC-BY).
- **[Nave's Topical Bible](https://github.com/BradyStephenson/bible-data)**: Public-domain topical index, via the BradyStephenson/bible-data dataset (licensed under CC-BY 4.0).
- **[Berean Study Bible](https://berean.bible/)**: Public domain Bible text and audio resources.
- **Clojure/JavaFX Study Bible**: The original desktop application that inspired and provided the feature foundation for this Flutter reimplementation.

*Note: Individual Bible modules, commentaries, and dictionaries downloaded or imported into this application are subject to their respective copyright holders and licenses. Please review the specific copyright information provided within each module.*

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



## License

StudyBible is licensed under the [Apache License 2.0](LICENSE). See [NOTICE](NOTICE) for attribution.

Individual Bible modules, commentaries, and dictionaries downloaded or imported into the app remain subject to their own respective copyrights and licenses.

## ❤️ Support

This is a free app, built as a labor of love. If it's been a blessing to your study and you'd like to support its continued development, you can leave a gift on Ko-fi:

**[☕ Support on Ko-fi → ko-fi.com/jessiehughart](https://ko-fi.com/jessiehughart)**

Every gift is appreciated and helps keep the project going. Thank you!

---
