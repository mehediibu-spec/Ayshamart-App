import '../models/category.dart';
import '../models/product.dart';
import '../models/product_variation.dart';
import '../services/woocommerce_service.dart';
import 'demo_data.dart';

/// Repository for catalog reads (products + categories). Falls back to bundled
/// demo data when API credentials are not configured, so the UI is fully
/// previewable during development.
class CatalogRepository {
  final WooCommerceService _service;
  final bool useDemoData;

  CatalogRepository(this._service, {required this.useDemoData});

  Future<List<Product>> products({
    int page = 1,
    int? categoryId,
    String? search,
    bool? onSale,
    bool? featured,
    String orderBy = 'date',
  }) async {
    if (useDemoData) {
      return DemoData.products(
          onSale: onSale, featured: featured, categoryId: categoryId);
    }
    final raw = await _service.getProducts(
      page: page,
      categoryId: categoryId,
      search: search,
      onSale: onSale,
      featured: featured,
      orderBy: orderBy,
    );
    return raw
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Product> product(int id) async {
    if (useDemoData) return DemoData.products().firstWhere((p) => p.id == id);
    final raw = await _service.getProduct(id);
    return Product.fromJson(raw);
  }

  Future<List<ProductVariation>> variations(int productId) async {
    if (useDemoData) return const [];
    final raw = await _service.getVariations(productId);
    return raw
        .map((e) => ProductVariation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductCategory>> categories({int? parent}) async {
    if (useDemoData) return DemoData.categories();
    final raw = await _service.getCategories(parent: parent);
    return raw
        .map((e) => ProductCategory.fromJson(e as Map<String, dynamic>))
        .where((c) => c.slug != 'uncategorized')
        .toList();
  }
}
