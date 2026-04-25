import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class LocationPicker extends StatefulWidget {
  final String? country;
  final String? state;
  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<String?> onStateChanged;

  const LocationPicker({
    super.key,
    required this.country,
    required this.state,
    required this.onCountryChanged,
    required this.onStateChanged,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();

  // Curated list, weighted toward where Her Style Co. expects users.
  // "Other" allows write-in via the state field.
  static const _countries = [
    'United States',
    'Canada',
    'United Kingdom',
    'Australia',
    'New Zealand',
    'Ireland',
    'Mexico',
    'Brazil',
    'Argentina',
    'France',
    'Germany',
    'Italy',
    'Spain',
    'Netherlands',
    'Sweden',
    'Norway',
    'Denmark',
    'Finland',
    'Portugal',
    'Switzerland',
    'Belgium',
    'Austria',
    'Poland',
    'Greece',
    'Turkey',
    'United Arab Emirates',
    'Saudi Arabia',
    'India',
    'Pakistan',
    'Singapore',
    'Hong Kong',
    'Japan',
    'South Korea',
    'Philippines',
    'Indonesia',
    'Thailand',
    'Vietnam',
    'South Africa',
    'Nigeria',
    'Egypt',
    'Other',
  ];

  static const _usStates = [
    'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado',
    'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho',
    'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana',
    'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
    'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada',
    'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
    'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon',
    'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota',
    'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
    'West Virginia', 'Wisconsin', 'Wyoming', 'District of Columbia',
  ];
}

class _LocationPickerState extends State<LocationPicker> {
  late final TextEditingController _stateCtrl;

  @override
  void initState() {
    super.initState();
    _stateCtrl = TextEditingController(text: widget.state ?? '');
  }

  @override
  void didUpdateWidget(LocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-seed the field when the parent's state value changes externally —
    // happens on country change (parent resets state to null) and on profile
    // hydration (retake / edit profile fills it in after async load).
    final external = widget.state ?? '';
    if (external != _stateCtrl.text) {
      _stateCtrl.value = TextEditingValue(
        text: external,
        selection: TextSelection.collapsed(offset: external.length),
      );
    }
  }

  @override
  void dispose() {
    _stateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUs = widget.country == 'United States';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Where do you live?',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Helps us match outfits to your climate and the brands available near you.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 24),

          Text('Country',
              style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: widget.country,
                hint: const Text('Choose your country'),
                items: LocationPicker._countries
                    .map((c) =>
                        DropdownMenuItem<String>(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  widget.onCountryChanged(v);
                  // Reset state when country changes — old US state is meaningless
                  // for a new country. didUpdateWidget will clear the controller.
                  widget.onStateChanged(null);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(isUs ? 'State' : 'State / Region',
              style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (isUs)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: widget.state,
                  hint: const Text('Choose your state'),
                  items: LocationPicker._usStates
                      .map((s) =>
                          DropdownMenuItem<String>(value: s, child: Text(s)))
                      .toList(),
                  onChanged: widget.onStateChanged,
                ),
              ),
            )
          else
            TextField(
              controller: _stateCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Ontario, Bavaria, NSW',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              onChanged: (v) =>
                  widget.onStateChanged(v.trim().isEmpty ? null : v),
            ),
        ],
      ),
    );
  }
}
