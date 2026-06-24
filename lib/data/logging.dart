import 'package:flutter/foundation.dart';

/// Central sink for *caught* errors that would otherwise be swallowed at the
/// call site.
///
/// This mirrors the uncaught/framework error path in `main.dart` (`runZonedGuarded`
/// + `FlutterError.onError`) so that every recorded failure — caught or not —
/// flows through a single place. When a crash-reporting service (Sentry,
/// Crashlytics, …) is eventually wired in, this is the one function to update.
///
/// [context] is a short label identifying the operation that failed, e.g.
/// `'ContentManagerApi.fetchModules'`. Pass the [stack] whenever one is
/// available (`catch (e, stack)`) so the report is actionable.
void logError(Object error, StackTrace? stack, {required String context}) {
  debugPrint('[$context] $error');
  if (stack != null) {
    debugPrint(stack.toString());
  }
}
