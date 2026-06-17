import '../../core/utils/currency_formatter.dart';

/// One purchasable variation of a `variable` WooCommerce product
/// (e.g. "256GB / Titanium Blue").
class ProductVariation {
  final int id;
  final String price;
  final String regularPrice;
  final String salePrice;
  final bool onSale;
  final bool inStock;
  final int? stockQuantity;
  final String? image;

  /// attribute name → selected option, e.g. {"Storage": "256GB", "Color": "Blue"}.
  final Map<String, String> attributes;

  const ProductVariation({
    required this.id,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    required this.onSale,
    required this.inStock,
    required this.stockQuantity,
    required this.image,
    required this.attributes,
  });

  factory ProductVariation.fromJson(Map<String, dynamic> json) {
    final attrs = <String, String>{};
    for (final a in (json['attributes'] as List? ?? const [])) {
      final name = (a['name'] ?? '').toString();
      final option = (a['option'] ?? '').toString();
      if (name.isNotEmpty) attrs[name] = option;
    }
    return ProductVariation(
      id: json['id'] as int? ?? 0,
      price: json['price']?.toString() ?? '0',
      regularPrice: json['regular_price']?.toString() ?? '0',
      salePrice: json['sale_price']?.toString() ?? '',
      onSale: json['on_sale'] as bool? ?? false,
      inStock: (json['stock_status']?.toString() ?? 'instock') == 'instock',
      stockQuantity: json['stock_quantity'] as int?,
      image: json['image'] is Map ? json['image']['src']?.toString() : null,
      attributes: attrs,
    );
  }

  int get discountPercent => Taka.discountPercent(regularPrice, salePrice);

  /// Human label like "256GB · Titanium Blue".
  String get label => attributes.values.join(' · ');
}
