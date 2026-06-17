/// WooCommerce / WordPress REST endpoint paths (relative to base URL).
class ApiConstants {
  const ApiConstants._();

  // ---- WooCommerce (wc/v3) ----
  static const String products = '/products';
  static const String categories = '/products/categories';
  static const String productVariations = '/products/{id}/variations';
  static const String reviews = '/products/reviews';
  static const String orders = '/orders';
  static const String customers = '/customers';
  static const String paymentGateways = '/payment_gateways';
  static const String shippingZones = '/shipping/zones';
  static const String coupons = '/coupons';

  // ---- WordPress core / auth ----
  static const String jwtToken = '/jwt-auth/v1/token';
  static const String jwtValidate = '/jwt-auth/v1/token/validate';
  static const String currentUser = '/wp/v2/users/me';

  static String variations(int productId) =>
      productVariations.replaceFirst('{id}', '$productId');
}
