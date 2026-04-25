import 'package:flutter_dotenv/flutter_dotenv.dart';

// Compile-time values injected via `--dart-define`. Used for web production
// builds where .env is not served. Falls back to dotenv for local dev.
const _dartDefSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _dartDefSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _dartDefClaudeApiKey = String.fromEnvironment('CLAUDE_API_KEY');
const _dartDefGeminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
const _dartDefSentryDsn = String.fromEnvironment('SENTRY_DSN');
const _dartDefPosthogKey = String.fromEnvironment('POSTHOG_API_KEY');
const _dartDefPosthogHost = String.fromEnvironment('POSTHOG_HOST',
    defaultValue: 'https://us.i.posthog.com');
const _dartDefAppEnv =
    String.fromEnvironment('APP_ENV', defaultValue: 'production');

// Firebase web SDK config for push notifications. All optional — empty values
// mean notifications are inert (no FCM token registration, no service worker
// init). Match the keys to the Firebase console → Project Settings → SDK
// snippet.
const _dartDefFirebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
const _dartDefFirebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
const _dartDefFirebaseMessagingSenderId =
    String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
const _dartDefFirebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
const _dartDefFirebaseAuthDomain =
    String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
const _dartDefFirebaseStorageBucket =
    String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
const _dartDefFirebaseVapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY');

String _pickEnv(String compileTime, String key) {
  if (compileTime.isNotEmpty) return compileTime;
  return dotenv.env[key] ?? '';
}

abstract class AppConstants {
  static String get supabaseUrl =>
      _pickEnv(_dartDefSupabaseUrl, 'SUPABASE_URL');
  static String get supabaseAnonKey =>
      _pickEnv(_dartDefSupabaseAnonKey, 'SUPABASE_ANON_KEY');
  static String get claudeApiKey =>
      _pickEnv(_dartDefClaudeApiKey, 'CLAUDE_API_KEY');
  static String get geminiApiKey =>
      _pickEnv(_dartDefGeminiApiKey, 'GEMINI_API_KEY');
  static String get sentryDsn => _pickEnv(_dartDefSentryDsn, 'SENTRY_DSN');
  static String get posthogApiKey =>
      _pickEnv(_dartDefPosthogKey, 'POSTHOG_API_KEY');
  static String get posthogHost =>
      _pickEnv(_dartDefPosthogHost, 'POSTHOG_HOST').isNotEmpty
          ? _pickEnv(_dartDefPosthogHost, 'POSTHOG_HOST')
          : 'https://us.i.posthog.com';
  static String get appEnv => _dartDefAppEnv;

  // Firebase web — push notifications
  static String get firebaseApiKey =>
      _pickEnv(_dartDefFirebaseApiKey, 'FIREBASE_API_KEY');
  static String get firebaseProjectId =>
      _pickEnv(_dartDefFirebaseProjectId, 'FIREBASE_PROJECT_ID');
  static String get firebaseMessagingSenderId => _pickEnv(
      _dartDefFirebaseMessagingSenderId, 'FIREBASE_MESSAGING_SENDER_ID');
  static String get firebaseAppId =>
      _pickEnv(_dartDefFirebaseAppId, 'FIREBASE_APP_ID');
  static String get firebaseAuthDomain =>
      _pickEnv(_dartDefFirebaseAuthDomain, 'FIREBASE_AUTH_DOMAIN');
  static String get firebaseStorageBucket =>
      _pickEnv(_dartDefFirebaseStorageBucket, 'FIREBASE_STORAGE_BUCKET');
  static String get firebaseVapidKey =>
      _pickEnv(_dartDefFirebaseVapidKey, 'FIREBASE_VAPID_KEY');
  static bool get isFcmConfigured =>
      firebaseApiKey.isNotEmpty &&
      firebaseProjectId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseVapidKey.isNotEmpty;

  static const String wardrobeBucket = 'wardrobe-images';
  static const String claudeModel = 'claude-sonnet-4-20250514';
  static const String claudeApiUrl = 'https://api.anthropic.com/v1/messages';
  static const String geminiModel = 'gemini-2.5-flash';

  // Free tier limits
  static const int freeWardrobeLimit = 20;
  static const int freeDailyOutfits = 3;
  static const int freeDailyFitChecks = 3;
}
