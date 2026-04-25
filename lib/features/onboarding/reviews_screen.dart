import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../widgets/decorative_symbols.dart';

/// Shown right after the questionnaire on first-time onboarding.
/// The 4 testimonials below are illustrative copy — replace with real quotes
/// before any paid acquisition. <<MARKETING REVIEW>> noted in HANDOFF.md.
class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  static const _reviews = [
    (
      'Sienna R.',
      'New York, NY',
      5,
      '“My closet finally feels intentional. I open the app every morning and I’m dressed in five minutes.”',
    ),
    (
      'Mae C.',
      'Austin, TX',
      5,
      '“The color season analysis was scarily accurate. I stopped buying olive — and I’ve never gotten more compliments.”',
    ),
    (
      'Priya S.',
      'Toronto, ON',
      5,
      '“I travel for work and pack three outfits in 10 minutes now. The weather-aware suggestions are actually useful.”',
    ),
    (
      'Rachel M.',
      'London, UK',
      5,
      '“I’ve tried every wardrobe app. This is the first one that feels like a stylist, not a spreadsheet.”',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WithDecorations(
        sparse: true,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (b) =>
                          AppTheme.primaryGradient.createShader(b),
                      child: const Text(
                        'Loved by women like you',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Examples of feedback we hope to hear from you.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // FTC + App Store: placeholder testimonials must be visibly
                    // labeled. Replace this banner with real customer quotes
                    // before paid acquisition.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.accent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 13,
                            color: AppTheme.primaryDeep,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Illustrative — quotes will be real once we launch publicly.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.primaryDeep,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  itemCount: _reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final (name, city, stars, quote) = _reviews[i];
                    return _ReviewCard(
                      name: name,
                      city: city,
                      stars: stars,
                      quote: quote,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.go('/walkthrough'),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
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

class _ReviewCard extends StatelessWidget {
  final String name;
  final String city;
  final int stars;
  final String quote;

  const _ReviewCard({
    required this.name,
    required this.city,
    required this.stars,
    required this.quote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.18),
                child: Text(
                  name.substring(0, 1),
                  style: TextStyle(
                    color: AppTheme.primaryDeep,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      city,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  stars,
                  (_) => Icon(Icons.star, size: 14, color: AppTheme.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            quote,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
