/// Central runtime configuration for the Ayshamart app.
///
/// NEVER hard-code production WooCommerce keys in source that ships to the
/// store. The Consumer Key/Secret grant read+write access to your shop.
/// Pass them at build time via `--dart-define` (see docs/SETUP.md):
///
///   flutter run \
///     --dart-define=WC_BASE_URL=https://ayshamart.com \
///     --dart-define=WC_CONSUMER_KEY=ck_xxx \
///     --dart-define=WC_CONSUMER_SECRET=cs_xxx
///
/// For production you should proxy write operations (orders, account
/// creation) through a thin serverless function so the secret never lives
/// on-device. Read-only catalog calls can use a read-only key + Cloudflare
/// caching. See docs/ARCHITECTURE.md.
class AppConfig {
  const AppConfig._();

  /// Storefront base URL (no trailing slash).
  static const String baseUrl = String.fromEnvironment(
    'WC_BASE_URL',
    defaultValue: 'https://ayshamart.com',
  );

  /// WooCommerce REST API consumer key (prefer a READ-ONLY key on device).
  static const String consumerKey = String.fromEnvironment(
    'WC_CONSUMER_KEY',
    defaultValue: '',
  );

  static const String consumerSecret = String.fromEnvironment(
    'WC_CONSUMER_SECRET',
    defaultValue: '',
  );

  /// WooCommerce REST API version.
  static const String wcApiVersion = 'wc/v3';

  /// WordPress JWT/auth endpoint base (for customer login). Requires the
  /// "JWT Authentication for WP REST API" plugin or similar.
  static const String wpApiBase = '/wp-json';

  /// Default page size for paginated product lists.
  static const int pageSize = 20;

  /// Network timeouts.
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 25);

  /// True when API credentials are present (lets the UI degrade gracefully
  /// to demo data during development).
  static bool get hasCredentials =>
      consumerKey.isNotEmpty && consumerSecret.isNotEmpty;
}
