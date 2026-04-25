import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../widgets/decorative_symbols.dart';

/// First-time-only "how to use the app" tour shown after Reviews.
/// Differs from `WalkthroughOverlay` (the in-app tooltip tour) — this is a
/// full-screen hero sequence that introduces the 5 core surfaces.
class WalkthroughScreen extends StatefulWidget {
  const WalkthroughScreen({super.key});

  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _steps = <_Step>[
    _Step(
      icon: Icons.checkroom_outlined,
      title: 'Build your closet',
      body:
          'Snap or upload everything you own. We tag each piece, learn your palette, and use it for every suggestion.',
      color: Color(0xFFC48A96),
    ),
    _Step(
      icon: Icons.auto_awesome_outlined,
      title: 'Generate outfits',
      body:
          'Tell us the occasion — “summer brunch” or “first date” — and we’ll style a head-to-toe look from your closet.',
      color: Color(0xFFB89A5D),
    ),
    _Step(
      icon: Icons.calendar_month_outlined,
      title: 'Plan your week',
      body:
          'Drag outfits onto the calendar. We pull tomorrow’s weather and adjust automatically.',
      color: Color(0xFFA96E7A),
    ),
    _Step(
      icon: Icons.shopping_bag_outlined,
      title: 'Shop your gaps',
      body:
          'See what your closet is missing for the looks you love — curated, palette-matched, never men’s.',
      color: Color(0xFFD8A7B1),
    ),
    _Step(
      icon: Icons.favorite_outline,
      title: 'It learns you',
      body:
          'Every outfit you keep or skip teaches us your taste. Suggestions get sharper with every wear.',
      color: Color(0xFFC6A96B),
    ),
  ];

  void _next() {
    if (_index < _steps.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WithDecorations(
        sparse: true,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(
                      'Skip',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _steps.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _StepView(step: _steps[i]),
                ),
              ),
              // Page dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active
                          ? AppTheme.primary
                          : AppTheme.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _next,
                    child: Text(
                      _index == _steps.length - 1
                          ? 'Enter Her Style Co.'
                          : 'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _Step {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const _Step({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
}

class _StepView extends StatelessWidget {
  final _Step step;
  const _StepView({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: step.color.withValues(alpha: 0.14),
            ),
            child: Icon(step.icon, size: 60, color: step.color),
          ),
          const SizedBox(height: 32),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            step.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.5,
              height: 1.55,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
