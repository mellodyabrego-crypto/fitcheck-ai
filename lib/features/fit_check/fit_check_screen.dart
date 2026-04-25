import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../widgets/decorative_symbols.dart';
import '../../services/usage_tracker.dart';
import '../../services/gemini_service.dart';
import '../../services/share_service.dart';
import '../../services/observability_service.dart';
import '../../providers/user_providers.dart';
import '../../widgets/score_dial.dart';
import '../outfits/outfit_screen.dart';

/// Minimum displayed score. The model can return anything 0-100, but we
/// clamp the *display* upward to 70 so feedback stays kind and actionable
/// (per CLAUDE.md rule #7 — feedback must still be honest, so we surface a
/// "Limited match" tag when the underlying score was below 70).
const int _kDisplayMinScore = 70;

class FitCheckScreen extends ConsumerStatefulWidget {
  final String outfitId;

  const FitCheckScreen({super.key, required this.outfitId});

  @override
  ConsumerState<FitCheckScreen> createState() => _FitCheckScreenState();
}

class _FitCheckScreenState extends ConsumerState<FitCheckScreen> {
  RichFitCheckResult? _result;
  int? _rawOverall; // un-clamped, for "Limited match" badge
  String? _occasion;
  bool _isLoading = true;
  String? _error;
  final GlobalKey _shareCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runFitCheck());
  }

  Future<void> _runFitCheck() async {
    final tracker = ref.read(usageTrackerProvider.notifier);
    if (!tracker.canDoFitCheck()) {
      if (mounted) context.go('/paywall');
      return;
    }

    try {
      // Pull outfit detail
      final detail = await ref.read(
        outfitDetailProvider(widget.outfitId).future,
      );
      _occasion = detail.outfit.occasion;
      final items = detail.items
          .where((i) => i.wardrobeItem != null)
          .map(
            (i) => {
              'name': i.wardrobeItem!.name ?? i.wardrobeItem!.category.label,
              'color': i.wardrobeItem!.color ?? 'unspecified',
              'category': i.wardrobeItem!.category.name,
            },
          )
          .toList();

      if (items.isEmpty) {
        throw const GeminiResponseException(
          'This outfit has no items to score yet.',
        );
      }

      final profile = await ref.read(styleProfileContextProvider.future);

      final gemini = ref.read(geminiServiceProvider);
      final result = await gemini.scoreFitCheckFromItems(
        occasion: _occasion ?? 'casual',
        items: items,
        profile: profile,
      );

      tracker.recordFitCheck();

      if (!mounted) return;
      setState(() {
        _rawOverall = result.overall;
        _result = result;
        _isLoading = false;
      });
    } catch (e, st) {
      Observability.capture(e, st, tags: {'op': 'fit_check'});
      if (!mounted) return;
      setState(() {
        _error = _humanError(e);
        _isLoading = false;
      });
    }
  }

  String _humanError(Object e) {
    if (e is GeminiRateLimitException) {
      return 'You\'ve hit today\'s AI limit. It resets at midnight UTC.';
    }
    if (e is GeminiAuthException) {
      return 'Your session expired. Sign out and back in to continue.';
    }
    if (e is GeminiNetworkException) {
      return 'Couldn\'t reach our AI service. Check your connection and retry.';
    }
    if (e is GeminiInputTooLargeException) {
      return 'Outfit input was too large. Trim some items and retry.';
    }
    if (e is GeminiResponseException) {
      return e.message;
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _shareScore() async {
    final result = _result;
    if (result == null) return;

    Uint8List? bytes;
    try {
      final boundary = _shareCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3.0);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        bytes = data?.buffer.asUint8List();
      }
    } catch (e, st) {
      Observability.capture(e, st, tags: {'op': 'fit_check.share.render'});
    }

    final scoreForShare =
        (_rawOverall != null && _rawOverall! < _kDisplayMinScore)
            ? _kDisplayMinScore
            : result.overall;
    final fallbackText =
        '✨ My ${(_occasion ?? "outfit").toUpperCase()} fit check on Her Style Co. — '
        '$scoreForShare/100. ${result.headline}';

    final share = ref.read(shareServiceProvider);
    bool ok;
    if (bytes != null) {
      ok = await share.shareImage(
        bytes: bytes,
        fallbackText: fallbackText,
        subject: 'My Her Style Co. fit check',
      );
    } else {
      ok = await share.shareText(
        fallbackText,
        subject: 'My Her Style Co. fit check',
      );
    }
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Couldn\'t open share — copied to clipboard.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fit Check')),
      body: WithDecorations(
        sparse: true,
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.accent),
                    SizedBox(height: 20),
                    Text(
                      'Reading your fit…',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : _error != null
                ? _ErrorView(
                    message: _error!,
                    onRetry: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      _runFitCheck();
                    },
                  )
                : _buildResult(),
      ),
    );
  }

  Widget _buildResult() {
    final result = _result!;
    final raw = _rawOverall ?? result.overall;
    final displayedScore = raw < _kDisplayMinScore ? _kDisplayMinScore : raw;
    final isClampedUp = raw < _kDisplayMinScore;

    final scoreColor = displayedScore >= 90
        ? Colors.green.shade600
        : displayedScore >= 80
            ? Colors.green.shade400
            : AppTheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Capture region for share — wraps headline + score dial in a
          // branded card. Off-screen rendering still works because RepaintBoundary
          // composites whatever's currently laid out.
          RepaintBoundary(
            key: _shareCardKey,
            child: _ShareCard(
              score: displayedScore,
              headline: result.headline,
              occasion: _occasion ?? 'outfit',
              scoreColor: scoreColor,
            ),
          ),
          if (isClampedUp) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.orange.shade800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Limited match — see the tips below to lift this fit.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Sub-score breakdown
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Breakdown',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _SubScoreBar(
                  label: 'Color Harmony',
                  score: result.colorHarmony,
                  icon: Icons.palette,
                ),
                _SubScoreBar(
                  label: 'Style Cohesion',
                  score: result.styleCohesion,
                  icon: Icons.auto_awesome,
                ),
                _SubScoreBar(
                  label: 'Occasion Fit',
                  score: result.occasionFit,
                  icon: Icons.event,
                ),
                _SubScoreBar(
                  label: 'Versatility',
                  score: result.versatility,
                  icon: Icons.swap_horiz,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Feedback card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb, color: AppTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Stylist Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  result.feedback,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          if (result.tips.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Style Tips',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...result.tips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Share button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _shareScore,
              icon: const Icon(Icons.share),
              label: const Text('Share My Score'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  final int score;
  final String headline;
  final String occasion;
  final Color scoreColor;

  const _ShareCard({
    required this.score,
    required this.headline,
    required this.occasion,
    required this.scoreColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, AppTheme.primary.withValues(alpha: 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'HER STYLE CO.',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: AppTheme.primaryDeep,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            occasion.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ScoreDial(score: score, color: scoreColor, size: 180),
          const SizedBox(height: 8),
          Text(
            '$score / 100',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: scoreColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubScoreBar extends StatelessWidget {
  final String label;
  final int score;
  final IconData icon;

  const _SubScoreBar({
    required this.label,
    required this.score,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? Colors.green
        : score >= 60
            ? AppTheme.primary
            : Colors.orange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                backgroundColor: Colors.grey.shade200,
                color: color,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 30,
            child: Text(
              '$score',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 56, color: Colors.orange.shade400),
            const SizedBox(height: 16),
            Text(
              'AI fit check failed',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
