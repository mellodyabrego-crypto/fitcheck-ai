import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../models/wardrobe_item.dart';

final shareServiceProvider = Provider<ShareService>((ref) {
  return ShareService();
});

class ShareService {
  /// Shares an outfit summary. On web, falls back to clipboard copy.
  /// Returns true if native share opened, false if copied to clipboard.
  Future<bool> shareOutfitCard({
    required String occasion,
    required List<WardrobeItem> items,
    int? fitCheckScore,
    bool isPro = false,
  }) async {
    final itemNames = items
        .map(
          (i) => '• ${i.name ?? i.category.label}'
              '${i.color != null ? ' (${i.color})' : ''}',
        )
        .join('\n');

    final scoreLine = fitCheckScore != null
        ? '\n\n⭐ Fit Check Score: $fitCheckScore/100'
        : '';

    final shareText =
        '✨ My ${occasion.toUpperCase()} look — styled by Her Style Co. AI:\n\n'
        '$itemNames'
        '$scoreLine\n\n'
        '💅 Her Style Co. — Your personal Stylist';

    try {
      await Share.share(shareText, subject: 'My Her Style Co. Outfit');
      return true;
    } catch (_) {
      // Web fallback: copy to clipboard
      await Clipboard.setData(ClipboardData(text: shareText));
      return false;
    }
  }

  /// Share an arbitrary block of text. Falls back to clipboard on web.
  Future<bool> shareText(String text, {String? subject}) async {
    try {
      await Share.share(text, subject: subject);
      return true;
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      return false;
    }
  }

  /// Share a pre-rendered image (from a RepaintBoundary). Tries native share
  /// with the image first; falls back to text-only share, then clipboard.
  /// Returns true if any share/clipboard path succeeded.
  Future<bool> shareImage({
    required Uint8List bytes,
    required String fallbackText,
    String filename = 'her-style-co.png',
    String? subject,
  }) async {
    // Try native image share via share_plus XFile (works on web in modern browsers
    // that support navigator.share with files; falls through otherwise).
    try {
      final file = XFile.fromData(bytes, name: filename, mimeType: 'image/png');
      final result = await Share.shareXFiles(
        [file],
        text: fallbackText,
        subject: subject,
      );
      if (result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed) {
        return true;
      }
    } catch (_) {
      // Fall through to text-only share.
    }
    // Fallback: text share
    try {
      await Share.share(fallbackText, subject: subject);
      return true;
    } catch (_) {
      // Last fallback: clipboard
      try {
        await Clipboard.setData(ClipboardData(text: fallbackText));
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  // Keep for API compatibility
  Future<Uint8List?> renderToBytes(Widget widget) async => null;
}
