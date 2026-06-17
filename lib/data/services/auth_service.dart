import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_exception.dart';
import '../models/app_user.dart';

/// Authentication against WordPress + WooCommerce.
///
/// Login uses the *JWT Authentication for WP REST API* plugin
/// (`/jwt-auth/v1/token`). Registration creates a WooCommerce customer
/// (`wc/v3/customers`) — a write call, so in production route it through your
/// server proxy (see docs/ARCHITECTURE.md §Security).
class AuthService {
  final Dio _dio;
  AuthService(this._dio);

  String _wc(String path) => '/${AppConfig.wcApiVersion}$path';

  /// Returns the raw JWT on success.
  Future<String> login(String username, String password) async {
    try {
      final res = await _dio.post(
        ApiConstants.jwtToken,
        data: {'username': username, 'password': password},
      );
      if (res.statusCode != null && res.statusCode! >= 400) {
        throw ApiException(
          _message(res.data) ?? 'Invalid email or password.',
          statusCode: res.statusCode,
        );
      }
      final token = (res.data as Map)['token']?.toString();
      if (token == null || token.isEmpty) {
        throw const ApiException('Login failed: no token returned.');
      }
      return token;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Fetches the signed-in user. The bearer token is attached either by the
  /// global interceptor (once stored) or explicitly via [token].
  Future<AppUser> currentUser({String? token}) async {
    try {
      final res = await _dio.get(
        ApiConstants.currentUser,
        queryParameters: const {'context': 'edit'},
        options: token != null
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );
      if (res.statusCode != null && res.statusCode! >= 400) {
        throw ApiException(_message(res.data) ?? 'Session expired.',
            statusCode: res.statusCode);
      }
      return AppUser.fromWpUser(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Creates a WooCommerce customer, then returns it.
  Future<AppUser> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final res = await _dio.post(
        _wc(ApiConstants.customers),
        data: {
          'email': email,
          'username': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
        },
        options: Options(extra: {'woo': true}),
      );
      if (res.statusCode != null && res.statusCode! >= 400) {
        throw ApiException(
          _message(res.data) ?? 'Could not create account.',
          statusCode: res.statusCode,
          code: res.data is Map ? res.data['code']?.toString() : null,
        );
      }
      return AppUser.fromWooCustomer(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  String? _message(dynamic data) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString().replaceAll(RegExp(r'<[^>]*>'), '');
    }
    return null;
  }
}
