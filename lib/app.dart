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
    );
  }
}
