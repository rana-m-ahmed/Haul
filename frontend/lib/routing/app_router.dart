import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../features/dev/presentation/gallery_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/presentation/preferences_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/visual_search/presentation/scan_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/product/presentation/product_screen.dart';
import '../features/cart/presentation/cart_screen.dart';
import '../features/checkout/presentation/checkout_screen.dart';
import '../features/orders/presentation/order_success_screen.dart';
import '../features/orders/presentation/orders_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import 'main_scaffold.dart';

part 'app_router.g.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/gallery',
        builder: (context, state) => const GalleryScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/preferences',
        builder: (context, state) => const PreferencesScreen(),
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) => const ScanScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) => ProductScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/product/:id/reviews',
        builder: (context, state) => Scaffold(body: Center(child: Text('Product Reviews ${state.pathParameters['id']}'))),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order/:id/success',
        builder: (context, state) => OrderSuccessScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          int currentIndex = 0;
          if (state.uri.path.startsWith('/search')) currentIndex = 1;
          if (state.uri.path.startsWith('/cart')) currentIndex = 2;
          if (state.uri.path.startsWith('/profile')) currentIndex = 3;

          return MainScaffold(
            currentIndex: currentIndex,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => SearchScreen(initialQuery: state.uri.queryParameters['q']),
          ),
          GoRoute(
            path: '/cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
