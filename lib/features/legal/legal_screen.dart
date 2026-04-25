import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/decorative_symbols.dart';
import 'legal_text.dart';

/// Renders either the Terms of Service or the Privacy Policy from the plain-text
/// strings in [legal_text.dart]. Wrapped in [WithDecorations] per the project
/// hard rule.
class LegalScreen extends StatelessWidget {
  final String title;
  final String body;

  const LegalScreen({super.key, required this.title, required this.body});

  factory LegalScreen.terms({Key? key}) =>
      LegalScreen(key: key, title: 'Terms of Service', body: kTermsOfService);

  factory LegalScreen.privacy({Key? key}) =>
      LegalScreen(key: key, title: 'Privacy Policy', body: kPrivacyPolicy);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Semantics(header: true, child: Text(title))),
      body: WithDecorations(
        sparse: true,
        child: SafeArea(
          child: Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: SelectableText(
                body,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
