# Architecture

## Layers

```
┌──────────────────────────────────────────────┐
│ Presentation  (features/*/presentation)       │  Widgets, screens
│   ▲ watch / read                              │
│ Providers     (Riverpod)                      │  UI state, async caching
│   ▲                                           │
│ Repositories  (data/repositories)             │  Maps DTO→model, demo fallback
│   ▲                                           │
│ Services      (data/services)                 │  WooCommerceService (Dio)
│   ▲                                           │
│ Network       (core/network)                  │  Dio + auth interceptor
└──────────────────────────────────────────────┘
        │ HTTPS (WooCommerce REST wc/v3)
        ▼
   Cloudflare  →  WordPress + WooCommerce + WoodMart
```

**Why this shape:** screens never call Dio directly. They watch a provider,
which calls a repository, which calls the service. This keeps the UI testable,
lets us swap demo↔live data with one flag, and isolates the one place credentials
are attached (the interceptor).

## State management — Riverpod

- `FutureProvider.autoDispose` per home section → each loads independently, so a
  slow flash-sale call never blocks banners/categories from painting.
- `ref.invalidate(...)` powers pull-to-refresh.
- `localeCodeProvider` (StateProvider) drives ৳ digit rendering app-wide.

## Performance budget

| Technique | Where |
|-----------|-------|
| Trim API payloads with `_fields` | `WooCommerceService.getProducts/getCategories` |
| Section-wise async loading | `home_screen.dart` slivers |
| Image disk+memory cache & downscaling (`memCacheWidth`) | `AppNetworkImage` |
| Skeleton shimmers (perceived speed) | `home_screen.dart`, `AppNetworkImage` |
| Lazy lists / slivers / masonry grid | home screen |
| `const` widgets + IndexedStack tab retention | `app.dart` |
| Pagination (`page`, `per_page`) | service layer |

## Security model (important)

The WooCommerce Consumer **Secret** is effectively a password to the shop.

- **On device:** ship only a **read-only** key for catalog browsing. Even then,
  prefer routing through a thin proxy. Read GETs are low-risk and cache well.
- **Writes (orders, account creation, payments):** route through a **server
  proxy** (Cloudflare Worker / small Node/PHP endpoint) that holds the
  write-enabled secret. The app calls the proxy with the customer's JWT; the
  proxy calls WooCommerce. This keeps the secret out of the APK.
- **Customer sessions:** JWT via the *JWT Authentication for WP REST API* plugin.
  Tokens stored in `flutter_secure_storage`. The Dio interceptor attaches the
  bearer token to WP user calls.

The current code attaches keys directly to keep the starter runnable; the
interceptor (`_AuthInterceptor`) is the single swap-point to move writes behind
a proxy — change the `baseUrl`/auth for non-GET there.

## Cloudflare

**Caching (Cache Rules):**
- Match: `URI Path contains "/wp-json/wc/v3/products"` and `Request Method == GET`
  → *Eligible for cache*, Edge TTL 5–15 min, *Cache by query string: include*
  (so category/page variants cache separately). Add `Bypass cache on cookie` for
  logged-in sessions if you serve personalised data.
- Never cache `/orders`, `/customers`, `/jwt-auth/*` (non-GET; ensure no rule
  forces caching).

**WAF / Bot protection:**
- The app sends `X-Ayshamart-Client: android-app`. Create a **WAF custom rule
  (Skip)**: when `http.request.headers["x-ayshamart-client"][0] == "android-app"`
  → *Skip: Managed Challenge, Browser Integrity Check*. This stops Cloudflare
  from challenging legitimate app traffic (which has no browser to solve a
  challenge). Combine with a rate-limit rule so the header can't be abused.

**Tip:** keep query params stable and ordered to maximise cache HIT ratio. The
service builds them deterministically.

## Data flow example — Home flash sale

1. `HomeScreen` watches `flashSaleProvider`.
2. Provider calls `CatalogRepository.products(onSale: true)`.
3. Repo (live mode) calls `WooCommerceService.getProducts(onSale:true, _fields:…)`.
4. Dio interceptor appends `consumer_key/secret` (GET → query params, cacheable).
5. Cloudflare serves a cache HIT when warm; else WooCommerce responds.
6. JSON → `Product.fromJson` → typed list → `FlashSaleSection` renders with ৳.
