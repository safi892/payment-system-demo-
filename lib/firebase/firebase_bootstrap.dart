import 'package:firebase_core/firebase_core.dart';

/// Runtime probe for Firebase availability.
///
/// `configured` is `true` only when `android/app/google-services.json` is
/// present and the google-services Gradle plugin has processed it into the
/// app. When it is `false`, every service automatically falls back to its
/// simulated implementation, so the app always runs — with or without a
/// Firebase project.
///
/// This is what makes Phase 3 dual-mode: wire the console config and the
/// app switches to real auth + Firestore with no code change.
abstract final class FirebaseBootstrap {
  static bool configured = false;
  static String? lastError;

  static Future<void> initialize() async {
    if (configured) return;
    try {
      await Firebase.initializeApp();
      configured = true;
      lastError = null;
    } catch (e) {
      configured = false;
      lastError = '$e';
    }
  }
}
