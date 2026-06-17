import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/category.dart';
import '../../../data/models/product.dart';
import '../../../data/models/promo_banner.dart';
import '../../../providers/core_providers.dart';

/// Top-level categories for the category slider.
final homeCategoriesProvider =
    FutureProvider.autoDispose<List<ProductCategory>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.categories(parent: 0);
});

/// Flash-sale products (on_sale=true).
final flashSaleProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.products(onSale: true, orderBy: 'popularity');
});

/// Featured / new-arrival products grid.
final featuredProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.products(featured: true, orderBy: 'date');
});

/// Home banners. Swap the demo list for a WordPress endpoint in production
/// (see PromoBanner doc comment).
final homeBannersProvider =
    FutureProvider.autoDispose<List<PromoBanner>>((ref) async {
  return const [
    PromoBanner(
      id: 'b1',
      imageUrl:
          'https://images.unsplash.com/photo-1592286927505-1def25115558?w=1200',
      title: 'Eid Gadget Fest',
      subtitle: 'Up to 40% off flagship phones',
      deepLink: 'category:1',
    ),
    PromoBanner(
      id: 'b2',
      imageUrl:
          'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=1200',
      title: 'New MacBook Air M3',
      subtitle: 'Free delivery across Bangladesh',
      deepLink: 'product:103',
    ),
    PromoBanner(
      id: 'b3',
      imageUrl:
          'https://images.unsplash.com/photo-1606220588913-b3aacb4d2f46?w=1200',
      title: 'Audio Week',
      subtitle: 'Premium earbuds from ৳2,490',
      deepLink: 'category:3',
    ),
  ];
});
