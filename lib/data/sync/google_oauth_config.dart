/// OAuth client identifiers for Google Drive sync.
///
/// These values come from a Google Cloud project you control — see
/// `docs/google-drive-sync-setup.md` for the step-by-step setup. They are
/// **not secrets** in the usual sense: OAuth client IDs (and the "secret" of a
/// Desktop/Installed-app client) are designed to ship inside the client and
/// are protected by the user-consent flow, not by being hidden. Even so, we
/// read them from `--dart-define` at build time so forks and CI can inject
/// their own without editing source.
///
/// Provide them at build/run time, e.g.:
///
/// ```sh
/// flutter run \
///   --dart-define=GOOGLE_OAUTH_DESKTOP_CLIENT_ID=xxxx.apps.googleusercontent.com \
///   --dart-define=GOOGLE_OAUTH_DESKTOP_CLIENT_SECRET=yyyy \
///   --dart-define=GOOGLE_OAUTH_ANDROID_CLIENT_ID=zzzz.apps.googleusercontent.com \
///   --dart-define=GOOGLE_OAUTH_IOS_CLIENT_ID=wwww.apps.googleusercontent.com \
///   --dart-define=GOOGLE_OAUTH_WEB_CLIENT_ID=vvvv.apps.googleusercontent.com
/// ```
class GoogleOAuthConfig {
  GoogleOAuthConfig._();

  /// The single scope we request: a private, hidden, per-app folder in the
  /// user's Drive. It cannot see or touch any of the user's other files.
  static const String appDataScope =
      'https://www.googleapis.com/auth/drive.appdata';

  /// Desktop (Linux/Windows/macOS) "Desktop app" OAuth client. The loopback
  /// flow exchanges an auth code for tokens, so both id and secret are needed.
  static const String desktopClientId =
      String.fromEnvironment('GOOGLE_OAUTH_DESKTOP_CLIENT_ID');
  static const String desktopClientSecret =
      String.fromEnvironment('GOOGLE_OAUTH_DESKTOP_CLIENT_SECRET');

  /// Android OAuth client. Configured with the app's package name + signing
  /// SHA-1; no client id is passed to the plugin on Android (it reads the
  /// google-services config), but we keep it here for completeness/docs.
  static const String androidClientId =
      String.fromEnvironment('GOOGLE_OAUTH_ANDROID_CLIENT_ID');

  /// iOS/macOS OAuth client id (passed to google_sign_in on iOS).
  static const String iosClientId =
      String.fromEnvironment('GOOGLE_OAUTH_IOS_CLIENT_ID');

  /// Web OAuth client id, also used as the `serverClientId` on mobile when you
  /// want an ID token for a backend (not required for Drive-only sync).
  static const String webClientId =
      String.fromEnvironment('GOOGLE_OAUTH_WEB_CLIENT_ID');

  /// Whether desktop OAuth has been configured at build time.
  static bool get hasDesktopConfig =>
      desktopClientId.isNotEmpty && desktopClientSecret.isNotEmpty;
}
