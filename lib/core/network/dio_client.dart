import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/app_config.dart';

/// Configured Dio instance for the WooCommerce REST API.
///
/// Auth: WooCommerce supports HTTP Basic auth over HTTPS using the
/// consumer key/secret. We attach them as query params for GET (the most
/// Cloudflare-cache-friendly approach for read-only catalog calls) and as a
/// Basic auth header for write calls. JWT bearer tokens (customer sessions)
/// are injected per-request by the auth interceptor when available.
///
/// Cloudflare notes:
///  * Read-only GETs (products/categories) are cacheable. Keep the URL/query
///    stable so Cloudflare can serve cache HITs. Avoid cache-busting params.
///  * Set a custom User-Agent so the WAF can allow-list the app traffic and
///    you can build a Cloudflare rule that bypasses challenges for the app.
///  * Write calls (orders/cart) must never be cached — they are PO/PUT/POST
///    and Cloudflare won't cache them by default, but keep them on a path or
///    header you can match in a "bypass cache" rule.
class DioClient {
  DioClient._();

  /// Bearer token provider — set by the auth layer after login.
  static String? Function()? authTokenProvider;

  static Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: '${AppConfig.baseUrl}${AppConfig.wpApiBase}',
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          // Lets you build a Cloudflare WAF allow-list rule for app traffic.
          'X-Ayshamart-Client': 'android-app',
        },
        // Treat 4xx as responses we can inspect (WooCommerce error bodies).
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    dio.interceptors.add(_AuthInterceptor());

    if (kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          responseBody: false,
          compact: true,
        ),
      );
    }

    return dio;
  }
}

/// Injects WooCommerce key/secret + optional customer JWT, and routes the
/// request to the correct API namespace.
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) {
    final isWoo = options.path.startsWith('/wc') ||
        options.extra['woo'] == true;

    if (isWoo && AppConfig.hasCredentials) {
      final isRead = options.method.toUpperCase() == 'GET';
      if (isRead) {
        // Cache-friendly: keys travel as query params on GET.
        options.queryParameters = {
          ...options.queryParameters,
          'consumer_key': AppConfig.consumerKey,
          'consumer_secret': AppConfig.consumerSecret,
        };
      } else {
        // Writes: HTTP Basic header (do this server-side in production).
        final creds =
            '${AppConfig.consumerKey}:${AppConfig.consumerSecret}';
        final encoded = _base64(creds);
        options.headers['Authorization'] = 'Basic $encoded';
      }
    }

    // Customer session token (overrides Basic when present).
    final token = DioClient.authTokenProvider?.call();
    if (token != null && token.isNotEmpty && options.extra['woo'] != true) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  static String _base64(String input) {
    // Lightweight base64 without importing dart:convert at call sites.
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final bytes = input.codeUnits;
    final buffer = StringBuffer();
    for (var i = 0; i < bytes.length; i += 3) {
      final b0 = bytes[i];
      final b1 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      final b2 = i + 2 < bytes.length ? bytes[i + 2] : 0;
      buffer.write(chars[b0 >> 2]);
      buffer.write(chars[((b0 & 0x03) << 4) | (b1 >> 4)]);
      buffer.write(i + 1 < bytes.length
          ? chars[((b1 & 0x0f) << 2) | (b2 >> 6)]
          : '=');
      buffer.write(i + 2 < bytes.length ? chars[b2 & 0x3f] : '=');
    }
    return buffer.toString();
  }
}
