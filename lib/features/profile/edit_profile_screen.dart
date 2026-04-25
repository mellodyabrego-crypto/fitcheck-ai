import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../main.dart';
import '../../providers/user_providers.dart';
import '../../widgets/decorative_symbols.dart';
import '../onboarding/widgets/location_picker.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // About You section
  DateTime? _dob;
  String? _gender;
  String? _country;
  String? _state;

  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _showNewPass = false;
  bool _showConfirm = false;
  String? _profileError;
  String? _passwordError;

  static const _genderOptions = [
    ('woman', 'Woman'),
    ('man', 'Man'),
    ('non_binary', 'Non-Binary'),
    ('prefer_not', 'Prefer Not to Say'),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    if (kDemoMode) {
      _nameCtrl.text = 'Style Queen';
      _emailCtrl.text = 'demo@thecandyshop.com';
      _phoneCtrl.text = '';
      return;
    }
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    _emailCtrl.text = user.email ?? '';
    _nameCtrl.text = user.userMetadata?['full_name'] as String? ?? '';
    _phoneCtrl.text = user.phone ?? '';

    try {
      final row = await client
          .from('user_profiles')
          .select('dob, gender, country, state')
          .eq('user_id', user.id)
          .maybeSingle();
      if (row != null && mounted) {
        setState(() {
          if (row['dob'] != null) {
            _dob = DateTime.tryParse(row['dob'].toString());
          }
          _gender = row['gender'] as String?;
          _country = row['country'] as String?;
          _state = row['state'] as String?;
        });
      }
    } catch (_) {
      // Best-effort — falls back to empty fields.
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final last = DateTime(now.year - 13, now.month, now.day);
    final initial = _dob ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(last) ? last : initial,
      firstDate: DateTime(now.year - 100, 1, 1),
      lastDate: last,
      helpText: 'Your date of birth',
    );
    if (picked != null && mounted) setState(() => _dob = picked);
  }

  Future<void> _saveProfile() async {
    setState(() {
      _savingProfile = true;
      _profileError = null;
    });
    try {
      if (!kDemoMode) {
        final client = Supabase.instance.client;
        await client.auth.updateUser(
          UserAttributes(
            email: _emailCtrl.text.trim().isEmpty
                ? null
                : _emailCtrl.text.trim(),
            data: {'full_name': _nameCtrl.text.trim()},
          ),
        );
        final userId = client.auth.currentUser?.id;
        if (userId != null) {
          await client.from('user_profiles').upsert({
            'user_id': userId,
            'dob': _dob?.toIso8601String().split('T').first,
            'gender': _gender,
            'country': _country,
            'state': _state,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id');
        }
      }
      if (mounted) {
        ref.read(displayNameProvider.notifier).state = _nameCtrl.text.trim();
        context.showSnackBar('Profile updated!');
      }
    } on AuthException catch (e) {
      setState(() => _profileError = e.message);
    } catch (e) {
      setState(() => _profileError = 'Could not save — try again.');
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    final newPass = _newPassCtrl.text;
    final confirm = _confirmCtrl.text;

    if (newPass.length < 6) {
      setState(
        () => _passwordError = 'Password must be at least 6 characters.',
      );
      return;
    }
    if (newPass != confirm) {
      setState(() => _passwordError = 'Passwords do not match.');
      return;
    }
    setState(() {
      _savingPassword = true;
      _passwordError = null;
    });
    try {
      if (!kDemoMode) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: newPass),
        );
      }
      _newPassCtrl.clear();
      _confirmCtrl.clear();
      if (mounted) context.showSnackBar('Password updated!');
    } on AuthException catch (e) {
      setState(() => _passwordError = e.message);
    } catch (e) {
      setState(() => _passwordError = 'Could not update password.');
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  String _formatDob(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: WithDecorations(
        sparse: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Personal info section ─────────────────────────────────
              _SectionCard(
                title: 'Personal Info',
                icon: Icons.person_outline,
                children: [
                  _Field(
                    controller: _nameCtrl,
                    label: 'Display Name',
                    hint: 'e.g. Style Queen',
                    icon: Icons.badge_outlined,
                    inputType: TextInputType.name,
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    controller: _emailCtrl,
                    label: 'Email Address',
                    hint: 'you@example.com',
                    icon: Icons.email_outlined,
                    inputType: TextInputType.emailAddress,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── About You section (DOB, gender, country, state) ───────
              _SectionCard(
                title: 'About You',
                icon: Icons.cake_outlined,
                children: [
                  // DOB
                  InkWell(
                    onTap: _pickDob,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        prefixIcon: const Icon(Icons.cake_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                      ),
                      child: Text(
                        _dob != null ? _formatDob(_dob!) : 'Tap to choose',
                        style: TextStyle(
                          fontSize: 15,
                          color: _dob != null
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: const Icon(Icons.wc_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                    items: _genderOptions
                        .map(
                          (opt) => DropdownMenuItem(
                            value: opt.$1,
                            child: Text(opt.$2),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  const SizedBox(height: 14),
                  // Reuse the picker UI for consistency
                  LocationPicker(
                    country: _country,
                    state: _state,
                    onCountryChanged: (v) => setState(() {
                      _country = v;
                      _state = null;
                    }),
                    onStateChanged: (v) => setState(() => _state = v),
                  ),
                  if (_profileError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _profileError!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _savingProfile ? null : _saveProfile,
                      child: _savingProfile
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Change password section ───────────────────────────────
              _SectionCard(
                title: 'Change Password',
                icon: Icons.lock_outline,
                children: [
                  _Field(
                    controller: _newPassCtrl,
                    label: 'New Password',
                    hint: 'Min 6 characters',
                    icon: Icons.lock_outlined,
                    obscure: !_showNewPass,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showNewPass ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _showNewPass = !_showNewPass),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    controller: _confirmCtrl,
                    label: 'Confirm Password',
                    hint: 'Repeat new password',
                    icon: Icons.lock_outlined,
                    obscure: !_showConfirm,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirm ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _showConfirm = !_showConfirm),
                    ),
                  ),
                  if (_passwordError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _passwordError!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _savingPassword ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                      ),
                      child: _savingPassword
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Update Password'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Reusable section card ────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable text field ──────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType inputType;
  final bool obscure;
  final Widget? suffixIcon;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.inputType = TextInputType.text,
    this.obscure = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}
