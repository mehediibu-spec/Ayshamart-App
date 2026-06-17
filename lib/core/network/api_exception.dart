import 'package:dio/dio.dart';

/// Normalised API failure surfaced to the UI/repository layer.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code; // WooCommerce error code, e.g. "woocommerce_rest_..."

  const ApiException(this.message, {this.statusCode, this.code});

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
            'Connection timed out. Please check your internet and try again.');
      case DioExceptionType.connectionError:
        return const ApiException(
            'Unable to reach Ayshamart. Please check your connection.');
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        final status = e.response?.statusCode;
        if (data is Map && data['message'] != null) {
          return ApiException(
            _stripHtml(data['message'].toString()),
            statusCode: status,
            code: data['code']?.toString(),
          );
        }
        return ApiException('Request failed (${status ?? 'unknown'}).',
            statusCode: status);
      case DioExceptionType.cancel:
        return const ApiException('Request cancelled.');
      default:
        return ApiException(e.message ?? 'Something went wrong.');
    }
  }

  static String _stripHtml(String input) =>
      input.replaceAll(RegExp(r'<[^>]*>'), '').trim();

  @override
  String toString() => message;
}
