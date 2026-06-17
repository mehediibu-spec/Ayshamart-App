import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/models/product.dart';
import '../../../data/models/promo_banner.dart';
import '../../cart/presentation/cart_screen.dart';
import '../../cart/providers/cart_provider.dart';
import '../../product/presentation/product_detail_screen.dart';
import '../providers/home_providers.dart';
import 'widgets/category_slider.dart';
import 'widgets/flash_sale_section.dart';
import 'widgets/product_card.dart';
import 'widgets/promo_banner_carousel.dart';

/// Dynamic, scrollable home screen: search header → banners → categories →
/// flash sale → featured grid. Each section is independently loaded via
/// Riverpod so a slow request never blocks the rest of the page (a key
/// perceived-performance win).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(homeBannersProvider);
    final categories = ref.watch(homeCategoriesProvider);
    final flashSale = ref.watch(flashSaleProvider);
    final featured = ref.watch(featuredProductsProvider);

    Future<void> refresh() async {
      ref.invalidate(homeBannersProvider);
      ref.invalidate(homeCategoriesProvider);
      ref.invalidate(flashSaleProvider);
      ref.invalidate(featuredProductsProvider);
      await Future.wait([
        ref.read(homeCategoriesProvider.future),
        ref.read(flashSaleProvider.future),
        ref.read(featuredProductsProvider.future),
      ]);
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: refresh,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              const _HomeAppBar(),

              // Banners
              SliverToBoxAdapter(
                child: banners.when(
                  data: (data) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: PromoBannerCarousel(
                      banners: data,
                      onTap: (b) => _handleDeepLink(context, b),
                    ),
                  ),
                  loading: () => const _BannerShimmer(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // Categories
              SliverToBoxAdapter(
                child: categories.when(
                  data: (data) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                          title: 'Shop by Category', actionLabel: 'See all'),
                      CategorySlider(
                        categories: data,
                        onTap: (c) {/* TODO: push category screen */},
                      ),
                    ],
                  ),
                  loading: () => const _CategoryShimmer(),
                  error: (e, __) => _SectionError(message: '$e'),
                ),
              ),

              // Flash sale
              SliverToBoxAdapter(
                child: flashSale.when(
                  data: (data) => FlashSaleSection(
                    products: data,
                    endsAt: DateTime.now()
                        .add(const Duration(hours: 5, minutes: 32)),
                    onProductTap: (p) => _openProduct(context, p),
                    onAddToCart: (p) => _addToCart(context, ref, p),
                  ),
                  loading: () => const _RowShimmer(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // Featured grid header
              const SliverToBoxAdapter(
                child: SectionHeader(
                    title: 'New Arrivals', actionLabel: 'See all'),
              ),

              // Featured staggered grid
              featured.when(
                data: (data) => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverMasonryGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childCount: data.length,
                    itemBuilder: (context, i) => ProductCard(
                      product: data[i],
                      onTap: () => _openProduct(context, data[i]),
                      onAddToCart: () => _addToCart(context, ref, data[i]),
                    ),
                  ),
                ),
                loading: () => const SliverToBoxAdapter(child: _GridShimmer()),
                error: (e, __) =>
                    SliverToBoxAdapter(child: _SectionError(message: '$e')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDeepLink(BuildContext context, PromoBanner banner) {
    // TODO: parse banner.deepLink ("category:3" | "product:101" | "url:...")
    // and navigate via go_router.
  }

  void _openProduct(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }

  void _addToCart(BuildContext context, WidgetRef ref, Product product) {
    // Variable products need options chosen → open the detail page instead.
    if (product.hasVariations) {
      _openProduct(context, product);
      return;
    }
    ref.read(cartProvider.notifier).add(
          CartItem(
            productId: product.id,
            variationId: null,
            name: product.name,
            image: product.primaryImage,
            price: product.price,
            variationLabel: null,
            quantity: 1,
            maxStock: product.stockQuantity,
          ),
        );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${product.name} added to cart'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          duration: const Duration(milliseconds: 1200),
        ),
      );
  }
}

/// Sticky, branded app bar with a location row, cart action and search field.
class _HomeAppBar extends ConsumerWidget {
  const _HomeAppBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      toolbarHeight: 64,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Ayshamart',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              Text('Deliver to Dhaka',
                  style: TextStyle(
                      fontSize: 11.5, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
              icon: const Icon(Icons.shopping_bag_outlined),
            ),
            if (cartCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: const BoxDecoration(
                      color: AppColors.sale, shape: BoxShape.circle),
                  child: Text('$cartCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            readOnly: true,
            onTap: () {/* TODO: push search screen */},
            decoration: InputDecoration(
              hintText: 'Search phones, laptops, gadgets…',
              prefixIcon: const Icon(Icons.search_rounded),
              fillColor: AppColors.scaffold,
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer placeholders
// ---------------------------------------------------------------------------

class _Shimmer extends StatelessWidget {
  final Widget child;
  const _Shimmer({required this.child});
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: child,
      );
}

class _BannerShimmer extends StatelessWidget {
  const _BannerShimmer();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: _Shimmer(
          child: Container(
            height: 175,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      );
}

class _CategoryShimmer extends StatelessWidget {
  const _CategoryShimmer();
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 130,
        child: _Shimmer(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, __) => Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                ),
                const SizedBox(height: 8),
                Container(width: 48, height: 10, color: Colors.white),
              ],
            ),
          ),
        ),
      );
}

class _RowShimmer extends StatelessWidget {
  const _RowShimmer();
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 260,
        child: _Shimmer(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => Container(
              width: 168,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      );
}

class _GridShimmer extends StatelessWidget {
  const _GridShimmer();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: _Shimmer(
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.62,
            children: List.generate(
              4,
              (_) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      );
}

class _SectionError extends StatelessWidget {
  final String message;
  const _SectionError({required this.message});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      );
}
