import 'package:flutter/material.dart';
import '../core/theme.dart';

class _Deco {
  final IconData? icon;
  final String? glyph;
  final double size;
  final double opacity;
  final double rotation;
  final double left;
  final double top;
  final Color color;

  const _Deco({
    this.icon,
    this.glyph,
    required this.size,
    required this.opacity,
    required this.rotation,
    required this.left,
    required this.top,
    required this.color,
  });
}

const _pink   = AppTheme.primary;
const _orange = AppTheme.secondary;
const _gold   = AppTheme.accent;
const _lpink  = AppTheme.lightPink;

// Full scatter — auth & onboarding (opacities raised +0.10 from original)
const _full = [
  // Hearts
  _Deco(icon: Icons.favorite,         size: 48, opacity: 0.20, rotation: -0.3,  left: 0.06, top: 0.04,  color: _pink),
  _Deco(icon: Icons.favorite,         size: 22, opacity: 0.23, rotation:  0.2,  left: 0.82, top: 0.11,  color: _pink),
  _Deco(icon: Icons.favorite,         size: 16, opacity: 0.20, rotation: -0.5,  left: 0.44, top: 0.02,  color: _lpink),
  _Deco(icon: Icons.favorite,         size: 34, opacity: 0.19, rotation:  0.4,  left: 0.90, top: 0.55,  color: _pink),
  _Deco(icon: Icons.favorite,         size: 18, opacity: 0.22, rotation: -0.2,  left: 0.12, top: 0.72,  color: _pink),
  _Deco(icon: Icons.favorite,         size: 28, opacity: 0.18, rotation:  0.6,  left: 0.70, top: 0.88,  color: _lpink),

  // Stars / sparkles
  _Deco(icon: Icons.auto_awesome,     size: 30, opacity: 0.24, rotation:  0.0,  left: 0.88, top: 0.03,  color: _gold),
  _Deco(icon: Icons.auto_awesome,     size: 18, opacity: 0.21, rotation:  0.3,  left: 0.25, top: 0.08,  color: _gold),
  _Deco(icon: Icons.auto_awesome,     size: 22, opacity: 0.23, rotation: -0.4,  left: 0.65, top: 0.30,  color: _gold),
  _Deco(icon: Icons.star,             size: 20, opacity: 0.20, rotation:  0.5,  left: 0.04, top: 0.42,  color: _orange),
  _Deco(icon: Icons.star,             size: 14, opacity: 0.20, rotation: -0.2,  left: 0.78, top: 0.70,  color: _gold),
  _Deco(icon: Icons.auto_awesome,     size: 24, opacity: 0.22, rotation:  0.1,  left: 0.50, top: 0.92,  color: _gold),

  // Flowers
  _Deco(icon: Icons.local_florist,    size: 40, opacity: 0.20, rotation:  0.4,  left: 0.02, top: 0.18,  color: _orange),
  _Deco(icon: Icons.local_florist,    size: 24, opacity: 0.21, rotation: -0.3,  left: 0.92, top: 0.36,  color: _pink),
  _Deco(icon: Icons.spa,              size: 28, opacity: 0.19, rotation:  0.6,  left: 0.55, top: 0.78,  color: _orange),
  _Deco(icon: Icons.local_florist,    size: 18, opacity: 0.20, rotation: -0.5,  left: 0.35, top: 0.96,  color: _lpink),

  // Moon
  _Deco(icon: Icons.nightlight_round, size: 36, opacity: 0.21, rotation: -0.3,  left: 0.72, top: 0.06,  color: _gold),
  _Deco(icon: Icons.nightlight_round, size: 22, opacity: 0.19, rotation:  0.5,  left: 0.08, top: 0.88,  color: _gold),

  // Infinity
  _Deco(glyph: '∞',                   size: 38, opacity: 0.20, rotation:  0.0,  left: 0.15, top: 0.54,  color: _pink),
  _Deco(glyph: '∞',                   size: 26, opacity: 0.19, rotation:  0.1,  left: 0.78, top: 0.82,  color: _orange),

  // Crown
  _Deco(glyph: '♛',                   size: 34, opacity: 0.22, rotation: -0.1,  left: 0.60, top: 0.12,  color: _gold),
  _Deco(glyph: '♛',                   size: 20, opacity: 0.19, rotation:  0.2,  left: 0.20, top: 0.35,  color: _gold),

  // Butterfly
  _Deco(glyph: '❋',                   size: 32, opacity: 0.20, rotation:  0.3,  left: 0.40, top: 0.60,  color: _pink),
  _Deco(glyph: '❋',                   size: 20, opacity: 0.19, rotation: -0.4,  left: 0.85, top: 0.22,  color: _lpink),
];

// Sparse scatter — content screens (opacities raised +0.10 from original)
const _sparse = [
  _Deco(icon: Icons.favorite,         size: 38, opacity: 0.18, rotation: -0.3,  left: 0.04, top: 0.05,  color: _pink),
  _Deco(icon: Icons.auto_awesome,     size: 24, opacity: 0.20, rotation:  0.2,  left: 0.88, top: 0.04,  color: _gold),
  _Deco(icon: Icons.local_florist,    size: 30, opacity: 0.18, rotation:  0.4,  left: 0.90, top: 0.52,  color: _orange),
  _Deco(icon: Icons.nightlight_round, size: 28, opacity: 0.19, rotation: -0.2,  left: 0.06, top: 0.78,  color: _gold),
  _Deco(glyph: '♛',                   size: 26, opacity: 0.19, rotation:  0.1,  left: 0.70, top: 0.88,  color: _gold),
  _Deco(icon: Icons.favorite,         size: 18, opacity: 0.18, rotation:  0.5,  left: 0.45, top: 0.96,  color: _lpink),
  _Deco(icon: Icons.auto_awesome,     size: 18, opacity: 0.19, rotation: -0.3,  left: 0.20, top: 0.18,  color: _gold),
  _Deco(glyph: '∞',                   size: 30, opacity: 0.18, rotation:  0.0,  left: 0.82, top: 0.72,  color: _pink),
];

class DecorativeSymbols extends StatelessWidget {
  final bool sparse;
  const DecorativeSymbols({super.key, this.sparse = false});

  @override
  Widget build(BuildContext context) {
    final decos = sparse ? _sparse : _full;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          children: decos.map((d) {
            final Widget symbol = d.icon != null
                ? Icon(d.icon, size: d.size, color: d.color)
                : Text(d.glyph!, style: TextStyle(fontSize: d.size, color: d.color, height: 1));
            return Positioned(
              left: d.left * w,
              top: d.top * h,
              child: Transform.rotate(
                angle: d.rotation,
                child: Opacity(opacity: d.opacity, child: symbol),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class WithDecorations extends StatelessWidget {
  final Widget child;
  final bool sparse;
  const WithDecorations({super.key, required this.child, this.sparse = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: DecorativeSymbols(sparse: sparse)),
        child,
      ],
    );
  }
}
