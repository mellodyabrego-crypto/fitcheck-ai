import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../main.dart';
import '../../providers/photo_providers.dart';
import '../../providers/collection_providers.dart';
import '../../widgets/decorative_symbols.dart';
import '../../models/outfit.dart';
import '../../services/supabase_service.dart';
import '../../services/image_service.dart';
import '../../services/gemini_service.dart';
import '../../services/share_service.dart';
import '../calendar/calendar_screen.dart';
import 'generate_sheet.dart';
import 'outfit_controller.dart';

final outfitHistoryProvider = FutureProvider<List<Outfit>>((ref) async {
  if (kDemoMode) {
    return [
      Outfit(
        id: 'demo-1',
        userId: 'demo',
        occasion: 'casual',
        reasoning:
            'The white tee pairs perfectly with slim jeans for an effortless casual look.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Outfit(
        id: 'demo-2',
        userId: 'demo',
        occasion: 'date_night',
        reasoning:
            'The Oxford shirt with chinos creates a smart-casual vibe. Chelsea boots elevate the look.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
  final supabase = ref.read(supabaseServiceProvider);
  if (supabase == null) return <Outfit>[];
  try {
    return await supabase.getOutfits();
  } catch (_) {
    return <Outfit>[];
  }
});

class OutfitHistoryScreen extends ConsumerWidget {
  const OutfitHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outfitsAsync = ref.watch(outfitHistoryProvider);
    final ratedPhotos = ref.watch(ratedPhotosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Outfits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: () => _uploadOutfitPhoto(context, ref),
            tooltip: 'Upload Outfit',
          ),
        ],
      ),
      body: WithDecorations(
        sparse: true,
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: const TabBar(
                  indicatorColor: AppTheme.primary,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.textSecondary,
                  tabs: [
                    Tab(text: 'Create'),
                    Tab(text: 'My Creations'),
                    Tab(text: 'Collections'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // ── AI Generated outfits ──
                    outfitsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (outfits) {
                        if (outfits.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 64,
                                  color: AppTheme.textSecondary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No creations yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap Create to generate your first look!',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: outfits.length,
                          itemBuilder: (context, index) {
                            final outfit = outfits[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                title: Text(
                                  outfit.occasion?.toUpperCase() ?? 'OUTFIT',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  outfit.reasoning ?? 'Tap to view',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () =>
                                    context.push('/outfit/${outfit.id}'),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    // ── My Photos ──
                    ratedPhotos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.photo_camera,
                                  size: 64,
                                  color: AppTheme.textSecondary.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No photos yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Upload a photo or generate an AI outfit!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _uploadOutfitPhoto(context, ref),
                                  icon: const Icon(Icons.add_a_photo),
                                  label: const Text('Upload Photo'),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.72,
                                ),
                            itemCount: ratedPhotos.length,
                            itemBuilder: (ctx, i) =>
                                _RatedPhotoCard(photo: ratedPhotos[i]),
                          ),

                    // ── Collections ──
                    const _CollectionsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'generate_fab',
        onPressed: () => _showGenerateSheet(context),
        icon: const Icon(Icons.auto_awesome, size: 22),
        label: const Text(
          'Create',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        extendedPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 4,
        ),
        extendedIconLabelSpacing: 10,
      ),
    );
  }

  Future<void> _uploadOutfitPhoto(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final imageService = ref.read(imageServiceProvider);
    final bytes = source == 'camera'
        ? await imageService.pickFromCamera()
        : await imageService.pickFromGallery();
    if (bytes == null) return;

    // Auto-save to calendar for today.
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final calPhotos = Map<DateTime, List<Uint8List>>.from(
      ref.read(calendarPhotosProvider),
    );
    calPhotos[todayKey] = [...(calPhotos[todayKey] ?? []), bytes];
    ref.read(calendarPhotosProvider.notifier).state = calPhotos;

    // Optimistically add the photo to My Creations with "scoring…" status,
    // then run Gemini scoring in the background and update the entry.
    final pendingPhoto = RatedPhoto(
      bytes: bytes,
      score: 0, // hidden by UI until real score arrives
      feedback: 'Analyzing your look…',
      improvements: '',
    );
    ref.read(ratedPhotosProvider.notifier).update((l) => [...l, pendingPhoto]);

    // Score via Gemini in the background
    _scoreUploadedPhoto(ref, bytes, pendingPhoto);
  }

  /// Call Gemini (via the proxy) to score the uploaded outfit photo.
  /// Minimum score shown is 7 (per product spec).
  Future<void> _scoreUploadedPhoto(
    WidgetRef ref,
    Uint8List bytes,
    RatedPhoto pending,
  ) async {
    try {
      final gemini = ref.read(geminiServiceProvider);
      if (!gemini.isGeminiConfigured) throw Exception('Gemini not configured');
      final result = await gemini.scoreFitCheck(bytes);

      // Normalize: Gemini returns 1-100, we show /10. Clamp to min 7.
      final rawTen = (result.score / 10).round().clamp(7, 10);
      final suggestion = _improvementFor(rawTen);
      final feedback = result.feedback.isNotEmpty
          ? result.feedback
          : 'Solid look — polished and wearable.';

      _replacePhoto(
        ref,
        pending,
        score: rawTen,
        feedback: feedback,
        improvements: suggestion,
      );
    } catch (_) {
      // Scoring failed — leave as unscored with an honest message.
      _replacePhoto(
        ref,
        pending,
        score: 0,
        feedback: 'Saved to your looks. AI scoring unavailable right now.',
        improvements: '',
      );
    }
  }

  void _replacePhoto(
    WidgetRef ref,
    RatedPhoto old, {
    required int score,
    required String feedback,
    required String improvements,
  }) {
    final list = [...ref.read(ratedPhotosProvider)];
    final idx = list.indexOf(old);
    if (idx == -1) return;
    list[idx] = RatedPhoto(
      bytes: old.bytes,
      networkUrl: old.networkUrl,
      isAiGenerated: old.isAiGenerated,
      score: score,
      feedback: feedback,
      improvements: improvements,
      outfitLabel: old.outfitLabel,
      buyUrl: old.buyUrl,
    );
    ref.read(ratedPhotosProvider.notifier).state = list;
  }

  String _improvementFor(int score) {
    if (score == 10) return 'Nothing to change — this is a 10/10 look!';
    if (score == 9)
      return 'To hit 10: add a statement accessory (belt, bag, or bold jewelry).';
    if (score == 8)
      return 'To hit 10: elevate footwear and add a layering piece like a blazer.';
    return 'To hit 10: tuck in the top, swap to shoes that add height, add one standout accessory.';
  }

  void _showGenerateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const GenerateSheet(),
    );
  }
}

// ─── Rated Photo Card ─────────────────────────────────────────────────────────

class _RatedPhotoCard extends ConsumerWidget {
  final RatedPhoto photo;
  const _RatedPhotoCard({required this.photo});

  Color get _scoreColor {
    if (photo.score == 10) return Colors.green;
    if (photo.score >= 9) return const Color(0xFF4CAF50);
    if (photo.score >= 8) return AppTheme.accent;
    return AppTheme.secondary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => showRatedPhotoDetail(context, ref, photo),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image — bytes (real photo) or network URL (AI outfit)
              if (photo.bytes != null)
                Image.memory(photo.bytes!, fit: BoxFit.cover)
              else if (photo.networkUrl != null)
                Image.network(
                  photo.networkUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    child: const Center(
                      child: Icon(
                        Icons.auto_awesome,
                        color: AppTheme.primary,
                        size: 40,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome,
                      color: AppTheme.primary,
                      size: 40,
                    ),
                  ),
                ),

              // AI badge
              if (photo.isAiGenerated)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 10),
                        SizedBox(width: 3),
                        Text(
                          'AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Score badge — hidden for unscored (score == 0) photos
              if (photo.score > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _scoreColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      '${photo.score}/10',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

              // Bottom gradient with feedback
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (photo.outfitLabel != null)
                        Text(
                          photo.outfitLabel!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Text(
                        photo.feedback,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (photo.score > 0 &&
                          photo.score < 10 &&
                          photo.improvements.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡 ', style: TextStyle(fontSize: 10)),
                            Expanded(
                              child: Text(
                                photo.improvements,
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 10,
                                  height: 1.3,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (photo.buyUrl != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Shop Similar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Expanded detail view for a My Creations photo ─────────────────────────────

Future<void> showRatedPhotoDetail(
  BuildContext context,
  WidgetRef ref,
  RatedPhoto photo,
) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => _RatedPhotoDetailView(photo: photo),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _RatedPhotoDetailView extends ConsumerWidget {
  final RatedPhoto photo;
  const _RatedPhotoDetailView({required this.photo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 56, 16, 140),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildPhotoImage(),
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
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (photo.outfitLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        photo.outfitLabel!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    photo.feedback,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (photo.improvements.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '💡 ${photo.improvements}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _PhotoAction(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        onTap: () => _share(context, ref),
                      ),
                      _PhotoAction(
                        icon: Icons.bookmark_add_outlined,
                        label: 'Save to\nCollection',
                        onTap: () => _saveToCollection(context, ref),
                      ),
                      _PhotoAction(
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        color: Colors.redAccent,
                        onTap: () => _delete(context, ref),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoImage() {
    if (photo.bytes != null) {
      return Image.memory(photo.bytes!, fit: BoxFit.contain);
    }
    if (photo.networkUrl != null) {
      return Image.network(
        photo.networkUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          color: AppTheme.primary.withValues(alpha: 0.1),
          padding: const EdgeInsets.all(40),
          child: const Center(
            child: Icon(Icons.auto_awesome, color: AppTheme.primary, size: 48),
          ),
        ),
      );
    }
    return Container(
      color: AppTheme.primary.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(40),
      child: const Center(
        child: Icon(Icons.auto_awesome, color: AppTheme.primary, size: 48),
      ),
    );
  }

  void _delete(BuildContext context, WidgetRef ref) {
    final list = [...ref.read(ratedPhotosProvider)];
    list.remove(photo);
    ref.read(ratedPhotosProvider.notifier).state = list;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Photo deleted')));
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final text = '${photo.outfitLabel ?? "Outfit"} — ${photo.feedback}';
    await ref.read(shareServiceProvider).shareText(text);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Look shared!')));
  }

  Future<void> _saveToCollection(BuildContext context, WidgetRef ref) async {
    // AI-generated photos have an associated local outfit we can link to.
    // For uploaded photos (bytes only), there's no outfit id yet — show an info note.
    String? outfitId;
    if (photo.isAiGenerated && photo.outfitLabel != null) {
      final localStore = ref.read(localOutfitStoreProvider);
      for (final entry in localStore.reversed) {
        if ((entry.outfit.occasion?.toUpperCase() ?? '') == photo.outfitLabel) {
          outfitId = entry.outfit.id;
          break;
        }
      }
    }
    if (outfitId == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Uploaded photos can be saved from the outfit view. Open an AI look to save it to a collection.',
          ),
        ),
      );
      return;
    }
    if (!context.mounted) return;
    await pickCollectionAndAdd(context, ref, outfitId);
  }
}

// ─── Collections tab ──────────────────────────────────────────────────────────

class _CollectionsTab extends ConsumerWidget {
  const _CollectionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionsProvider);

    if (collections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              size: 64,
              color: AppTheme.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'No collections yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Group your favorite looks into themed collections!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _createCollection(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('New Collection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${collections.length} collection${collections.length == 1 ? '' : 's'}',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
              TextButton.icon(
                onPressed: () => _createCollection(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('New'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: collections.length,
            itemBuilder: (_, i) => _CollectionCard(collection: collections[i]),
          ),
        ),
      ],
    );
  }

  Future<void> _createCollection(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Collection'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Date Night, Work, Vacation',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      ref.read(collectionsProvider.notifier).create(name);
    }
  }
}

class _CollectionCard extends ConsumerWidget {
  final OutfitCollection collection;
  const _CollectionCard({required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = collection.outfitIds.length;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.collections_bookmark, color: AppTheme.accent),
        ),
        title: Text(
          collection.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('$count outfit${count == 1 ? '' : 's'}'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'delete') {
              ref.read(collectionsProvider.notifier).delete(collection.id);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                _CollectionDetailScreen(collectionId: collection.id),
          ),
        ),
      ),
    );
  }
}

class _CollectionDetailScreen extends ConsumerWidget {
  final String collectionId;
  const _CollectionDetailScreen({required this.collectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionsProvider);
    final collection = collections.firstWhere(
      (c) => c.id == collectionId,
      orElse: () => OutfitCollection(
        id: collectionId,
        name: 'Collection',
        outfitIds: const [],
        createdAt: DateTime.now(),
      ),
    );
    final outfitsAsync = ref.watch(outfitHistoryProvider);
    final localStore = ref.watch(localOutfitStoreProvider);

    return Scaffold(
      appBar: AppBar(title: Text(collection.name)),
      body: WithDecorations(
        sparse: true,
        child: Builder(
          builder: (_) {
            if (collection.outfitIds.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 56,
                      color: AppTheme.textSecondary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No outfits in this collection yet',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Open an outfit and tap "Save to Collection"',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }

            final savedOutfits = outfitsAsync.value ?? const [];
            final resolved = [
              for (final id in collection.outfitIds)
                () {
                  final local = findLocalOutfit(localStore, id);
                  if (local != null) return local.outfit;
                  final match = savedOutfits.where((o) => o.id == id).toList();
                  return match.isEmpty ? null : match.first;
                }(),
            ].whereType<Outfit>().toList();

            if (resolved.isEmpty) {
              return const Center(
                child: Text('Saved outfits no longer available'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: resolved.length,
              itemBuilder: (_, i) {
                final outfit = resolved[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: AppTheme.primary,
                      ),
                    ),
                    title: Text(
                      outfit.occasion?.toUpperCase() ?? 'OUTFIT',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      outfit.reasoning ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => ref
                          .read(collectionsProvider.notifier)
                          .removeOutfit(collectionId, outfit.id),
                    ),
                    onTap: () => context.push('/outfit/${outfit.id}'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PhotoAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _PhotoAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable collection picker ───────────────────────────────────────────────

Future<void> pickCollectionAndAdd(
  BuildContext context,
  WidgetRef ref,
  String outfitId,
) async {
  final collections = ref.read(collectionsProvider);
  final picked = await showModalBottomSheet<OutfitCollection>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Save to Collection',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.add_circle_outline,
              color: AppTheme.primary,
            ),
            title: const Text('New collection…'),
            onTap: () async {
              final controller = TextEditingController();
              final name = await showDialog<String>(
                context: ctx,
                builder: (_) => AlertDialog(
                  title: const Text('New Collection'),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Date Night, Vacation',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(ctx, controller.text.trim()),
                      child: const Text('Create'),
                    ),
                  ],
                ),
              );
              if (name != null && name.isNotEmpty) {
                final created = ref
                    .read(collectionsProvider.notifier)
                    .create(name);
                if (ctx.mounted) Navigator.pop(ctx, created);
              }
            },
          ),
          if (collections.isNotEmpty) const Divider(height: 1),
          ...collections.map(
            (c) => ListTile(
              leading: const Icon(
                Icons.collections_bookmark,
                color: AppTheme.accent,
              ),
              title: Text(c.name),
              subtitle: Text(
                '${c.outfitIds.length} outfit${c.outfitIds.length == 1 ? '' : 's'}',
              ),
              trailing: c.outfitIds.contains(outfitId)
                  ? const Icon(Icons.check, color: AppTheme.primary)
                  : null,
              onTap: () => Navigator.pop(ctx, c),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (picked != null) {
    ref.read(collectionsProvider.notifier).addOutfit(picked.id, outfitId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Saved to "${picked.name}"')));
  }
}
