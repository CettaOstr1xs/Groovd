/// Last.fm Web Services configuration.
///
/// You can paste your Last.fm API Key directly here,
/// OR enter it in the app under Dossier -> Settings.
class LastFmConfig {
  LastFmConfig._();

  /// Default Last.fm API key (can be overridden via environment or app settings).
  /// Get a free key at https://www.last.fm/api/account/create
  static const String apiKey = 'b25b959554ed76058ac220b7b2e0a026';

  static bool get isConfigured => apiKey.trim().isNotEmpty;
}
