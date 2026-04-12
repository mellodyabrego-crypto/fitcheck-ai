import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class GoalPicker extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onChanged;

  const GoalPicker({super.key, required this.selected, required this.onChanged});

  static const _goals = [
    ('outfit_ideas', 'Get outfit ideas', Icons.auto_awesome, Color(0xFF6C5CE7)),
    ('capsule', 'Build a capsule wardrobe', Icons.grid_view, Color(0xFF00B894)),
    ('track', 'Track what I wear', Icons.calendar_today, Color(0xFF0984E3)),
    ('find_style', 'Find my personal style', Icons.search, Color(0xFFE17055)),
    ('intentional', 'Shop more intentionally', Icons.eco, Color(0xFF00CEC9)),
    ('daily', 'Look put-together daily', Icons.wb_sunny, Color(0xFFF39C12)),
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
            'What brings you here?',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that apply',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: _goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final (id, label, icon, color) = _goals[index];
                final isSelected = selected.contains(id);

                return GestureDetector(
                  onTap: () => onChanged(id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.1)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected ? color : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: color, size: 22),
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
