import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/gemini_service.dart';

// ─── LocalStorage helpers ──────────────────────────────────────────────────

String? _lsRead(String key) {
  try {
    final v = html.window.localStorage[key];
    return (v == null || v.isEmpty) ? null : v;
  } catch (_) {
    return null;
  }
}

void _lsWrite(String key, String? value) {
  try {
    if (value == null || value.isEmpty) {
      html.window.localStorage.remove(key);
    } else {
      html.window.localStorage[key] = value;
    }
  } catch (_) {
    // localStorage unavailable — value won't survive reload
  }
}

// Keys
const _kUsername = 'fitcheck_username';
const _kTopSize = 'fitcheck_top_size';
const _kBottomSize = 'fitcheck_bottom_size';
const _kShoeSize = 'fitcheck_shoe_size';
const _kColorSeason =
    'fitcheck_color_season'; // 'Spring'|'Summer'|'Autumn'|'Winter'
const _kFavColors = 'fitcheck_favorite_colors'; // JSON array of strings

// ─── Providers ──────────────────────────────────────────────────────────────

/// Shared username provider — @handle the user set in Profile.
/// Persisted to localStorage so it survives reloads.
final usernameProvider = StateProvider<String>((ref) {
  final initial = _lsRead(_kUsername) ?? '';
  ref.listenSelf((prev, next) => _lsWrite(_kUsername, next));
  return initial;
});

/// Display name read from Supabase user metadata (full_name).
/// Updated by EditProfileScreen after a successful save.
final displayNameProvider = StateProvider<String>((ref) {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['full_name'] as String? ?? '';
  } catch (_) {
    // Supabase not initialized — safe default
    return '';
  }
});

/// Clothing sizes — persisted so onboarding choices + profile edits survive reloads.
final topSizeProvider = StateProvider<String?>((ref) {
  final initial = _lsRead(_kTopSize);
  ref.listenSelf((prev, next) => _lsWrite(_kTopSize, next));
  return initial;
});

final bottomSizeProvider = StateProvider<String?>((ref) {
  final initial = _lsRead(_kBottomSize);
  ref.listenSelf((prev, next) => _lsWrite(_kBottomSize, next));
  return initial;
});

final shoeSizeProvider = StateProvider<String?>((ref) {
  final initial = _lsRead(_kShoeSize);
  ref.listenSelf((prev, next) => _lsWrite(_kShoeSize, next));
  return initial;
});

/// User's color season (Spring/Summer/Autumn/Winter). Set by onboarding or skin-tone AI.
final colorSeasonProvider = StateProvider<String?>((ref) {
  final initial = _lsRead(_kColorSeason);
  ref.listenSelf((prev, next) => _lsWrite(_kColorSeason, next));
  return initial;
});

/// Full StyleProfileContext built from the user's Supabase profile row plus
/// their last 10 outfit_feedback entries. Cached as a long-lived FutureProvider
/// so the outfit/fit-check controllers can pull it cheaply each call AND so
/// `ref.invalidate(...)` after `recordFeedback` actually warms a fresh value
/// instead of disposing the cell.
///
/// (Originally autoDispose, but autoDispose + invalidate-from-controller is a
/// race: if no widget is currently watching, the provider is already gone and
/// invalidate is a no-op for cache-warming.)
final styleProfileContextProvider = FutureProvider<StyleProfileContext>((
  ref,
) async {
  try {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return const StyleProfileContext();

    final row = await client
        .from('user_profiles')
        .select(
          'aesthetics, brands, body_type, color_preferences, skin_tone_undertone, top_size, bottom_size, shoe_size',
        )
        .eq('user_id', userId)
        .maybeSingle();

    String? mapSeason(String? undertone) {
      if (undertone == null) return null;
      final v = undertone.toLowerCase();
      if (v.contains('spring')) return 'Spring';
      if (v.contains('summer')) return 'Summer';
      if (v.contains('autumn') || v.contains('fall')) return 'Autumn';
      if (v.contains('winter')) return 'Winter';
      return null;
    }

    final fb = await client
        .from('outfit_feedback')
        .select('signal, occasion, reason')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20);

    final accepts = <String>[];
    final rejects = <String>[];
    for (final r in (fb as List)) {
      final m = r as Map;
      final tag = [
        if (m['occasion'] != null) m['occasion'].toString(),
        if (m['reason'] != null) m['reason'].toString(),
      ].where((s) => s.isNotEmpty).join(' — ');
      if (tag.isEmpty) continue;
      if (m['signal'] == 'accept' || m['signal'] == 'favorite') {
        if (accepts.length < 5) accepts.add(tag);
      } else if (m['signal'] == 'reject' && rejects.length < 5) {
        rejects.add(tag);
      }
    }

    return StyleProfileContext(
      colorSeason: mapSeason(row?['skin_tone_undertone'] as String?) ??
          ref.read(colorSeasonProvider),
      colorPreferences: ((row?['color_preferences'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          ref.read(favoriteColorsProvider)),
      bodyType: row?['body_type'] as String?,
      aesthetics:
          (row?['aesthetics'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      brands: (row?['brands'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      topSize: row?['top_size'] as String? ?? ref.read(topSizeProvider),
      bottomSize:
          row?['bottom_size'] as String? ?? ref.read(bottomSizeProvider),
      shoeSize: row?['shoe_size'] as String? ?? ref.read(shoeSizeProvider),
      recentAccepts: accepts,
      recentRejects: rejects,
    );
  } catch (_) {
    // Supabase down or no row yet — return what we have from local state
    return StyleProfileContext(
      colorSeason: ref.read(colorSeasonProvider),
      colorPreferences: ref.read(favoriteColorsProvider),
      topSize: ref.read(topSizeProvider),
      bottomSize: ref.read(bottomSizeProvider),
      shoeSize: ref.read(shoeSizeProvider),
    );
  }
});

/// User's favorite colors (free-form names). Set during onboarding "Colors" step.
final favoriteColorsProvider = StateProvider<List<String>>((ref) {
  final raw = _lsRead(_kFavColors);
  List<String> initial = [];
  if (raw != null && raw.isNotEmpty) {
    try {
      initial = (jsonDecode(raw) as List).cast<String>();
    } catch (_) {}
  }
  ref.listenSelf((prev, next) {
    try {
      _lsWrite(_kFavColors, jsonEncode(next));
    } catch (_) {}
  });
  return initial;
});
