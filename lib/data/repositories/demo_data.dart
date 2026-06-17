import '../models/category.dart';
import '../models/product.dart';

/// Bundled sample catalog so the UI renders before WooCommerce keys are wired
/// up. Replace nothing here — it is bypassed automatically once
/// AppConfig.hasCredentials is true.
class DemoData {
  const DemoData._();

  static const _img =
      'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=800';

  static List<ProductCategory> categories() => const [
        ProductCategory(
            id: 1, name: 'Smartphones', slug: 'smartphones', parent: 0, count: 64, image: null),
        ProductCategory(
            id: 2, name: 'Laptops', slug: 'laptops', parent: 0, count: 28, image: null),
        ProductCategory(
            id: 3, name: 'Earbuds', slug: 'earbuds', parent: 0, count: 41, image: null),
        ProductCategory(
            id: 4, name: 'Smart Watches', slug: 'watches', parent: 0, count: 33, image: null),
        ProductCategory(
            id: 5, name: 'Accessories', slug: 'accessories', parent: 0, count: 120, image: null),
        ProductCategory(
            id: 6, name: 'Power Banks', slug: 'power-banks', parent: 0, count: 19, image: null),
      ];

  static List<Product> products({
    bool? onSale,
    bool? featured,
    int? categoryId,
  }) {
    final all = _all;
    return all.where((p) {
      if (onSale == true && !p.onSale) return false;
      if (categoryId != null && !p.categoryIds.contains(categoryId)) {
        return false;
      }
      return true;
    }).toList();
  }

  static Product _p(
    int id,
    String name,
    String price,
    String regular,
    String sale,
    int catId,
    String catName,
  ) {
    return Product(
      id: id,
      name: name,
      slug: name.toLowerCase().replaceAll(' ', '-'),
      type: 'simple',
      status: 'publish',
      description: '',
      shortDescription: '',
      price: price,
      regularPrice: regular,
      salePrice: sale,
      onSale: sale.isNotEmpty,
      purchasable: true,
      inStock: true,
      stockQuantity: 25,
      averageRating: 4.6,
      ratingCount: 134,
      images: const [_img],
      categoryIds: [catId],
      categoryNames: [catName],
      hasVariations: false,
      variationIds: const [],
    );
  }

  static final List<Product> _all = [
    _p(101, 'iPhone 15 Pro Max 256GB', '169900', '184900', '169900', 1, 'Smartphones'),
    _p(102, 'Samsung Galaxy S24 Ultra', '154900', '164900', '154900', 1, 'Smartphones'),
    _p(103, 'MacBook Air M3 13"', '139900', '149900', '139900', 2, 'Laptops'),
    _p(104, 'Sony WF-1000XM5 Earbuds', '28900', '32900', '28900', 3, 'Earbuds'),
    _p(105, 'Apple Watch Series 9', '46900', '52900', '46900', 4, 'Smart Watches'),
    _p(106, 'Anker 20000mAh Power Bank', '4290', '5290', '4290', 6, 'Power Banks'),
    _p(107, 'Xiaomi Redmi Note 13 Pro', '32999', '36999', '32999', 1, 'Smartphones'),
    _p(108, 'Galaxy Buds3 Pro', '23900', '26900', '23900', 3, 'Earbuds'),
  ];
}
