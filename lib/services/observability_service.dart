import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../core/constants.dart';

/// Thin wrapper around Sentry. Init is null-safe: if SENTRY_DSN isn't set
/// the app runs normally and reports just become no-ops.
class Observability {
  Observability._();

  static bool get isEnabled => AppConstants.sentryDsn.isNotEmpty;

  /// Wraps `runApp` so unhandled errors flow into Sentry.
  /// If [isEnabled] is false, just runs [appRunner] directly.
  static Future<void> bootstrap(Future<void> Function() appRunner) async {
    if (!isEnabled) {
      await appRunner();
      return;
    }
    try {
      await SentryFlutter.init(
        (options) {
          options.dsn = AppConstants.sentryDsn;
          options.environment = AppConstants.appEnv;
          options.tracesSampleRate = kDebugMode ? 0.0 : 0.1;
          options.attachScreenshot = false; // wardrobe photos are sensitive
          options.attachViewHierarchy = false;
          options.sendDefaultPii = false;
        },
        appRunner: appRunner,
      );
    } catch (e) {
      debugPrint('Sentry init failed (continuing): $e');
      await appRunner();
    }
  }

  /// Manually report an error from a try/catch.
  /// Call sites pass either `capture(e, st)` (two positional) or
  /// `capture(e, st, tags: {...})` (two positional + named tags).
  /// Dart doesn't allow mixing `[...]` and `{...}` in one signature, so
  /// stack is required here — pass `null` if you don't have one.
  static Future<void> capture(
    Object error,
    StackTrace? stack, {
    Map<String, String>? tags,
  }) async {
    if (!isEnabled) return;
    try {
      await Sentry.captureException(
        error,
        stackTrace: stack,
        withScope: tags == null
            ? null
            : (scope) {
                tags.forEach((k, v) => scope.setTag(k, v));
              },
      );
    } catch (_) {}
  }

  /// Capture a non-exception breadcrumb / message.
  /// Useful for "AI returned malformed JSON" — not an exception, but worth
  /// tracking so we can tighten the prompt over time.
  static Future<void> captureMessage(
    String message, {
    Map<String, dynamic>? extra,
    SentryLevel level = SentryLevel.warning,
  }) async {
    if (!isEnabled) return;
    try {
      await Sentry.captureMessage(
        message,
        level: level,
        withScope: extra == null
            ? null
            : (scope) {
                extra.forEach((k, v) => scope.setExtra(k, v));
              },
      );
    } catch (_) {}
  }

  /// Tag the current user (call after sign-in; clear on sign-out).
  static Future<void> setUser({String? id, String? email}) async {
    if (!isEnabled) return;
    try {
      await Sentry.configureScope((scope) {
        scope.setUser(id == null ? null : SentryUser(id: id, email: email));
      });
    } catch (_) {}
  }
}
