import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants.dart';
import 'services/analytics_service.dart';
import 'services/observability_service.dart';

/// Set to true to run without Supabase (UI preview mode)
const bool kDemoMode = false;

/// App name constant
const String kAppName = 'Her Style Co.';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sentry wraps runApp so unhandled framework + zone errors are captured.
  // No-op when SENTRY_DSN dart-define isn't set.
  await Observability.bootstrap(() async {
    runZonedGuarded(() async {
      try {
        try {
          await dotenv.load(fileName: '.env');
        } catch (_) {
          // .env not available (e.g. web production) — dart-define values will be used
        }

        // Supabase init is isolated so a failure here cannot crash the whole
        // app. The rest of the code is null-safe when Supabase is missing.
        final supabaseUrl = AppConstants.supabaseUrl;
        final supabaseKey = AppConstants.supabaseAnonKey;
        if (!kDemoMode && supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
          _clearStaleSupabaseSessions(supabaseUrl);
          try {
            await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
          } catch (e, st) {
            debugPrint('SUPABASE INIT FAILED (continuing): $e\n$st');
            await Observability.capture(e, st,
                tags: {'phase': 'supabase_init'});
            _nukeSupabaseLocalStorage();
            try {
              await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
            } catch (e2, st2) {
              await Observability.capture(e2, st2,
                  tags: {'phase': 'supabase_init_retry'});
            }
          }
        }

        // PostHog init — no-op if POSTHOG_API_KEY isn't set.
        await Analytics.setup();

        // Identify the signed-in user with both Sentry + PostHog if a session
        // exists at boot. Auth controller should also call these on sign-in.
        try {
          final user = Supabase.instance.client.auth.currentUser;
          if (user != null) {
            await Observability.setUser(id: user.id, email: user.email);
            await Analytics.identify(user.id);
          }
        } catch (_) {}

        runApp(
          const ProviderScope(
            child: GRWMApp(),
          ),
        );
      } catch (e, st) {
        await Observability.capture(e, st, tags: {'phase': 'startup'});
        runApp(_ErrorApp(message: '$e', stack: st.toString()));
        debugPrint('STARTUP ERROR: $e\n$st');
      }
    }, (error, stack) {
      Observability.capture(error, stack, tags: {'phase': 'zone'});
      debugPrint('ZONE ERROR: $error\n$stack');
    });
  });
}

/// Extract the project ref from a Supabase URL like
/// `https://ntfgkukhjfzbmumhyqzq.supabase.co`.
String _projectRefFromUrl(String url) {
  final match = RegExp(r'https?://([^.]+)\.supabase\.co').firstMatch(url);
  return match?.group(1) ?? '';
}

/// Remove Supabase auth entries that belong to a DIFFERENT project than the
/// one the app is currently pointing at.
void _clearStaleSupabaseSessions(String currentSupabaseUrl) {
  try {
    final currentRef = _projectRefFromUrl(currentSupabaseUrl);
    if (currentRef.isEmpty) return;
    final keysToRemove = <String>[];
    for (int i = 0; i < html.window.localStorage.length; i++) {
      final key = html.window.localStorage.keys.elementAt(i);
      if (key.startsWith('sb-') && !key.contains(currentRef)) {
        keysToRemove.add(key);
      }
    }
    for (final k in keysToRemove) {
      html.window.localStorage.remove(k);
    }
  } catch (_) {
    // localStorage unavailable — nothing to clear.
  }
}

/// Last resort: clear every `sb-*` key. Called if Supabase.initialize throws.
void _nukeSupabaseLocalStorage() {
  try {
    final keysToRemove = <String>[];
    for (int i = 0; i < html.window.localStorage.length; i++) {
      final key = html.window.localStorage.keys.elementAt(i);
      if (key.startsWith('sb-') || key.contains('supabase')) {
        keysToRemove.add(key);
      }
    }
    for (final k in keysToRemove) {
      html.window.localStorage.remove(k);
    }
  } catch (_) {}
}

class _ErrorApp extends StatelessWidget {
  final String message;
  final String? stack;
  const _ErrorApp({required this.message, this.stack});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('App failed to start',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SelectableText(message,
                    style: const TextStyle(fontSize: 13, color: Colors.red)),
                if (stack != null) ...[
                  const SizedBox(height: 20),
                  const Text('Stack trace:',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SelectableText(stack!,
                      style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.black87)),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Clear site data & reload'),
                  onPressed: () {
                    try {
                      html.window.localStorage.clear();
                      html.window.sessionStorage.clear();
                    } catch (_) {}
                    html.window.location.reload();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
