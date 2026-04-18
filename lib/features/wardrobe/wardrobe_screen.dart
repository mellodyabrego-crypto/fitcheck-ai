import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../models/category.dart';
import '../../widgets/decorative_symbols.dart';
import '../../widgets/clothing_grid_tile.dart';
import 'wardrobe_controller.dart';
import 'item_detail_screen.dart';

// null = folder view, a category = filtered items view
final selectedCategoryProvider = StateProvider<ClothingCategory?>((ref) => null);
final _showingFolderView = StateProvider<bool>((ref) => true);

class WardrobeScreen extends ConsumerWidget {
  const WardrobeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showFolders = ref.watch(_showingFolderView);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          showFolders ? 'My Closet' : (selectedCategory?.label ?? 'My Closet'),
        ),
        leading: showFolders
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref.read(selectedCategoryProvider.notifier).state = null;
                  ref.read(_showingFolderView.notifier).state = true;
                },
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: () => context.push('/wardrobe/add'),
          ),
        ],
      ),
      body: WithDecorations(
        sparse: true,
        child: showFolders
            ? _FolderGrid(onCategoryTap: (cat) {
                ref.read(selectedCategoryProvider.notifier).state = cat;
                ref.read(_showingFolderView.notifier).state = false;
              })
            : _ItemsGrid(category: selectedCategory),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'wardrobe_fab',
        onPressed: () => context.push('/wardrobe/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ─── Folder Grid ────────────────────────────────────────────────────────────

class _FolderGrid extends ConsumerWidget {
  final void Function(ClothingCategory?) onCategoryTap;
  const _FolderGrid({required this.onCategoryTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wardrobeAsync = ref.watch(wardrobeControllerProvider);

    return wardrobeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        // Use sample items for counts when wardrobe is empty
        final source = items.isEmpty ? sampleWardrobeItems : items;
        final counts = <ClothingCategory, int>{};
        for (final item in source) {
          counts[item.category] = (counts[item.category] ?? 0) + 1;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── App name header (matches login screen style) ─────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 20, top: 4),
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFC48A96), Color(0xFFB89A5D)],
                      ).createShader(bounds),
                      child: Text(
                        'Her Style Co.',
                        style: GoogleFonts.pacifico(
                          fontSize: 34,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12, left: 4),
                child: Text(
                  'All',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.9,
                children: [
                  // Category folders — gold outline design, no background images
                  ...ClothingCategory.values.map((cat) => _FolderTile(
                        icon: cat.icon,
                        label: cat.label,
                        count: counts[cat] ?? 0,
                        color: _categoryColor(cat),
                        onTap: () => onCategoryTap(cat),
                      )),
                  // Your Runway Creations
                  _FolderTile(
                    icon: Icons.auto_awesome,
                    label: 'Runway\nCreations',
                    count: 0,
                    color: AppTheme.accent,
                    onTap: () => context.go('/home'),
                    badge: 'Outfits',
                  ),
                  // Create a New Look
                  _FolderTile(
                    icon: Icons.add_circle_outline,
                    label: 'Create a\nNew Look',
                    count: null,
                    color: AppTheme.primary,
                    onTap: () => GoRouter.of(context).push('/generate'),
                    badge: 'Generate',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _categoryEmoji(ClothingCategory cat) {
    return switch (cat) {
      ClothingCategory.tops        => '👚',
      ClothingCategory.bottoms     => '👖',
      ClothingCategory.dresses     => '👗',
      ClothingCategory.shoes       => '👠',
      ClothingCategory.outerwear   => '🧥',
      ClothingCategory.accessories => '💍',
      ClothingCategory.bags        => '👜',
    };
  }

  Color _categoryColor(ClothingCategory cat) => AppTheme.primary;
}

class _FolderTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
  final String? emoji;

  const _FolderTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
    this.badge,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gold-tinted icon circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.30), width: 1),
              ),
              alignment: Alignment.center,
              child: emoji != null
                  ? Text(emoji!, style: const TextStyle(fontSize: 26))
                  : Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.30)),
                ),
                child: Text(badge!,
                    style: TextStyle(
                        fontSize: 9, color: color, fontWeight: FontWeight.w700)),
              )
            else
              Text(
                count == 0 ? 'Empty' : '$count item${count == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Items Grid (filtered by category) ───────────────────────────────────────

class _ItemsGrid extends ConsumerWidget {
  final ClothingCategory? category;
  const _ItemsGrid({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wardrobeAsync = ref.watch(wardrobeControllerProvider);

    return wardrobeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        final isSample = items.isEmpty;
        final source = isSample ? sampleWardrobeItems : items;
        final filtered = category == null
            ? source
            : source.where((i) => i.category == category).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category?.icon ?? Icons.checkroom, size: 64,
                    color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text(
                  'No ${category?.label ?? 'items'} yet',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text('Tap + to add your first item!',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          );
        }

        return Column(
          children: [
            if (isSample)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Example items — tap + to add your own!',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.72,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return ClothingGridTile(
                    item: item,
                    onTap: isSample
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ItemDetailScreen(item: item),
                              ),
                            ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
