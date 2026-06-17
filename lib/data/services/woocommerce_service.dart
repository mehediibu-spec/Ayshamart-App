import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_exception.dart';

/// Thin wrapper over Dio that talks to the WooCommerce REST API. It marks
/// requests with `extra: {'woo': true}` so the auth interceptor attaches the
/// consumer key/secret and prefixes the wc/v3 namespace.
class WooCommerceService {
  final Dio _dio;
  WooCommerceService(this._dio);

  String _wc(String path) => '/${AppConfig.wcApiVersion}$path';

  Options get _wooOptions => Options(extra: {'woo': true});

  Future<List<dynamic>> getProducts({
    int page = 1,
    int perPage = AppConfig.pageSize,
    int? categoryId,
    String? search,
    bool? onSale,
    bool? featured,
    String orderBy = 'date',
    String order = 'desc',
    int? minPrice,
    int? maxPrice,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      'orderby': orderBy,
      'order': order,
      'status': 'publish',
      if (categoryId != null) 'category': categoryId,
      if (search != null && search.isNotEmpty) 'search': search,
      if (onSale == true) 'on_sale': true,
      if (featured == true) 'featured': true,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      // Only request fields we render → smaller payloads, faster + cheaper
      // through Cloudflare.
      '_fields':
          'id,name,slug,type,status,price,regular_price,sale_price,on_sale,'
              'purchasable,stock_status,stock_quantity,average_rating,'
              'rating_count,images,categories,variations',
    };
    return _getList(_wc(ApiConstants.products), query);
  }

  Future<Map<String, dynamic>> getProduct(int id) async {
    return _getObject(_wc('${ApiConstants.products}/$id'));
  }

  Future<List<dynamic>> getCategories({
    int perPage = 100,
    int? parent,
    bool hideEmpty = true,
    String orderBy = 'menu_order',
  }) async {
    final query = <String, dynamic>{
      'per_page': perPage,
      'hide_empty': hideEmpty,
      'orderby': orderBy,
      if (parent != null) 'parent': parent,
      '_fields': 'id,name,slug,parent,count,image',
    };
    return _getList(_wc(ApiConstants.categories), query);
  }

  Future<List<dynamic>> getVariations(int productId,
      {int perPage = 50}) async {
    return _getList(
      _wc(ApiConstants.variations(productId)),
      {'per_page': perPage},
    );
  }

  /// Create an order. `lineItems` = [{product_id, quantity, variation_id?}].
  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> lineItems,
    required Map<String, dynamic> billing,
    required Map<String, dynamic> shipping,
    required String paymentMethod, // e.g. 'sslcommerz', 'bkash', 'cod'
    required String paymentMethodTitle,
    int? customerId,
    List<String>? couponCodes,
    bool setPaid = false,
  }) async {
    final body = <String, dynamic>{
      'payment_method': paymentMethod,
      'payment_method_title': paymentMethodTitle,
      'set_paid': setPaid,
      'billing': billing,
      'shipping': shipping,
      'line_items': lineItems,
      if (customerId != null) 'customer_id': customerId,
      if (couponCodes != null && couponCodes.isNotEmpty)
        'coupon_lines':
            couponCodes.map((c) => {'code': c}).toList(),
    };
    try {
      final res = await _dio.post(
        _wc(ApiConstants.orders),
        data: body,
        options: _wooOptions,
      );
      _ensureOk(res);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<dynamic>> getPaymentGateways() async {
    return _getList(_wc(ApiConstants.paymentGateways), {});
  }

  // ---- helpers ----

  Future<List<dynamic>> _getList(
      String path, Map<String, dynamic> query) async {
    try {
      final res = await _dio.get(path,
          queryParameters: query, options: _wooOptions);
      _ensureOk(res);
      return (res.data as List?) ?? const [];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> _getObject(String path) async {
    try {
      final res = await _dio.get(path, options: _wooOptions);
      _ensureOk(res);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  void _ensureOk(Response res) {
    final code = res.statusCode ?? 0;
    if (code >= 400) {
      final data = res.data;
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Request failed ($code).';
      throw ApiException(
        msg.replaceAll(RegExp(r'<[^>]*>'), ''),
        statusCode: code,
        code: (data is Map) ? data['code']?.toString() : null,
      );
    }
  }
}
