import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme.dart';
import '../../../main.dart';

class SkinTonePicker extends StatefulWidget {
  final String? selectedUndertone;
  final ValueChanged<String> onUndertoneChanged;

  const SkinTonePicker({
    super.key,
    required this.selectedUndertone,
    required this.onUndertoneChanged,
  });

  @override
  State<SkinTonePicker> createState() => _SkinTonePickerState();
}

class _UndertoneInfo {
  final String label;
  final String description;
  final List<Color> colors;
  final List<String> names;

  const _UndertoneInfo({
    required this.label,
    required this.description,
    required this.colors,
    required this.names,
  });
}

class _SkinTonePickerState extends State<SkinTonePicker> {
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  bool _analyzing = false;
  bool _showResult = false;

  static const _undertones = {
    'warm': _UndertoneInfo(
      label: 'Warm Undertone',
      description: 'Golden, peachy, or yellow hues in your complexion',
      colors: [
        Color(0xFFCD7F32), Color(0xFFB85C38), Color(0xFF8B9467),
        Color(0xFFD4A017), Color(0xFF8B5C2A),
      ],
      names: ['Copper', 'Terracotta', 'Olive', 'Gold', 'Camel'],
    ),
    'cool': _UndertoneInfo(
      label: 'Cool Undertone',
      description: 'Pink, rosy, or bluish hues in your complexion',
      colors: [
        Color(0xFF9B59B6), Color(0xFFE8A0B4), Color(0xFF2C4770),
        Color(0xFF1E8449), Color(0xFF922B21),
      ],
      names: ['Lavender', 'Dusty Rose', 'Navy', 'Emerald', 'Burgundy'],
    ),
    'neutral': _UndertoneInfo(
      label: 'Neutral Undertone',
      description: 'A mix of warm and cool — you can wear almost anything!',
      colors: [
        Color(0xFFD4B5B5), Color(0xFF9E9E80), Color(0xFF4A7C59),
        Color(0xFF5B7FA6), Color(0xFFC0392B),
      ],
      names: ['Blush', 'Taupe', 'Sage', 'Denim', 'Brick Red'],
    ),
    'deep': _UndertoneInfo(
      label: 'Deep & Rich',
      description: 'Rich, deep complexion — bold and jewel tones are your best friends',
      colors: [
        Color(0xFF6B2D0E), Color(0xFF1A3A6B), Color(0xFF196F3D),
        Color(0xFF7D3C98), Color(0xFFF0A500),
      ],
      names: ['Chocolate', 'Cobalt', 'Forest', 'Plum', 'Amber'],
    ),
  };

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _showResult = false;
      });
      await _analyze();
    } catch (_) {}
  }

  Future<void> _analyze() async {
    setState(() => _analyzing = true);

    if (kDemoMode) {
      await Future.delayed(const Duration(seconds: 2));
      widget.onUndertoneChanged('warm');
    }
    // Real mode: call Gemini vision API here

    setState(() {
      _analyzing = false;
      _showResult = true;
    });
  }

  void _selectManually(String key) {
    widget.onUndertoneChanged(key);
    setState(() => _showResult = true);
  }

  @override
  Widget build(BuildContext context) {
    final undertone = widget.selectedUndertone != null
        ? _undertones[widget.selectedUndertone]
        : null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Your color palette',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a selfie for a personalized AI analysis',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 24),

          // Photo upload circle
          Center(
            child: GestureDetector(
              onTap: _analyzing ? null : _pickImage,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                  border: Border.all(
                    color: _imageBytes != null
                        ? AppTheme.primary
                        : Colors.grey.shade300,
                    width: 2.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _imageBytes != null
                    ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo,
                              size: 32, color: Colors.grey.shade400),
                          const SizedBox(height: 6),
                          Text(
                            'Upload\nSelfie',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          if (_imageBytes != null && !_analyzing && !_showResult)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: _analyze,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Analyze My Skin Tone'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Analyzing indicator
          if (_analyzing)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 12),
                  Text('Analyzing your skin tone…',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            )

          // Result card
          else if (_showResult && undertone != null)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  undertone.label,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(undertone.description,
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 13)),
                          const SizedBox(height: 16),
                          const Text('Your best colors',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(undertone.colors.length,
                                (i) {
                              return Column(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: undertone.colors[i],
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.12),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(undertone.names[i],
                                      style: const TextStyle(fontSize: 9)),
                                ],
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _pickImage,
                      child: const Text('Retake photo'),
                    ),
                  ],
                ),
              ),
            )

          // No photo yet — manual selection
          else if (!_analyzing)
            Expanded(
              child: Column(
                children: [
                  Center(
                    child: TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload),
                      label: const Text('Choose a photo'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text('or pick your undertone below',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                  ..._undertones.entries.map((entry) {
                    final isSelected =
                        widget.selectedUndertone == entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => _selectManually(entry.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary.withValues(alpha: 0.1)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Row(
                                children: entry.value.colors
                                    .take(3)
                                    .map((c) => Container(
                                          width: 20,
                                          height: 20,
                                          margin: const EdgeInsets.only(
                                              right: 3),
                                          decoration: BoxDecoration(
                                            color: c,
                                            shape: BoxShape.circle,
                                          ),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.value.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle,
                                    color: AppTheme.primary, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
