import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
const _kUsername     = 'fitcheck_username';
const _kTopSize      = 'fitcheck_top_size';
const _kBottomSize   = 'fitcheck_bottom_size';
const _kShoeSize     = 'fitcheck_shoe_size';
const _kColorSeason  = 'fitcheck_color_season';   // 'Spring'|'Summer'|'Autumn'|'Winter'
const _kFavColors    = 'fitcheck_favorite_colors'; // JSON array of strings

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
