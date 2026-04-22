import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../main.dart';
import '../../widgets/decorative_symbols.dart';
import '../../services/image_service.dart';
import '../../providers/user_providers.dart';

// ─── LocalStorage helpers (web-only) ────────────────────────────────────────
String? _lsGet(String k) {
  try {
    return html.window.localStorage[k];
  } catch (_) {
    return null;
  }
}

void _lsSet(String k, String v) {
  try {
    html.window.localStorage[k] = v;
  } catch (_) {/* quota */}
}

const _kBrands = 'fitcheck_brands';
const _kSocials = 'fitcheck_socials';
const _kShops = 'fitcheck_shops';
const _kProfilePic = 'fitcheck_profile_pic';

// Providers for profile data (persisted across reloads via localStorage)
final profilePhotoProvider = StateProvider<Uint8List?>((ref) {
  final raw = _lsGet(_kProfilePic);
  final initial = (raw != null && raw.isNotEmpty) ? base64Decode(raw) : null;
  ref.listenSelf((prev, next) {
    _lsSet(_kProfilePic, next == null ? '' : base64Encode(next));
  });
  return initial;
});

final favoriteShopsProvider = StateProvider<List<_ShopLink>>((ref) {
  final raw = _lsGet(_kShops);
  List<_ShopLink> initial = [];
  if (raw != null && raw.isNotEmpty) {
    try {
      initial = (jsonDecode(raw) as List)
          .map((e) =>
              _ShopLink(name: e['name'] as String, url: e['url'] as String))
          .toList();
    } catch (_) {}
  }
  ref.listenSelf((prev, next) {
    _lsSet(_kShops,
        jsonEncode(next.map((s) => {'name': s.name, 'url': s.url}).toList()));
  });
  return initial;
});

