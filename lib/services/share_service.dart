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
        .map((i) => '• ${i.name ?? i.category.label}'
            '${i.color != null ? ' (${i.color})' : ''}')
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

  // Keep for API compatibility
  Future<Uint8List?> renderToBytes(Widget widget) async => null;
}
