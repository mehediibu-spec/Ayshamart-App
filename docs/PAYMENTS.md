# Payments — SSLCommerz, bKash & Cash on Delivery

Bangladesh-friendly checkout. The cleanest, most secure integration for a mobile
app reuses your **existing WooCommerce payment gateways** via a **hosted
checkout page in a WebView** — you do not handle card/wallet credentials in the
app, and settlement/IPN stays on your trusted WordPress backend.

## Strategy overview

```
App → create WooCommerce order (status: pending)
    → open gateway payment URL in WebView
       ├─ Cash on Delivery: no gateway; order set to "processing", done.
       ├─ SSLCommerz: redirect to SSLCommerz hosted page
       └─ bKash: redirect to bKash PGW page
    → listen for success/fail/cancel redirect URL in the WebView
    → confirm final order status via REST, show result screen
```

Why hosted (WebView) over native SDK first: fastest to ship, PCI scope stays on
the gateway, and WooCommerce's IPN/callback already updates order status
server-side. You can add native bKash Tokenized SDK later for a slicker flow.

## 1. Server-side gateway setup (one-time)

- **SSLCommerz:** install *SSLCommerz for WooCommerce*, enter Store ID/Password
  (sandbox first), enable. Supports cards, bKash, Nagad, Rocket, internet banking
  in one checkout — often the simplest single integration for BD.
- **bKash (direct):** install the official *bKash PGW* plugin, enter app
  key/secret/username/password, set the callback URL.
- **Cash on Delivery:** WooCommerce → Settings → Payments → enable COD.

Verify available methods at runtime:
```dart
final gateways = await wooService.getPaymentGateways(); // returns enabled list
```

## 2. App checkout flow (code sketch)

```dart
// 1) Create the order as pending
final order = await wooService.createOrder(
  lineItems: cart.toLineItems(),          // [{product_id, quantity, variation_id?}]
  billing: billingMap,
  shipping: shippingMap,
  paymentMethod: 'sslcommerz',            // or 'bkash' / 'cod'
  paymentMethodTitle: 'SSLCommerz',
  customerId: auth.customerId,
  setPaid: false,
);

// 2) COD → done immediately
if (method == 'cod') { showSuccess(order); return; }

// 3) Online → open the gateway. Easiest: open the order-pay URL, which WooCommerce
//    renders and which hands off to the configured gateway:
final payUrl =
    '${AppConfig.baseUrl}/checkout/order-pay/${order['id']}'
    '?pay_for_order=true&key=${order['order_key']}';

await Navigator.push(context, MaterialPageRoute(
  builder: (_) => PaymentWebView(
    url: payUrl,
    successHosts: const ['ayshamart.com'],
    onResult: (status) => handlePaymentResult(order['id'], status),
  ),
));

// 4) Re-fetch order to confirm final status set by the gateway IPN
final fresh = await wooService.getProduct; // use getOrder(id) in your impl
```

## 3. PaymentWebView (skeleton)

```dart
class PaymentWebView extends StatefulWidget {
  final String url;
  final List<String> successHosts;
  final void Function(String status) onResult;
  // ...
}

// In initState, configure a WebViewController and a NavigationDelegate.
// onNavigationRequest: inspect the redirect URL. WooCommerce returns to URLs
// containing "order-received" (success) or "?cancel_order" (cancelled). Match
// those, pop the WebView, and call onResult('success' | 'failed' | 'cancelled').
```

> Match redirect URLs, not page content. SSLCommerz/bKash both redirect back to
> your `order-received` (thank-you) URL on success and to the checkout URL with a
> cancel flag on failure/cancel.

## 4. Reconcile (never trust the client)

Always re-query the order status from WooCommerce after the WebView closes; the
authoritative state is set server-side by the gateway IPN/callback, not by the
redirect. Show your success screen only when the order status is `processing`,
`completed`, or `on-hold` (bank transfer).

## 5. Later: native bKash Tokenized Checkout

For a one-tap in-app bKash experience, integrate the bKash Tokenized Checkout
through a small server endpoint (create payment → execute payment) and a native
deep link. Keep all bKash secrets server-side. This is an enhancement over the
hosted flow above, not a prerequisite.

## Test checklist

- [ ] Sandbox SSLCommerz: success, failed, cancelled paths each handled
- [ ] bKash sandbox number completes and order flips to `processing`
- [ ] COD creates an order without opening a WebView
- [ ] App re-reads order status before showing success
- [ ] Prices/totals match WooCommerce exactly (compare ৳ amounts)
```
