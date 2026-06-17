/// Maps a WooCommerce `wc/v3/products/categories` item.
class ProductCategory {
  final int id;
  final String name;
  final String slug;
  final int parent;
  final int count;
  final String? image;

  const ProductCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.parent,
    required this.count,
    required this.image,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as int? ?? 0,
      name: (json['name']?.toString() ?? '')
          .replaceAll('&amp;', '&')
          .trim(),
      slug: json['slug']?.toString() ?? '',
      parent: json['parent'] as int? ?? 0,
      count: json['count'] as int? ?? 0,
      image: json['image'] is Map
          ? (json['image']['src']?.toString())
          : null,
    );
  }

  bool get isTopLevel => parent == 0;
}
