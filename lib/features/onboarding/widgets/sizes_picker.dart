import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class SizesPicker extends StatelessWidget {
  final String? topSize;
  final String? bottomSize;
  final String? shoeSize;
  final ValueChanged<String> onTopChanged;
  final ValueChanged<String> onBottomChanged;
  final ValueChanged<String> onShoeChanged;

  const SizesPicker({
    super.key,
    required this.topSize,
    required this.bottomSize,
    required this.shoeSize,
    required this.onTopChanged,
    required this.onBottomChanged,
    required this.onShoeChanged,
  });

  static const _clothingSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  static const _shoeSizes = [
    '5',
    '5.5',
    '6',
    '6.5',
    '7',
    '7.5',
    '8',
    '8.5',
    '9',
    '9.5',
    '10',
    '10.5',
    '11',
    '11.5',
    '12',
    '13',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Your sizes',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'So suggestions will actually fit you',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 32),

            _SizeRow(
              label: 'Tops',
              icon: Icons.checkroom,
              sizes: _clothingSizes,
              selected: topSize,
              onChanged: onTopChanged,
            ),
            const SizedBox(height: 28),

            _SizeRow(
              label: 'Bottoms',
              icon: Icons.airline_seat_legroom_normal,
              sizes: _clothingSizes,
              selected: bottomSize,
              onChanged: onBottomChanged,
            ),
            const SizedBox(height: 28),

            // Shoe size — horizontal scroll
            Row(
              children: [
                const Icon(Icons.do_not_step,
                    color: AppTheme.textSecondary, size: 20),
                const SizedBox(width: 8),
                const Text('Shoes (US)',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _shoeSizes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final size = _shoeSizes[index];
                  final isSelected = shoeSize == size;
                  return GestureDetector(
                    onTap: () => onShoeChanged(size),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        size,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color:
                              isSelected ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SizeRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> sizes;
  final String? selected;
  final ValueChanged<String> onChanged;

  const _SizeRow({
    required this.label,
    required this.icon,
    required this.sizes,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: sizes.map((size) {
            final isSelected = selected == size;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => onChanged(size),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppTheme.primary : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      size,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
