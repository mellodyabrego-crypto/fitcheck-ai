import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme.dart';
import '../../../main.dart';
import '../../../services/gemini_service.dart';

// Error type for displaying in the UI
enum _AnalysisError { apiKeyMissing, genericFailure }

// ---------------------------------------------------------------------------
// Seasonal color data (Itten / Carole Jackson)
// ---------------------------------------------------------------------------

class _SeasonInfo {
  final String label;
  final String subtitle;
  final String description;
  final String tagline;
  final Color accent;
  final List<Color> palette;
  final List<String> paletteNames;
  final List<Color> avoidColors;
  final List<String> avoidNames;
  final String traits; // physical description
  final List<String> celebs; // celebrity examples

  const _SeasonInfo({
    required this.label,
    required this.subtitle,
    required this.description,
    required this.tagline,
    required this.accent,
    required this.palette,
    required this.paletteNames,
    required this.avoidColors,
    required this.avoidNames,
    required this.traits,
    required this.celebs,
  });
}

const _seasons = {
  'spring': _SeasonInfo(
    label: 'Spring',
    subtitle: 'Warm · Clear · Low contrast',
    description:
        'Your coloring is warm and fresh — think golden undertones, clear eyes, and light-to-medium hair. '
        'You radiate a sun-kissed brightness that calls for warm, clear colors that mirror nature in bloom.',
    tagline: 'Sun-kissed warmth with a luminous glow',
    accent: Color(0xFFE8955A),
    palette: [
      Color(0xFFFFB347), // Peach
      Color(0xFFFF6F61), // Coral
      Color(0xFFFF8FAB), // Warm Pink
      Color(0xFFFFD700), // Golden Yellow
      Color(0xFFF5DEB3), // Ivory Wheat
      Color(0xFFC19A6B), // Camel
      Color(0xFFA67B5B), // Warm Tan
      Color(0xFF8A9A5B), // Moss Green
    ],
    paletteNames: [
      'Peach',
      'Coral',
      'Warm Pink',
      'Golden Yellow',
      'Ivory',
      'Camel',
      'Warm Tan',
      'Moss Green',
    ],
    avoidColors: [Color(0xFF708090), Color(0xFF4B0082), Color(0xFF000000)],
    avoidNames: ['Slate Grey', 'Indigo', 'Black'],
    traits:
        'Warm peachy or golden skin · Golden blonde, strawberry blonde or light auburn hair · Blue, green or hazel eyes with gold flecks · Freckles common',
    celebs: [
      'Jennifer Aniston',
      'Blake Lively',
      'Cameron Diaz',
      'Sienna Miller'
    ],
  ),
  'summer': _SeasonInfo(
    label: 'Summer',
    subtitle: 'Cool · Muted · Low contrast',
    description:
        'Your coloring is cool and soft — rosy or ashy undertones, muted hair, and gentle eyes that blend harmoniously. '
        'You glow in dusty, cool-toned colors that feel effortlessly elegant and romantic.',
    tagline: 'Cool rose softness like morning mist',
    accent: Color(0xFF9BB7D4),
    palette: [
      Color(0xFFDCA0A0), // Dusty Rose
      Color(0xFFB39BC8), // Lavender
      Color(0xFF87CEEB), // Soft Blue
      Color(0xFF8090BF), // Periwinkle
      Color(0xFFB07A8C), // Mauve
      Color(0xFFAEC6CF), // Powder Blue
      Color(0xFFB2B7B5), // Soft Grey
      Color(0xFF3B4F6E), // Light Navy
    ],
    paletteNames: [
      'Dusty Rose',
      'Lavender',
      'Soft Blue',
      'Periwinkle',
      'Mauve',
      'Powder Blue',
      'Soft Grey',
      'Light Navy',
    ],
    avoidColors: [Color(0xFFFF4500), Color(0xFFDAA520), Color(0xFF000000)],
    avoidNames: ['Orange-Red', 'Gold', 'Black'],
    traits:
        'Pink or rosy cool-toned skin · Ash blonde, mousy or cool light brown hair · Grey-blue, soft grey or muted brown eyes · Skin may flush easily',
    celebs: [
      'Gwyneth Paltrow',
      'Cate Blanchett',
      'Reese Witherspoon',
      'Taylor Swift'
    ],
  ),
  'autumn': _SeasonInfo(
    label: 'Autumn',
    subtitle: 'Warm · Muted · Medium–high contrast',
    description:
        'Your coloring is warm and rich — golden or bronze undertones, hair with depth and warmth, and earthy eyes. '
        'You\'re meant for the rich, muted colors of a harvest season: rust, terracotta, olive, and chocolate.',
    tagline: 'Rich warmth like golden leaves at dusk',
    accent: Color(0xFFB7472A),
    palette: [
      Color(0xFFB7472A), // Rust
      Color(0xFFCC5500), // Burnt Orange
      Color(0xFF708238), // Olive
      Color(0xFFCB6040), // Terracotta
      Color(0xFF228B22), // Forest Green
      Color(0xFFE1AA3E), // Mustard
      Color(0xFFC19A6B), // Camel
      Color(0xFF7B3F00), // Chocolate
    ],
    paletteNames: [
      'Rust',
      'Burnt Orange',
      'Olive',
      'Terracotta',
      'Forest Green',
      'Mustard',
      'Camel',
      'Chocolate',
    ],
    avoidColors: [Color(0xFFFF69B4), Color(0xFF000080), Color(0xFFE0E0E0)],
    avoidNames: ['Hot Pink', 'Navy Blue', 'Light Grey'],
    traits:
        'Golden, olive, bronze or warm medium-to-deep skin · Auburn, chestnut, warm brown or dark brown hair · Brown, hazel or olive-green eyes · Rich & earthy overall',
    celebs: ['Jennifer Lopez', 'Jessica Alba', 'Beyoncé', 'Tyra Banks'],
  ),
  'winter': _SeasonInfo(
    label: 'Winter',
    subtitle: 'Cool · Clear · High contrast',
    description:
        'Your coloring is cool and striking — high contrast between your hair, skin, and eyes creates dramatic presence. '
        'You shine in bold, clear, saturated colors and crisp neutrals that match your natural intensity.',
    tagline: 'Striking contrast with crystalline clarity',
    accent: Color(0xFF3B4F6E),
    palette: [
      Color(0xFFCC0000), // True Red
      Color(0xFF1F4FA6), // Royal Blue
      Color(0xFF1A1A1A), // Black
      Color(0xFFF5F5F5), // Crisp White
      Color(0xFF009473), // Emerald
      Color(0xFF6B2442), // Burgundy
      Color(0xFF36454F), // Charcoal
      Color(0xFFF2C4CE), // Icy Pink
    ],
    paletteNames: [
      'True Red',
      'Royal Blue',
      'Black',
      'Crisp White',
      'Emerald',
      'Burgundy',
      'Charcoal',
      'Icy Pink',
    ],
    avoidColors: [Color(0xFFFFD700), Color(0xFFFF6347), Color(0xFFF5DEB3)],
    avoidNames: ['Gold', 'Tomato', 'Wheat'],
    traits:
        'Any depth skin with cool pink/blue undertone · Blue-black, dark brown, silver or platinum hair · Dark brown, black, cool grey or icy blue eyes · Strong contrast between features',
    celebs: ['Zendaya', 'Lupita Nyong\'o', 'Katy Perry', 'Audrey Hepburn'],
  ),
};

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

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

