import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import '../core/constants.dart';

/// Thin wrapper around PostHog. All call sites can fire events without caring
/// whether analytics is configured — `isEnabled` is checked here. If the
/// POSTHOG_API_KEY dart-define isn't set, every call is a no-op.
class Analytics {
  Analytics._();

  static bool _initialized = false;
  static bool get isEnabled => AppConstants.posthogApiKey.isNotEmpty;

  /// Call once during app start, after Posthog SDK is set up by setup() above.
  static Future<void> setup() async {
    if (!isEnabled || _initialized) return;
    try {
      final config = PostHogConfig(AppConstants.posthogApiKey)
        ..host = AppConstants.posthogHost
        ..captureApplicationLifecycleEvents = true
        ..debug = kDebugMode;
      await Posthog().setup(config);
      _initialized = true;
    } catch (e) {
      debugPrint('PostHog setup failed (continuing): $e');
    }
  }

  /// Identify the current user. [userId] should be the Supabase auth uid.
  static Future<void> identify(String userId, {Map<String, Object>? props}) async {
    if (!isEnabled || !_initialized) return;
    try {
      await Posthog().identify(userId: userId, userProperties: props);
    } catch (_) {}
  }

  /// Reset on logout.
  static Future<void> reset() async {
    if (!isEnabled || !_initialized) return;
    try {
      await Posthog().reset();
    } catch (_) {}
  }

  /// Fire a product event. Always safe to call.
  static Future<void> track(String event, {Map<String, Object>? props}) async {
    if (!isEnabled || !_initialized) return;
    try {
      await Posthog().capture(eventName: event, properties: props);
    } catch (_) {}
  }

  /// Page-view-style screen event.
  static Future<void> screen(String name, {Map<String, Object>? props}) async {
    if (!isEnabled || !_initialized) return;
    try {
      await Posthog().screen(screenName: name, properties: props);
    } catch (_) {}
  }
}

/// Centralised event names — keep all funnels in one file so we can grep for
/// usage and see which screens fire what.
abstract class AnalyticsEvents {
  // Onboarding funnel
  static const onboardingStarted = 'onboarding_started';
  static const onboardingStepReached = 'onboarding_step_reached';
  static const onboardingCompleted = 'onboarding_completed';
  static const onboardingSkipped = 'onboarding_skipped';

  // Walkthrough funnel
  static const walkthroughShown = 'walkthrough_shown';
  static const walkthroughStepReached = 'walkthrough_step_reached';
  static const walkthroughCompleted = 'walkthrough_completed';
  static const walkthroughSkipped = 'walkthrough_skipped';

  // Core actions
  static const wardrobeItemAdded = 'wardrobe_item_added';
  static const outfitGenerateRequested = 'outfit_generate_requested';
  static const outfitGenerateSucceeded = 'outfit_generate_succeeded';
  static const outfitGenerateFailed = 'outfit_generate_failed';
  static const fitCheckRequested = 'fit_check_requested';
  static const colorSeasonRequested = 'color_season_requested';

  // Monetisation
  static const paywallViewed = 'paywall_viewed';
  static const paywallCtaTapped = 'paywall_cta_tapped';

  // Errors
  static const aiQuotaExceeded = 'ai_quota_exceeded';
  static const aiNetworkError = 'ai_network_error';
}
