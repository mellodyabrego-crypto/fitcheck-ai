import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A photo in the "My Photos" tab — either uploaded from camera/gallery
/// or auto-created from an AI-generated outfit.
class RatedPhoto {
  final Uint8List? bytes; // real camera/gallery photo
  final String? networkUrl; // AI outfit — first item's Unsplash image
  final bool isAiGenerated;
  final int score; // 7–10
  final String feedback;
  final String improvements;
  final String? outfitLabel; // e.g. "CASUAL"
  final String? buyUrl; // tappable shop link

  RatedPhoto({
    this.bytes,
    this.networkUrl,
    this.isAiGenerated = false,
    required this.score,
    required this.feedback,
    required this.improvements,
    this.outfitLabel,
    this.buyUrl,
  });
}

final ratedPhotosProvider = StateProvider<List<RatedPhoto>>((ref) => []);
