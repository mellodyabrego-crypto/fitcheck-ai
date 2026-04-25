import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';
import '../../widgets/walkthrough_overlay.dart';
import '../../widgets/lazy_indexed_stack.dart';
import '../../services/analytics_service.dart';
import '../wardrobe/wardrobe_screen.dart';
import '../outfits/outfit_history_screen.dart';
import '../shop/shop_screen.dart';
import '../network/network_screen.dart';
import '../calendar/calendar_screen.dart';
import '../fashion/fashion_screen.dart';
import '../profile/profile_screen.dart';
import '../../core/theme.dart';

final homeTabProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _screens = [
    WardrobeScreen(),
    OutfitHistoryScreen(),
    ShopScreen(),
    NetworkScreen(),
    CalendarScreen(),
    FashionScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // After the first frame, if the logged-in user hasn't completed onboarding,
    // redirect to it. This ensures first-time users (including OAuth arrivals
    // who land on /home directly) still see the questionnaire.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeRouteToOnboarding(),
    );
  }

  Future<void> _maybeRouteToOnboarding() async {
    if (kDemoMode) return;
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;
      final profile = await client
          .from('user_profiles')
          .select('onboarding_complete')
          .eq('user_id', user.id)
          .maybeSingle();
      final done = (profile?['onboarding_complete'] as bool?) ?? false;
      if (!done && mounted) context.go('/onboarding');
    } catch (_) {
      // Silent — if the check fails, stay on /home rather than blocking the UI.
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(homeTabProvider);

    return WalkthroughOverlay(
      child: Scaffold(
        body: LazyIndexedStack(index: currentTab, children: _screens),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200, width: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: currentTab,
            onTap: (index) {
              ref.read(homeTabProvider.notifier).state = index;
              const tabNames = [
                'closet',
                'outfits',
                'shop',
                'network',
                'calendar',
                'fashion',
                'profile',
              ];
              Analytics.screen('home_tab', props: {'tab': tabNames[index]});
            },
            selectedFontSize: 10,
            unselectedFontSize: 10,
            iconSize: 22,
            elevation: 0,
            backgroundColor: Colors.transparent,
            // primaryDeep meets WCAG AA contrast vs white; primary (#C48A96)
            // does not (3.2:1).
            selectedItemColor: AppTheme.primaryDeep,
            unselectedItemColor: AppTheme.textSecondary,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.checkroom_outlined),
                activeIcon: Icon(Icons.checkroom),
                label: 'My Closet',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome_outlined),
                activeIcon: Icon(Icons.auto_awesome),
                label: 'Outfits',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag_outlined),
                activeIcon: Icon(Icons.shopping_bag),
                label: 'Shop',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Network',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined),
                activeIcon: Icon(Icons.calendar_month),
                label: 'Calendar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.play_circle_outline),
                activeIcon: Icon(Icons.play_circle),
                label: 'Fashion',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ), // Scaffold
    ); // WalkthroughOverlay
  }
}
