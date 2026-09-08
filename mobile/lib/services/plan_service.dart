import 'package:shared_preferences/shared_preferences.dart';

/// Manages the user's subscription plan.
///
/// For now this is a local stub that stores the plan in SharedPreferences.
/// When the API sync is implemented, this will be replaced with a real
/// subscription check against the backend.
///
/// Plan tiers:
/// - free: Solo use, up to 100 items, no CSV export
/// - crew: $9/mo, 5 members, CSV export enabled
/// - enterprise: $29/mo, unlimited members, CSV export enabled
class PlanService {
  static const _planKey = 'subscription_plan';

  static const free = 'free';
  static const crew = 'crew';
  static const enterprise = 'enterprise';

  /// Get the current plan. Defaults to 'free'.
  static Future<String> getPlan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_planKey) ?? free;
  }

  /// Set the plan (for testing or when sync confirms a purchase).
  static Future<void> setPlan(String plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planKey, plan);
  }

  /// Whether the user can export to CSV (crew or enterprise only).
  static Future<bool> canExportCsv() async {
    final plan = await getPlan();
    return plan != free;
  }

  /// Whether the user can use team sync (crew or enterprise only).
  static Future<bool> canSyncTeam() async {
    final plan = await getPlan();
    return plan != free;
  }

  /// Whether the user has unlimited items (crew or enterprise only).
  static Future<bool> hasUnlimitedItems() async {
    final plan = await getPlan();
    return plan != free;
  }

  /// Human-readable plan name.
  static String planDisplayName(String plan) {
    switch (plan) {
      case crew:
        return 'Crew';
      case enterprise:
        return 'Enterprise';
      default:
        return 'Free';
    }
  }
}