import '../../core/utils/currency_formatter.dart';

/// Maps a WooCommerce `wc/v3/products` item to a strongly-typed model.
class Product {
  final int id;
  final String name;
  final String slug;
  final String type; // simple | variable | grouped | external
  final String status;
  final String description;
  final String shortDescription;
  final String price; // current price (string from WC)
  final String regularPrice;
  final String salePrice;
  final bool onSale;
  final bool purchasable;
  final bool inStock;
  final int? stockQuantity;
  final double averageRating;
  final int ratingCount;
  final List<String> images;
  final List<int> categoryIds;
  final List<String> categoryNames;
  final bool hasVariations;
  final List<int> variationIds;

  const Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.type,
    required this.status,
    required this.description,
    required this.shortDescription,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    required this.onSale,
    required this.purchasable,
    required this.inStock,
    required this.stockQuantity,
    required this.averageRating,
    required this.ratingCount,
    required this.images,
    required this.categoryIds,
    required this.categoryNames,
    required this.hasVariations,
    required this.variationIds,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final categories = (json['categories'] as List? ?? const []);
    final images = (json['images'] as List? ?? const [])
        .map((e) => (e['src'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toList();

    return Product(
      id: json['id'] as int? ?? 0,
      name: _decode(json['name']?.toString() ?? ''),
      slug: json['slug']?.toString() ?? '',
      type: json['type']?.toString() ?? 'simple',
      status: json['status']?.toString() ?? 'publish',
      description: json['description']?.toString() ?? '',
      shortDescription: json['short_description']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      regularPrice: json['regular_price']?.toString() ?? '0',
      salePrice: json['sale_price']?.toString() ?? '',
      onSale: json['on_sale'] as bool? ?? false,
      purchasable: json['purchasable'] as bool? ?? false,
      inStock: (json['stock_status']?.toString() ?? 'instock') == 'instock',
      stockQuantity: json['stock_quantity'] as int?,
      averageRating:
          double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0,
      ratingCount: json['rating_count'] as int? ?? 0,
      images: images,
      categoryIds:
          categories.map<int>((e) => e['id'] as int? ?? 0).toList(),
      categoryNames: categories
          .map<String>((e) => _decode(e['name']?.toString() ?? ''))
          .toList(),
      hasVariations: (json['type']?.toString() ?? '') == 'variable',
      variationIds: (json['variations'] as List? ?? const [])
          .map<int>((e) => e is int ? e : int.tryParse('$e') ?? 0)
          .toList(),
    );
  }

  String get primaryImage => images.isNotEmpty ? images.first : '';

  int get discountPercent => Taka.discountPercent(regularPrice, salePrice);

  String formattedPrice(String locale) =>
      Taka.formatForLocale(price, locale);

  String formattedRegularPrice(String locale) =>
      Taka.formatForLocale(regularPrice, locale);

  /// Strip WP-encoded HTML entities commonly present in titles.
  static String _decode(String input) => input
      .replaceAll('&amp;', '&')
      .replaceAll('&#038;', '&')
      .replaceAll('&#8211;', '–')
      .replaceAll('&#8217;', '’')
      .replaceAll('&quot;', '"')
      .replaceAll('&nbsp;', ' ')
      .trim();
}
