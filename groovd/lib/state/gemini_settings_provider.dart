import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:groovd/core/constants/gemini_config.dart';

class GeminiSettingsState {
  final String apiKey;
  final bool isConfigured;

  const GeminiSettingsState({
    this.apiKey = '',
    this.isConfigured = false,
  });

  GeminiSettingsState copyWith({
    String? apiKey,
    bool? isConfigured,
  }) {
    return GeminiSettingsState(
      apiKey: apiKey ?? this.apiKey,
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }
}

class GeminiSettingsNotifier extends Notifier<GeminiSettingsState> {
  static const _apiKeyKey = 'groovd_gemini_api_key';

  @override
  GeminiSettingsState build() {
    _loadKey();
    return GeminiSettingsState(
      apiKey: GeminiConfig.defaultKey,
      isConfigured: GeminiConfig.isConfigured,
    );
  }

  Future<void> _loadKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var key = prefs.getString(_apiKeyKey) ?? '';

      // Fallback to GeminiConfig if not set in SharedPreferences
      if (key.isEmpty && GeminiConfig.defaultKey.isNotEmpty) {
        key = GeminiConfig.defaultKey;
      }

      final isConfigured = key.trim().isNotEmpty;
      state = GeminiSettingsState(
        apiKey: key.trim(),
        isConfigured: isConfigured,
      );
    } catch (_) {}
  }

  Future<void> saveApiKey(String key) async {
    final cleanKey = key.trim();
    final isConfigured = cleanKey.isNotEmpty;

    state = GeminiSettingsState(
      apiKey: cleanKey,
      isConfigured: isConfigured,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      if (isConfigured) {
        await prefs.setString(_apiKeyKey, cleanKey);
      } else {
        await prefs.remove(_apiKeyKey);
      }
    } catch (_) {}
  }

  Future<void> clearApiKey() async {
    state = const GeminiSettingsState(
      apiKey: '',
      isConfigured: false,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_apiKeyKey);
    } catch (_) {}
  }
}

final geminiSettingsProvider =
    NotifierProvider<GeminiSettingsNotifier, GeminiSettingsState>(
  GeminiSettingsNotifier.new,
);

