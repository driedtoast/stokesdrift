import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';

/// Manages the rate/review prompt triggered after successful scans.
///
/// We prompt the user after their 5th successful scan, and never again
/// once they've been prompted. The In-App Review API handles the rest
/// (including Apple's throttling and Google's review flow).
class ReviewPrompt {
  static const _scanCountKey = 'review_prompt_scan_count';
  static const _hasPromptedKey = 'review_prompt_has_prompted';
  static const _triggerThreshold = 5;

  /// Call this after every successful item scan.
  /// It increments the counter and triggers the review prompt when
  /// the threshold is reached.
  static Future<void> recordScan() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPrompted = prefs.getBool(_hasPromptedKey) ?? false;
    if (hasPrompted) return; // Already prompted, don't annoy

    final count = (prefs.getInt(_scanCountKey) ?? 0) + 1;
    await prefs.setInt(_scanCountKey, count);

    if (count >= _triggerThreshold) {
      await _requestReview();
      await prefs.setBool(_hasPromptedKey, true);
    }
  }

  /// Call this after a successful checkout scan (all items scanned).
  /// This is an even better moment to prompt — the user just had a
  /// "wow, that saved me" experience.
  static Future<void> recordCheckoutComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPrompted = prefs.getBool(_hasPromptedKey) ?? false;
    if (hasPrompted) return;

    await _requestReview();
    await prefs.setBool(_hasPromptedKey, true);
  }

  static Future<void> _requestReview() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    }
  }

  /// Reset for testing purposes.
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scanCountKey);
    await prefs.remove(_hasPromptedKey);
  }
}