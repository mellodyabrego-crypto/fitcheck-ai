import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../main.dart';
import '../models/wardrobe_item.dart';

class ClothingGridTile extends StatelessWidget {
  final WardrobeItem item;
  final VoidCallback? onTap;

  const ClothingGridTile({super.key, required this.item, this.onTap});

  String get _heroTag => 'wardrobe_item_${item.id}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: Hero(
                  tag: _heroTag,
                  child: WardrobeItemImage(item: item),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Text(
                item.name ?? item.category.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showExpandedWardrobeImage(
  BuildContext context,
  WardrobeItem item, {
  VoidCallback? onViewDetails,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => _ExpandedImageView(
        item: item,
        onViewDetails: onViewDetails,
      ),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _ExpandedImageView extends StatelessWidget {
  final WardrobeItem item;
  final VoidCallback? onViewDetails;

  const _ExpandedImageView({required this.item, this.onViewDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Hero(
                tag: 'wardrobe_item_${item.id}',
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: WardrobeItemImage(
                        item: item,
                        fit: BoxFit.contain,
                        useThumbnail: false,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name ?? item.category.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (onViewDetails != null) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onViewDetails!();
                      },
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      label: const Text(
                        'View Details',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WardrobeItemImage extends StatelessWidget {
  final WardrobeItem item;
  final BoxFit fit;
  final bool useThumbnail;

  const WardrobeItemImage({
    super.key,
    required this.item,
    this.fit = BoxFit.cover,
    this.useThumbnail = true,
  });

  @override
  Widget build(BuildContext context) {
    if (item.imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: item.imagePath,
        fit: fit,
        width: double.infinity,
        placeholder: (_, __) => Container(
          color: Colors.grey.shade100,
          child: const Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          color: _colorFromName(item.color),
          child: Center(
              child: Icon(item.category.icon,
                  size: 28, color: Colors.white.withValues(alpha: 0.9))),
        ),
      );
    }

    if (kDemoMode || item.imagePath == 'demo') {
      return Container(
        width: double.infinity,
        color: _colorFromName(item.color),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.category.icon,
                  size: 28, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(height: 4),
              Text(item.color ?? '',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    final path = (useThumbnail ? item.thumbnailPath : null) ?? item.imagePath;
    final url = Supabase.instance.client.storage
        .from(AppConstants.wardrobeBucket)
        .getPublicUrl(path);

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: double.infinity,
      placeholder: (_, __) => Container(
        color: Colors.grey.shade100,
        child: const Center(
          child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        color: Colors.grey.shade100,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  Color _colorFromName(String? colorName) {
    return switch (colorName?.toLowerCase()) {
      'white' => Colors.blueGrey.shade200,
      'black' => Colors.grey.shade800,
      'dark blue' || 'navy' => Colors.indigo.shade400,
      'light blue' => Colors.lightBlue.shade300,
      'khaki' || 'beige' => Colors.amber.shade300,
      'brown' => Colors.brown.shade400,
      'silver' || 'grey' || 'gray' => Colors.blueGrey.shade300,
      'gold' => Colors.amber.shade600,
      'red' => Colors.red.shade400,
      'green' => Colors.green.shade400,
      _ => AppTheme.primary.withValues(alpha: 0.6),
    };
  }
}
