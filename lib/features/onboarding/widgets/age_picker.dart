import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class AgePicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onChanged;

  const AgePicker({super.key, required this.selected, required this.onChanged});

  static const _ranges = [
    'Under 18',
    '18–24',
    '25–34',
    '35–44',
    '45–54',
    '55+',
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
            'How old are you?',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Helps us tailor recommendations to your life stage',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: _ranges.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final range = _ranges[index];
                final isSelected = selected == range;

                return GestureDetector(
                  onTap: () => onChanged(range),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 20),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            range,
                            style: TextStyle(
                              fontSize: 16,
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
                              color: AppTheme.primary),
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
