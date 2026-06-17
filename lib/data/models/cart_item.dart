import '../../core/utils/currency_formatter.dart';

/// A single line in the cart. Captures enough product/variation snapshot data
/// to render the cart offline and to build a WooCommerce order line item.
class CartItem {
  final int productId;
  final int? variationId;
  final String name;
  final String image;
  final String price; // unit price at time of add (string, WC format)
  final String? variationLabel; // e.g. "256GB · Blue"
  final int quantity;
  final int? maxStock;

  const CartItem({
    required this.productId,
    required this.variationId,
    required this.name,
    required this.image,
    required this.price,
    required this.variationLabel,
    required this.quantity,
    required this.maxStock,
  });

  /// Stable identity — same product + variation collapses into one line.
  String get key => '$productId:${variationId ?? 0}';

  double get unitPrice => Taka.toDouble(price);
  double get lineTotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        productId: productId,
        variationId: variationId,
        name: name,
        image: image,
        price: price,
        variationLabel: variationLabel,
        quantity: quantity ?? this.quantity,
        maxStock: maxStock,
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'variationId': variationId,
        'name': name,
        'image': image,
        'price': price,
        'variationLabel': variationLabel,
        'quantity': quantity,
        'maxStock': maxStock,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json['productId'] as int,
        variationId: json['variationId'] as int?,
        name: json['name'] as String? ?? '',
        image: json['image'] as String? ?? '',
        price: json['price']?.toString() ?? '0',
        variationLabel: json['variationLabel'] as String?,
        quantity: json['quantity'] as int? ?? 1,
        maxStock: json['maxStock'] as int?,
      );

  /// WooCommerce order line_item shape.
  Map<String, dynamic> toLineItem() => {
        'product_id': productId,
        if (variationId != null && variationId != 0)
          'variation_id': variationId,
        'quantity': quantity,
      };
}
