# Building & Testing the APK

Three ways to get a testable app on a phone — pick what fits you.

---

## Option A — GitHub Actions (no local setup) ⭐ easiest

The repo includes `.github/workflows/build-apk.yml`. It builds a debug APK on
every push and on demand.

1. Push is already done → open the repo on GitHub → **Actions** tab.
2. Open the latest **"Build Android APK"** run (or click **Run workflow**).
3. When it finishes (~5–8 min), scroll to **Artifacts** → download
   **`ayshamart-apk`** (a zip).
4. Unzip → you get `app-debug.apk`.
5. Copy it to your Android phone and tap to install (allow "Install from unknown
   sources" when prompted).

> The app opens on **demo data** so the UI works immediately. To build against
> the live store, add repo **Settings → Secrets → Actions**:
> `WC_CONSUMER_KEY`, `WC_CONSUMER_SECRET`. The workflow injects them automatically.

---

## Option B — Build locally (full dev setup)

Requires the Flutter SDK + Android toolchain once.

```bash
# 0. One-time: install Flutter + Android Studio, then:
flutter doctor                 # fix anything it flags (Android SDK, licenses)

# 1. In the project root, generate the android/ folder (keeps lib/ intact):
flutter create --org com.ayshamart --project-name ayshamart_app --platforms=android .

# 2. Dependencies + localizations
flutter pub get
flutter gen-l10n

# 3a. Run on a connected phone / emulator (hot reload, demo data):
flutter run

# 3b. …or against the live store:
flutter run \
  --dart-define=WC_BASE_URL=https://ayshamart.com \
  --dart-define=WC_CONSUMER_KEY=ck_xxx \
  --dart-define=WC_CONSUMER_SECRET=cs_xxx

# 4. Build an installable APK:
flutter build apk --debug
#   → output: build/app/outputs/flutter-apk/app-debug.apk

# 5. Install it on a USB-connected phone:
flutter install
```

### Run on a real phone
- Enable **Developer options → USB debugging** on the phone, connect via USB,
  accept the prompt, then `flutter devices` should list it → `flutter run`.

### Run on an emulator
- Android Studio → **Device Manager** → create a Pixel virtual device → start it,
  then `flutter run`.

---

## Option C — Release APK (for sharing / Play Store)

```bash
flutter build apk --release          # single APK
# or, smaller per-device APKs:
flutter build apk --release --split-per-abi
# or an app bundle for the Play Store:
flutter build appbundle --release
```

For Play Store distribution you must sign with your own keystore — see the
Flutter docs and `android/key.properties` (git-ignored). The default template
signs `--release` with the debug key, which is fine for personal testing but
**not** for publishing.

---

## What works without store keys (demo mode)
✅ Home, banners, categories, flash sale, product detail, cart, language toggle,
the full checkout UI.
⚠️ Placing an order, login, and registration are **write/auth** calls that hit
your real WooCommerce backend — they need valid keys (Option A secrets or the
`--dart-define` flags) and the JWT plugin (see `docs/AUTH.md`).

## First-run note on fonts
Bengali typography (Hind Siliguri) loads via `google_fonts` on first launch, so
the **first** run needs internet (demo product images need it too). For an
offline-safe build, bundle the TTFs — see `docs/SETUP.md` §5.

## Troubleshooting
| Symptom | Fix |
|---------|-----|
| `No pubspec.yaml` / `android` missing | run the `flutter create … .` step first |
| Gradle/AGP or SDK errors | `flutter doctor`, update Android SDK, accept licenses |
| Boxes instead of Bengali/৳ on first launch | ensure internet on first run (google_fonts), or bundle TTFs |
| APK won't install | enable "Install unknown apps" for your file manager |
