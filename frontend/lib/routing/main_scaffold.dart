import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_shadows.dart';

// Dummy cart provider for validation
final cartItemCountProvider = StateProvider<int>((ref) => 0);

class MainScaffold extends ConsumerWidget {
  final Widget child;
  final int currentIndex;

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  void _onItemTapped(int index, BuildContext context) {
    if (index == 0) context.go('/home');
    if (index == 1) context.go('/search');
    if (index == 2) context.go('/cart');
    if (index == 3) context.go('/profile');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      body: Stack(
        children: [
          child,
          // Camera FAB Positioned above bottom nav
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: _CameraFab(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.pebble, width: 1)),
        ),
        child: NavigationBar(
          backgroundColor: AppColors.warmWhite,
          selectedIndex: currentIndex,
          onDestinationSelected: (index) => _onItemTapped(index, context),
          indicatorColor: AppColors.signal.withValues(alpha: 0.1),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined, color: AppColors.pebble),
              selectedIcon: Icon(Icons.home, color: AppColors.signal),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.search_outlined, color: AppColors.pebble),
              selectedIcon: Icon(Icons.search, color: AppColors.signal),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text(cartCount.toString(), style: const TextStyle(color: AppColors.warmWhite, fontSize: 10)),
                backgroundColor: AppColors.signal,
                child: const Icon(Icons.shopping_cart_outlined, color: AppColors.pebble),
              ),
              selectedIcon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text(cartCount.toString(), style: const TextStyle(color: AppColors.warmWhite, fontSize: 10)),
                backgroundColor: AppColors.signal,
                child: const Icon(Icons.shopping_cart, color: AppColors.signal),
              ),
              label: 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline, color: AppColors.pebble),
              selectedIcon: Icon(Icons.person, color: AppColors.signal),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraFab extends StatefulWidget {
  @override
  State<_CameraFab> createState() => _CameraFabState();
}

class _CameraFabState extends State<_CameraFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _animation,
          child: GestureDetector(
            onTap: () => context.go('/scan'),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.signal,
                shape: BoxShape.circle,
                boxShadow: AppShadows.high,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: AppColors.warmWhite,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'SCAN',
          style: AppTypography.labelSM.copyWith(color: AppColors.signal),
        ),
      ],
    );
  }
}