enum _PickerStep { upload, analyzing, result, manual }

class _SkinTonePickerState extends State<SkinTonePicker>
    with SingleTickerProviderStateMixin {
  final _gemini = GeminiService();
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  _PickerStep _step = _PickerStep.upload;
  ColorSeasonResult? _result;
  String? _error;
  _AnalysisError? _errorType;

  // Pulse animation for the analyzing step only
  int _analysisStepIndex = 0;
  late AnimationController _pulseController;

  static const _analysisSteps = [
    'Scanning skin undertone…',
    'Reading hair pigment…',
    'Analyzing eye color…',
    'Measuring contrast level…',
    'Applying Itten color theory…',
    'Determining your season…',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // If already has a season selected, show result immediately
    if (widget.selectedUndertone != null &&
        _seasons.containsKey(widget.selectedUndertone)) {
      _step = _PickerStep.result;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _error = null;
      });
      await _runAnalysis(bytes);
    } catch (e) {
      setState(() => _error = 'Could not load image. Please try again.');
    }
  }

  Future<void> _runAnalysis(Uint8List bytes) async {
    setState(() {
      _step = _PickerStep.analyzing;
      _analysisStepIndex = 0;
    });

    if (kDemoMode) {
      // Simulate analysis steps
      for (int i = 0; i < _analysisSteps.length; i++) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        setState(() => _analysisStepIndex = i);
      }
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      widget.onUndertoneChanged('autumn');
      setState(() => _step = _PickerStep.result);
      return;
    }

    // Check if key is configured before showing analysis animation
    final gemini = _gemini;
    if (!gemini.isGeminiConfigured) {
      if (!mounted) return;
      setState(() {
        _error =
            'AI analysis needs a Gemini API key.\nGet a free one at aistudio.google.com, '
            'then add it to your .env file:\nGEMINI_API_KEY=your_key_here';
        _errorType = _AnalysisError.apiKeyMissing;
        _step = _PickerStep.manual;
      });
      return;
    }

    // Real analysis — advance step labels while Gemini runs
    final stepTimer =
        Stream.periodic(const Duration(milliseconds: 700), (i) => i)
            .take(_analysisSteps.length - 1)
            .listen((i) {
      if (mounted) setState(() => _analysisStepIndex = i + 1);
    });

    try {
      final result = await gemini.analyzeColorSeason(bytes);
      stepTimer.cancel();
      if (!mounted) return;
      widget.onUndertoneChanged(result.season);
      setState(() {
        _result = result;
        _errorType = null;
        _step = _PickerStep.result;
      });
    } on GeminiRateLimitException {
      stepTimer.cancel();
      if (!mounted) return;
      setState(() {
        _error =
            'AI is rate-limited right now — the Gemini API key is over quota. '
            'Pick your color season below for now, or try again later once the key is rotated.';
        _errorType = _AnalysisError.apiKeyMissing;
        _step = _PickerStep.manual;
      });
    } on GeminiApiKeyException catch (e) {
      stepTimer.cancel();
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _errorType = _AnalysisError.apiKeyMissing;
        _step = _PickerStep.manual;
      });
    } catch (e) {
      stepTimer.cancel();
      if (!mounted) return;
      setState(() {
        _error =
            'Analysis failed: ${e.toString().replaceAll('Exception: ', '')}';
        _errorType = _AnalysisError.genericFailure;
        _step = _PickerStep.manual;
      });
    }
  }

  void _selectManually(String key) {
    widget.onUndertoneChanged(key);
    setState(() {
      _result = null;
      _step = _PickerStep.result;
    });
  }

  void _reset() {
    setState(() {
      _imageBytes = null;
      _result = null;
      _error = null;
      _errorType = null;
      _step = _PickerStep.upload;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Your color palette',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload a selfie for AI analysis, or pick your season manually below',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildStep()),
        ],
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      _PickerStep.upload => _buildUploadStep(),
      _PickerStep.analyzing => _buildAnalyzingStep(),
      _PickerStep.result => _buildResultStep(),
      _PickerStep.manual => _buildManualStep(),
    };
  }

  // ---------------------------------------------------------------------------
  // Step 1 — Upload
  // ---------------------------------------------------------------------------

  Widget _buildUploadStep() {
    return Column(
      children: [
        // Photo circle
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.4),
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
                            size: 36,
                            color: AppTheme.primary.withValues(alpha: 0.7)),
                        const SizedBox(height: 8),
                        Text(
                          'Upload\nSelfie',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Tips card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'For best results:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ...[
                ('Natural light, no harsh flash', Icons.wb_sunny_outlined),
                ('No heavy filters or edits', Icons.filter_none_outlined),
                ('Face clearly visible', Icons.face_outlined),
                ('Natural hair color if possible', Icons.content_cut_outlined),
              ].map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        Icon(tip.$2, size: 15, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text(tip.$1,
                            style: const TextStyle(fontSize: 12, height: 1.3)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Analyze with AI',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _step = _PickerStep.manual),
            icon: const Icon(Icons.palette_outlined),
            label: const Text('Pick my season manually',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
            ),
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!,
              style: TextStyle(color: Colors.red.shade600, fontSize: 13),
              textAlign: TextAlign.center),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2 — Analyzing
  // ---------------------------------------------------------------------------

  Widget _buildAnalyzingStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Photo thumbnail
        if (_imageBytes != null)
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary, width: 3),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.memory(_imageBytes!, fit: BoxFit.cover),
            ),
          ),
        const SizedBox(height: 28),

        // Animated scanner ring
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primary
                      .withValues(alpha: 0.3 + 0.5 * _pulseController.value),
                  width: 3,
                ),
              ),
              child: const CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 2.5,
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        // Step labels
        ...List.generate(_analysisSteps.length, (i) {
          final isDone = i < _analysisStepIndex;
          final isCurrent = i == _analysisStepIndex;
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: (isDone || isCurrent) ? 1.0 : 0.25,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: isDone ? Colors.green : AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _analysisSteps[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isCurrent ? FontWeight.w700 : FontWeight.normal,
                      color: isCurrent
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3 — Result
  // ---------------------------------------------------------------------------

  Widget _buildResultStep() {
    final seasonKey = widget.selectedUndertone ?? 'spring';
    final season = _seasons[seasonKey] ?? _seasons['spring']!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Season hero card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  season.accent.withValues(alpha: 0.15),
                  season.accent.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: season.accent.withValues(alpha: 0.3), width: 1.5),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Season badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: season.accent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              season.label.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            season.subtitle,
                            style: TextStyle(
                              color: season.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Photo thumbnail if available
                    if (_imageBytes != null)
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: season.accent, width: 2.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Tagline
                Text(
                  _result?.tagline ?? season.tagline,
                  style: TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: season.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  season.description,
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),

                // AI reasoning if available
                if (_result != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                size: 13, color: season.accent),
                            const SizedBox(width: 6),
                            Text(
                              'AI Analysis  •  ${_result!.confidence}% confident',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: season.accent),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _result!.reasoning,
                          style: const TextStyle(
                              fontSize: 12, height: 1.4, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Palette
          const Text(
            'Your best colors',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: season.palette.length,
            itemBuilder: (context, i) => Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: season.palette[i],
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: season.palette[i].withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  season.paletteNames[i],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Colors to avoid
          Row(
            children: [
              Icon(Icons.block, size: 15, color: Colors.red.shade400),
              const SizedBox(width: 6),
              const Text('Colors to avoid',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(season.avoidColors.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: season.avoidColors[i],
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.red.shade300, width: 2),
                      ),
                      child: Icon(Icons.close,
                          size: 16, color: Colors.red.shade400),
                    ),
                    const SizedBox(height: 4),
                    Text(season.avoidNames[i],
                        style: const TextStyle(fontSize: 10)),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retake Photo',
                      style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _step = _PickerStep.manual),
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Change Season',
                      style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 4 — Manual selection
  // ---------------------------------------------------------------------------

  Widget _buildManualStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: _errorType == _AnalysisError.apiKeyMissing
                  ? Colors.amber.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _errorType == _AnalysisError.apiKeyMissing
                    ? Colors.amber.shade300
                    : Colors.red.shade200,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _errorType == _AnalysisError.apiKeyMissing
                      ? Icons.key_outlined
                      : Icons.error_outline,
                  size: 18,
                  color: _errorType == _AnalysisError.apiKeyMissing
                      ? Colors.amber.shade800
                      : Colors.red.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: _errorType == _AnalysisError.apiKeyMissing
                          ? Colors.amber.shade900
                          : Colors.red.shade700,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Text(
          'Which season best describes your coloring?',
          style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: _seasons.entries.map((entry) {
                final season = entry.value;
                final isSelected = widget.selectedUndertone == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => _selectManually(entry.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? season.accent.withValues(alpha: 0.08)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              isSelected ? season.accent : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Mini palette strip
                          Column(
                            children: [
                              Row(
                                children: season.palette
                                    .take(4)
                                    .map((c) => Container(
                                          width: 16,
                                          height: 16,
                                          margin:
                                              const EdgeInsets.only(right: 2),
                                          decoration: BoxDecoration(
                                            color: c,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: season.palette
                                    .skip(4)
                                    .take(4)
                                    .map((c) => Container(
                                          width: 16,
                                          height: 16,
                                          margin:
                                              const EdgeInsets.only(right: 2),
                                          decoration: BoxDecoration(
                                            color: c,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  season.label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? season.accent
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  season.subtitle,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  season.traits,
                                  style: const TextStyle(
                                      fontSize: 11, height: 1.4),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: season.celebs
                                      .map((name) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: season.accent
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              name,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: season.accent,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle,
                                color: season.accent, size: 22)
                          else
                            Icon(Icons.radio_button_unchecked,
                                color: Colors.grey.shade400, size: 22),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (_error != null || widget.selectedUndertone == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.photo_camera_outlined, size: 16),
              label: const Text('Try photo analysis instead'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            ),
          ),
      ],
    );
  }
}
