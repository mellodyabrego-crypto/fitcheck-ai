import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import 'observability_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Push-notification glue. Inert until FIREBASE_* env vars are set — same
/// pattern as Sentry/PostHog. The pipeline:
///   1. App init (or sign-in): bootstrap() initializes Firebase web SDK if
///      configured, requests notification permission, mints an FCM token,
///      and upserts it into the device_tokens table.
///   2. Edge function `send-daily-reminder` (fired hourly by pg_cron) reads
///      device_tokens for users whose notification_time == current UTC HH:MM
///      and sends FCM v1 pushes.
///   3. Service worker `web/firebase-messaging-sw.js` handles background pushes.
///
/// All early returns log a debug line so it's easy to tell why notifications
/// aren't firing in dev.
class NotificationService {
  static bool _initialized = false;

  Future<void> bootstrap() async {
    if (!AppConstants.isFcmConfigured) {
      debugPrint('[notifications] FCM not configured — skipping init.');
      return;
    }
    if (_initialized) return;
    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: AppConstants.firebaseApiKey,
          appId: AppConstants.firebaseAppId,
          messagingSenderId: AppConstants.firebaseMessagingSenderId,
          projectId: AppConstants.firebaseProjectId,
          authDomain: AppConstants.firebaseAuthDomain.isEmpty
              ? null
              : AppConstants.firebaseAuthDomain,
          storageBucket: AppConstants.firebaseStorageBucket.isEmpty
              ? null
              : AppConstants.firebaseStorageBucket,
        ),
      );
      _initialized = true;
    } catch (e, st) {
      Observability.capture(e, st, tags: {'op': 'fcm.init'});
      debugPrint('[notifications] Firebase init failed: $e');
    }
  }

  /// Call after the user signs in (or any time the auth state changes to
  /// signed-in). Requests notification permission, mints a token, and
  /// upserts it to device_tokens. Idempotent — safe to call repeatedly.
  Future<void> registerForCurrentUser() async {
    if (!_initialized) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        debugPrint(
            '[notifications] Permission not granted: ${settings.authorizationStatus}');
        return;
      }
      final token = await messaging.getToken(
        vapidKey: AppConstants.firebaseVapidKey,
      );
      if (token == null || token.isEmpty) {
        debugPrint('[notifications] FCM returned null token.');
        return;
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      await Supabase.instance.client.from('device_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': kIsWeb ? 'web' : 'unknown',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,token');
    } catch (e, st) {
      Observability.capture(e, st, tags: {'op': 'fcm.register'});
      debugPrint('[notifications] register failed: $e');
    }
  }

  /// Call on sign-out so the next user on this device doesn't get the prior
  /// user's reminders.
  Future<void> unregisterCurrentDevice() async {
    if (!_initialized) return;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final token = await FirebaseMessaging.instance.getToken(
        vapidKey: AppConstants.firebaseVapidKey,
      );
      if (user != null && token != null) {
        await Supabase.instance.client
            .from('device_tokens')
            .delete()
            .eq('user_id', user.id)
            .eq('token', token);
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (e, st) {
      Observability.capture(e, st, tags: {'op': 'fcm.unregister'});
    }
  }
}
