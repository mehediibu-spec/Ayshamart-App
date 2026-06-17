# Ayshamart — Premium Gadget Store (Flutter + WooCommerce)

A fast, modern Android (and iOS-ready) e-commerce app for **Ayshamart.com**, a
mobile & gadget retailer in Bangladesh. The app talks to the existing
WordPress + WooCommerce + WoodMart backend over the WooCommerce REST API and is
optimised for low-bandwidth networks, Cloudflare caching, professional Bengali
typography and accurate **৳ (Bangladeshi Taka)** rendering.

> Built with Flutter so a single codebase ships a highly responsive, native-feel
> UI on Android and iOS.

---

## ✨ Features

| Area | What's implemented |
|------|--------------------|
| Backend | WooCommerce REST `wc/v3` client (products, categories, variations, orders, payment gateways) |
| Performance | Riverpod state mgmt, `cached_network_image`, lazy/section-wise loading, shimmer skeletons, `_fields` payload trimming, Cloudflare-friendly GETs |
| UI/UX | Dynamic home: promo banner carousel, category slider, flash-sale countdown, new-arrivals staggered grid, branded bottom-nav shell |
| Localization | English + Bengali locales, Hind Siliguri Bengali typography, Bengali numeral + ৳ currency formatting |
| Checkout | Order creation via REST; SSLCommerz / bKash hosted-checkout flow via WebView (see `docs/PAYMENTS.md`) |
| Auth | JWT-based customer login foundation (interceptor wired) |
| Notifications | FCM + local-notification foundation (see `docs/PUSH_NOTIFICATIONS.md`) |

---

## 🧱 Tech Stack

- **Framework:** Flutter 3.22+ / Dart 3.4+
- **State management:** Riverpod 2 (compile-safe, testable, no `BuildContext` coupling)
- **Networking:** Dio (interceptors, timeouts, typed errors)
- **Routing:** go_router
- **Images:** cached_network_image (disk + memory cache, downscaling)
- **Local storage:** Hive + flutter_secure_storage (tokens)
- **Push:** firebase_messaging + flutter_local_notifications
- **Payments:** webview_flutter (SSLCommerz / bKash hosted pages)

Why Flutter over a WebView wrapper: native scrolling/animation performance,
offline image caching, push notifications, and a genuinely premium feel that a
wrapped WoodMart site can't match.

---

## 🚀 Quick start

```bash
# 1. Get dependencies
flutter pub get

# 2. Run on demo data (no keys needed — bundled sample catalog renders)
flutter run

# 3. Run against the live store (read-only key recommended on device)
flutter run \
  --dart-define=WC_BASE_URL=https://ayshamart.com \
  --dart-define=WC_CONSUMER_KEY=ck_xxxxxxxxxxxxxxxx \
  --dart-define=WC_CONSUMER_SECRET=cs_xxxxxxxxxxxxxxxx
```

Full setup (generating WooCommerce keys, fonts, Firebase, signing) is in
[`docs/SETUP.md`](docs/SETUP.md).

---

## 📂 Folder structure

```
lib/
├── main.dart                     # Entry point (bindings, orientation, runApp)
├── app.dart                      # MaterialApp, theme, locales, bottom-nav shell
├── core/
│   ├── config/app_config.dart    # --dart-define runtime config (keys, URLs)
│   ├── constants/                # colors, api paths
│   ├── network/                  # Dio client + auth interceptor, ApiException
│   ├── theme/app_theme.dart      # Material 3 theme + Bengali typography
│   ├── utils/currency_formatter.dart  # ৳ / Bengali-numeral formatting
│   └── widgets/                  # shared widgets (cached image, section header)
├── data/
│   ├── models/                   # Product, ProductCategory, PromoBanner
│   ├── services/                 # WooCommerceService (REST calls)
│   └── repositories/             # CatalogRepository (+ demo data fallback)
├── providers/core_providers.dart # Dio / service / repo / locale providers
└── features/
    └── home/
        ├── providers/            # home FutureProviders
        └── presentation/         # HomeScreen + widgets/
docs/                             # SETUP, ARCHITECTURE, PAYMENTS, PUSH...
```

Each new feature (product detail, cart, checkout, auth, search) follows the same
`features/<name>/{providers,presentation}` convention.

---

## 🗺️ Roadmap (next features to build)

1. Product detail screen + variation selector (uses `getVariations`)
2. Cart (Hive-persisted) + Checkout flow → `createOrder`
3. SSLCommerz / bKash payment WebView (`docs/PAYMENTS.md`)
4. Auth screens wired to the JWT endpoints
5. Search + category listing screens
6. FCM wiring (`docs/PUSH_NOTIFICATIONS.md`)

See `docs/ARCHITECTURE.md` for the data-flow and security model.
