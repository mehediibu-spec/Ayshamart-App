import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/core_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../providers/checkout_provider.dart';
import 'order_success_screen.dart';
import 'payment_webview.dart';

/// Single-page checkout: contact + shipping form, payment method, order
/// summary and place-order. Free delivery assumed; wire real shipping zones
/// later via WooCommerceService.shippingZones.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController(text: 'Dhaka');
  final _postcode = TextEditingController();

  PaymentMethod _method = PaymentMethod.cod;
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    // Prefill contact details for signed-in customers.
    final user = ref.read(authControllerProvider).user;
    if (user != null) {
      _firstName.text = user.firstName;
      _lastName.text = user.lastName;
      _email.text = user.email;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _phone,
      _email,
      _address,
      _city,
      _postcode
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final locale = ref.watch(localeCodeProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Contact & Shipping'),
            Row(
              children: [
                Expanded(child: _field(_firstName, 'First name')),
                const SizedBox(width: 12),
                Expanded(child: _field(_lastName, 'Last name')),
              ],
            ),
            const SizedBox(height: 12),
            _field(_phone, 'Phone (01XXXXXXXXX)',
                keyboard: TextInputType.phone, validator: _validatePhone),
            const SizedBox(height: 12),
            _field(_email, 'Email (optional)',
                keyboard: TextInputType.emailAddress, required: false),
            const SizedBox(height: 12),
            _field(_address, 'Full address',
                maxLines: 2, hint: 'House, road, area'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(flex: 2, child: _field(_city, 'City')),
                const SizedBox(width: 12),
                Expanded(
                    child: _field(_postcode, 'Postcode', required: false)),
              ],
            ),

            const SizedBox(height: 8),
            _section('Payment Method'),
            ...PaymentMethod.values.map(_paymentTile),

            const SizedBox(height: 8),
            _section('Order Summary'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('${item.name}  ×${item.quantity}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13)),
                          ),
                          Text(Taka.formatForLocale(item.lineTotal, locale),
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  const Divider(height: 20),
                  _summaryRow('Subtotal',
                      Taka.formatForLocale(subtotal, locale)),
                  const SizedBox(height: 6),
                  _summaryRow('Delivery', 'Free'),
                  const Divider(height: 20),
                  _summaryRow(
                    'Total',
                    Taka.formatForLocale(subtotal, locale),
                    emphasize: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: ElevatedButton(
          onPressed: (_placing || items.isEmpty) ? null : _placeOrder,
          child: _placing
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Text(_method == PaymentMethod.cod
                  ? 'Place Order'
                  : 'Place Order & Pay'),
        ),
      ),
    );
  }

  // ---- order placement ----

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    final items = ref.read(cartProvider);
    if (items.isEmpty) return;

    setState(() => _placing = true);
    final form = CheckoutForm(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      address: _address.text.trim(),
      city: _city.text.trim(),
      postcode: _postcode.text.trim(),
      method: _method,
    );

    try {
      final controller = ref.read(placeOrderProvider.notifier);
      // Attaches the order to the customer account when signed in (else guest).
      final customerId = ref.read(currentCustomerIdProvider);
      final placed = await controller.place(
        items: items,
        form: form,
        customerId: customerId,
      );

      // Online payment → open gateway WebView and reconcile.
      if (placed.requiresPayment) {
        final outcome = await Navigator.of(context).push<PaymentOutcome>(
          MaterialPageRoute(
            builder: (_) =>
                PaymentWebView(url: placed.payUrl(controller.baseUrl)),
          ),
        );
        if (!mounted) return;
        if (outcome != PaymentOutcome.success) {
          _toast(outcome == PaymentOutcome.cancelled
              ? 'Payment cancelled. Your order is saved as pending.'
              : 'Payment failed. Please try again.');
          setState(() => _placing = false);
          return;
        }
        // Reconcile authoritative status from WooCommerce.
        final fresh =
            await ref.read(wooServiceProvider).getOrder(placed.id);
        final status = fresh['status']?.toString() ?? placed.status;
        _onSuccess(placed.id, status);
        return;
      }

      // Offline (COD) → done.
      _onSuccess(placed.id, placed.status);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _placing = false);
        _toast(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _placing = false);
        _toast('Could not place order. Please try again.');
      }
    }
  }

  void _onSuccess(int orderId, String status) {
    ref.read(cartProvider.notifier).clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OrderSuccessScreen(
          orderId: orderId,
          statusLabel: _statusLabel(status),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'processing':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'on-hold':
        return 'Awaiting payment';
      default:
        return 'Pending confirmation';
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ));
  }

  // ---- form helpers ----

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 10),
        child: Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700)),
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
    int maxLines = 1,
    bool required = true,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: validator ??
          (v) {
            if (!required) return null;
            if (v == null || v.trim().isEmpty) return '$label is required';
            return null;
          },
    );
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone is required';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 11) return 'Enter a valid Bangladeshi number';
    return null;
  }

  Widget _paymentTile(PaymentMethod method) {
    final selected = _method == method;
    return GestureDetector(
      onTap: () => setState(() => _method = method),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(_iconFor(method),
                color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(method.title,
                  style: TextStyle(
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500)),
            ),
            Radio<PaymentMethod>(
              value: method,
              groupValue: _method,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _method = v!),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.sslcommerz:
        return Icons.credit_card_rounded;
      case PaymentMethod.bkash:
        return Icons.account_balance_wallet_rounded;
      case PaymentMethod.cod:
        return Icons.local_shipping_rounded;
    }
  }

  Widget _summaryRow(String label, String value, {bool emphasize = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              color: emphasize ? AppColors.textPrimary : AppColors.textMuted,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
              fontSize: emphasize ? 16 : 14,
            )),
        Text(value,
            style: TextStyle(
              color: emphasize ? AppColors.primary : AppColors.textPrimary,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              fontSize: emphasize ? 18 : 14,
            )),
      ],
    );
  }
}
