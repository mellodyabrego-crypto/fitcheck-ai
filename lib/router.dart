import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/home_screen.dart';
import 'features/wardrobe/add_item_screen.dart';
import 'features/outfits/outfit_screen.dart';
import 'features/outfits/generate_screen.dart';
import 'features/fit_check/fit_check_screen.dart';
import 'features/subscription/paywall_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/profile/edit_profile_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      if (kDemoMode) return null;

      Session? session;
      try {
        session = Supabase.instance.client.auth.currentSession;
      } catch (_) {
        // Supabase not initialized (missing env) — treat as logged out
        session = null;
      }
      final isLoggedIn = session != null;
      final location = state.matchedLocation;

      // Not logged in — send to auth
      if (!isLoggedIn && location != '/auth') return '/auth';

      // Logged in but stuck on auth — go to onboarding (onboarding will skip to home if already done)
      if (isLoggedIn && location == '/auth') return '/onboarding';

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/wardrobe/add',
        builder: (context, state) => const AddItemScreen(),
      ),
      GoRoute(
        path: '/outfit/:id',
        builder: (context, state) => OutfitScreen(
          outfitId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/fit-check/:outfitId',
        builder: (context, state) => FitCheckScreen(
          outfitId: state.pathParameters['outfitId']!,
        ),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/generate',
        builder: (context, state) => const GenerateScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );
});
