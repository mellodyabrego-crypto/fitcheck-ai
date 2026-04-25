import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../core/constants.dart';

final accountServiceProvider = Provider<AccountService>((ref) {
  return AccountService();
});

class AccountException implements Exception {
  final String message;
  const AccountException(this.message);
  @override
  String toString() => message;
}

class AccountService {
  static String get _deleteUrl {
    final s = AppConstants.supabaseUrl;
    if (s.isEmpty) return '';
    return '${s.replaceAll(RegExp(r'/+$'), '')}/functions/v1/delete-account';
  }

  /// Calls the `delete-account` edge function. The user is banned from auth
  /// (cannot log in again) and their profile is stamped with `deleted_at`,
  /// but ALL DATA IS RETAINED for analytics — see HANDOFF.md.
  ///
  /// On success, signs the user out locally so the app returns to /auth.
  Future<void> deleteAccount() async {
    final session = sb.Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw const AccountException('Not signed in.');
    }
    if (_deleteUrl.isEmpty) {
      throw const AccountException(
        'Backend not configured — contact support to delete your account.',
      );
    }

    final res = await http.post(
      Uri.parse(_deleteUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
        'apikey': AppConstants.supabaseAnonKey,
      },
      body: jsonEncode({'confirm': 'DELETE'}),
    );

    if (res.statusCode == 200 || res.statusCode == 207) {
      // 207 = banned but profile flag failed; treat as success client-side.
      await sb.Supabase.instance.client.auth.signOut();
      return;
    }

    String message = 'Could not delete account.';
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['error'] is String) {
        message = decoded['error'] as String;
      }
    } catch (_) {}
    throw AccountException(message);
  }
}
