import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/extensions.dart';
import '../../services/usage_tracker.dart';
import '../../services/weather_service.dart';
import 'outfit_controller.dart';

// Color seasons for palette selection
const _colorSeasons = ['Spring', 'Summer', 'Autumn', 'Winter'];

class GenerateSheet extends ConsumerStatefulWidget {
  const GenerateSheet({super.key});

  @override
  ConsumerState<GenerateSheet> createState() => _GenerateSheetState();
}

class _GenerateSheetState extends ConsumerState<GenerateSheet> {
  String _occasion = 'casual';
  String? _colorSeason;
  bool _fromScratch = false;
  bool _isGenerating = false;

  static const _occasions = [
    ('casual',    'Casual',     Icons.weekend),
    ('work',      'Work',       Icons.business_center),
    ('date_night','Date Night', Icons.favorite),
    ('formal',    'Formal',     Icons.diamond),
    ('workout',   'Workout',    Icons.fitness_center),
    ('outdoor',   'Outdoor',    Icons.park),
  ];

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(weatherProvider);
    final todayWeather = weatherAsync.value?[DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day)];

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Generate Outfit',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Let AI style you based on your palette & trends',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),

            // Weather strip
            if (todayWeather != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: todayWeather.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: todayWeather.color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(todayWeather.icon, size: 16, color: todayWeather.color),
                    const SizedBox(width: 6),
                    Text(
                      '${todayWeather.description} · ${todayWeather.tempRange} — outfit adapted for weather',
                      style: TextStyle(fontSize: 12, color: todayWeather.color,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            // ── Generation mode ──
            const Text('Generate from',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: 'My Wardrobe',
                    icon: Icons.checkroom,
                    selected: !_fromScratch,
                    onTap: () => setState(() => _fromScratch = false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeButton(
                    label: 'Scratch\n(Trending)',
                    icon: Icons.trending_up,
                    selected: _fromScratch,
                    onTap: () => setState(() => _fromScratch = true),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── Occasion ──
            const Text('Occasion',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _occasions.map((o) {
                final isSelected = _occasion == o.$1;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(o.$3, size: 14),
                      const SizedBox(width: 4),
                      Text(o.$2, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _occasion = o.$1),
                  selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // ── Color Season ──
            const Text('My Color Season',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Auto-detect', style: TextStyle(fontSize: 12)),
                  selected: _colorSeason == null,
                  onSelected: (_) => setState(() => _colorSeason = null),
                  selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                ),
                ..._colorSeasons.map((s) => ChoiceChip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      selected: _colorSeason == s,
                      onSelected: (_) => setState(() => _colorSeason = s),
                      selectedColor: AppTheme.accent.withValues(alpha: 0.3),
                    )),
              ],
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isGenerating ? null : _generate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isGenerating
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white)),
                        SizedBox(width: 12),
                        Text('Styling your look...'),
                      ],
                    )
                  : const Text('Generate Outfit'),
            ),

            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, _) {
                final remaining = ref
                    .watch(usageTrackerProvider.notifier)
                    .remainingOutfitsText;
                return Text(remaining,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generate() async {
    final tracker = ref.read(usageTrackerProvider.notifier);
    if (!tracker.canGenerateOutfit()) {
      if (mounted) {
        Navigator.pop(context);
        context.push('/paywall');
      }
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final outfit = await ref
          .read(outfitControllerProvider.notifier)
          .generateOutfit(
            _occasion,
            colorSeason: _colorSeason,
            fromScratch: _fromScratch,
          );

      tracker.recordOutfitGeneration();

      if (mounted) {
        Navigator.pop(context);
        context.push('/outfit/${outfit.id}');
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to generate outfit: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
                size: 22),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppTheme.primary : AppTheme.textSecondary,
                    height: 1.3)),
          ],
        ),
      ),
    );
  }
}
