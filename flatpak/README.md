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

## Before submitting to Flathub

1. **License.** ✅ Apache-2.0 (`LICENSE` + `NOTICE` in the repo root, and
   `project_license` set in the metainfo).
2. **Switch the source to a release tarball.** Replace the `type: dir` source in
   the `studybible` module with the published `StudyBible-Linux.tar.gz` from a
   GitHub release, pinned by `sha256` (see the comment in the manifest). A
   release job already produces this artifact (`.github/workflows/release.yml`).
3. **Validate metadata:**
   ```bash
   flatpak run org.freedesktop.appstream.cli validate io.github.crazymevt.StudyBible.metainfo.xml
   desktop-file-validate io.github.crazymevt.StudyBible.desktop
   ```
4. **Submit** a PR adding the manifest to
   [`flathub/flathub`](https://github.com/flathub/flathub). After acceptance you
   maintain a `flathub/io.github.crazymevt.StudyBible` repo; each release =
   bump the tarball URL + `sha256` there.
