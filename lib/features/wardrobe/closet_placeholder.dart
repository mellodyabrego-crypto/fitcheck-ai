import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../models/category.dart';

/// Three premium directions for the empty-state on My Closet.
/// Pick one by changing [kClosetPlaceholderStyle] below.
///
/// 1. `editorial`  — magazine-style stacked silhouettes with serif headline.
/// 2. `sketched`   — soft hand-drawn-feel icon orbiting the category symbol.
/// 3. `mannequin`  — outlined fashion croquis shape with category badge.
///
/// All three respect the palette in `AppTheme` — no new hex values introduced
/// (CLAUDE.md hard rule #8).
enum ClosetPlaceholderStyle { editorial, sketched, mannequin }

const ClosetPlaceholderStyle kClosetPlaceholderStyle =
    ClosetPlaceholderStyle.editorial;

class ClosetPlaceholder extends StatelessWidget {
  final ClothingCategory? category;
  final VoidCallback? onAdd;

  const ClosetPlaceholder({super.key, this.category, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return switch (kClosetPlaceholderStyle) {
      ClosetPlaceholderStyle.editorial => _EditorialPlaceholder(
          category: category,
          onAdd: onAdd,
        ),
      ClosetPlaceholderStyle.sketched => _SketchedPlaceholder(
          category: category,
          onAdd: onAdd,
        ),
      ClosetPlaceholderStyle.mannequin => _MannequinPlaceholder(
          category: category,
          onAdd: onAdd,
        ),
    };
  }
}

// ─── Direction 1: Editorial ──────────────────────────────────────────────
// Stacked translucent shape silhouettes with a serif "ISSUE 01" headline
// — leans into the fashion-magazine feel.
class _EditorialPlaceholder extends StatelessWidget {
  final ClothingCategory? category;
  final VoidCallback? onAdd;
  const _EditorialPlaceholder({this.category, this.onAdd});

  @override
  Widget build(BuildContext context) {
    final label = category?.label ?? 'Closet';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Stacked shape silhouettes
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 8,
                  left: 28,
                  child: Container(
                    width: 110,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.18),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(60),
                        topRight: Radius.circular(60),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 18,
                  child: Container(
                    width: 90,
                    height: 130,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    category?.icon ?? Icons.checkroom_outlined,
                    size: 32,
                    color: AppTheme.primaryDeep,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ISSUE — 01',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 4,
              fontWeight: FontWeight.w800,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your $label, blank canvas',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Add your first piece — every great wardrobe starts with one.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          if (onAdd != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add an item'),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Direction 2: Sketched ───────────────────────────────────────────────
// Three concentric soft rings with a hand-drawn-feel icon — friendlier,
// "art journal" vibe.
class _SketchedPlaceholder extends StatelessWidget {
  final ClothingCategory? category;
  final VoidCallback? onAdd;
  const _SketchedPlaceholder({this.category, this.onAdd});

  @override
  Widget build(BuildContext context) {
    final label = category?.label ?? 'closet';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _Ring(diameter: 200, color: AppTheme.primary, alpha: 0.10),
                _Ring(diameter: 160, color: AppTheme.accent, alpha: 0.18),
                _Ring(diameter: 120, color: AppTheme.primary, alpha: 0.28),
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.18),
                        AppTheme.accent.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                  child: Icon(
                    category?.icon ?? Icons.checkroom_outlined,
                    size: 38,
                    color: AppTheme.primaryDeep,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'A blank $label is a blessing',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Snap or upload a piece — we\'ll handle the rest.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          if (onAdd != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Add your first piece'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double diameter;
  final Color color;
  final double alpha;
  const _Ring({
    required this.diameter,
    required this.color,
    required this.alpha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: alpha), width: 1.5),
      ),
    );
  }
}

// ─── Direction 3: Mannequin ──────────────────────────────────────────────
// Outlined fashion croquis shape — minimalist boutique aesthetic.
class _MannequinPlaceholder extends StatelessWidget {
  final ClothingCategory? category;
  final VoidCallback? onAdd;
  const _MannequinPlaceholder({this.category, this.onAdd});

  @override
  Widget build(BuildContext context) {
    final label = category?.label ?? 'closet';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 200,
            child: CustomPaint(
              painter: _CroquisPainter(
                outline: AppTheme.primary.withValues(alpha: 0.55),
                fill: AppTheme.primary.withValues(alpha: 0.06),
              ),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.accent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDeep,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Dress the form',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Add a piece and watch your $label come to life.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          if (onAdd != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add an item'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CroquisPainter extends CustomPainter {
  final Color outline;
  final Color fill;
  _CroquisPainter({required this.outline, required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final paintFill = Paint()
      ..color = fill
      ..style = PaintingStyle.fill;
    final paintLine = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final w = size.width;
    final h = size.height;

    // Head
    final head = Rect.fromCircle(center: Offset(w / 2, 22), radius: 16);
    canvas.drawOval(head, paintFill);
    canvas.drawOval(head, paintLine);

    // Body silhouette (hourglass)
    final body = Path()
      ..moveTo(w * 0.42, 38)
      ..lineTo(w * 0.32, 70)
      ..lineTo(w * 0.36, 110)
      ..lineTo(w * 0.30, 150)
      ..lineTo(w * 0.34, h)
      ..lineTo(w * 0.66, h)
      ..lineTo(w * 0.70, 150)
      ..lineTo(w * 0.64, 110)
      ..lineTo(w * 0.68, 70)
      ..lineTo(w * 0.58, 38)
      ..close();

    canvas.drawPath(body, paintFill);
    canvas.drawPath(body, paintLine);
  }

  @override
  bool shouldRepaint(covariant _CroquisPainter old) =>
      old.outline != outline || old.fill != fill;
}
