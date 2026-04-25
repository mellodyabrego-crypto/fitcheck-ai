import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class ReferralPicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onChanged;

  const ReferralPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _options = [
    ('app_store', 'App Store', Icons.apps),
    ('online', 'Online / Search', Icons.public),
    ('chatgpt', 'ChatGPT', Icons.smart_toy_outlined),
    ('friends_family', 'Friends or Family', Icons.favorite_outline),
    ('instagram', 'Instagram', Icons.photo_camera_outlined),
    ('facebook', 'Facebook', Icons.facebook),
    ('tiktok', 'TikTok', Icons.music_note_outlined),
    ('other', 'Other', Icons.more_horiz),
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
            'How did you hear about us?',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Helps us know where to keep showing up.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final (id, label, icon) = _options[index];
                final isSelected = selected == id;
                return GestureDetector(
                  onTap: () => onChanged(id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.08)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 15,
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
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.primary,
                            size: 20,
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