final socialLinksProvider = StateProvider<Map<String, String>>((ref) {
  final raw = _lsGet(_kSocials);
  Map<String, String> initial = {};
  if (raw != null && raw.isNotEmpty) {
    try {
      initial = Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {}
  }
  ref.listenSelf((prev, next) => _lsSet(_kSocials, jsonEncode(next)));
  return initial;
});

final favoriteBrandsProvider = StateProvider<List<String>>((ref) {
  final raw = _lsGet(_kBrands);
  List<String> initial = [];
  if (raw != null && raw.isNotEmpty) {
    try {
      initial = (jsonDecode(raw) as List).cast<String>();
    } catch (_) {}
  }
  ref.listenSelf((prev, next) => _lsSet(_kBrands, jsonEncode(next)));
  return initial;
});

// Well-known shop URL lookup for auto-fill
const _knownShopUrls = {
  'fashion nova': 'https://fashionnova.com',
  'fashionnova': 'https://fashionnova.com',
  'zara': 'https://zara.com',
  'asos': 'https://asos.com',
  'h&m': 'https://hm.com',
  'hm': 'https://hm.com',
  'revolve': 'https://revolve.com',
  'nordstrom': 'https://nordstrom.com',
  'prettylittlething': 'https://prettylittlething.com',
  'plt': 'https://prettylittlething.com',
  'boohoo': 'https://boohoo.com',
  'shein': 'https://shein.com',
  'free people': 'https://freepeople.com',
  'urban outfitters': 'https://urbanoutfitters.com',
  'nike': 'https://nike.com',
  'adidas': 'https://adidas.com',
  'lululemon': 'https://lululemon.com',
  'skims': 'https://skims.com',
  'good american': 'https://goodamerican.com',
  'anthropologie': 'https://anthropologie.com',
  'forever 21': 'https://forever21.com',
  'target': 'https://target.com',
  'amazon': 'https://amazon.com/fashion',
  'mango': 'https://mango.com',
  'coach': 'https://coach.com',
  'coach outlet': 'https://coachoutlet.com',
  'windsor': 'https://windsorstore.com',
  'express': 'https://express.com',
  'banana republic': 'https://bananarepublic.gap.com',
  'gap': 'https://gap.com',
  'old navy': 'https://oldnavy.gap.com',
  'j.crew': 'https://jcrew.com',
  'ralph lauren': 'https://ralphlauren.com',
};

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final photo = ref.watch(profilePhotoProvider);
    final username = ref.watch(usernameProvider);
    final displayName = ref.watch(displayNameProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: WithDecorations(
        sparse: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // ── Avatar ──────────────────────────────────────────────────
              GestureDetector(
                onTap: () => _pickProfilePhoto(),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      backgroundImage:
                          photo != null ? MemoryImage(photo) : null,
                      child: photo == null
                          ? const Icon(Icons.person,
                              size: 52, color: AppTheme.primary)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                kDemoMode
                    ? 'Demo User'
                    : (displayName.isNotEmpty ? displayName : 'Your Name'),
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),

              // ── Username chip ────────────────────────────────────────────
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _editUsername(username),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: username.isEmpty
                          ? Colors.grey.shade100
                          : AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: username.isEmpty
                            ? Colors.grey.shade300
                            : AppTheme.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          username.isEmpty
                              ? Icons.add_circle_outline
                              : Icons.alternate_email,
                          size: 14,
                          color: username.isEmpty
                              ? AppTheme.textSecondary
                              : AppTheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          username.isEmpty
                              ? 'Set your @username'
                              : '@${username.replaceFirst(RegExp(r'^@+'), '')}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: username.isEmpty
                                ? AppTheme.textSecondary
                                : AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.edit,
                            size: 12,
                            color: username.isEmpty
                                ? AppTheme.textSecondary
                                : AppTheme.primary.withValues(alpha: 0.6)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('FREE',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary)),
              ),

              const SizedBox(height: 20),

              // ── Retake Style Quiz (onboarding replay) ─────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.replay, size: 18),
                  label: const Text('Retake Style Quiz'),
                  onPressed: () => context.push('/onboarding?retake=true'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── My Sizes ───────────────────────────────────────────────────
              _SectionCard(
                title: 'My Sizes',
                icon: Icons.straighten,
                child: _SizesSection(),
              ),
              const SizedBox(height: 16),

              // ── Color Palette ──────────────────────────────────────────────
              _SectionCard(
                title: 'My Color Palette',
                icon: Icons.palette,
                child: _ColorPaletteSection(),
              ),
              const SizedBox(height: 16),

              // ── Go-To Brands ───────────────────────────────────────────────
              _SectionCard(
                title: 'Go-To Brands',
                icon: Icons.local_mall,
                child: _BrandsSection(),
              ),
              const SizedBox(height: 16),

              // ── Favorite Shops ─────────────────────────────────────────────
              _SectionCard(
                title: 'Favorite Shops',
                icon: Icons.shopping_bag,
                trailing: IconButton(
                  icon:
                      const Icon(Icons.add, color: AppTheme.primary, size: 20),
                  onPressed: () => _showAddShopDialog(),
                ),
                child: _FavoriteShopsSection(),
              ),
              const SizedBox(height: 16),

              // ── Social Media ───────────────────────────────────────────────
              _SectionCard(
                title: 'Social Media',
                icon: Icons.share,
                child: _SocialMediaSection(),
              ),
              const SizedBox(height: 24),

              // ── Upgrade Banner ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text('Upgrade to Pro',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text(
                      'Unlimited outfits, no watermarks, weather-based daily picks',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.push('/paywall'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primary),
                      child: const Text('See Plans'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Username editor ──────────────────────────────────────────────────────────

  void _editUsername(String current) {
    // Strip any leading @ so the field only holds the bare handle
    final bare = current.replaceAll('@', '');
    final ctrl = TextEditingController(text: bare);
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => AlertDialog(
          title: const Text('Set Username'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose your unique handle. Others will see you as @handle on the Network.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 14, right: 4),
                    child: Text('@',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary)),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  labelText: 'Username',
                  hintText: 'e.g. fashionista',
                  errorText: error,
                ),
                maxLength: 24,
                onChanged: (_) => setS(() => error = null),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final val = ctrl.text.trim().replaceAll('@', '');
                if (val.isEmpty) {
                  setS(() => error = 'Username cannot be empty');
                  return;
                }
                if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(val)) {
                  setS(() => error = 'Only letters, numbers, _ and . allowed');
                  return;
                }
                ref.read(usernameProvider.notifier).state = val;
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Photo picker ─────────────────────────────────────────────────────────────

  Future<void> _pickProfilePhoto() async {
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
    if (bytes != null && mounted) {
      ref.read(profilePhotoProvider.notifier).state = bytes;
    }
  }

  // ── Add shop dialog ──────────────────────────────────────────────────────────

  Future<void> _showAddShopDialog() async {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String? suggestion;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => AlertDialog(
          title: const Text('Add Favorite Shop'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Shop name'),
                onChanged: (v) {
                  final key = v.toLowerCase().trim();
                  final url = _knownShopUrls[key];
                  setS(() {
                    suggestion = url;
                    if (url != null && urlCtrl.text.isEmpty) {
                      urlCtrl.text = url;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlCtrl,
                decoration: InputDecoration(
                  labelText: 'Website URL',
                  hintText: 'https://...',
                  suffixIcon: suggestion != null
                      ? const Icon(Icons.check_circle,
                          color: Colors.green, size: 18)
                      : null,
                  helperText: suggestion != null
                      ? 'Auto-filled from known stores'
                      : null,
                  helperStyle:
                      const TextStyle(color: Colors.green, fontSize: 11),
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  final shops = [...ref.read(favoriteShopsProvider)];
                  if (shops.length < 5) {
                    shops
                        .add(_ShopLink(name: nameCtrl.text, url: urlCtrl.text));
                    ref.read(favoriteShopsProvider.notifier).state = shops;
                  }
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sizes Section ───────────────────────────────────────────────────────────

class _SizesSection extends ConsumerWidget {
  static const _clothingSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  static const _shoeSizes = [
    '6',
    '6.5',
    '7',
    '7.5',
    '8',
    '8.5',
    '9',
    '9.5',
    '10',
    '10.5',
    '11'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topSize = ref.watch(topSizeProvider);
    final bottomSize = ref.watch(bottomSizeProvider);
    final shoeSize = ref.watch(shoeSizeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SizeRow(
            label: 'Tops',
            sizes: _clothingSizes,
            selected: topSize,
            onChanged: (v) => ref.read(topSizeProvider.notifier).state = v),
        const SizedBox(height: 16),
        _SizeRow(
            label: 'Bottoms',
            sizes: _clothingSizes,
            selected: bottomSize,
            onChanged: (v) => ref.read(bottomSizeProvider.notifier).state = v),
        const SizedBox(height: 16),
        const Text('Shoes (US)',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _shoeSizes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final s = _shoeSizes[i];
              final sel = shoeSize == s;
              return GestureDetector(
                onTap: () => ref.read(shoeSizeProvider.notifier).state = s,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.primary : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: sel ? AppTheme.primary : Colors.grey.shade300),
                  ),
                  child: Text(s,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel ? Colors.white : AppTheme.textPrimary,
                      )),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SizeRow extends StatelessWidget {
  final String label;
  final List<String> sizes;
  final String? selected;
  final ValueChanged<String> onChanged;

  const _SizeRow(
      {required this.label,
      required this.sizes,
      required this.selected,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: sizes.map((s) {
            final sel = selected == s;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: GestureDetector(
                  onTap: () => onChanged(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primary : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: sel ? AppTheme.primary : Colors.grey.shade300),
                    ),
                    child: Text(s,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color: sel ? Colors.white : AppTheme.textPrimary,
                        )),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Color Palette Section ────────────────────────────────────────────────────

class _ColorPaletteSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasons = [
      _SeasonPalette(
          'Spring',
          [
            const Color(0xFFF9A8D4),
            const Color(0xFFFDE68A),
            const Color(0xFF86EFAC),
            const Color(0xFFFCA5A5),
            const Color(0xFFFED7AA),
            const Color(0xFFBFDBFE),
          ],
          const Color(0xFFF9A8D4)),
      _SeasonPalette(
          'Summer',
          [
            const Color(0xFFC4B5FD),
            const Color(0xFF93C5FD),
            const Color(0xFFA5F3FC),
            const Color(0xFFF9A8D4),
            const Color(0xFFE2E8F0),
            const Color(0xFF6EE7B7),
          ],
          const Color(0xFFC4B5FD)),
      _SeasonPalette(
          'Autumn',
          [
            const Color(0xFFB45309),
            const Color(0xFFD97706),
            const Color(0xFF92400E),
            const Color(0xFF78350F),
            const Color(0xFFDC8A32),
            const Color(0xFF6B7280),
          ],
          const Color(0xFFD97706)),
      _SeasonPalette(
          'Winter',
          [
            const Color(0xFF1E40AF),
            const Color(0xFF7C3AED),
            const Color(0xFF111827),
            const Color(0xFFDC2626),
            const Color(0xFFF9FAFB),
            const Color(0xFF065F46),
          ],
          const Color(0xFF7C3AED)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...seasons.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: s.accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 56,
                    child: Text(s.name,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: s.colors
                        .map((c) => Container(
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 2)
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            )),
        const Divider(height: 20),
        const Text('Overall Favorites',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['Hot Pink', 'Ivory', 'Camel', 'Black', 'Coral']
              .map((c) => Chip(
                    label: Text(c, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _SeasonPalette {
  final String name;
  final List<Color> colors;
  final Color accent;
  _SeasonPalette(this.name, this.colors, this.accent);
}

// ─── Brands Section ───────────────────────────────────────────────────────────

class _BrandsSection extends ConsumerWidget {
  static const _allBrands = [
    'Zara',
    'H&M',
    'Fashion Nova',
    'SHEIN',
    'ASOS',
    'Nordstrom',
    'Revolve',
    'PrettyLittleThing',
    'Boohoo',
    'Free People',
    'Anthropologie',
    'Urban Outfitters',
    'Nike',
    'Adidas',
    'Lululemon',
    'Skims',
    'Good American',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(favoriteBrandsProvider);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allBrands.map((b) {
        final isSelected = selected.contains(b);
        return FilterChip(
          label: Text(b, style: const TextStyle(fontSize: 12)),
          selected: isSelected,
          onSelected: (_) {
            final updated = [...selected];
            if (isSelected)
              updated.remove(b);
            else
              updated.add(b);
            ref.read(favoriteBrandsProvider.notifier).state = updated;
          },
          selectedColor: AppTheme.primary.withValues(alpha: 0.15),
          checkmarkColor: AppTheme.primary,
        );
      }).toList(),
    );
  }
}

// ─── Favorite Shops Section ───────────────────────────────────────────────────

class _FavoriteShopsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shops = ref.watch(favoriteShopsProvider);

    if (shops.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Add up to 5 favorite online shops — type name to auto-fill URL.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      );
    }

    return Column(
      children: shops
          .map((shop) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.store,
                      color: AppTheme.primary, size: 18),
                ),
                title: Text(shop.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: shop.url.isNotEmpty
                    ? Text(shop.url,
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary),
                        overflow: TextOverflow.ellipsis)
                    : null,
                trailing: shop.url.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.open_in_new,
                            size: 16, color: AppTheme.primary),
                        onPressed: () async {
                          final uri = Uri.parse(shop.url.startsWith('http')
                              ? shop.url
                              : 'https://${shop.url}');
                          if (await canLaunchUrl(uri)) launchUrl(uri);
                        },
                      )
                    : null,
              ))
          .toList(),
    );
  }
}

// ─── Social Media Section ─────────────────────────────────────────────────────

class _SocialMediaSection extends ConsumerWidget {
  static const _platforms = [
    _SocialPlatform('Instagram', Icons.camera_alt, Color(0xFFE1306C),
        'https://instagram.com'),
    _SocialPlatform(
        'TikTok', Icons.music_note, Color(0xFF000000), 'https://tiktok.com'),
    _SocialPlatform(
        'Snapchat', Icons.camera, Color(0xFFFFFC00), 'https://snapchat.com'),
    _SocialPlatform(
        'Facebook', Icons.facebook, Color(0xFF1877F2), 'https://facebook.com'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(socialLinksProvider);

    return Column(
      children: _platforms.map((p) {
        final handle = links[p.name] ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: p.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(p.icon, color: p.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: handle),
                  decoration: InputDecoration(
                    hintText: '@${p.name.toLowerCase()}handle',
                    hintStyle: const TextStyle(fontSize: 12),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (v) {
                    final updated = Map<String, String>.from(links);
                    updated[p.name] = v;
                    ref.read(socialLinksProvider.notifier).state = updated;
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.open_in_new, color: p.color, size: 18),
                onPressed: () async {
                  final uri = Uri.parse(handle.isNotEmpty
                      ? '${p.baseUrl}/${handle.replaceAll('@', '')}'
                      : p.baseUrl);
                  if (await canLaunchUrl(uri)) launchUrl(uri);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ShopLink {
  final String name;
  final String url;
  const _ShopLink({required this.name, required this.url});
}

class _SocialPlatform {
  final String name;
  final IconData icon;
  final Color color;
  final String baseUrl;
  const _SocialPlatform(this.name, this.icon, this.color, this.baseUrl);
}
