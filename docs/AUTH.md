# Authentication

Customer login/registration backed by WordPress + WooCommerce.

## How it works

```
Login    → POST /wp-json/jwt-auth/v1/token  (username/password) → JWT
         → GET  /wp-json/wp/v2/users/me      (Bearer JWT)        → AppUser
Register → POST /wp-json/wc/v3/customers     (creates customer)  → auto-login
Restore  → on app start, read JWT from secure storage → validate via /users/me
Logout   → wipe JWT from secure storage
```

- **Token storage:** `flutter_secure_storage` (Android Keystore / iOS Keychain)
  — never plain SharedPreferences. See `core/storage/token_storage.dart`.
- **Token injection:** `AuthController` registers `DioClient.authTokenProvider`,
  so the Dio interceptor attaches `Authorization: Bearer <jwt>` synchronously to
  every WordPress request once signed in.
- **Order linking:** when signed in, checkout passes `customer_id` so orders
  attach to the account and appear in order history.

## Required WordPress setup

1. Install **JWT Authentication for WP REST API**.
2. Add to `wp-config.php`:
   ```php
   define('JWT_AUTH_SECRET_KEY', 'a-long-random-secret');
   define('JWT_AUTH_CORS_ENABLE', true);
   ```
3. Ensure your server passes the `Authorization` header to PHP. For Apache add
   to `.htaccess`:
   ```apache
   RewriteEngine on
   RewriteCond %{HTTP:Authorization} ^(.*)
   RewriteRule ^(.*) - [E=HTTP_AUTHORIZATION:%1]
   ```
4. Allow customer registration: WooCommerce → Settings → Accounts & Privacy →
   "Allow customers to create an account".

## Security notes

- Registration (`wc/v3/customers`) is a **write** call needing the consumer
  secret. For production, proxy it through your server so the secret isn't in
  the APK (see `docs/ARCHITECTURE.md` §Security). The `AuthService` is the single
  swap-point.
- JWTs expire (default 7 days). On a 401/403 the controller wipes the token and
  drops to the unauthenticated state, prompting re-login.
- Consider adding "forgot password" via the WP `/wp/v2` lost-password flow or a
  custom endpoint.

## Files

| File | Responsibility |
|------|----------------|
| `data/models/app_user.dart` | User model (WP + Woo shapes) |
| `core/storage/token_storage.dart` | Encrypted JWT persistence |
| `data/services/auth_service.dart` | login / register / currentUser calls |
| `features/auth/providers/auth_provider.dart` | State + token lifecycle |
| `features/auth/presentation/login_screen.dart` | Sign-in UI |
| `features/auth/presentation/register_screen.dart` | Registration UI |
| `features/account/presentation/account_screen.dart` | Profile + language + logout |
