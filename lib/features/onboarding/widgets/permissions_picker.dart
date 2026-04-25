import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme.dart';

/// Combined permissions step: notifications opt-in + weather/location opt-in.
/// Tapping the weather toggle requests browser/OS geolocation immediately so the
/// user understands the trade-off; we don't silently store an opt-in without a
/// real permission grant.
class PermissionsPicker extends StatefulWidget {
  final bool notificationsEnabled;
  final bool weatherOptIn;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<bool> onWeatherChanged;

  const PermissionsPicker({
    super.key,
    required this.notificationsEnabled,
    required this.weatherOptIn,
    required this.onNotificationsChanged,
    required this.onWeatherChanged,
  });

  @override
  State<PermissionsPicker> createState() => _PermissionsPickerState();
}

class _PermissionsPickerState extends State<PermissionsPicker> {
  String? _locationStatus;
  bool _checkingLocation = false;

  Future<void> _toggleWeather(bool requested) async {
    if (!requested) {
      widget.onWeatherChanged(false);
      setState(() => _locationStatus = null);
      return;
    }
    setState(() {
      _checkingLocation = true;
      _locationStatus = null;
    });
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        widget.onWeatherChanged(false);
        if (mounted) {
          setState(() {
            _locationStatus =
                'Location was blocked — you can enable it later in your browser settings.';
            _checkingLocation = false;
          });
        }
        return;
      }
      widget.onWeatherChanged(true);
      if (mounted) {
        setState(() {
          _locationStatus = 'Location enabled — we’ll dress you for the weather.';
          _checkingLocation = false;
        });
      }
    } catch (e) {
      widget.onWeatherChanged(false);
      if (mounted) {
        setState(() {
          _locationStatus = 'Couldn’t get permission. You can try again later.';
          _checkingLocation = false;
        });
      }
    }
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
            'A few helpful permissions',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Turn these on to get the most out of Her Style Co. You can change them anytime in Settings.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 28),

          _PermTile(
            icon: Icons.notifications_active_outlined,
            title: 'Daily outfit reminder',
            subtitle:
                'A gentle nudge each morning with a look picked just for you.',
            value: widget.notificationsEnabled,
            onChanged: widget.onNotificationsChanged,
          ),
          const SizedBox(height: 14),
          _PermTile(
            icon: Icons.wb_sunny_outlined,
            title: 'Dress according to weather',
            subtitle:
                'We’ll use your location to match outfits to today’s forecast.',
            value: widget.weatherOptIn,
            onChanged: _toggleWeather,
            loading: _checkingLocation,
          ),
          if (_locationStatus != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.weatherOptIn
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.weatherOptIn
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Text(
                _locationStatus!,
                style: TextStyle(
                  fontSize: 12.5,
                  color: widget.weatherOptIn
                      ? Colors.green.shade900
                      : Colors.orange.shade900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PermTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool loading;

  const _PermTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: value
            ? AppTheme.primary.withValues(alpha: 0.06)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? AppTheme.primary : Colors.grey.shade200,
          width: value ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12.5, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child:
                      CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(
                  value: value,
                  activeColor: AppTheme.primary,
                  onChanged: onChanged,
                ),
        ],
      ),
    );
  }
}
