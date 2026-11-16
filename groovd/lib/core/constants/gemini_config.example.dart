/// Example configuration constants for AI critic integration.
///
/// Copy this file to `gemini_config.dart` and enter your API key if desired,
/// or leave empty and enter your API key directly within the app under DOSSIER -> Settings.
class GeminiConfig {
  /// Default API key loaded at build time via --dart-define=GEMINI_API_KEY=xxx
  /// or left empty for in-app configuration.
  static const String defaultKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// AI Critic model identifier
  static const String modelName = 'gemini-3.5-flash-lite';

  /// Whether a default key is configured at build time
  static bool get isConfigured => defaultKey.trim().isNotEmpty;
}

