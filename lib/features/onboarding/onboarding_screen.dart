import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';

import '../../core/theme.dart';
import 'widgets/goal_picker.dart';
import 'widgets/age_picker.dart';
import 'widgets/aesthetic_picker.dart';
import 'widgets/body_type_picker.dart';
import 'widgets/brands_picker.dart';
import 'widgets/sizes_picker.dart';
import 'widgets/skin_tone_picker.dart';
import 'widgets/color_preference_picker.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Page 0 — Goals
  final Set<String> _selectedGoals = {};
  // Page 1 — Age
  String? _selectedAge;
  // Page 2 — Body type
  String? _selectedBodyType;
  // Page 3 — Aesthetics
  final Set<String> _selectedAesthetics = {};
  // Page 4 — Brands (optional)
  final List<String> _selectedBrands = [];
  // Page 5 — Sizes
  String? _topSize;
  String? _bottomSize;
  String? _shoeSize;
  // Page 6 — Skin tone (optional)
  String? _skinToneUndertone;
  // Page 7 — Color preferences
  final Set<String> _selectedColors = {};

  static const _totalPages = 8;

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
    if (!kDemoMode) {
      try {
        final client = Supabase.instance.client;
        final userId = client.auth.currentUser?.id;
        if (userId != null) {
          await client.from('user_profiles').upsert({
            'user_id': userId,
            'aesthetics': _selectedAesthetics.toList(),
            'body_type': _selectedBodyType,
            'color_preferences': _selectedColors.toList(),
            'goals': _selectedGoals.toList(),
            'age_range': _selectedAge,
            'brands': _selectedBrands,
            'top_size': _topSize,
            'bottom_size': _bottomSize,
            'shoe_size': _shoeSize,
            'skin_tone_undertone': _skinToneUndertone,
            'onboarding_complete': true,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id');
        }
      } catch (_) {
        // Don't block navigation on save failure
      }
    }
    if (mounted) context.go('/home');
  }

  bool get _canProceed {
    return switch (_currentPage) {
      0 => _selectedGoals.isNotEmpty,
      1 => _selectedAge != null,
      2 => _selectedBodyType != null,
      3 => _selectedAesthetics.isNotEmpty,
      4 => true, // brands optional
      5 => _topSize != null,
      6 => true, // skin tone optional
      7 => _selectedColors.isNotEmpty,
      _ => false,
    };
  }

  static const _pageTitles = [
    'Goals',
    'Age',
    'Body Type',
    'Style',
    'Brands',
    'Sizes',
    'Skin Tone',
    'Colors',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: i <= _currentPage
                                  ? AppTheme.primary
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text('Skip',
                        style: TextStyle(color: AppTheme.textSecondary)),
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
                  if (_currentPage == 4 || _currentPage == 6)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Optional',
                            style: TextStyle(fontSize: 11)),
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
                  // Page 0 — Goals
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

                  // Page 1 — Age
                  AgePicker(
                    selected: _selectedAge,
                    onChanged: (v) => setState(() => _selectedAge = v),
                  ),

                  // Page 2 — Body type
                  BodyTypePicker(
                    selected: _selectedBodyType,
                    onChanged: (v) => setState(() => _selectedBodyType = v),
                  ),

                  // Page 3 — Aesthetics
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

                  // Page 4 — Brands (optional)
                  BrandsPicker(
                    selected: _selectedBrands,
                    onChanged: (v) => setState(() {
                      _selectedBrands
                        ..clear()
                        ..addAll(v);
                    }),
                  ),

                  // Page 5 — Sizes
                  SizesPicker(
                    topSize: _topSize,
                    bottomSize: _bottomSize,
                    shoeSize: _shoeSize,
                    onTopChanged: (v) => setState(() => _topSize = v),
                    onBottomChanged: (v) => setState(() => _bottomSize = v),
                    onShoeChanged: (v) => setState(() => _shoeSize = v),
                  ),

                  // Page 6 — Skin tone (optional)
                  SkinTonePicker(
                    selectedUndertone: _skinToneUndertone,
                    onUndertoneChanged: (v) =>
                        setState(() => _skinToneUndertone = v),
                  ),

                  // Page 7 — Color preferences
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
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
