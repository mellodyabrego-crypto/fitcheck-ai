import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../main.dart';
import '../../widgets/decorative_symbols.dart';
import '../../models/category.dart';
import '../../models/outfit.dart';
import '../../models/wardrobe_item.dart';
import '../../services/share_service.dart';
import '../../services/supabase_service.dart';
import 'outfit_controller.dart';
import 'outfit_history_screen.dart';

final outfitDetailProvider =
    FutureProvider.family<_OutfitDetail, String>((ref, outfitId) async {
  // Check local in-memory store first (for locally generated outfits)
  final localStore = ref.read(localOutfitStoreProvider);
  final local = findLocalOutfit(localStore, outfitId);
  if (local != null) {
    return _OutfitDetail(
      outfit: local.outfit,
      items: local.items
          .map((wi) =>
              _OutfitItemDetail(slot: wi.category.name, wardrobeItem: wi))
          .toList(),
    );
  }

  if (kDemoMode) {
    return _OutfitDetail(
      outfit: Outfit(
        id: outfitId,
        userId: 'demo',
        occasion: 'casual',
        reasoning:
            'The white tee and slim jeans create a timeless casual look. White sneakers keep everything cohesive and clean.',
        createdAt: DateTime.now(),
      ),
      items: [
        _OutfitItemDetail(
            slot: 'top',
            wardrobeItem: WardrobeItem(
              id: '1',
              userId: 'demo',
              category: ClothingCategory.tops,
              color: 'White',
              imagePath: 'demo',
              name: 'White Tee',
              createdAt: DateTime.now(),
            )),
        _OutfitItemDetail(
            slot: 'bottom',
            wardrobeItem: WardrobeItem(
              id: '3',
              userId: 'demo',
              category: ClothingCategory.bottoms,
              color: 'Dark Blue',
              imagePath: 'demo',
              name: 'Slim Jeans',
              createdAt: DateTime.now(),
            )),
        _OutfitItemDetail(
            slot: 'shoes',
            wardrobeItem: WardrobeItem(
              id: '5',
              userId: 'demo',
              category: ClothingCategory.shoes,
              color: 'White',
              imagePath: 'demo',
              name: 'White Sneakers',
              createdAt: DateTime.now(),
            )),
      ],
    );
  }

  try {
    final supabase = ref.read(supabaseServiceProvider);
    if (supabase == null) throw StateError('Supabase not configured');
    final outfits = await supabase.getOutfits();
    final outfit = outfits.firstWhere((o) => o.id == outfitId);
    final outfitItems = await supabase.getOutfitItems(outfitId);
    final wardrobeItems = await supabase.getWardrobeItems();

    final itemsWithDetails = outfitItems.map((oi) {
      final wardrobeItem =
          wardrobeItems.where((wi) => wi.id == oi.wardrobeItemId).firstOrNull;
      return _OutfitItemDetail(slot: oi.slot, wardrobeItem: wardrobeItem);
    }).toList();

    return _OutfitDetail(outfit: outfit, items: itemsWithDetails);
  } catch (e) {
    // Surface the real error to the caller — the UI's FutureProvider error
    // state will render a proper message instead of a fake "Outfit not found".
    rethrow;
  }
});

class OutfitScreen extends ConsumerStatefulWidget {
  final String outfitId;

  const OutfitScreen({super.key, required this.outfitId});

  @override
  ConsumerState<OutfitScreen> createState() => _OutfitScreenState();
}

class _OutfitScreenState extends ConsumerState<OutfitScreen> {
  bool _isRegenerating = false;

  String get outfitId => widget.outfitId;

