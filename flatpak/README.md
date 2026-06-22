# Flatpak packaging

Files to build Study Bible as a [Flatpak](https://flatpak.org/) and, eventually,
publish it on [Flathub](https://flathub.org/).

| File | Purpose |
|---|---|
| `io.github.crazymevt.StudyBible.yml` | Flatpak manifest (packages a prebuilt Flutter Linux bundle) |
| `io.github.crazymevt.StudyBible.desktop` | Desktop entry (menu launcher) |
| `io.github.crazymevt.StudyBible.metainfo.xml` | AppStream metadata (name, screenshots, releases) |
| `io.github.crazymevt.StudyBible.png` | 512×512 app icon |
| `build-local.sh` | One-shot local build + install for testing |

The app ID is **`io.github.crazymevt.StudyBible`**, matching the GitHub repo
(`github.com/crazymevt/StudyBible`). It must stay consistent across the manifest,
the `.desktop`/`.metainfo`/icon filenames, and `APPLICATION_ID` in
`linux/CMakeLists.txt`.

## Build & test locally

```bash
# one-time: install runtime + builder
flatpak install -y flathub org.gnome.Platform//47 org.gnome.Sdk//47
sudo apt install -y flatpak-builder   # or your distro's equivalent

# build + install --user, then run
flatpak/build-local.sh --run
```

The manifest packages a **prebuilt** bundle (it copies
`build/linux/x64/release/bundle`), so `build-local.sh` runs
`flutter build linux --release` first. This mirrors how Flathub works: their
buildbot cannot run `flutter build`, so the binary is built ahead of time and
the Flatpak just wraps it.

### What to verify in the sandboxed app

- It launches and the window is titled "Study Bible" with the correct icon.
- **Sync folder picker** works through the portal and the chosen folder stays
  readable after a restart (the manifest grants no static `--filesystem`; access
  is portal-mediated). If background sync loses access, add a narrow
  `--filesystem=` grant in `finish-args`.
- Audio/video playback works (`--socket=pulseaudio`).
- Content manager can download from ph4.org (`--share=network`).

## TODO: Flathub submission (not started — deferred)

Phase A (a working, self-distributed Flatpak) is **done**. Publishing on Flathub
is deferred until we're ready. When we are, the remaining steps:

Already in place:
- [x] **License** — Apache-2.0 (`LICENSE` + `NOTICE`, `project_license` in metainfo).
- [x] **Flathub manifest** — `io.github.crazymevt.StudyBible.flathub.yml` (archive
      source), separate from the CI/local `dir` manifest so the release build is
      unaffected.
- [x] **Metadata validation** — `appstreamcli` + `desktop-file-validate` run in
      the `flatpak-test` workflow (and locally, below).

Remaining, in order:
1. [ ] **Cut a release** that includes the file_selector + persistence fixes, so
       a current `StudyBible-Linux.tar.gz` exists (run `./scripts/release.sh`,
       push the tag — `release.yml` publishes the asset).
2. [ ] **Pin the tarball** — one command (downloads the asset, computes the
       checksum, fills in `url` + `sha256`):
       ```bash
       flatpak/pin-flathub.sh <tag>
       ```
3. [ ] **Final local validation:**
       ```bash
       appstreamcli validate io.github.crazymevt.StudyBible.metainfo.xml
       desktop-file-validate io.github.crazymevt.StudyBible.desktop
       flatpak-builder --force-clean build-dir io.github.crazymevt.StudyBible.flathub.yml  # builds from the pinned tarball
       ```
4. [ ] **Fork & PR** the manifest to
       [`flathub/flathub`](https://github.com/flathub/flathub) (new-submissions
       process). Reviewers check the app id, license, permissions, and metadata.
5. [x] **After acceptance** — per-release bumps are automated: the manifest's
       `x-checker-data` lets Flathub's `flatpak-external-data-checker` auto-PR a
       new `url` + `sha256` whenever a GitHub release publishes the asset. (You
       just merge the bot's PR.)

Reference: <https://docs.flathub.org/docs/for-app-authors/submission>.
