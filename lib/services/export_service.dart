import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

class ExportException implements Exception {
  final String message;
  const ExportException(this.message);
  @override
  String toString() => message;
}

/// Generates a JSON archive of the user's data (profile, wardrobe, outfits,
/// outfit feedback) and triggers a browser download via a Blob anchor.
///
/// Web-only — the app is web-first. The download is fully client-side; nothing
/// is sent to a third party. Image bytes are NOT bundled (they're served from
/// Supabase storage and the URL is included instead).
class ExportService {
  Future<void> exportWardrobeJson() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      throw const ExportException('Sign in to export your data.');
    }
    final userId = user.id;

    // Pull every table the user can read. Each query is wrapped so partial
    // failures still produce a usable export — degraded > nothing.
    final profile = await _safeFetch(
      () => client
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle(),
    );
    final wardrobeItems = await _safeFetch(
      () => client.from('wardrobe_items').select().eq('user_id', userId),
    );
    final outfits = await _safeFetch(
      () => client.from('outfits').select().eq('user_id', userId),
    );
    final outfitItems = await _safeFetch(
      () => client
          .from('outfit_items')
          .select('*, outfits!inner(user_id)')
          .eq('outfits.user_id', userId),
    );
    final feedback = await _safeFetch(
      () => client
          .from('outfit_feedback')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false),
    );

    final payload = {
      'export_version': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'user': {'id': userId, 'email': user.email, 'created_at': user.createdAt},
      'profile': profile,
      'wardrobe_items': wardrobeItems,
      'outfits': outfits,
      'outfit_items': outfitItems,
      'outfit_feedback': feedback,
    };

    final json = const JsonEncoder.withIndent('  ').convert(payload);
    _triggerDownload(
      bytes: utf8.encode(json),
      mime: 'application/json',
      filename:
          'her-style-co-export-${DateTime.now().toIso8601String().split("T").first}.json',
    );
  }

  Future<dynamic> _safeFetch(Future<dynamic> Function() query) async {
    try {
      return await query();
    } catch (e) {
      return {'_error': e.toString()};
    }
  }

  void _triggerDownload({
    required List<int> bytes,
    required String mime,
    required String filename,
  }) {
    final blob = html.Blob([bytes], mime);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    // Defer revoke — some browsers cancel the download if revoke fires
    // synchronously in the same tick.
    Future.delayed(
      const Duration(seconds: 1),
      () => html.Url.revokeObjectUrl(url),
    );
  }
}
