import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/cart_item.dart';
import '../../../providers/core_providers.dart';

/// Supported payment methods. `id`/`title` map to the WooCommerce gateway
/// slugs that must be enabled server-side (see docs/PAYMENTS.md).
enum PaymentMethod {
  sslcommerz('sslcommerz', 'SSLCommerz (Card/Nagad/Rocket)', false),
  bkash('bkash', 'bKash', false),
  cod('cod', 'Cash on Delivery', true);

  const PaymentMethod(this.id, this.title, this.isOffline);
  final String id;
  final String title;
  final bool isOffline; // offline = no payment gateway redirect needed
}

/// Customer-entered checkout details.
class CheckoutForm {
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String postcode;
  final PaymentMethod method;

  const CheckoutForm({
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.city = 'Dhaka',
    this.postcode = '',
    this.method = PaymentMethod.cod,
  });

  CheckoutForm copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? postcode,
    PaymentMethod? method,
  }) =>
      CheckoutForm(
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        address: address ?? this.address,
        city: city ?? this.city,
        postcode: postcode ?? this.postcode,
        method: method ?? this.method,
      );

  Map<String, dynamic> toBilling() => {
        'first_name': firstName,
        'last_name': lastName,
        'address_1': address,
        'city': city,
        'postcode': postcode,
        'country': 'BD',
        'email': email,
        'phone': phone,
      };

  Map<String, dynamic> toShipping() => {
        'first_name': firstName,
        'last_name': lastName,
        'address_1': address,
        'city': city,
        'postcode': postcode,
        'country': 'BD',
      };
}

/// Result of placing an order, including the gateway pay URL when an online
/// payment redirect is required.
class PlacedOrder {
  final int id;
  final String orderKey;
  final String status;
  final bool requiresPayment;
  PlacedOrder({
    required this.id,
    required this.orderKey,
    required this.status,
    required this.requiresPayment,
  });

  /// WooCommerce hosted order-pay URL — opens the configured gateway.
  String payUrl(String baseUrl) =>
      '$baseUrl/checkout/order-pay/$id?pay_for_order=true&key=$orderKey';
}

/// Places the order and (for online methods) returns the pay URL to open in a
/// WebView. Throws ApiException on failure.
class PlaceOrderController extends AsyncNotifier<PlacedOrder?> {
  @override
  Future<PlacedOrder?> build() async => null;

  Future<PlacedOrder> place({
    required List<CartItem> items,
    required CheckoutForm form,
    int? customerId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(wooServiceProvider);
      final order = await service.createOrder(
        lineItems: items.map((e) => e.toLineItem()).toList(),
        billing: form.toBilling(),
        shipping: form.toShipping(),
        paymentMethod: form.method.id,
        paymentMethodTitle: form.method.title,
        customerId: customerId,
        setPaid: false,
      );
      final placed = PlacedOrder(
        id: order['id'] as int,
        orderKey: order['order_key']?.toString() ?? '',
        status: order['status']?.toString() ?? 'pending',
        requiresPayment: !form.method.isOffline,
      );
      state = AsyncValue.data(placed);
      return placed;
    } catch (e, st) {
      // Preserve the typed ApiException for the UI to surface.
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  String get baseUrl => AppConfig.baseUrl;
}

final placeOrderProvider =
    AsyncNotifierProvider<PlaceOrderController, PlacedOrder?>(
        PlaceOrderController.new);
