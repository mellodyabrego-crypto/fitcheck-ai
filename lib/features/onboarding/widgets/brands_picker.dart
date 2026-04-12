import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class BrandsPicker extends StatefulWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const BrandsPicker(
      {super.key, required this.selected, required this.onChanged});

  @override
  State<BrandsPicker> createState() => _BrandsPickerState();
}

class _BrandsPickerState extends State<BrandsPicker> {
  final _controller = TextEditingController();
  String _query = '';

  static const _suggestions = [
    'Zara', 'H&M', 'Uniqlo', 'Nike', 'Adidas', "Levi's", 'Gap', 'ASOS',
    'Free People', 'Anthropologie', 'Madewell', 'J.Crew', 'Ralph Lauren',
    'Tommy Hilfiger', 'Calvin Klein', 'Gucci', 'Louis Vuitton', 'Prada',
    'Balenciaga', 'Off-White', 'Forever 21', 'Target', 'Urban Outfitters',
    'Reformation', 'Everlane', 'Patagonia', 'Supreme', 'Jordan', 'New Balance',
    'Shein', 'Princess Polly', 'Revolve', 'Nordstrom', 'Banana Republic',
  ];

  void _add(String brand) {
    final trimmed = brand.trim();
    if (trimmed.isEmpty || widget.selected.length >= 5) return;
    if (widget.selected.map((b) => b.toLowerCase()).contains(trimmed.toLowerCase())) return;
    widget.onChanged([...widget.selected, trimmed]);
    _controller.clear();
    setState(() => _query = '');
  }

  void _remove(String brand) {
    widget.onChanged(widget.selected.where((b) => b != brand).toList());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _suggestions
        .where((b) =>
            _query.isEmpty ||
            b.toLowerCase().contains(_query.toLowerCase()))
        .where((b) => !widget.selected
            .map((s) => s.toLowerCase())
            .contains(b.toLowerCase()))
        .take(15)
        .toList();

    final canAdd = widget.selected.length < 5;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Your go-to brands',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            canAdd
                ? 'Add up to 5 brands you wear most  (${widget.selected.length}/5)'
                : 'Great choices! (${widget.selected.length}/5)',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 20),

          // Selected chips
          if (widget.selected.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.selected
                  .map((brand) => Chip(
                        label: Text(brand,
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600)),
                        backgroundColor:
                            AppTheme.primary.withValues(alpha: 0.1),
                        side: const BorderSide(color: AppTheme.primary),
                        deleteIconColor: AppTheme.primary,
                        onDeleted: () => _remove(brand),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Search input
          if (canAdd)
            TextField(
              controller: _controller,
              onChanged: (v) => setState(() => _query = v),
              onSubmitted: _add,
              decoration: InputDecoration(
                hintText: 'Search or type a brand...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: AppTheme.primary),
                        onPressed: () => _add(_query),
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppTheme.primary, width: 2),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Suggestions
          if (canAdd && filtered.isNotEmpty) ...[
            Text('Popular brands',
                style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: filtered
                      .map((brand) => GestureDetector(
                            onTap: () => _add(brand),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add,
                                      size: 14,
                                      color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(brand,
                                      style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ] else if (!canAdd)
            Center(
              child: Column(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppTheme.primary, size: 40),
                  const SizedBox(height: 8),
                  Text("You've added 5 brands — perfect!",
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