  Future<void> _generateAgain(String occasion) async {
    setState(() => _isRegenerating = true);
    try {
      final newOutfit = await ref
          .read(outfitControllerProvider.notifier)
          .generateOutfit(occasion);
      if (!mounted) return;
      context.pushReplacement('/outfit/${newOutfit.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to regenerate: $e')),
      );
    } finally {
      if (mounted) setState(() => _isRegenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(outfitDetailProvider(outfitId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Outfit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Save to Collection',
            onPressed: () => pickCollectionAndAdd(context, ref, outfitId),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final detail = ref.read(outfitDetailProvider(outfitId)).value;
              if (detail == null) return;
              final items = detail.items
                  .where((i) => i.wardrobeItem != null)
                  .map((i) => i.wardrobeItem!)
                  .toList();
              final shared =
                  await ref.read(shareServiceProvider).shareOutfitCard(
                        occasion: detail.outfit.occasion ?? 'outfit',
                        items: items,
                      );
              if (!shared && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Outfit copied to clipboard!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: WithDecorations(
        sparse: true,
        child: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (detail) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Occasion badge
                if (detail.outfit.occasion != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        detail.outfit.occasion!.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Outfit items grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: detail.items.length,
                  itemBuilder: (context, index) {
                    final item = detail.items[index];
                    return _OutfitItemCard(item: item);
                  },
                ),

                const SizedBox(height: 24),

                // Reasoning
                if (detail.outfit.reasoning != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: AppTheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            detail.outfit.reasoning!,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Generate Again button
                OutlinedButton.icon(
                  onPressed: _isRegenerating
                      ? null
                      : () =>
                          _generateAgain(detail.outfit.occasion ?? 'casual'),
                  icon: _isRegenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.primary),
                        )
                      : const Icon(Icons.refresh),
                  label:
                      Text(_isRegenerating ? 'Generating…' : 'Generate Again'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Fit Check button
                ElevatedButton.icon(
                  onPressed: () => context.push('/fit-check/$outfitId'),
                  icon: const Icon(Icons.star),
                  label: const Text('Get Fit Check Score'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutfitItemCard extends StatelessWidget {
  final _OutfitItemDetail item;

  const _OutfitItemCard({required this.item});

  Color _colorFromName(String? colorName) {
    return switch (colorName?.toLowerCase()) {
      'white' || 'ivory' || 'champagne' => Colors.blueGrey.shade200,
      'black' => Colors.grey.shade800,
      'dark blue' || 'navy' => Colors.indigo.shade400,
      'light blue' => Colors.lightBlue.shade300,
      'khaki' || 'beige' || 'camel' => Colors.amber.shade300,
      'brown' || 'tan' => Colors.brown.shade400,
      'silver' || 'grey' || 'gray' => Colors.blueGrey.shade300,
      'pink' || 'hot pink' || 'coral' => Colors.pink.shade300,
      'red' => Colors.red.shade400,
      'green' || 'emerald' => Colors.green.shade400,
      'gold' || 'yellow' => Colors.amber.shade600,
      'purple' || 'violet' => Colors.purple.shade400,
      'floral' => AppTheme.accent,
      _ => AppTheme.primary.withValues(alpha: 0.6),
    };
  }

  // Shop URL based on category/name
  String _shopUrl(WardrobeItem? wi) {
    if (wi == null) return 'https://fashionnova.com';
    return switch (wi.category) {
      ClothingCategory.dresses => 'https://fashionnova.com/collections/dresses',
      ClothingCategory.tops => 'https://fashionnova.com/collections/tops',
      ClothingCategory.bottoms => 'https://fashionnova.com/collections/bottoms',
      ClothingCategory.shoes => 'https://stevemadden.com',
      ClothingCategory.bags => 'https://fashionnova.com/collections/bags',
      ClothingCategory.accessories => 'https://mejuri.com',
      ClothingCategory.outerwear => 'https://zara.com',
    };
  }

  @override
  Widget build(BuildContext context) {
    final wi = item.wardrobeItem;
    final hasUrl = wi?.imagePath.startsWith('http') ?? false;

    return GestureDetector(
      onTap: () async {
        final url = wi?.imagePath.startsWith('http') == true
            ? _shopUrl(wi)
            : _shopUrl(wi);
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri))
          launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Show real Unsplash photo if available, else color swatch
                    if (hasUrl)
                      Image.network(
                        wi!.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: _colorFromName(wi.color),
                          child: Center(
                            child: Icon(wi.category.icon ?? Icons.checkroom,
                                size: 32, color: Colors.white70),
                          ),
                        ),
                        loadingBuilder: (ctx, child, prog) {
                          if (prog == null) return child;
                          return Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          );
                        },
                      )
                    else
                      Container(
                        color: _colorFromName(wi?.color),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                wi?.category.icon ?? Icons.checkroom,
                                size: 32,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                wi?.name ?? item.slot,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // "Shop" overlay badge
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined,
                                color: Colors.white70, size: 11),
                            SizedBox(width: 3),
                            Text('Shop',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                children: [
                  Text(
                    wi?.name ?? item.slot,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.slot.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutfitDetail {
  final Outfit outfit;
  final List<_OutfitItemDetail> items;

  _OutfitDetail({required this.outfit, required this.items});
}

class _OutfitItemDetail {
  final String slot;
  final WardrobeItem? wardrobeItem;

  _OutfitItemDetail({required this.slot, this.wardrobeItem});
}
