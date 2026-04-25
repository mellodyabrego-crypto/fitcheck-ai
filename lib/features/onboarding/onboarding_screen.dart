import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';
import '../../providers/user_providers.dart';
import '../../services/notification_service.dart';

import '../../core/theme.dart';
import '../../widgets/decorative_symbols.dart';
import 'widgets/dob_picker.dart';
import 'widgets/gender_picker.dart';
import 'widgets/location_picker.dart';
import 'widgets/goal_picker.dart';
import 'widgets/aesthetic_picker.dart';
import 'widgets/body_type_picker.dart';
import 'widgets/brands_picker.dart';
import 'widgets/sizes_picker.dart';
import 'widgets/skin_tone_picker.dart';
import 'widgets/color_preference_picker.dart';
import 'widgets/referral_picker.dart';
import 'widgets/permissions_picker.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isRetake = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final retake =
          GoRouterState.of(context).uri.queryParameters['retake'] == 'true';
      _isRetake = retake;
      if (!kDemoMode && !retake) _skipIfAlreadyOnboarded();
      if (retake) _hydrateExistingProfile();
    });
  }

  Future<void> _skipIfAlreadyOnboarded() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;
      final profile = await client
          .from('user_profiles')
          .select('onboarding_complete')
          .eq('user_id', userId)
          .maybeSingle();
      if ((profile?['onboarding_complete'] as bool? ?? false) && mounted) {
        context.go('/home');
      }
    } catch (_) {
      // Table doesn't exist yet or other error — stay on onboarding
    }
  }

  // Pre-fill values when the user is editing their preferences (retake=true)
  // so they don't see a blank questionnaire and have to start over.
  Future<void> _hydrateExistingProfile() async {
    if (kDemoMode) return;
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;
      final row = await client
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null || !mounted) return;
      setState(() {
        if (row['dob'] != null) {
          _dob = DateTime.tryParse(row['dob'].toString());
        }
        _gender = row['gender'] as String?;
        _country = row['country'] as String?;
        _state = row['state'] as String?;
        _selectedGoals
          ..clear()
          ..addAll((row['goals'] as List?)?.cast<String>() ?? const []);
        _selectedBodyType = row['body_type'] as String?;
        _selectedAesthetics
          ..clear()
          ..addAll((row['aesthetics'] as List?)?.cast<String>() ?? const []);
        _selectedBrands
          ..clear()
          ..addAll((row['brands'] as List?)?.cast<String>() ?? const []);
        _topSize = row['top_size'] as String?;
        _bottomSize = row['bottom_size'] as String?;
        _shoeSize = row['shoe_size'] as String?;
        _skinToneUndertone = row['skin_tone_undertone'] as String?;
        _selectedColors
          ..clear()
          ..addAll(
            (row['color_preferences'] as List?)?.cast<String>() ?? const [],
          );
        _referralSource = row['referral_source'] as String?;
        _notificationsEnabled = row['notifications_enabled'] as bool? ?? false;
        _weatherOptIn = row['weather_opt_in'] as bool? ?? false;
      });
    } catch (_) {
      // Best-effort prefill — not blocking.
    }
  }

  // Page state -------------------------------------------------------
  // Page 0 — DOB
  DateTime? _dob;
  // Page 1 — Gender
  String? _gender;
  // Page 2 — Location
  String? _country;
  String? _state;
  // Page 3 — Goals
  final Set<String> _selectedGoals = {};
  // Page 4 — Body type
  String? _selectedBodyType;
  // Page 5 — Aesthetics
  final Set<String> _selectedAesthetics = {};
  // Page 6 — Brands (optional)
  final List<String> _selectedBrands = [];
  // Page 7 — Sizes
  String? _topSize;
  String? _bottomSize;
  String? _shoeSize;
  // Page 8 — Skin tone (optional)
  String? _skinToneUndertone;
  // Page 9 — Color preferences
  final Set<String> _selectedColors = {};
  // Page 10 — Referral
  String? _referralSource;
  // Page 11 — Permissions
  bool _notificationsEnabled = false;
  bool _weatherOptIn = false;

  static const _totalPages = 12;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finishOnboarding() async {
    bool saveFailed = false;
    String? saveError;

    if (!kDemoMode) {
      try {
        final client = Supabase.instance.client;
        final userId = client.auth.currentUser?.id;
        if (userId != null) {
          await client.from('user_profiles').upsert({
            'user_id': userId,
            'dob': _dob?.toIso8601String().split('T').first,
            'gender': _gender,
            'country': _country,
            'state': _state,
            'aesthetics': _selectedAesthetics.toList(),
            'body_type': _selectedBodyType,
            'color_preferences': _selectedColors.toList(),
            'goals': _selectedGoals.toList(),
            'brands': _selectedBrands,
            'top_size': _topSize,
            'bottom_size': _bottomSize,
            'shoe_size': _shoeSize,
            'skin_tone_undertone': _skinToneUndertone,
            'referral_source': _referralSource,
            'notifications_enabled': _notificationsEnabled,
            'weather_opt_in': _weatherOptIn,
            'onboarding_complete': true,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id');
        } else {
          saveFailed = true;
          saveError = 'Not signed in — preferences saved on this device only.';
        }
      } catch (e) {
        saveFailed = true;
        saveError =
            'Could not save to cloud: $e. Preferences saved on this device only.';
      }
    }

    // If the user opted in to reminders during onboarding, register the FCM
    // token now (no-op if FCM isn't configured). Without this, the toggle
    // persists but the device_tokens row is never created and the cron has
    // nothing to send to.
    if (_notificationsEnabled && !kDemoMode) {
      // ignore: unawaited_futures
      ref.read(notificationServiceProvider).registerForCurrentUser();
    }

    // Push user preferences to providers so the rest of the app reflects them immediately.
    if (_topSize != null) ref.read(topSizeProvider.notifier).state = _topSize;
    if (_bottomSize != null) {
      ref.read(bottomSizeProvider.notifier).state = _bottomSize;
    }
    if (_shoeSize != null) {
      ref.read(shoeSizeProvider.notifier).state = _shoeSize;
    }
    if (_selectedColors.isNotEmpty) {
      ref.read(favoriteColorsProvider.notifier).state =
          _selectedColors.toList();
    }
    final season = _mapUndertoneToSeason(_skinToneUndertone);
    if (season != null) {
      ref.read(colorSeasonProvider.notifier).state = season;
    }

    if (!mounted) return;
    if (saveFailed && saveError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saveError),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.orange.shade700,
        ),
      );
    }
    // First-time onboarding shows reviews + overview before /home;
    // a "retake" goes straight back to home.
    if (_isRetake) {
      context.go('/home');
    } else {
      context.go('/reviews');
    }
  }

  bool get _canProceed {
    return switch (_currentPage) {
      0 => _dob != null,
      1 => _gender != null,
      2 => _country != null && (_state != null && _state!.isNotEmpty),
      3 => _selectedGoals.isNotEmpty,
      4 => _selectedBodyType != null,
      5 => _selectedAesthetics.isNotEmpty,
      6 => true, // brands optional
      7 => _topSize != null,
      8 => true, // skin tone optional
      9 => _selectedColors.isNotEmpty,
      10 => _referralSource != null,
      11 => true, // permissions optional — user can decline both
      _ => false,
    };
  }

  String? _mapUndertoneToSeason(String? u) {
    if (u == null || u.isEmpty) return null;
    final v = u.toLowerCase();
    if (v.contains('spring')) return 'Spring';
    if (v.contains('summer')) return 'Summer';
    if (v.contains('autumn') || v.contains('fall')) return 'Autumn';
    if (v.contains('winter')) return 'Winter';
    return null;
  }

  static const _pageTitles = [
    'Birthday',
    'About You',
    'Location',
    'Goals',
    'Body Type',
    'Style',
    'Brands',
    'Sizes',
    'Skin Tone',
    'Colors',
    'How You Found Us',
    'Permissions',
  ];

  // Optional pages — show "Optional" chip in the step header
  static const _optionalPages = {6, 8};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WithDecorations(
        sparse: true,
        child: SafeArea(
          child: Column(
            children: [
              // Progress bar + nav
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _prevPage,
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: Row(
                        children: List.generate(_totalPages, (i) {
                          return Expanded(
                            child: Container(
                              height: 4,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 1.5,
                              ),
                              decoration: BoxDecoration(
                                gradient: i <= _currentPage
                                    ? AppTheme.primaryGradient
                                    : null,
                                color: i <= _currentPage
                                    ? null
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.go(_isRetake ? '/home' : '/reviews'),
                      child: Text(
                        'Skip',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              // Step label
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                child: Row(
                  children: [
                    Text(
                      '${_currentPage + 1} of $_totalPages  •  ${_pageTitles[_currentPage]}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_optionalPages.contains(_currentPage))
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Optional',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    DobPicker(
                      selected: _dob,
                      onChanged: (v) => setState(() => _dob = v),
                    ),
                    GenderPicker(
                      selected: _gender,
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                    LocationPicker(
                      country: _country,
                      state: _state,
                      onCountryChanged: (v) => setState(() => _country = v),
                      onStateChanged: (v) => setState(() => _state = v),
                    ),
                    GoalPicker(
                      selected: _selectedGoals,
                      onChanged: (v) => setState(() {
                        if (_selectedGoals.contains(v)) {
                          _selectedGoals.remove(v);
                        } else {
                          _selectedGoals.add(v);
                        }
                      }),
                    ),
                    BodyTypePicker(
                      selected: _selectedBodyType,
                      onChanged: (v) => setState(() => _selectedBodyType = v),
                    ),
                    AestheticPicker(
                      selected: _selectedAesthetics,
                      onChanged: (v) => setState(() {
                        if (_selectedAesthetics.contains(v)) {
                          _selectedAesthetics.remove(v);
                        } else {
                          _selectedAesthetics.add(v);
                        }
                      }),
                    ),
                    BrandsPicker(
                      selected: _selectedBrands,
                      onChanged: (v) => setState(() {
                        _selectedBrands
                          ..clear()
                          ..addAll(v);
                      }),
                    ),
                    SizesPicker(
                      topSize: _topSize,
                      bottomSize: _bottomSize,
                      shoeSize: _shoeSize,
                      onTopChanged: (v) => setState(() => _topSize = v),
                      onBottomChanged: (v) => setState(() => _bottomSize = v),
                      onShoeChanged: (v) => setState(() => _shoeSize = v),
                    ),
                    SkinTonePicker(
                      selectedUndertone: _skinToneUndertone,
                      onUndertoneChanged: (v) =>
                          setState(() => _skinToneUndertone = v),
                    ),
                    ColorPreferencePicker(
                      selected: _selectedColors,
                      onChanged: (v) => setState(() {
                        if (_selectedColors.contains(v)) {
                          _selectedColors.remove(v);
                        } else {
                          _selectedColors.add(v);
                        }
                      }),
                    ),
                    ReferralPicker(
                      selected: _referralSource,
                      onChanged: (v) => setState(() => _referralSource = v),
                    ),
                    PermissionsPicker(
                      notificationsEnabled: _notificationsEnabled,
                      weatherOptIn: _weatherOptIn,
                      onNotificationsChanged: (v) =>
                          setState(() => _notificationsEnabled = v),
                      onWeatherChanged: (v) =>
                          setState(() => _weatherOptIn = v),
                    ),
                  ],
                ),
              ),

              // Continue button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _canProceed ? _nextPage : null,
                    child: Text(
                      _currentPage == _totalPages - 1
                          ? 'Get Started'
                          : 'Continue',
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
