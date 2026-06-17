# Setup Guide

Step-by-step from a clean machine to a running, store-connected app.

## 1. Install the toolchain

```bash
# Install Flutter (https://docs.flutter.dev/get-started/install)
flutter --version      # expect >= 3.22
flutter doctor         # resolve any reported issues (Android SDK, licenses)
```

## 2. Get dependencies

```bash
cd Ayshamart-App

# This repo contains the Dart source + config. Generate the platform folders
# (android/, ios/, etc.) once on your machine — this does NOT overwrite lib/:
flutter create . --org com.ayshamart --project-name ayshamart_app --platforms=android,ios

flutter pub get

# (Optional) generate the localized strings classes from lib/l10n/*.arb
flutter gen-l10n
```

The app runs immediately on **bundled demo data** — no keys required — so you
can preview the UI first:

```bash
flutter run
```

## 3. Generate WooCommerce REST API keys

1. WordPress Admin → **WooCommerce → Settings → Advanced → REST API**.
2. **Add key**:
   - Description: `Ayshamart Android App (read)`
   - User: an admin/shop-manager account
   - Permissions: **Read** (catalog only — recommended for on-device key)
3. Copy the **Consumer key** (`ck_…`) and **Consumer secret** (`cs_…`).

> Create a **second, write-enabled key** for order creation, but keep it on a
> server proxy — not in the app binary. See `docs/ARCHITECTURE.md` §Security.

## 4. Run against the live store

```bash
flutter run \
  --dart-define=WC_BASE_URL=https://ayshamart.com \
  --dart-define=WC_CONSUMER_KEY=ck_xxxxxxxxxxxxxxxx \
  --dart-define=WC_CONSUMER_SECRET=cs_xxxxxxxxxxxxxxxx
```

For repeatable builds, put these in a `--dart-define-from-file`:

```jsonc
// config/dev.json  (git-ignored)
{
  "WC_BASE_URL": "https://ayshamart.com",
  "WC_CONSUMER_KEY": "ck_...",
  "WC_CONSUMER_SECRET": "cs_..."
}
```
```bash
flutter run --dart-define-from-file=config/dev.json
```

## 5. Bengali fonts (typography)

The theme uses **Hind Siliguri** (full Bengali coverage + correct ৳ glyph).

- **Easiest:** nothing to do — `google_fonts` fetches it at runtime in dev.
- **Production (recommended, offline-safe):** download the TTFs and drop them in
  `assets/fonts/`:
  - `HindSiliguri-Regular.ttf`, `-Medium.ttf`, `-SemiBold.ttf`, `-Bold.ttf`
  - Source: Google Fonts → *Hind Siliguri* (Open Font License).
  These are already declared in `pubspec.yaml`. Verify the ৳ symbol renders in a
  price label after adding them.

## 6. Required WordPress plugins

| Purpose | Plugin |
|---------|--------|
| Customer login (JWT) | *JWT Authentication for WP REST API* |
| Payments (gateway) | *SSLCommerz for WooCommerce* and/or *bKash PGW* |
| (Optional) banners | ACF + a small custom REST route, or any "app banners" plugin |

After installing the JWT plugin, add to `wp-config.php`:
```php
define('JWT_AUTH_SECRET_KEY', 'a-long-random-secret');
define('JWT_AUTH_CORS_ENABLE', true);
```

## 7. Cloudflare configuration

See `docs/ARCHITECTURE.md` §Cloudflare for the exact cache rules and a WAF
allow-list rule keyed off the app's `X-Ayshamart-Client: android-app` header.

## 8. Android release build

```bash
flutter build apk --release --dart-define-from-file=config/prod.json
# or an app bundle for Play Store
flutter build appbundle --release --dart-define-from-file=config/prod.json
```

Set up signing in `android/key.properties` (git-ignored) per the Flutter docs.

## 9. Firebase (push) — optional, do when ready

Follow `docs/PUSH_NOTIFICATIONS.md`. Until then the app builds and runs without
any Firebase config.
