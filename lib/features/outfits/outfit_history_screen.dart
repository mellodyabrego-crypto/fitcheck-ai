import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../main.dart';
import '../../providers/photo_providers.dart';
import '../../widgets/decorative_symbols.dart';
import '../../models/outfit.dart';
import '../../services/supabase_service.dart';
import '../../services/image_service.dart';
import '../../services/gemini_service.dart';
import '../calendar/calendar_screen.dart';
import 'generate_sheet.dart';

final outfitHistoryProvider = FutureProvider<List<Outfit>>((ref) async {
  if (kDemoMode) {
    return [
      Outfit(
        id: 'demo-1', userId: 'demo', occasion: 'casual',
        reasoning: 'The white tee pairs perfectly with slim jeans for an effortless casual look.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Outfit(
        id: 'demo-2', userId: 'demo', occasion: 'date_night',
        reasoning: 'The Oxford shirt with chinos creates a smart-casual vibe. Chelsea boots elevate the look.',
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
    final ratedPhotos  = ref.watch(ratedPhotosProvider);

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
          length: 2,
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
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // ── AI Generated outfits ──
                    outfitsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (outfits) {
                        if (outfits.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_awesome, size: 64,
                                    color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                                const SizedBox(height: 16),
                                const Text('No creations yet',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                Text('Tap Create to generate your first look!',
                                    style: TextStyle(color: AppTheme.textSecondary)),
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
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.auto_awesome, color: AppTheme.primary),
                                ),
                                title: Text(
                                  outfit.occasion?.toUpperCase() ?? 'OUTFIT',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  outfit.reasoning ?? 'Tap to view',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => context.push('/outfit/${outfit.id}'),
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
                                Icon(Icons.photo_camera, size: 64,
                                    color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                                const SizedBox(height: 16),
                                const Text('No photos yet',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                Text('Upload a photo or generate an AI outfit!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppTheme.textSecondary)),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () => _uploadOutfitPhoto(context, ref),
                                  icon: const Icon(Icons.add_a_photo),
                                  label: const Text('Upload Photo'),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: ratedPhotos.length,
                            itemBuilder: (ctx, i) => _RatedPhotoCard(photo: ratedPhotos[i]),
                          ),
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
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Create'),
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _uploadOutfitPhoto(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, 'camera')),
          ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery')),
        ]),
      ),
    );
    if (source == null) return;
    final imageService = ref.read(imageServiceProvider);
    final bytes = source == 'camera'
        ? await imageService.pickFromCamera()
        : await imageService.pickFromGallery();
    if (bytes == null) return;

    // Auto-save to calendar for today.
    final today    = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final calPhotos = Map<DateTime, List<Uint8List>>.from(
        ref.read(calendarPhotosProvider));
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
      WidgetRef ref, Uint8List bytes, RatedPhoto pending) async {
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

      _replacePhoto(ref, pending,
          score: rawTen, feedback: feedback, improvements: suggestion);
    } catch (_) {
      // Scoring failed — leave as unscored with an honest message.
      _replacePhoto(ref, pending,
          score: 0,
          feedback: 'Saved to your looks. AI scoring unavailable right now.',
          improvements: '');
    }
  }

  void _replacePhoto(WidgetRef ref, RatedPhoto old,
      {required int score, required String feedback, required String improvements}) {
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
    if (score == 9)  return 'To hit 10: add a statement accessory (belt, bag, or bold jewelry).';
    if (score == 8)  return 'To hit 10: elevate footwear and add a layering piece like a blazer.';
    return 'To hit 10: tuck in the top, swap to shoes that add height, add one standout accessory.';
  }

  void _showGenerateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const GenerateSheet(),
    );
  }
}

// ─── Rated Photo Card ─────────────────────────────────────────────────────────

class _RatedPhotoCard extends StatelessWidget {
  final RatedPhoto photo;
  const _RatedPhotoCard({required this.photo});

  Color get _scoreColor {
    if (photo.score == 10) return Colors.green;
    if (photo.score >= 9)  return const Color(0xFF4CAF50);
    if (photo.score >= 8)  return AppTheme.accent;
    return AppTheme.secondary;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: photo.buyUrl != null
          ? () async {
              // tapping an AI card navigates to the outfit
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4)),
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
                        child: Icon(Icons.auto_awesome,
                            color: AppTheme.primary, size: 40)),
                  ),
                )
              else
                Container(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  child: const Center(
                      child: Icon(Icons.auto_awesome,
                          color: AppTheme.primary, size: 40)),
                ),

              // AI badge
              if (photo.isAiGenerated)
                Positioned(
                  top: 10, left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 10),
                        SizedBox(width: 3),
                        Text('AI', style: TextStyle(color: Colors.white,
                            fontSize: 10, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),

              // Score badge — hidden for unscored (score == 0) photos
              if (photo.score > 0)
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _scoreColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4)
                      ],
                    ),
                    child: Text(
                      '${photo.score}/10',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13),
                    ),
                  ),
                ),

              // Bottom gradient with feedback
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                        Text(photo.outfitLabel!,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      Text(photo.feedback,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      if (photo.score > 0 && photo.score < 10 && photo.improvements.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡 ', style: TextStyle(fontSize: 10)),
                            Expanded(
                              child: Text(photo.improvements,
                                  style: const TextStyle(
                                      color: Colors.amber,
                                      fontSize: 10,
                                      height: 1.3),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                      if (photo.buyUrl != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Shop Similar',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700)),
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
