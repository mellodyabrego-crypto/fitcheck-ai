import 'dart:js' as js;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../main.dart';
import '../../services/account_service.dart';
import '../../services/export_service.dart';
import '../../services/notification_service.dart';
import '../../services/observability_service.dart';
import '../../widgets/decorative_symbols.dart';
import '../auth/auth_controller.dart';

final _settingsProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
      if (kDemoMode) return null;
      try {
        final client = Supabase.instance.client;
        final userId = client.auth.currentUser?.id;
        if (userId == null) return null;
        return await client
            .from('user_profiles')
            .select('notifications_enabled, notification_time')
            .eq('user_id', userId)
            .maybeSingle();
      } catch (_) {
        return null;
      }
    });

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _exporting = false;
  bool _deleting = false;

  // Local override for the notification toggle. Set on tap so the Switch
  // reflects the new value instantly while the network roundtrip completes;
  // cleared once the FutureProvider returns the persisted value. Without this,
  // `ref.invalidate` flips the toggle through AsyncLoading → false → true.
  bool? _localNotifOverride;
  String? _localReminderTimeOverride;

  Future<void> _setNotificationsEnabled(bool v) async {
    if (kDemoMode) return;
    setState(() => _localNotifOverride = v);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;
      await client.from('user_profiles').upsert({
        'user_id': userId,
        'notifications_enabled': v,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
      ref.invalidate(_settingsProfileProvider);
      // Trigger the OS permission prompt + token registration when the user
      // turns reminders on. No-op if FCM isn't configured (Phase B inert).
      if (v) {
        // ignore: unawaited_futures
        ref.read(notificationServiceProvider).registerForCurrentUser();
      }
    } catch (e, st) {
      Observability.capture(e, st, tags: {'op': 'settings.notifications'});
      if (mounted) {
        // Roll back the optimistic update on failure.
        setState(() => _localNotifOverride = !v);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update — try again. ($e)')),
        );
      }
    }
  }

  /// Browser-detected IANA timezone (e.g. "America/Los_Angeles"). Persisted
  /// alongside notification_time so the daily-reminder cron can match against
  /// each user's local clock instead of UTC.
  String? _browserTimezone() {
    try {
      final intl = js.context['Intl'];
      if (intl == null) return null;
      final ctor = intl['DateTimeFormat'];
      if (ctor == null) return null;
      final dtf = js.JsObject(ctor as js.JsFunction);
      final opts = dtf.callMethod('resolvedOptions') as js.JsObject;
      final tz = opts['timeZone'];
      return (tz is String && tz.isNotEmpty) ? tz : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickReminderTime(String? current) async {
    final initial = _parseTime(current) ?? const TimeOfDay(hour: 8, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    final value = '$hh:$mm';
    if (kDemoMode) return;
    setState(() => _localReminderTimeOverride = value);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;
      // Save the raw local time + the user's IANA TZ. The cron resolves the
      // local clock per user — keeps the picker WYSIWYG (8:00 AM stays 8:00 AM
      // in the user's experience) and doesn't drift across DST boundaries.
      await client.from('user_profiles').upsert({
        'user_id': userId,
        'notification_time': value,
        'notification_tz': _browserTimezone(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
      ref.invalidate(_settingsProfileProvider);
    } catch (e, st) {
      Observability.capture(e, st, tags: {'op': 'settings.reminder_time'});
      if (mounted) {
        setState(() => _localReminderTimeOverride = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save reminder time. ($e)')),
        );
      }
    }
  }

  TimeOfDay? _parseTime(String? s) {
    if (s == null || !s.contains(':')) return null;
    final parts = s.split(':');
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTime(BuildContext context, String? s) {
    final t = _parseTime(s);
    if (t == null) return 'Not set';
    return t.format(context);
  }

  Future<void> _exportData() async {
    setState(() => _exporting = true);
    try {
      await ref.read(exportServiceProvider).exportWardrobeJson();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export downloaded — check your browser downloads.'),
          ),
        );
      }
    } on ExportException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e, st) {
      Observability.capture(e, st, tags: {'op': 'settings.export'});
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed — $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    // Step 1
    final step1 = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will block you from signing in again. We will keep an '
          'anonymized copy of your wardrobe and outfits for analytics — see the '
          'Privacy Policy for details. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(_, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (step1 != true || !mounted) return;

    // Step 2 — type-to-confirm so it can't be a stray tap.
    final controller = TextEditingController();
    final step2 = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateInner) {
          final ok = controller.text.trim().toUpperCase() == 'DELETE';
          return AlertDialog(
            title: const Text('Type DELETE to confirm'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Type the word DELETE (in caps) to permanently disable your account.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  onChanged: (_) => setStateInner(() {}),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'DELETE',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(_, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: ok ? () => Navigator.pop(_, true) : null,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete account'),
              ),
            ],
          );
        },
      ),
    );

    if (step2 != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(accountServiceProvider).deleteAccount();
      if (!mounted) return;
      context.go('/auth');
    } on AccountException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e, st) {
      Observability.capture(e, st, tags: {'op': 'settings.delete_account'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Couldn\'t delete account. $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(_settingsProfileProvider);

    // Clear the local override the moment the persisted value matches it —
    // means the round-trip succeeded and the provider is now authoritative.
    final persistedNotif =
        (profileAsync.valueOrNull?['notifications_enabled'] as bool?);
    if (_localNotifOverride != null && persistedNotif == _localNotifOverride) {
      _localNotifOverride = null;
    }
    final persistedTime =
        profileAsync.valueOrNull?['notification_time'] as String?;
    if (_localReminderTimeOverride != null &&
        persistedTime == _localReminderTimeOverride) {
      _localReminderTimeOverride = null;
    }

    final notifEnabled = _localNotifOverride ?? persistedNotif ?? false;
    final reminderTime = _localReminderTimeOverride ?? persistedTime;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: WithDecorations(
        sparse: true,
        child: ListView(
          children: [
            // Account section
            _SectionHeader(title: 'Account'),
            _SettingsTile(
              icon: Icons.manage_accounts_outlined,
              title: 'Edit Profile',
              subtitle: 'Change name, email, password, birthday, location',
              onTap: () => context.push('/profile/edit'),
            ),
            _SettingsTile(
              icon: Icons.palette_outlined,
              title: 'Edit Style Preferences',
              subtitle: 'Update your aesthetics, body type, colors',
              onTap: () => context.push('/onboarding?retake=true'),
            ),
            _SettingsTile(
              icon: Icons.diamond_outlined,
              title: 'Manage Subscription',
              subtitle: 'View or change your plan',
              onTap: () => context.push('/paywall'),
            ),

            const SizedBox(height: 16),

            // Notifications section
            _SectionHeader(title: 'Notifications'),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Daily Outfit Reminder',
              subtitle: 'A gentle nudge with an outfit picked for the day',
              trailing: Switch(
                value: notifEnabled,
                activeColor: AppTheme.primary,
                onChanged: profileAsync.isLoading
                    ? null
                    : _setNotificationsEnabled,
              ),
            ),
            _SettingsTile(
              icon: Icons.access_time,
              title: 'Reminder Time',
              subtitle: _formatTime(context, reminderTime),
              onTap: notifEnabled
                  ? () => _pickReminderTime(reminderTime)
                  : null,
              // Greyed out subtitle when notifications are off — visual cue.
              trailing: notifEnabled
                  ? const Icon(Icons.chevron_right, size: 20)
                  : Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
            ),

            const SizedBox(height: 16),

            // Data section
            _SectionHeader(title: 'Data'),
            _SettingsTile(
              icon: Icons.download,
              title: 'Export Wardrobe',
              subtitle:
                  'Download a JSON copy of your closet, outfits, and feedback',
              onTap: _exporting ? null : _exportData,
              trailing: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right, size: 20),
            ),

            const SizedBox(height: 16),

            // About section
            _SectionHeader(title: 'About'),
            _SettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              subtitle: 'How you and we agree to use the app',
              onTap: () => context.push('/terms'),
            ),
            _SettingsTile(
              icon: Icons.shield_outlined,
              title: 'Privacy Policy',
              subtitle: 'What we collect, how we use it, your rights',
              onTap: () => context.push('/privacy'),
            ),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: '1.0.0',
            ),

            const SizedBox(height: 24),

            // Sign out
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton(
                onPressed: () async {
                  if (!kDemoMode) {
                    await ref
                        .read(notificationServiceProvider)
                        .unregisterCurrentDevice();
                    await ref.read(authControllerProvider.notifier).signOut();
                  }
                  if (context.mounted) context.go('/auth');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Sign Out'),
              ),
            ),

            const SizedBox(height: 12),

            // Delete account — real, gated by 2-step confirmation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                onPressed: _deleting ? null : _confirmDeleteAccount,
                child: _deleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Delete Account',
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            )
          : null,
      trailing:
          trailing ??
          (onTap != null ? const Icon(Icons.chevron_right, size: 20) : null),
      onTap: onTap,
    );
  }
}
