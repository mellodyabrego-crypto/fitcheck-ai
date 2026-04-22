import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class AestheticPicker extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onChanged;

  const AestheticPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _aesthetics = [
    ('minimalist', 'Minimalist', Icons.crop_square, AppTheme.primary),
    ('streetwear', 'Streetwear', Icons.skateboarding, AppTheme.accent),
    ('preppy', 'Preppy', Icons.school, AppTheme.primaryDeep),
    ('y2k', 'Y2K', Icons.star, AppTheme.primary),
    ('cottagecore', 'Cottagecore', Icons.local_florist, AppTheme.accent),
    ('casual', 'Casual', Icons.weekend, AppTheme.primaryDeep),
    ('formal', 'Formal', Icons.business_center, AppTheme.primary),
    ('bohemian', 'Bohemian', Icons.auto_awesome, AppTheme.accent),
    ('athleisure', 'Athleisure', Icons.fitness_center, AppTheme.primaryDeep),
    ('vintage', 'Vintage', Icons.camera_alt, AppTheme.accent),
    ('edgy', 'Edgy', Icons.bolt, AppTheme.primary),
    ('romantic', 'Romantic', Icons.favorite, AppTheme.primaryDeep),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'What\'s your style?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick all that vibe with you',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _aesthetics.length,
              itemBuilder: (context, index) {
                final (id, label, icon, color) = _aesthetics[index];
                final isSelected = selected.contains(id);

                return GestureDetector(
                  onTap: () => onChanged(id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.1)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textPrimary,
                          ),
                        ),
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(Icons.check_circle,
                                color: AppTheme.primary, size: 16),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
