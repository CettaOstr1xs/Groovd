import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:groovd/core/constants/gemini_config.dart';
import 'package:groovd/state/gemini_settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeminiSettingsProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initializes with defaultKey and reports isConfigured correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(geminiSettingsProvider);
      expect(state.apiKey, equals(GeminiConfig.defaultKey));
      expect(state.isConfigured, equals(GeminiConfig.isConfigured));
    });

    test('GeminiConfig has pre-configured defaultKey for instant out-of-the-box chat', () {
      expect(GeminiConfig.defaultKey, startsWith('AQ.Ab8'));
      expect(GeminiConfig.isConfigured, isTrue);
    });

    test('GeminiConfig uses free gemini-3.5-flash-lite model', () {
      expect(GeminiConfig.modelName, equals('gemini-3.5-flash-lite'));
    });

    test('saveApiKey persists to SharedPreferences and updates state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(geminiSettingsProvider.notifier).saveApiKey('AIzaSyTestKey123');

      final state = container.read(geminiSettingsProvider);
      expect(state.apiKey, equals('AIzaSyTestKey123'));
      expect(state.isConfigured, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('groovd_gemini_api_key'), equals('AIzaSyTestKey123'));
    });

    test('clearApiKey removes custom key from preferences and resets to defaultKey', () async {
      SharedPreferences.setMockInitialValues({'groovd_gemini_api_key': 'existing_key'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(geminiSettingsProvider.notifier).clearApiKey();

      final state = container.read(geminiSettingsProvider);
      expect(state.apiKey, equals(GeminiConfig.defaultKey));
      expect(state.isConfigured, equals(GeminiConfig.isConfigured));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('groovd_gemini_api_key'), isNull);
    });
  });
}

