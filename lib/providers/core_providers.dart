import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/network/dio_client.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/services/woocommerce_service.dart';

/// Shared Dio instance.
final dioProvider = Provider<Dio>((ref) => DioClient.create());

/// WooCommerce service.
final wooServiceProvider = Provider<WooCommerceService>(
  (ref) => WooCommerceService(ref.watch(dioProvider)),
);

/// Catalog repository (auto-falls back to demo data without credentials).
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(
    ref.watch(wooServiceProvider),
    useDemoData: !AppConfig.hasCredentials,
  ),
);

/// Active locale code ('en' | 'bn'). Drives currency digit rendering.
final localeCodeProvider = StateProvider<String>((ref) => 'en');
