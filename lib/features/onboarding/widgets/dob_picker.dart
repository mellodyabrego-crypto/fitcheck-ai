import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class DobPicker extends StatelessWidget {
  final DateTime? selected;
  final ValueChanged<DateTime?> onChanged;

  const DobPicker({super.key, required this.selected, required this.onChanged});

  static String _format(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    // Cap at 13+ to comply with COPPA-style minimums.
    final initial = selected ?? DateTime(now.year - 25, now.month, now.day);
    final last = DateTime(now.year - 13, now.month, now.day);
    final first = DateTime(now.year - 100, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(last) ? last : initial,
      firstDate: first,
      lastDate: last,
      helpText: 'Your date of birth',
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                  primary: AppTheme.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'When’s your birthday?',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'We use your age to tune outfit suggestions — nothing more.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => _pickDate(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: selected != null
                    ? AppTheme.primary.withValues(alpha: 0.08)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected != null
                      ? AppTheme.primary
                      : Colors.grey.shade200,
                  width: selected != null ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.cake_outlined,
                      color: selected != null
                          ? AppTheme.primary
                          : AppTheme.textSecondary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      selected != null ? _format(selected!) : 'Tap to choose',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: selected != null
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected != null
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
