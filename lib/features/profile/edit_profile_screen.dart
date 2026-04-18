import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../main.dart';
import '../../providers/user_providers.dart';
import '../../widgets/decorative_symbols.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _newPassCtrl  = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _savingProfile  = false;
  bool _savingPassword = false;
  bool _showNewPass    = false;
  bool _showConfirm    = false;
  String? _profileError;
  String? _passwordError;

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

  void _loadCurrentProfile() {
    if (kDemoMode) {
      _nameCtrl.text  = 'Style Queen';
      _emailCtrl.text = 'demo@thecandyshop.com';
      _phoneCtrl.text = '';
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    _emailCtrl.text = user.email ?? '';
    _nameCtrl.text  = user.userMetadata?['full_name'] as String? ?? '';
    _phoneCtrl.text = user.phone ?? '';
  }

  Future<void> _saveProfile() async {
    setState(() {
      _savingProfile = true;
      _profileError  = null;
    });
    try {
      if (!kDemoMode) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
            data: {'full_name': _nameCtrl.text.trim()},
          ),
        );
      }
      if (mounted) {
        // Refresh the display name in the profile page
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
      setState(() => _passwordError = 'Password must be at least 6 characters.');
      return;
    }
    if (newPass != confirm) {
      setState(() => _passwordError = 'Passwords do not match.');
      return;
    }
    setState(() {
      _savingPassword = true;
      _passwordError  = null;
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
              // ── Profile info section ──────────────────────────────────
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
                  // Phone number update not available (requires SMS provider setup)
                  if (_profileError != null) ...[
                    const SizedBox(height: 10),
                    Text(_profileError!,
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 13)),
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
                                  strokeWidth: 2, color: Colors.white))
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
                        _showNewPass
                            ? Icons.visibility_off
                            : Icons.visibility,
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
                        _showConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _showConfirm = !_showConfirm),
                    ),
                  ),
                  if (_passwordError != null) ...[
                    const SizedBox(height: 10),
                    Text(_passwordError!,
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 13)),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _savingPassword ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary),
                      child: _savingPassword
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
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
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
