import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kHasSeenLandingKey = 'groovd_has_seen_landing_v1';

/// Manages whether the guest has viewed or bypassed the welcome landing screen.
class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadFromPrefs();
    return false;
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool(_kHasSeenLandingKey) ?? false;
      state = hasSeen;
    } catch (_) {}
  }

  /// Marks the onboarding / landing screen as completed or bypassed.
  Future<void> completeOnboarding() async {
    state = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kHasSeenLandingKey, true);
    } catch (_) {}
  }

  /// Resets the onboarding status, used on logout so the user sees the landing page again.
  Future<void> resetOnboarding() async {
    state = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kHasSeenLandingKey, false);
    } catch (_) {}
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);
