import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/constants/app_colors.dart';

/// Outcome of a hosted-gateway payment session.
enum PaymentOutcome { success, failed, cancelled }

/// Hosts the WooCommerce order-pay page (which hands off to SSLCommerz / bKash)
/// and resolves the outcome by matching the redirect URL — NOT page content.
///
/// WooCommerce returns to:
///   * `.../order-received/...`  → success (thank-you page)
///   * checkout URL with `cancel_order=true` / `?cancelled` → cancelled
/// Always reconcile the true status via REST afterwards (see docs/PAYMENTS.md).
class PaymentWebView extends StatefulWidget {
  final String url;
  const PaymentWebView({super.key, required this.url});

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            final outcome = _classify(request.url);
            if (outcome != null) {
              _resolve(outcome);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  PaymentOutcome? _classify(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('order-received') ||
        lower.contains('payment=success') ||
        lower.contains('status=success')) {
      return PaymentOutcome.success;
    }
    if (lower.contains('cancel_order') ||
        lower.contains('cancelled') ||
        lower.contains('payment=failed') ||
        lower.contains('status=failed')) {
      return PaymentOutcome.failed;
    }
    return null;
  }

  void _resolve(PaymentOutcome outcome) {
    if (_resolved) return;
    _resolved = true;
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop && !_resolved) {
          _resolve(PaymentOutcome.cancelled);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Secure Payment'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => _resolve(PaymentOutcome.cancelled),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const LinearProgressIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.border,
              ),
          ],
        ),
      ),
    );
  }
}
