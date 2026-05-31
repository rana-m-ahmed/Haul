import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/wishlist_provider.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/widgets/haul_states.dart';
import '../../product/domain/product_provider.dart';
import '../domain/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null || userId.startsWith('guest_')) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text('PROFILE', style: AppTypography.titleLG.copyWith(color: AppColors.ink)),
        ),
        body: Center(
          child: HaulEmptyState(
            title: 'Sign in to see your profile',
            message: 'Track orders, save wishlists, and more.',
            actionLabel: 'SIGN IN',
            onAction: () => context.push('/onboarding'),
          ),
        ),
      );
    }

    final profileAsync = ref.watch(profileNotifierProvider);
    final wishlistIds = ref.watch(wishlistNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('PROFILE', style: AppTypography.titleLG.copyWith(color: AppColors.ink)),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long, color: AppColors.ink),
            onPressed: () => context.push('/orders'),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            profileAsync.when(
              data: (profile) {
                final name = profile['displayName'] as String;
                final email = profile['email'] as String;
                final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: AppTypography.displayMD.copyWith(
                            color: AppColors.warmWhite,
                            fontFamily: 'Syne',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: AppTypography.titleLG.copyWith(color: AppColors.ink)),
                            if (email.isNotEmpty)
                              Text(email, style: AppTypography.bodySM.copyWith(color: AppColors.stone)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text('Edit', style: AppTypography.labelMD.copyWith(color: AppColors.signal)),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator(color: AppColors.signal)),
              ),
              error: (err, st) => const SizedBox(),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Wishlist Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Text('WISHLIST', style: AppTypography.labelSM.copyWith(color: AppColors.stone)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${wishlistIds.length}', style: AppTypography.labelSM.copyWith(color: AppColors.ink)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            
            if (wishlistIds.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
                child: Text('Save items you love. ♡', style: AppTypography.bodySM.copyWith(color: AppColors.stone)),
              )
            else
              SizedBox(
                height: 140, // 2 rows of 64px + 12px gap
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: wishlistIds.length,
                  itemBuilder: (context, index) {
                    final productId = wishlistIds.elementAt(index);
                    return _WishlistThumbnail(productId: productId);
                  },
                ),
              ),

            const SizedBox(height: AppSpacing.xl),

            // Settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('SETTINGS', style: AppTypography.labelSM.copyWith(color: AppColors.stone)),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SettingsTile(
              title: 'Notifications',
              trailing: Switch(
                value: true,
                onChanged: (_) {},
                activeTrackColor: AppColors.signal,
              ),
            ),
            const Divider(height: 1),
            _SettingsTile(
              title: 'Language',
              trailing: Text('English', style: AppTypography.bodyMD.copyWith(color: AppColors.stone)),
            ),
            const Divider(height: 1),
            _SettingsTile(
              title: 'Help & Support',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.stone),
              onTap: () {},
            ),
            const Divider(height: 1),
            _SettingsTile(
              title: 'Log Out',
              titleColor: AppColors.errorCrimson,
              onTap: () async {
                ref.read(cartNotifierProvider.notifier).clearCart();
                ref.read(wishlistNotifierProvider.notifier).clearWishlist();
                await ref.read(authNotifierProvider.notifier).logOut();
                if (context.mounted) {
                  context.go('/onboarding');
                }
              },
            ),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.title,
    this.trailing = const SizedBox(),
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: AppTypography.bodyMD.copyWith(color: titleColor ?? AppColors.ink)),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    );
  }
}

class _WishlistThumbnail extends ConsumerWidget {
  final String productId;
  const _WishlistThumbnail({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(productNotifierProvider(productId));
    final product = productState.product;

    if (product == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return GestureDetector(
      onTap: () => context.push('/product/$productId'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: product.imageUrl ?? 'https://placehold.co/64x64/png',
          fit: BoxFit.cover,
          memCacheWidth: 200,
        ),
      ),
    );
  }
}
