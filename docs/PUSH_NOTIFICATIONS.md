# Push Notifications (FCM)

Announce new gadget arrivals and seasonal sales with Firebase Cloud Messaging +
local notifications. Kept out of the default build so the app runs without a
Firebase project during early development; wire it up when ready.

## 1. Create the Firebase project

1. https://console.firebase.google.com → **Add project** (`Ayshamart`).
2. Add an **Android app**, package name e.g. `com.ayshamart.app` (must match
   `android/app/build.gradle` `applicationId`).
3. Download **`google-services.json`** → place in `android/app/`.
   (It's git-ignored — never commit it.)
4. (iOS later) Add iOS app, download `GoogleService-Info.plist`, enable APNs.

Or use the FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

## 2. Android Gradle wiring

`android/build.gradle`:
```gradle
buildscript { dependencies { classpath 'com.google.gms:google-services:4.4.2' } }
```
`android/app/build.gradle` (bottom):
```gradle
apply plugin: 'com.google.gms.google-services'
```

## 3. Initialise in `main.dart`

Uncomment / add before `runApp`:
```dart
await Firebase.initializeApp();
FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
await PushService.instance.init();   // requests permission, gets token, topics
```

## 4. PushService (skeleton to add under lib/core/notifications/)

```dart
class PushService {
  static final instance = PushService._();
  final _fln = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await FirebaseMessaging.instance.requestPermission(); // iOS + Android 13+
    await _initLocalNotifications();

    // Topic subscriptions for broadcast campaigns
    await FirebaseMessaging.instance.subscribeToTopic('all-users');
    await FirebaseMessaging.instance.subscribeToTopic('new-arrivals');
    await FirebaseMessaging.instance.subscribeToTopic('sales');

    // Foreground messages → show a local notification
    FirebaseMessaging.onMessage.listen((m) => _show(m));
    // Tapped notification (background) → deep link
    FirebaseMessaging.onMessageOpenedApp.listen(_handleDeepLink);

    final token = await FirebaseMessaging.instance.getToken();
    // Optionally POST token to your backend for targeted sends.
  }
  // _initLocalNotifications / _show / _handleDeepLink ...
}

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
```

## 5. Android 13+ runtime permission

Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```
`requestPermission()` triggers the system dialog.

## 6. Sending campaigns

- **Marketing blasts:** Firebase Console → Messaging → send to topic
  `new-arrivals` or `sales`.
- **Targeted (order updates):** store device tokens server-side, send via the
  FCM HTTP v1 API, include a `data` payload with a `deeplink` (e.g.
  `product:101`) that `_handleDeepLink` routes with go_router.

## 7. Deep-link payload convention

Reuse the banner convention so notifications and banners share routing:
```
data: { "deeplink": "category:3" }   // or "product:101", "url:https://..."
```

## Test checklist

- [ ] Permission prompt shows on Android 13+ / iOS
- [ ] Foreground message shows a local notification
- [ ] Tapping a notification opens the correct product/category
- [ ] Topic send reaches a test device
```
