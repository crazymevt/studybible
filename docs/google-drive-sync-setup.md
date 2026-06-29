# Google Drive sync — setup

StudyBible can sync your data (notes, highlights, bookmarks, sermons, prayers,
reading progress, plans, tags, …) through a **hidden, app-private folder in your
Google Drive** (`appDataFolder`). The folder is invisible in the Drive UI and
the app is granted only the `drive.appdata` scope, so it can never see or touch
any of your other Drive files.

Under the hood this is just another `SyncStorage` backend
(`lib/data/sync/google_drive_sync_storage.dart`): each device writes a
`state-<deviceId>.jsonl` file into the app folder, and the existing
last-writer-wins merge in `lib/app/sync_service.dart` reconciles them — the same
model used by the local-folder and Android SAF backends.

Because Google OAuth requires credentials tied to a specific developer project,
**you must create your own OAuth client IDs** and provide them to the build.
This is a one-time setup.

---

## 1. Create a Google Cloud project

1. Go to <https://console.cloud.google.com/> and create a project (e.g.
   "StudyBible").
2. **APIs & Services → Library →** enable the **Google Drive API**.
3. **APIs & Services → OAuth consent screen:**
   - User type: **External** (unless you only ever use a Workspace account).
   - Fill in app name, support email, developer email.
   - **Scopes:** add `.../auth/drive.appdata` (the app-data scope). Nothing else
     is needed.
   - Add yourself (and any testers) under **Test users** while the app is in
     "Testing". Test-mode refresh tokens expire after 7 days, so publish the
     consent screen once you're satisfied.

## 2. Create OAuth client IDs

Create one client per platform you ship (**APIs & Services → Credentials →
Create credentials → OAuth client ID**):

| Platform            | Client type   | Notes |
|---------------------|---------------|-------|
| Linux/Windows/macOS | **Desktop app** | Used by the loopback browser flow. Has an id **and** a secret. |
| Android             | **Android**   | Package name `io.github.crazymevt.studybible` + your signing SHA-1. |
| iOS / macOS (mobile)| **iOS**       | Bundle id `io.github.crazymevt.studybible`. |
| Web                 | **Web application** | Add your origin(s) to *Authorized JavaScript origins*. |

> The "secret" of a Desktop client is **not** a true secret — it's expected to
> ship inside the installed app and is protected by the user-consent flow, not by
> being hidden. See Google's "Installed applications" OAuth docs.

## 3. Give the IDs to the build

The app reads the IDs from `--dart-define` (see
`lib/data/sync/google_oauth_config.dart`). Nothing is committed to source.

```sh
flutter run \
  --dart-define=GOOGLE_OAUTH_DESKTOP_CLIENT_ID=xxxx.apps.googleusercontent.com \
  --dart-define=GOOGLE_OAUTH_DESKTOP_CLIENT_SECRET=yyyy \
  --dart-define=GOOGLE_OAUTH_IOS_CLIENT_ID=wwww.apps.googleusercontent.com \
  --dart-define=GOOGLE_OAUTH_WEB_CLIENT_ID=vvvv.apps.googleusercontent.com
```

For reproducible builds, put these in a `--dart-define-from-file=oauth.json`
(JSON of `KEY: value`) and keep that file out of git.

### Platform extras

- **Android:** no client id is passed in code — the Android OAuth client is
  matched by package name + SHA-1. Just make sure those match your keystore(s)
  (debug and release have different SHA-1s).
- **iOS:** add the **reversed** iOS client id as a URL scheme in
  `ios/Runner/Info.plist` (`CFBundleURLTypes`), per the `google_sign_in`
  README.
- **macOS (mobile-style sign-in):** this build uses the **Desktop loopback**
  flow on macOS, not `google_sign_in`, so no URL scheme is required. The
  loopback listener needs the `com.apple.security.network.server` entitlement —
  already added to both `macos/Runner/DebugProfile.entitlements` and
  `Release.entitlements`.
- **Web:** `google_sign_in_web` 7.x uses the GIS flow; interactive
  `authenticate()` is limited on web and may require the rendered sign-in
  button. Desktop and mobile are the primary targets.

## 4. Use it

**Settings → Sync → Google Drive → Connect Google Drive.** On desktop a browser
window opens for consent; on mobile the native account picker appears. Once
connected, the regular Sync action (and the connect step itself) reads/writes the
Drive app folder. **Disconnect** revokes the grant and forgets the stored
credentials on that device.

If the build has no credentials, Connect surfaces a clear "not configured"
message and sync falls back to the local folder.
