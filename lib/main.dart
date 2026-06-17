import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';

/// Application entry point.
///
/// Initialisation order matters for a fast, smooth first frame:
///  1. ensureInitialized (binding)
///  2. system UI / orientation
///  3. (production) Firebase.initializeApp + FCM background handler — see
///     docs/PUSH_NOTIFICATIONS.md. Kept out of the default build so the app
///     runs without a Firebase config during early development.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait for a focused shopping experience.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Surface a clear hint in debug if the store keys are missing — the app
  // still runs on bundled demo data.
  assert(() {
    if (!AppConfig.hasCredentials) {
      debugPrint(
        '[Ayshamart] No WooCommerce credentials provided — running on DEMO '
        'data. Pass --dart-define=WC_CONSUMER_KEY=... to connect the store.',
      );
    }
    return true;
  }());

  runApp(const ProviderScope(child: AyshamartApp()));
}
