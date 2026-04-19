import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'router.dart';

class GRWMApp extends ConsumerWidget {
  const GRWMApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Her Style Co.',
      theme: AppTheme.light,
      // Force light theme on every device — the "dark" theme isn't styled for
      // Her Style Co. and caused text-on-background contrast bugs on phones set
      // to system dark mode.
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // Honor the user's OS-level text scaling, but clamp it so layouts don't
      // blow up at extreme settings (a11y best practice — never ignore it).
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final clamped = media.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.4,
        );
        return MediaQuery(
          data: media.copyWith(textScaler: clamped),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
