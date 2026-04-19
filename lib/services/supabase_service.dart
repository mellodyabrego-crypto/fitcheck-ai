import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/wardrobe_item.dart';
import '../models/outfit.dart';
import '../models/fit_check.dart';
import '../core/constants.dart';

final supabaseServiceProvider = Provider<SupabaseService?>((ref) {
  try {
    return SupabaseService(Supabase.instance.client);
  } catch (_) {
    // Supabase wasn't initialized (missing env) — return null so callers can skip
    return null;
  }
});

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  SupabaseClient get client => _client;
  User? get currentUser => _client.auth.currentUser;
  // Safe getter — returns empty string when no user (queries just return empty)
  String get userId => currentUser?.id ?? '';

  // ── Auth ──────────────────────────────────────────────
  Future<bool> signInWithApple() =>
      _client.auth.signInWithOAuth(OAuthProvider.apple);

  Future<bool> signInWithGoogle() async {
    final res = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.grwm.app://callback',
    );
    return res;
  }

  Future<void> signOut() => _client.auth.signOut();

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ── Storage ───────────────────────────────────────────
  /// Hard limits for any image we accept into storage. Server-side resize
  /// happens in image_service; this is the last-line guard before Supabase.
  static const int _maxImageBytes = 2 * 1024 * 1024; // 2 MB

  Future<String> uploadImage(String path, Uint8List bytes) async {
    if (bytes.lengthInBytes > _maxImageBytes) {
      throw UploadValidationException(
        'Image too large (${(bytes.lengthInBytes / 1024 / 1024).toStringAsFixed(1)} MB). '
        'Max is ${(_maxImageBytes / 1024 / 1024).toStringAsFixed(0)} MB.',
      );
    }
    final mime = _sniffImageMime(bytes);
    if (mime == null) {
      throw const UploadValidationException(
        'That file isn\'t a recognized image (only JPEG / PNG / WebP allowed).',
      );
    }
    await _client.storage.from(AppConstants.wardrobeBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: mime,
          ),
        );
    return path;
  }

  /// Inspect the magic bytes of [bytes] and return one of:
  ///   - 'image/jpeg', 'image/png', 'image/webp'
  /// Returns null if no known image header is present.
  String? _sniffImageMime(Uint8List bytes) {
    if (bytes.length < 12) return null;
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'image/png';
    }
    // WebP: "RIFF" .... "WEBP"
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }

  String getPublicUrl(String path) {
    return _client.storage
        .from(AppConstants.wardrobeBucket)
        .getPublicUrl(path);
  }

  Future<void> deleteImage(String pathOrUrl) async {
    // Accept both bucket paths ('user-id/item.png') and full public URLs.
    // Public URL format: https://<project>.supabase.co/storage/v1/object/public/<bucket>/<path>
    var path = pathOrUrl;
    final marker = '/storage/v1/object/public/${AppConstants.wardrobeBucket}/';
    final i = pathOrUrl.indexOf(marker);
    if (i != -1) {
      path = pathOrUrl.substring(i + marker.length);
    }
    await _client.storage.from(AppConstants.wardrobeBucket).remove([path]);
  }

  // ── Wardrobe Items ────────────────────────────────────
  Future<List<WardrobeItem>> getWardrobeItems() async {
    final data = await _client
        .from('wardrobe_items')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return data.map((json) => WardrobeItem.fromJson(json)).toList();
  }

  Future<WardrobeItem> addWardrobeItem(Map<String, dynamic> item) async {
    final data = await _client
        .from('wardrobe_items')
        .insert(item)
        .select()
        .single();
    return WardrobeItem.fromJson(data);
  }

  Future<void> deleteWardrobeItem(String id) async {
    await _client.from('wardrobe_items').delete().eq('id', id);
  }

  // ── Outfits ───────────────────────────────────────────
  Future<Outfit> createOutfit(Map<String, dynamic> outfit, List<Map<String, dynamic>> items) async {
    final outfitData = await _client
        .from('outfits')
        .insert(outfit)
        .select()
        .single();

    for (final item in items) {
      item['outfit_id'] = outfitData['id'];
      await _client.from('outfit_items').insert(item);
    }

    return Outfit.fromJson(outfitData);
  }

  Future<List<Outfit>> getOutfits() async {
    final data = await _client
        .from('outfits')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return data.map((json) => Outfit.fromJson(json)).toList();
  }

  Future<List<OutfitItem>> getOutfitItems(String outfitId) async {
    final data = await _client
        .from('outfit_items')
        .select()
        .eq('outfit_id', outfitId);
    return data.map((json) => OutfitItem.fromJson(json)).toList();
  }

  // ── Fit Checks ────────────────────────────────────────
  Future<FitCheck> saveFitCheck(Map<String, dynamic> fitCheck) async {
    final data = await _client
        .from('fit_checks')
        .insert(fitCheck)
        .select()
        .single();
    return FitCheck.fromJson(data);
  }

  Future<List<FitCheck>> getFitChecks() async {
    final data = await _client
        .from('fit_checks')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return data.map((json) => FitCheck.fromJson(json)).toList();
  }
}

class UploadValidationException implements Exception {
  final String message;
  const UploadValidationException(this.message);
  @override
  String toString() => message;
}
