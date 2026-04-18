import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/extensions.dart';
import '../../services/usage_tracker.dart';
import '../../services/weather_service.dart';
import '../../widgets/decorative_symbols.dart';
import 'outfit_controller.dart';

const _colorSeasons = ['Spring', 'Summer', 'Autumn', 'Winter'];

class GenerateScreen extends ConsumerStatefulWidget {
  const GenerateScreen({super.key});

  @override
  ConsumerState<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends ConsumerState<GenerateScreen> {
  String _occasion = 'casual';
  String? _colorSeason;
  bool _fromScratch = false;
  bool _isGenerating = false;

  static const _occasions = [
    ('casual',     'Casual',     Icons.weekend),
    ('work',       'Work',       Icons.business_center),
    ('date_night', 'Date Night', Icons.favorite),
    ('formal',     'Formal',     Icons.diamond),
    ('workout',    'Workout',    Icons.fitness_center),
    ('outdoor',    'Outdoor',    Icons.park),
    ('brunch',     'Brunch',     Icons.local_cafe),
    ('party',      'Party',      Icons.celebration),
  ];

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(weatherProvider);
    final todayWeather = weatherAsync.value?[DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day)];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create an Outfit'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: WithDecorations(
        sparse: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Stylist',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18)),
                          Text('Styled for your palette, weather & trends',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Weather
              if (todayWeather != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: todayWeather.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: todayWeather.color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(todayWeather.icon,
                          size: 16, color: todayWeather.color),
                      const SizedBox(width: 8),
                      Text(
                        '${todayWeather.description} · ${todayWeather.tempRange} — outfit adapted for weather',
                        style: TextStyle(
                            fontSize: 12,
                            color: todayWeather.color,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Generation mode
              const Text('Generate from',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ModeCard(
                      label: 'My Wardrobe',
                      subtitle: 'Uses your saved items',
                      icon: Icons.checkroom,
                      selected: !_fromScratch,
                      onTap: () => setState(() => _fromScratch = false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ModeCard(
                      label: 'Trending',
                      subtitle: 'Fresh AI-curated look',
                      icon: Icons.trending_up,
                      selected: _fromScratch,
                      onTap: () => setState(() => _fromScratch = true),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Occasion
              const Text('Occasion',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _occasions.map((o) {
                  final isSelected = _occasion == o.$1;
                  return GestureDetector(
                    onTap: () => setState(() => _occasion = o.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(o.$3,
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textSecondary),
                          const SizedBox(width: 5),
                          Text(
                            o.$2,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Color Season
              const Text('My Color Season',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SeasonChip(
                    label: 'Auto',
                    selected: _colorSeason == null,
                    color: AppTheme.primary,
                    onTap: () => setState(() => _colorSeason = null),
                  ),
                  ..._colorSeasons.map((s) => _SeasonChip(
                        label: s,
                        selected: _colorSeason == s,
                        color: _seasonColor(s),
                        onTap: () => setState(() => _colorSeason = s),
                      )),
                ],
              ),

              const SizedBox(height: 32),

              // Generate button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isGenerating
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white)),
                            SizedBox(width: 12),
                            Text('Creating your look...',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('Create My Outfit',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 10),
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
      ),
    );
  }

  Color _seasonColor(String season) => switch (season) {
        'Spring' => const Color(0xFFE8955A),
        'Summer' => const Color(0xFF9BB7D4),
        'Autumn' => const Color(0xFFB5651D),
        'Winter' => const Color(0xFF5B7FA6),
        _ => AppTheme.primary,
      };

  Future<void> _generate() async {
    final tracker = ref.read(usageTrackerProvider.notifier);
    if (!tracker.canGenerateOutfit()) {
      context.push('/paywall');
      return;
    }
    setState(() => _isGenerating = true);
    try {
      final outfit = await ref
          .read(outfitControllerProvider.notifier)
          .generateOutfit(_occasion,
              colorSeason: _colorSeason, fromScratch: _fromScratch);
      tracker.recordOutfitGeneration();
      if (mounted) {
        context.pushReplacement('/outfit/${outfit.id}');
      }
    } catch (e) {
      if (mounted) context.showSnackBar('Failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}

class _ModeCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              selected ? AppTheme.primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
                size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppTheme.primary : AppTheme.textPrimary)),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10,
                    color: selected
                        ? AppTheme.primary.withValues(alpha: 0.7)
                        : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _SeasonChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _SeasonChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : Colors.grey.shade300, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
