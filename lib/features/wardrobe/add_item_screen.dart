import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../core/extensions.dart';
import '../../widgets/decorative_symbols.dart';
import '../../models/category.dart';
import '../../services/supabase_service.dart';
import '../../services/image_service.dart';
import '../../services/usage_tracker.dart';
import 'wardrobe_controller.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  Uint8List? _imageBytes;
  ClothingCategory _category = ClothingCategory.tops;
  String? _color;
  String? _name;
  bool _isUploading = false;
  final _nameController = TextEditingController();

  static const _categoryExamples = {
    ClothingCategory.tops:        ['T-Shirt', 'Blouse', 'Crop Top', 'Tank Top', 'Hoodie', 'Sweater'],
    ClothingCategory.bottoms:     ['Jeans', 'Leggings', 'Mini Skirt', 'Midi Skirt', 'Shorts', 'Trousers'],
    ClothingCategory.dresses:     ['Maxi Dress', 'Mini Dress', 'Wrap Dress', 'Sundress', 'Bodycon', 'Midi Dress'],
    ClothingCategory.shoes:       ['Sneakers', 'Heels', 'Sandals', 'Boots', 'Flats', 'Mules'],
    ClothingCategory.outerwear:   ['Denim Jacket', 'Blazer', 'Trench Coat', 'Puffer', 'Cardigan', 'Leather Jacket'],
    ClothingCategory.accessories: ['Belt', 'Scarf', 'Hat', 'Sunglasses', 'Hair Clip', 'Necklace'],
    ClothingCategory.bags:        ['Tote Bag', 'Crossbody', 'Clutch', 'Mini Bag', 'Backpack', 'Shoulder Bag'],
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: WithDecorations(sparse: true, child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Larger landscape image preview (4:3)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: GestureDetector(
                onTap: _imageBytes == null ? _pickImage : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo,
                                size: 56, color: AppTheme.textSecondary),
                            const SizedBox(height: 14),
                            Text('Tap to add a photo',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 17, fontWeight: FontWeight.w600,
                                )),
                            const SizedBox(height: 4),
                            Text('Photos fit best in landscape (4:3).',
                                style: TextStyle(
                                  color: AppTheme.textSecondary.withValues(alpha: 0.7),
                                  fontSize: 12,
                                )),
                          ],
                        ),
                ),
              ),
            ),

            if (_imageBytes != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retake'),
                      onPressed: _pickImage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      onPressed: _openEditor,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Category selector
            Text('Category', style: context.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ClothingCategory.values.map((cat) {
                final isSelected = _category == cat;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon, size: 16),
                      const SizedBox(width: 4),
                      Text(cat.label),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _category = cat),
                  selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Quick-fill name examples for selected category
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (_categoryExamples[_category] ?? []).map((example) {
                return ActionChip(
                  label: Text(example, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    setState(() => _name = example);
                    _nameController.text = example;
                  },
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.07),
                  side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Color input
            TextField(
              decoration: InputDecoration(
                labelText: 'Color (optional)',
                hintText: 'e.g. Navy Blue',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => _color = v.isEmpty ? null : v,
            ),

            const SizedBox(height: 16),

            // Name input
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name (optional)',
                hintText: 'e.g. My favorite denim jacket',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => _name = v.isEmpty ? null : v,
            ),

            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _imageBytes != null && !_isUploading ? _saveItem : null,
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save to Wardrobe'),
            ),
          ],
        ),
      ),),
    );
  }

  Future<void> _pickImage() async {
    final imageService = ref.read(imageServiceProvider);
    final bytes = await imageService.pickWithSheet(context);
    if (bytes != null) {
      setState(() => _imageBytes = bytes);
    }
  }

  /// Launch the full-screen image editor (zoom + crop) on the current photo.
  Future<void> _openEditor() async {
    if (_imageBytes == null) return;
    final edited = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => _ImageEditorScreen(source: _imageBytes!),
      ),
    );
    if (edited != null && mounted) {
      setState(() => _imageBytes = edited);
    }
  }

  /// Show aspect-ratio crop options. Center-crops the current image to the
  /// chosen aspect without requiring a native crop UI (works on web).
  Future<void> _showCropOptions() async {
    if (_imageBytes == null) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Crop to aspect ratio',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.crop_landscape, color: AppTheme.primary),
              title: const Text('Landscape (4:3)'),
              subtitle: const Text('Best for full outfit photos'),
              onTap: () => Navigator.pop(ctx, 'landscape'),
            ),
            ListTile(
              leading: const Icon(Icons.crop_square, color: AppTheme.primary),
              title: const Text('Square (1:1)'),
              subtitle: const Text('Classic grid-friendly'),
              onTap: () => Navigator.pop(ctx, 'square'),
            ),
            ListTile(
              leading: const Icon(Icons.crop_portrait, color: AppTheme.primary),
              title: const Text('Portrait (3:4)'),
              subtitle: const Text('Tall photos'),
              onTap: () => Navigator.pop(ctx, 'portrait'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null) return;

    final ratio = switch (choice) {
      'landscape' => 4 / 3,
      'portrait'  => 3 / 4,
      _           => 1.0, // square
    };
    final cropped = _centerCrop(_imageBytes!, ratio);
    if (cropped != null) setState(() => _imageBytes = cropped);
  }

  /// Decode, center-crop to [aspect] (width / height), re-encode as JPEG.
  Uint8List? _centerCrop(Uint8List bytes, double aspect) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final w = decoded.width;
      final h = decoded.height;
      int cropW, cropH;
      if (w / h > aspect) {
        cropH = h;
        cropW = (h * aspect).round();
      } else {
        cropW = w;
        cropH = (w / aspect).round();
      }
      final x = ((w - cropW) / 2).round();
      final y = ((h - cropH) / 2).round();
      final out = img.copyCrop(decoded, x: x, y: y, width: cropW, height: cropH);
      return Uint8List.fromList(img.encodeJpg(out, quality: 85));
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveItem() async {
    if (_imageBytes == null) return;

    final tracker = ref.read(usageTrackerProvider.notifier);
    if (!tracker.canAddItem()) {
      if (mounted) context.push('/paywall');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final supabase = ref.read(supabaseServiceProvider);
      if (supabase == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign in to save items to your wardrobe.')));
        }
        setState(() => _isUploading = false);
        return;
      }
      final imageService = ref.read(imageServiceProvider);
      final itemId = const Uuid().v4();
      final userId = supabase.userId;

      // Compress images
      final compressed = imageService.compressImage(_imageBytes!, maxSize: 512);
      final thumbnail = imageService.createThumbnail(_imageBytes!, size: 200);

      // Upload to storage
      final imagePath = '$userId/$itemId.png';
      final thumbPath = '$userId/${itemId}_thumb.png';

      await supabase.uploadImage(imagePath, compressed);
      await supabase.uploadImage(thumbPath, thumbnail);

      // Resolve public URLs so Image.network can display them directly.
      // The bucket is public; the URL stays stable.
      final imageUrl = supabase.getPublicUrl(imagePath);
      final thumbUrl = supabase.getPublicUrl(thumbPath);

      // Save the full public URLs in the DB (not just the bucket paths)
      // so every downstream consumer can just call Image.network(item.imagePath).
      await supabase.addWardrobeItem({
        'id': itemId,
        'user_id': userId,
        'category': _category.name,
        'color': _color,
        'image_path': imageUrl,
        'thumbnail_path': thumbUrl,
        'name': _name,
      });

      // Track usage and refresh wardrobe
      tracker.recordItemAdded();
      ref.invalidate(wardrobeControllerProvider);

      if (mounted) {
        context.showSnackBar('Item added to wardrobe!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to save item: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}

// ─── Full-screen image editor (zoom + crop) ──────────────────────────────────
class _ImageEditorScreen extends StatefulWidget {
  final Uint8List source;
  const _ImageEditorScreen({required this.source});

  @override
  State<_ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<_ImageEditorScreen> {
  double _scale = 1.0;
  final TransformationController _ctrl = TransformationController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setScale(double s) {
    _scale = s.clamp(1.0, 4.0);
    _ctrl.value = Matrix4.identity()..scale(_scale);
    setState(() {});
  }

  Future<void> _cropAspect(double aspect) async {
    final cropped = _centerCropWithZoom(widget.source, aspect, _scale);
    if (cropped != null && mounted) {
      Navigator.of(context).pop(cropped);
    }
  }

  void _saveAsIs() {
    // Apply zoom as a "digital zoom" center-crop.
    if (_scale <= 1.0) {
      Navigator.of(context).pop(widget.source);
      return;
    }
    final zoomed = _centerCropWithZoom(widget.source, null, _scale);
    Navigator.of(context).pop(zoomed ?? widget.source);
  }

  /// Center-crop with zoom factor. If [aspect] is null, just applies the zoom.
  Uint8List? _centerCropWithZoom(Uint8List bytes, double? aspect, double zoom) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      int w = decoded.width;
      int h = decoded.height;

      // Apply zoom first: crop the center to 1/zoom of the original dimensions.
      if (zoom > 1.0) {
        final zw = (w / zoom).round();
        final zh = (h / zoom).round();
        final zx = ((w - zw) / 2).round();
        final zy = ((h - zh) / 2).round();
        final zoomed = img.copyCrop(decoded, x: zx, y: zy, width: zw, height: zh);
        return _finalize(zoomed, aspect);
      }
      return _finalize(decoded, aspect);
    } catch (_) {
      return null;
    }
  }

  Uint8List _finalize(img.Image input, double? aspect) {
    var out = input;
    if (aspect != null) {
      final w = out.width;
      final h = out.height;
      int cropW, cropH;
      if (w / h > aspect) {
        cropH = h;
        cropW = (h * aspect).round();
      } else {
        cropW = w;
        cropH = (w / aspect).round();
      }
      final x = ((w - cropW) / 2).round();
      final y = ((h - cropH) / 2).round();
      out = img.copyCrop(out, x: x, y: y, width: cropW, height: cropH);
    }
    return Uint8List.fromList(img.encodeJpg(out, quality: 88));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Edit Image', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _saveAsIs,
            child: const Text('Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _ctrl,
              minScale: 1.0,
              maxScale: 4.0,
              onInteractionUpdate: (details) {
                final m = _ctrl.value;
                _scale = m.getMaxScaleOnAxis().clamp(1.0, 4.0);
                if (mounted) setState(() {});
              },
              child: Center(child: Image.memory(widget.source)),
            ),
          ),
          // Zoom slider
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.zoom_out, color: Colors.white70, size: 22),
                Expanded(
                  child: Slider(
                    value: _scale,
                    min: 1.0,
                    max: 4.0,
                    divisions: 30,
                    activeColor: AppTheme.primary,
                    inactiveColor: Colors.white24,
                    label: '${_scale.toStringAsFixed(1)}×',
                    onChanged: _setScale,
                  ),
                ),
                const Icon(Icons.zoom_in, color: Colors.white70, size: 22),
              ],
            ),
          ),
          // Crop aspect buttons
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _EditorBtn(
                  icon: Icons.crop_landscape,
                  label: 'Landscape 4:3',
                  onTap: () => _cropAspect(4 / 3),
                ),
                _EditorBtn(
                  icon: Icons.crop_square,
                  label: 'Square 1:1',
                  onTap: () => _cropAspect(1.0),
                ),
                _EditorBtn(
                  icon: Icons.crop_portrait,
                  label: 'Portrait 3:4',
                  onTap: () => _cropAspect(3 / 4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _EditorBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
