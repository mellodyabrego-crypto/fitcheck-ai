// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';

const _walkthroughStorageKey = 'fitcheck_walkthrough_seen';

bool _loadWalkthroughSeen() {
  try {
    return html.window.localStorage[_walkthroughStorageKey] == '1';
  } catch (_) {
    return false;
  }
}

void _saveWalkthroughSeen() {
  try {
    html.window.localStorage[_walkthroughStorageKey] = '1';
  } catch (_) {
    // localStorage unavailable — walkthrough will show again next reload
  }
}

// Tracks whether the user has seen the walkthrough (persisted across sessions)
final walkthroughSeenProvider = StateProvider<bool>((ref) => _loadWalkthroughSeen());

class WalkthroughOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const WalkthroughOverlay({super.key, required this.child});

  @override
  ConsumerState<WalkthroughOverlay> createState() => _WalkthroughOverlayState();
}

class _WalkthroughOverlayState extends ConsumerState<WalkthroughOverlay> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final seen = ref.read(walkthroughSeenProvider);
      if (!seen && mounted) _showWalkthrough();
    });
  }

  void _showWalkthrough() {
    ref.read(walkthroughSeenProvider.notifier).state = true;
    _saveWalkthroughSeen();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _WalkthroughDialog(),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _WalkthroughDialog extends StatefulWidget {
  const _WalkthroughDialog();
  @override
  State<_WalkthroughDialog> createState() => _WalkthroughDialogState();
}

class _WalkthroughDialogState extends State<_WalkthroughDialog> {
  int _step = 0;

  static const _steps = [
    _Step(
      icon: Icons.checkroom,
      title: 'My Closet',
      body: 'Upload and organize every piece in your wardrobe by category. Tops, dresses, shoes, bags — all in one place.',
      color: AppTheme.primary,
    ),
    _Step(
      icon: Icons.auto_awesome,
      title: 'Outfits',
      body: 'Tap Create to let our AI stylist build a full outfit from your closet. It picks tops, bottoms, shoes, accessories — all matched for you.',
      color: AppTheme.accent,
    ),
    _Step(
      icon: Icons.shopping_bag,
      title: 'Shop',
      body: 'Browse curated picks matched to your color palette. Tap the camera button to photo-check any item before you buy.',
      color: AppTheme.primaryDeep,
    ),
    _Step(
      icon: Icons.people,
      title: 'The Network',
      body: 'Share your looks, vote on style polls, and get inspired by the community. Tap a hashtag to filter by trend.',
      color: AppTheme.accent,
    ),
    _Step(
      icon: Icons.calendar_month,
      title: 'Calendar',
      body: 'Log what you wore each day with notes and photos. Weather icons show the forecast so you can plan outfits ahead.',
      color: AppTheme.primary,
    ),
    _Step(
      icon: Icons.play_circle,
      title: 'Fashion & Beauty',
      body: 'Swipe through style tutorials, articles from Vogue & Byrdie, trend reports, and skincare guides — all in one feed.',
      color: AppTheme.primaryDeep,
    ),
    _Step(
      icon: Icons.person,
      title: 'Your Profile',
      body: 'Set your sizes, color palette, favorite brands, and social links. Edit your display name and profile photo anytime.',
      color: AppTheme.accent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    final isLast = _step == _steps.length - 1;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_steps.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _step ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _step ? step.color : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: step.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(step.icon, color: step.color, size: 36),
            ),
            const SizedBox(height: 18),

            // Title
            Text(step.title,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: step.color)),
            const SizedBox(height: 12),

            // Body
            Text(step.body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 28),

            // Buttons
            Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _step--),
                      child: const Text('Back'),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isLast) {
                        Navigator.pop(context);
                      } else {
                        setState(() => _step++);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: step.color),
                    child: Text(isLast ? "Let's Go!" : 'Next'),
                  ),
                ),
              ],
            ),

            if (!isLast) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Skip tour',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ),
            ],
          ],
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
  const _Step({required this.icon, required this.title, required this.body, required this.color});
}
