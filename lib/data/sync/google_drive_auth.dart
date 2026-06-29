import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../app_paths.dart';
import '../logging.dart';
import 'google_oauth_config.dart';

/// Thrown when Drive sync is requested but the build wasn't given the OAuth
/// client credentials it needs. The message is surfaced to the user.
class GoogleDriveNotConfiguredException implements Exception {
  final String message;
  GoogleDriveNotConfiguredException(this.message);
  @override
  String toString() => message;
}

/// Abstraction over "get me an authenticated HTTP client for Google Drive".
///
/// Two implementations back this, picked by platform:
///   * [_DesktopGoogleDriveAuth] — Linux/Windows/macOS, using the
///     `googleapis_auth` loopback (browser) flow. We persist the refresh
///     credentials ourselves.
///   * [_MobileGoogleDriveAuth] — Android/iOS (and best-effort web), using the
///     `google_sign_in` plugin, which owns its own token storage.
///
/// Both return a `googleapis_auth` [auth.AuthClient] (an [http.Client]) that the
/// Drive API can be constructed from, and both expose the signed-in account's
/// email for display.
abstract class GoogleDriveAuth {
  /// The single OAuth scope all clients request.
  static const scopes = [GoogleOAuthConfig.appDataScope];

  /// Picks the right implementation for the current platform.
  factory GoogleDriveAuth() {
    if (Platform.isAndroid || Platform.isIOS) {
      return _MobileGoogleDriveAuth();
    }
    return _DesktopGoogleDriveAuth();
  }

  /// Runs the interactive consent flow. Returns the authenticated client and
  /// the account email (when known), or `null` if the user cancelled. Throws
  /// [GoogleDriveNotConfiguredException] if the build is missing credentials.
  Future<({auth.AuthClient client, String? email})?> signIn();

  /// Silently restores a client from previously stored credentials, or returns
  /// `null` if the user has never connected (or revoked) Drive on this device.
  Future<auth.AuthClient?> restore();

  /// Forgets stored credentials and revokes the grant where possible.
  Future<void> signOut();
}

/// Desktop loopback OAuth. `clientViaUserConsent` spins up a temporary local
/// HTTP server, opens the consent page in the user's browser, and captures the
/// redirect. We persist [auth.AccessCredentials] (which include the refresh
/// token) to an app-private file so subsequent launches reconnect silently.
class _DesktopGoogleDriveAuth implements GoogleDriveAuth {
  static const _credsFileName = 'gdrive_credentials.json';

  Future<File> _credsFile() async {
    final dir = await appDataDir();
    return File(p.join(dir.path, _credsFileName));
  }

  auth.ClientId _clientId() {
    if (!GoogleOAuthConfig.hasDesktopConfig) {
      throw GoogleDriveNotConfiguredException(
        'Google Drive sync is not configured in this build. The desktop OAuth '
        'client id/secret were not provided at build time. See '
        'docs/google-drive-sync-setup.md.',
      );
    }
    return auth.ClientId(
      GoogleOAuthConfig.desktopClientId,
      GoogleOAuthConfig.desktopClientSecret,
    );
  }

  @override
  Future<({auth.AuthClient client, String? email})?> signIn() async {
    final clientId = _clientId();
    try {
      final client = await auth.clientViaUserConsent(
        clientId,
        GoogleDriveAuth.scopes,
        (url) async {
          final uri = Uri.parse(url);
          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            logError(
              'Could not open consent URL',
              StackTrace.current,
              context: 'GoogleDriveAuth.desktop.launchUrl',
            );
          }
        },
      );
      await _persist(client.credentials);
      // The drive.appdata scope doesn't grant access to the user's profile, so
      // we have no email to display on desktop; the UI falls back to a generic
      // "Connected" label.
      return (client: client, email: null);
    } catch (e, stack) {
      logError(e, stack, context: 'GoogleDriveAuth.desktop.signIn');
      rethrow;
    }
  }

  @override
  Future<auth.AuthClient?> restore() async {
    if (!GoogleOAuthConfig.hasDesktopConfig) return null;
    final file = await _credsFile();
    if (!await file.exists()) return null;
    try {
      final json = jsonDecode(await file.readAsString());
      final creds = auth.AccessCredentials.fromJson(
        Map<String, dynamic>.from(json as Map),
      );
      if (creds.refreshToken == null) return null;
      // autoRefreshingClient transparently refreshes the access token from the
      // stored refresh token; we re-persist on the next signIn/sync.
      return auth.autoRefreshingClient(_clientId(), creds, http.Client());
    } catch (e, stack) {
      logError(e, stack, context: 'GoogleDriveAuth.desktop.restore');
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    final file = await _credsFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> _persist(auth.AccessCredentials creds) async {
    final file = await _credsFile();
    await file.writeAsString(jsonEncode(creds.toJson()));
  }
}

/// Mobile (Android/iOS) OAuth via the `google_sign_in` plugin. The plugin owns
/// token storage, so we don't persist anything ourselves — [restore] just asks
/// the plugin to reauthenticate lightly.
class _MobileGoogleDriveAuth implements GoogleDriveAuth {
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: Platform.isIOS && GoogleOAuthConfig.iosClientId.isNotEmpty
          ? GoogleOAuthConfig.iosClientId
          : null,
      serverClientId: GoogleOAuthConfig.webClientId.isNotEmpty
          ? GoogleOAuthConfig.webClientId
          : null,
    );
    _initialized = true;
  }

  Future<auth.AuthClient> _clientFor(GoogleSignInAccount account) async {
    final authz = await account.authorizationClient.authorizeScopes(
      GoogleDriveAuth.scopes,
    );
    return authz.authClient(scopes: GoogleDriveAuth.scopes);
  }

  @override
  Future<({auth.AuthClient client, String? email})?> signIn() async {
    await _ensureInit();
    try {
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw GoogleDriveNotConfiguredException(
          'Google sign-in is not supported on this platform build.',
        );
      }
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: GoogleDriveAuth.scopes,
      );
      final client = await _clientFor(account);
      return (client: client, email: account.email);
    } on GoogleSignInException catch (e, stack) {
      // A user-cancelled flow is not an error worth surfacing.
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      logError(e, stack, context: 'GoogleDriveAuth.mobile.signIn');
      rethrow;
    }
  }

  @override
  Future<auth.AuthClient?> restore() async {
    await _ensureInit();
    try {
      final account =
          await GoogleSignIn.instance.attemptLightweightAuthentication();
      if (account == null) return null;
      final authz = await account.authorizationClient.authorizationForScopes(
        GoogleDriveAuth.scopes,
      );
      if (authz == null) return null;
      return authz.authClient(scopes: GoogleDriveAuth.scopes);
    } catch (e, stack) {
      logError(e, stack, context: 'GoogleDriveAuth.mobile.restore');
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    await _ensureInit();
    await GoogleSignIn.instance.disconnect();
  }
}
